{System, ChargedSystem} = require '../BaseSystem'
C = require '../Constants'
Utility = require '../Utility'

up_to = ( n ) ->
    Math.floor(Math.random() * n)


OPERABILITY =
    OPERABLE: 'Operable'
    NONOPERABLE: 'Non-Operable'


class ReactorSystem extends System
    # Class for systems that generate power

    @ANTIMATTER = { max : 2.3, dyn : 1e6 }
    @FUSION = { max : 1.2, dyn : 1e3 }
    @BATTERY = { max : 1, dyn : 1e2 }

    @ANTIMATTER_SIGNATURE = [
        0.025477707
        0.2038216561
        0.2547770701
        0.2038216561
        0.127388535
        0.0891719745
        0.050955414
        0.025477707
        0.0127388535
        0.0063694268
    ]

    @FUSION_SIGNATURE = [
        0
        0
        0.0458715596
        0.0183486239
        0.0917431193
        0.0183486239
        0
        0
        0.8256880734
        0
    ]

    @BATTERY_SIGNATURE = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    @OPERABILITY_CUTOFF = 0.8


    constructor: ( @name, @deck, @section, @output_profile, @relay, base_power_signature ) ->

        super @name, @deck, @section
        if @state < 1
            @state = 0.95 + up_to(5) / 100
        @output = 0
        if base_power_signature?
            @_init_power_signature base_power_signature
        else
            console.log "Warning: #{ @name } set without power signature"


    _init_power_signature: ( base_signature ) ->

        @power_signature = []
        for i in base_signature
            p = i * ( 1 + ( 0.05 - Math.random() * 0.1 ) )
            @power_signature.push p


    push_power: ( power ) -> @relay.push_power power


    output_level: () -> @output / @output_profile.dyn


    activate: ( level ) ->

        if isNaN level
            throw new Error("Invalid power level for #{@name}: #{level}")

        level = Math.max level, 0
        @online = true

        # Turns on the power source, operating a the percentage level
        @output = (Math.min level, @output_profile.max) * @output_profile.dyn
        @push_power @output


    is_online: ->

        working_order = @state > ReactorSystem.OPERABILITY_CUTOFF
        if working_order and @online
            return true
        return false


    is_attached: ( relay ) -> @relay is relay


    set_required_output_power: () ->

        # Startup sequence helper
        required_output = do @relay.get_required_power
        balance = do @relay.get_required_power_balance
        if not balance?
            return
        @relay.set_system_balance balance
        do @relay.set_required_power_balance
        @activate required_output / @output_profile.dyn


    calculate_level_for_additional_output: ( output ) ->
        # Returns the level required for the additional
        # power required (output). Can be negative.
        level = (@output + output) / @output_profile.dyn


    power_distribution_report: () ->

        r = {}
        r['name'] = @name
        r['primary_relay'] = @relay.power_distribution_report()
        r['output'] = @output
        r['output_level'] = @output / @output_profile.dyn
        r['max_level'] = @output_profile.max
        return r


    damage_report: () ->

        operability = if @state > ReactorSystem.OPERABILITY_CUTOFF then OPERABILITY.OPERABLE else OPERABILITY.NONOPERABLE
        time_to_operability = do @_time_to_operability
        repair_requirements = []

        for k, v of @_repair_reqs
            repair_requirements.push({
                material : k,
                quantity : Utility.round_up( v * (1 - @state), 2 )
            })

        state =
            name: @name
            deck: @deck
            section: @section
            integrity: Utility.round( @state, 2 )
            repair_requirements: repair_requirements
            time_to_repair: do @_time_to_repair
            operability: operability
            online: @online

        if time_to_operability > 0
            state['time_to_operability'] = time_to_operability

        return state


    field_output: () ->

        if not @online
            return []

        r = ( c * @output for c in @power_signature )


