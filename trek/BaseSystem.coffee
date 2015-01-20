Cargo = require './Cargo'
C = require './Constants'
Utility = require './Utility'

up_to = ( n ) ->
    Math.floor(Math.random() * n)

OPERABILITY =
    OPERABLE: 'Operable'
    NONOPERABLE: 'Non-Operable'


class System

    @LIFESUPPORT_POWER = { min : 0.1, max : 2, dyn : 8e3 }

    @STATION_LIFESUPPORT_POWER = { min : 0.01, max : 3, dyn : 4.123e5 }

    @TRANSPONDER_POWER = { min : 0.1, max : 3, dyn : 4e3 }

    @SICKBAY_POWER = { min : 0.01, max : 1.3, dyn : 1e2 }

    @BRIG_POWER = { min : 0.1, max : 1.2, dyn : 1e2 }

    @DAMPENER_POWER = { min : 0.6, max : 1.7, dyn : 9e4 }

    @TRACTOR_POWER = { min : 0.1 , max : 2, dyn : 3e4 }

    @SENSOR_POWER = { min : 0.1, max : 1.7, dyn : 1e4 }

    @IMPULSE_POWER = { min : 0.01, max : 1.1, dyn : 1e3 }

    @REPAIR_TIME = 60 * 60 * 1000
    @OPERABILITY_CUTOFF = 0.2
    @STRENGTH = 150


    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        if not @deck? or not @section?
            throw new Error("Invalied deck and section for
                #{@name}: #{@deck} #{@section}")
        if not @power_thresholds?
            @power_thresholds = {'min': 1, 'max': 2, 'dyn': 1}
        if Math.random() > 0.8
            @state = 0.8 + up_to(20) / 100
        else
            @state = 1

        # consuming passive power
        @online = true

        # power subsystems blowout state
        @_fuse_on = true

        # materials required to repair
        @_repair_reqs = []
        @_repair_reqs[Cargo.COMPUTER_COMPONENTS] = up_to 5
        @_repair_reqs[Cargo.EPS_CONDUIT] = up_to 2
        # Power to the system, in megadynes
        @power = 0


    power_report: ->

        r =
            name: @name
            power: @power
            current_power_level: @power / @power_thresholds.dyn
            max_power_level: @power_thresholds.max
            min_power_level: @power_thresholds.min
            operational_dynes: @power_thresholds.dyn
            power_system_operational: @_fuse_on


    push_power: ( power ) ->

        # power (in Dynes) is being pushed to this system through charged plasma
        relative_power = power / @power_thresholds.dyn

        if not @_fuse_on
            # You may be pushing power, but nothing's coming out without some repairs
            # Otherwise you're just leaking plasma into the system and causing damage
            return 0

        # Normal operation
        if relative_power <= @power_thresholds.max
            return @power = power

        # Ya blew it
        console.log "#{ @name }: Too much power: #{ relative_power }x above operational levels."
        # Power components will be fused or blown
        @online = false
        @_fuse_on = false

        damage = ( relative_power - @power_thresholds.max ) / @power_thresholds.max
        damage = Math.min damage, 1
        @damage damage * System.STRENGTH

        @power = power

        # 0 indicates that this system is not operating with any power
        return 0


    update_system: ( delta_t_ms, engineering_locations ) ->

        engineers_in_position = ( c for c in engineering_locations when c.deck is @deck and c.section is @section )

        if @power > @power_thresholds.dyn and engineers_in_position.length is 0
            @_calculate_overdrive_damage delta_t_ms


    _calculate_overdrive_damage: ( delta_t_ms ) ->

        # power levels exceeding recommended operational levels
        diff = @power - @power_thresholds.dyn
        diff_pct = diff / ( ( @power_thresholds.max - 1 ) * @power_thresholds.dyn )

        # For every five minutes this system is running at this power level
        # the status should be damaged accordingly
        minutes = delta_t_ms / ( 5 * 60 * 1000 )
        damage_from_overdrive = diff_pct * minutes * System.STRENGTH
        @damage damage_from_overdrive


    damage: ( amt ) ->

        if typeof amt isnt 'number'
            throw new Error("We only accept numeric damage values: #{ amt }")

        dmg_pct = amt / System.STRENGTH

        if @state > 0
            @state = Math.max @state-dmg_pct, 0

        if @state <= System.OPERABILITY_CUTOFF
            @online = false

        # console.log "#{ @name } damaged by #{ amt }: #{ dmg_pct * 100 }% state: #{ @state }"

        return @state


    repair: ( amt ) ->

        if not amt or typeof amt isnt 'number'
            throw new Error "Repair requires a numeric value,
                not #{ typeof amt } (#{ amt })"

        if not @_fuse_on
            # The first thing to be repaired should be the plasma system
            @_fuse_on = true

        if @state < 1
            @state += amt

        @state = Math.min 1, @state


    damage_report: ->

        if @state > System.OPERABILITY_CUTOFF
            operability = OPERABILITY.OPERABLE
        else
            operability = OPERABILITY.NONOPERABLE

        time_to_operability = do @_time_to_operability
        repair_requirements = []
        for k, v of @_repair_reqs
            repair_requirements.push {
                material : k,
                quantity : Utility.round_up( v * ( 1 - @state ), 2 )
            }

        state =
            name: @name
            deck: @deck
            section: @section
            integrity: Utility.round @state, 2
            repair_requirements: repair_requirements
            time_to_repair: do @_time_to_repair
            operability: operability
            online: @online
            power_system_operational: @_fuse_on

        if time_to_operability > 0
            state['time_to_operability'] = time_to_operability

        return state


    bring_online: ->

        @online = true

        { min, max, dyn } = @power_thresholds
        sufficient_power  = ( dyn * min ) <= @power <= ( dyn * max )
        if not sufficient_power
            @online = false

        working_order = @state > System.OPERABILITY_CUTOFF
        if not working_order
            @online = false

        return @online


    deactivate: -> @online = false


    power_off: ->

        console.log "Call to depreciated power_off. Use 'deactivate'."
        do @deactivate


    get_required_power: ->

        if @online
            return @power_thresholds.dyn * ( @power_thresholds.min + 0.1 )

        return 0


    is_online: -> @online


    performance: ->

        { min, max, dyn } = @power_thresholds
        performance = @power / dyn


    _time_to_operability: ->

        Math.floor( ( System.OPERABILITY_CUTOFF - @state ) *
            System.REPAIR_TIME )


    _time_to_repair: -> Math.floor (1 - @state) * System.REPAIR_TIME


    layout: ->
        r =
            name: @name
            deck: @deck
            section: @section


class ChargedSystem extends System

    @CHARGE_TIME = 10e3


    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        super @name, @deck, @section, @power_thresholds

        # charge is a percentage from 0 - 1
        # representing a muliplier against power_thresholds.dyn

        # power levels above dyn fill the charge faster

        @charge = 0
        @charge_time = ChargedSystem.CHARGE_TIME

        # Distinct from online
        # Active means consuming / using charge
        @active = false

        @_repair_reqs = []
        @_repair_reqs[Cargo.COMPUTER_COMPONENTS] = up_to 10
        @_repair_reqs[Cargo.EPS_CONDUIT] = up_to 20
        @_repair_reqs[Cargo.PHASE_COILS] = up_to 10


    bring_online: ->

        @online = true
        do @power_on


    power_down: ->

        @active = false
        @charge = 0


    power_on: ->

        if not do @is_online
            @active = false
            return

        @active = true
        @online = true

        return @active


    is_active: ->

        if @state < System.OPERABILITY_CUTOFF
            @active = false

        @active


    energy_level: ->

        if @state > System.OPERABILITY_CUTOFF and @active
            return @charge
        # console.log "#{ @name } No charge: state #{ @state }, active #{ @active }"
        return 0


    update_system: ( delta_t_ms, engineering_locations ) ->

        super delta_t_ms, engineering_locations
        @charge_up delta_t_ms


    charge_up: ( delta_t_ms ) =>

        if not do @is_online
            return
        if not @active
            return

        power_level = @power / @power_thresholds.dyn

        charge_pct_per_ms = 1 / @charge_time * power_level
        charge_accumulated = charge_pct_per_ms * delta_t_ms

        @charge = Math.min @charge + charge_accumulated, 1

        # bah
        if 0.99 < @charge < 1
            @charge = 1

        return @charge


    charge_down: ( amt, as_percentage=false ) ->

        if as_percentage
            pct = amt
        else
            # Allows for charging down by an amount of energy
            pct = amt / @power_thresholds.dyn

        # Expend this system's charge
        # EG phasers firing, SIFs discharging, or shields being hit
        new_charge = Utility.round( @charge - pct, 4 )

        if new_charge < 0
            #console.log "#{ @name } drained below capacity: #{ new_charge } damage"
            @damage( Math.abs new_charge )
            @active = false
        else
            #console.log "#{ @name } not drained: #{ new_charge }"

        @charge = Math.max 0, new_charge


    damage_report: ->

        if @state > System.OPERABILITY_CUTOFF

            operability = OPERABILITY.OPERABLE

        else

            operabiltiy = OPERABILITY.NONOPERABLE

        time_to_operability = do @_time_to_operability

        state =
            name: @name
            deck: @deck
            section: @section
            integrity: Utility.round @state, 2
            charge: Utility.round @charge, 2
            repair_requirements: ({
                material: k,
                quantity: Utility.round_up(
                    v * (1 - @state),
                    2)} for k, v of @_repair_reqs)
            time_to_repair: @_time_to_repair()
            operability: operability
            online: @online
            active: @active

        if time_to_operability > 0
            state['time_to_operability'] = time_to_operability

        return state


    power_report: ->

        r = super()
        r.charge = @charge
        return r


exports.System = System
exports.ChargedSystem = ChargedSystem