class PowerSystem extends System
    # Class for systems that route power

    @WARP_RELAY_POWER = { min : 0, max : 4, dyn : 1e6 }
    @IMPULSE_RELAY_POWER = { min : 0, max : 1.1, dyn : 1e3 }
    @EMERGENCY_RELAY_POWER = { min : 0, max : 4, dyn : 1e2 }

    @EPS_RELAY_POWER = { min : 0, max : 4, dyn : 1e5 }

    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        super @name, @deck, @section, @power_thresholds
        # Power systems shunt their power to routed systems
        @attached_systems = []
        # A same-sized array maintains the power balance
        @power_distribution = []
        @input_power = 0


    add_route: ( system ) ->

        @attached_systems.push system
        @power_distribution.push 0


    remove_route: ( system ) ->

        index = @attached_systems.indexOf system
        @attached_systems = (s for s, i in @attached_systems when i isnt index)
        @power_distribution = (p for p, i in @power_distribution when i isnt index)


    is_attached: ( system ) -> system in @attached_systems


    get_systems: () ->

        r = {}
        for s, i in @attached_systems
            power_report = s.power_report()
            power_report['power'] = @power_distribution[i]
            r[s.name] = power_report
        return r


    get_required_power: () ->
        ###
        Determine the required power for all systems to
        operate a full capacity, up to the EPS maximum.

        ###

        p = 0

        sys_names = (s?.name for s in @attached_systems)

        for s in @attached_systems
            if not s? or not s?.get_required_power?
                throw new Error "invalid system in #{@name}: #{sys_names}"
            p += do s.get_required_power

        Math.min p, @power_thresholds.dyn * @power_thresholds.max


    set_system_balance: ( power_balance ) ->

        if power_balance?.length isnt @power_distribution.length
            throw new Error "Invalid power balance for #{@name}: #{ power_balance }"

        if not @is_online() or not @_fuse_on
            throw new Error "#{@name} Fused: Cannot reallocate power."

        sum = 0
        sum += p for p in power_balance
        # Rounding errors
        if sum < 0.999999
            console.log "#{@name}: Power levels don't sum (#{sum})--rebalancing"
            power_balance = (p/sum for p in power_balance)

        if sum == 0
            throw new Error "#{@name} invalid power balance calculated:
                all zero"

        @power_distribution = power_balance
        @push_power()


    calculate_new_balance: ( system, power ) ->

        i = @attached_systems.indexOf system
        power_dist = (@input_power * p for p in @power_distribution)
        power_dist[ i ] += power
        new_sum = 0
        new_sum += pwr for pwr in power_dist
        new_balance = (pwr/new_sum for pwr in power_dist)


    get_required_power_balance: () ->
        ###
        Initialization report to ensure
        the required power balance so that
        all systems receive their required full operating
        requirements.

        ###

        if @attached_systems.length == 0
            return

        megadynes = (s.get_required_power() for s in @attached_systems)
        sum = 0
        sum += megadyne for megadyne in megadynes when megadyne?
        balance = (megadyne / sum for megadyne in megadynes when megadyne?)


    set_required_power_balance: () ->
        ###
        Check for any attached power subsystems and have them
        prep for power flow
        ###
        for sys in @attached_systems
            if sys.get_required_power_balance?
                sys.set_system_balance do sys.get_required_power_balance


    power_distribution_report: () ->

        r = {'name': @name}
        subsystems = []
        for sys, i in @attached_systems
            sys_report = sys.power_report()
            if sys.power_distribution_report?
                # If you are a sub relay...
                sys_report = sys.power_distribution_report()
            subsystems.push sys_report
        r['subsystems'] = subsystems
        r['power_distribution'] = @power_distribution
        r['power'] = @input_power
        r['max_power_level'] = @power_thresholds.max
        r['min_power_level'] = 0
        r['current_power_level'] = @input_power / @power_thresholds.dyn
        return r


    power_report: () ->

        r =
            name: @name
            power: @input_power
            current_power_level: @input_power / @power_thresholds.dyn
            max_power_level: @power_thresholds.max
            min_power_level: @power_thresholds.min
            operational_dynes: @power_thresholds.dyn


    push_power: ( input_power ) ->
        ###
        Use the last input power if not given so that the
        function can be called from either a refresh or push
        method

        ###

        if input_power?
            @input_power = input_power

        max_power = @power_thresholds.max * @power_thresholds.dyn

        if @input_power > max_power
            @damage 1 * System.STRENGTH
            @_fuse_on = false
            @online = false

            console.log "WARNING: #{@name} blown. Attempting to push
            #{@input_power} Mdyn. Maximum rated power: #{max_power} Mdyn"
            console.log "\tCurrent Locked Distribution:"
            for s, i in @attached_systems
                p = @power_distribution[i]
                console.log "\t#{ s.name }\t#{ p * 100 }%"

        for s, i in @attached_systems

            power_level = @power_distribution[i]
            power_to_push = power_level * @input_power
            power_pushed = s.push_power power_to_push

            if not power_pushed?
                throw new Error "Failed to push power to #{s.name}"

            if power_pushed == 0 and power_to_push > 0
                # Blowout condition
                console.log "Power blowout to #{ s.name },
                #{ power_to_push } MDyn, power report:"
                console.log do s.power_report

                # This system blew up, cannot push power to it.
                # Presumably it's now pouring plasma all over itself


    is_online: () -> @state > System.OPERABILITY_CUTOFF


exports.PowerSystem = PowerSystem
exports.ReactorSystem = ReactorSystem