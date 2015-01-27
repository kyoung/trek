{System, ChargedSystem} = require '../BaseSystem'
{Transporters} = require '../systems/TransporterSystems'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{WarpSystem} = require '../systems/WarpSystems'
{ReactorSystem, PowerSystem} = require '../systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require '../systems/SensorSystems'
{SIFSystem} = require '../systems/SIFSystems'
{BridgeSystem} = require '../systems/BridgeSystems'
{Torpedo} = require '../Torpedo'
{BaseObject} = require '../BaseObject'
{CargoBay} = require '../CargoBay'
{Log} = require '../Log'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../Crew'

U = require '../Utility'
C = require '../Constants'

SECTIONS =
    PORT: 'Port'
    STARBOARD: 'Starboard'
    FORWARD: 'Forward'
    AFT: 'Aft'

# DECK A..R
DECKS = {}
for deck_number in [ 65..85 ]
    deck_letter = String.fromCharCode deck_number
    DECKS[deck_letter] = deck_letter


class BaseShip extends BaseObject

    @THRUSTER_DELTA_V_MPS = 200

    DECKS: DECKS
    SECTIONS: SECTIONS

    constructor: ( @name, @serial="" ) ->
        super()
        @state_stamp = do Date.now
        @alert = 'clear'
        @repairing = false
        @prefix_code = 1e4 + Math.round( Math.random() * 9e4 )
        @postfix_code =  do U.UID
        @bearing =
            bearing: 0
            mark: 0
        @bearing_v =
            bearing: 0
            mark: 0
        @_navigation_lock = false

        do @initialize_systems
        do @initialize_hull
        do @initialize_cargo
        do @initialize_crew
        do @initialize_logs

        @radiological_alerts = {} # Sectional radiological state
        for k, s of @SECTIONS
            @radiological_alerts[ s ] = false

        @impulse = 0
        @warp_speed = 0
        @navigation_target = null
        @set_shields false
        @alive = true
        @torpedo_inventory = 96
        @shuttles = []
        @_viewscreen_target = ""

        # Override these in your subclass to change your ship type
        @model_url = "constitution.js"
        @model_display_scale = 5
        @classification = "Starship"

        @_scan_density[ SensorSystem.SCANS.HIGHRES ] = Math.random() * 4
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES ] = Math.random() * 4

        # Socket messaging wonder
        @message = ( prefix, type, content ) ->
            console.log "Message from #{ @name } [#{ type }]:"
            console.log content


    set_message_function: ( new_message_function ) -> @message = new_message_function


    initialize_logs: ->

        @navigation_log = new Log "Navigation"
        @weapons_log = new Log "Tactical"
        @captains_log = new Log "Captain's"


    initialize_systems: ->

        # Override to configure ship's systems
        do @initialize_shileds
        do @initialize_weapons
        do @initialize_sensors
        do @initialize_power_systems

        do @initialize_power_connections

        # Turn on power
        do @_set_operational_reactor_settings

        # Activate basic systems
        do @primary_SIF.power_on
        do @secondary_SIF.power_on

        @systems = []


    initialize_power_connections: ->

        # Override to connect your power systems together


    initialize_power_systems: ->

        # Override to setup power systems
        @primary_power_relays = []
        @eps_grids = []
        @reactors = []
        @power_systems = [].concat(
            @primary_power_relays ).concat(
            @eps_grids ).concat(
            @reactors )


    initialize_shileds: ->

        # Override shield systems
        @shields = []


    initialize_weapons: ->

        # Override to setup phaser and torpedo systems
        @phasers = []
        @torpedo_banks = []


    initialize_sensors: ->

        # Override to populate your sensors
        @_logged_scanned_items = []
        @long_range_sensors = undefined
        @sensors = []


    initialize_hull: ->

        # Override to populate your hull object
        @hull = {}


    initialize_cargo: ->

        # Override to init you cargobays
        @cargobays = []


    initialize_crew: ->

        # Override to init your crew
        @internal_personnel = []


    set_coordinate: ( coordinate ) ->

        @position.x = coordinate.x
        @position.y = coordinate.y
        @position.z = coordinate.z

    set_bearing: ( bearing ) ->

        @bearing.bearing = bearing.bearing
        @bearing.mark = bearing.mark


    set_alignment: ( @alignment ) -> c.set_alignment @alignment for c in @crew


    get_postfix_code: ( prefix ) ->

        if prefix == @prefix_code
            return @postfix_code

        # If that was an invalid prefix code, then we want to return a random one
        return  Math.round( Math.random() * 10e16 ).toString( 16 ) +
        Math.round( Math.random() * 10e16 ).toString( 16 )



    ### Tactical
    _________________________________________________###


    hail: ( target ) ->

        if not @communication_array.is_online()
            throw new Error("Cannot hail. Communication array is offline.")
        console.log "{@name} <<incomming hail>>"


    set_alert: ( status ) ->

        @alert = status
        @message @prefix_code, "alert", status

        switch status
            when 'red'
                do @_power_shields
                do @_power_phasers
                do @_auto_load_torpedoes
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            when 'yellow'
                do @_power_shields
                do @_power_down_phasers
                do @_disable_torpedeo_autoload
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            when 'blue'
                do @_power_down_shields
                do @_power_down_phasers
                do @_disable_torpedeo_autoload
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            else
                do @_power_down_shields
                do @_power_down_phasers
                do @_disable_torpedeo_autoload
                @set_power_to_system @primary_SIF.name, SIFSystem.PRIMARY_POWER_PROFILE.min * 1.1
                @set_power_to_system @secondary_SIF.name, SIFSystem.SECONDARY_POWER_PROFILE.min * 1.1


    set_target: ( target, deck, section ) ->

        if not do @weapons_targeting.is_online
            throw new Error "Weapons Targeting systems offline."

        @weapons_targeting.set_target target, deck, section


    get_target_subsystems: ->

        ###
        Returns the name, deck, and section of all systems on a weapon's target

        ###

        if not @weapons_targeting.target?
            throw new Error "No weapons target selected."

        if not ( @weapons_targeting.target in @_logged_scanned_items )
            throw new Error "Cannot target subsystems until a detailed scan has been completed."

        ( { name : s.name, deck : s.deck, section: s.section } for s in @weapons_targeting.target.systems )


    fire_phasers: ( target=@weapons_targeting.target ) ->

        if target is null
            throw new Error 'No target selected'

        distance = U.distance @position, target.position
        if distance > PhaserSystem.RANGE
            throw new Error "Target is out of phaser range."

        if @warp_speed > 0 and distance > PhaserSystem.WARP_RANGE
            # TODO: Can fire within 5km; correct
            throw new Error "Firing phasers at warp requires close proximity. Close to within 5km."

        quad = @calculate_quadrant target.position

        if quad == @SECTIONS.FORWARD
            phaser = if @forward_phaser_bank_a.charge > @forward_phaser_bank_b.charge then @forward_phaser_bank_a else @forward_phaser_bank_b
        else if quad == @SECTIONS.PORT
            phaser = @port_phaser_bank
        else if quad == @SECTIONS.STARBOARD
            phaser = @starboard_phaser_bank
        else if quad == @SECTIONS.AFT
            phaser = @aft_phaser_bank

        if not do phaser.is_online
            throw new Error "Phaser system offline"

        #console.log "Firing #{ phaser.name } with #{ do phaser.energy_level } power"
        intensity = PhaserSystem.DAMAGE * do phaser.energy_level
        phaser.charge_down phaser.energy_level(), true

        target.process_phaser_damage @position, intensity, @weapons_targeting.target_deck, @weapons_targeting.target_section

        return 'OK'


    load_torpedo: ( tube_name ) ->

        if @torpedo_inventory == 0
            throw new Error "Insufficient torpedos to load."

        tubes = ( t for t in @torpedo_banks when t.name == tube_name )
        if tubes.length isnt 1
            throw new Error "Invalid torpedo bay: #{tube_number}"

        tube = tubes[0]
        tube.load()


    fire_torpedo: ( yield_level='16' ) ->

        if @weapons_targeting.target is null
            throw new Error 'Cannot fire without a target: Set target first'

        bearing_to_target = U.bearing @, @weapons_targeting.target
        quadrant = @calculate_quadrant_from_bearing bearing_to_target
        loaded_tubes = ( tube for tube in @torpedo_banks when tube.is_loaded() and tube.section_bearing == quadrant )
        if loaded_tubes.length == 0
            throw new Error "No loaded torpedo tubes in #{ quadrant } section.
            Please load torpedo tubes, or turn to target."
        tube = loaded_tubes[ 0 ]

        if not do @weapons_targeting.is_online
            throw new Error "Weapons Targeting Systems are Offline."

        if @torpedo_inventory <= 0
            throw new Error 'Torpedo inventory depleted'

        torpedo = tube.fire( @weapons_targeting.target, yield_level, @position )

        if @warp_speed > 0
            torpedo.fire_at_warp @warp_speed
        else
            torpedo.fire_at_impulse Math.max( @impulse, 0.1)

        return torpedo


    damage_report: ( filter ) ->

        r = ( s.damage_report() for s in @systems )

        if filter
            r = ( s for s in r when s.integrity < 1 )

        return r


    shield_report: -> ( do s.shield_report for s in @shields )


    phaser_report: -> ( do s.power_report for s in @phasers )


    tactical_report: ->

        shield_up = false
        report = {}
        for obj in @shields
            shield_up = shield_up or obj.active
            report[ obj.name ] = do obj.shield_report


        report =
            torpedo_inventory: @torpedo_inventory
            weapons_target: @weapons_targeting.target?.name
            weapons_target_deck: @weapons_targeting.target_deck
            weapons_target_section: @weapons_targeting.target_section
            shields_status: shield_up
            shield_report: report
            alert_status: @alert
            phaser_range: PhaserSystem.RANGE
            torpedo_ranage: TorpedoSystem.RANGE
            torpedo_max_yeild: TorpedoSystem.MAX_DAMAGE
            torpedo_bay_status: ( bay.status_report() for bay in @torpedo_banks )


    set_shields: ( state ) ->

        if state
            do @_power_shields
        else
            do @_power_down_shields

        p = ( obj.active for obj in @shields )


    process_phaser_damage: ( from_point, energy, target_deck, target_section ) =>

        quads = @calculate_quadrants from_point
        if target_section? and target_section in quads
            quad = target_section
        else
            quad = quads[ Math.floor( Math.random() * 2 ) ]

        if not target_deck?
            deck_list = ( k for k, v of @DECKS )
            deck_i = Math.floor Math.random() * deck_list.length
            target_deck = deck_list[ deck_i ]


        shield = ( s for s in @shields when s.section == quad )[0]

        damage = energy
        if shield.active and do shield.is_online
            damage = shield.hit energy
        else
            #console.log "Shields down!"

        #console.log "Phaser damage on deck #{target_deck} section #{quad}: energy level: #{ energy }. Passthrough damage: #{ damage }"

        system_passthrough = @_damage_hull [target_deck], quad, damage

        quad_systems = ( s for s in @systems when s.section == quad and s.deck == target_deck )
        for sys in quad_systems
            sys.damage system_passthrough

        do @_check_if_still_alive


    process_blast_damage: ( position, power, message_interface ) ->

        if not do @_check_if_still_alive
            return

        quad = @calculate_quadrant position
        if not quad in ( s for s, v of @SECTIONS )
            throw new Error "Invalid position: #{position}"

        deck_list = ( k for k, v of @DECKS )

        # Blast epicenter
        deck_i = Math.floor( deck_list.length * do Math.random )

        # Blast radius, given power
        deck_count = power / C.HULL_STRENGTH
        start_deck = deck_i - deck_count / 2
        end_deck = deck_i + deck_count / 2
        target_decks = deck_list[ start_deck..end_deck ]
        distance = Math.max U.distance( @position, position ), 1

        # Inverse square damage law
        damage = power / Math.pow( distance, 2 )

        #console.log "#{@name} detects blast of #{power} power #{distance} m away. #{ damage } damage."

        shield = ( s for s in @shields when s.section is quad )[ 0 ]
        if not shield?
            throw new Error "No shield found at quad #{quad}"

        if shield.is_online() and shield.is_active()
            #console.log "#{shield.name} hit ( #{shield.energy_level()} )"
            damage = shield.hit damage

        #console.log "Passthrough damage: #{ damage }."

        system_passthrough = @_damage_hull target_decks, quad, damage

        quad_systems = ( s for s in @systems \
            when s.section is quad \
            and s.deck in target_decks )

        # if the hull has been blow through, other
        # systems will be affected in different sections
        for d in target_decks
            if @hull[ d ][ quad ] == 0
                for s in @systems when s.deck is d and s.section isnt quad
                    quad_systems.push s

        for sys in quad_systems
            # Introduce some variability accross deck damage
            sys.damage ( 0.2 + ( Math.random() * 0.8 ) ) * system_passthrough

        if damage > 1
            #console.log "#{@name} hit! Blast. #{damage} damage"
            message_interface @prefix_code, "Display", "Blast damage!"

        do @_check_if_still_alive


    _process_radiation: ( dyns ) ->

        ### Process environmental radiation. Assumed to be global
        in this implementation.

        ###

        for k, s of @SECTIONS

            # radiation drains shields
            shield = ( sh for sh in @shields when sh.section is s )[ 0 ]
            passthrough = shield.drain dyns

            if passthrough == 0
                @radiological_alerts[ s ] = false
                continue

            # for now, this affects the entire section at a time
            if not @radiological_alerts[ s ]
                @radiological_alerts[ s ] = true
                @message(
                    @prefix_code,
                    "internal-alarm",
                    "Radiation Hazard in #{ s } section"
                )

            # radiation makes crew sick
            affected_crew = ( c for c in @internal_personnel when c.section is s )
            crew.radiation_exposure passthrough for crew in affected_crew

        do @_rebuild_crew_checks


    _power_shields: -> do s.power_on for s in @shields


    _power_phasers: -> do p.power_on for p in @phasers


    _auto_load_torpedoes: -> t.autoload( true ) for t in @torpedo_banks


    _power_down_shields: -> do s.power_down for s in @shields


    _power_down_phasers: -> do p.power_down for p in @phasers


    _disable_torpedeo_autoload: -> t.autoload( false ) for t in @torpedo_banks


    _consume_a_torpedo: () =>
        # Passed function to the torpedo bansk to decrement the shared
        # torpedo inventory

        if @torpedo_inventory <= 0
            return 0

        @torpedo_inventory -= 1
        return 1


    _damage_hull: ( decks, section, damage ) ->

        #console.log "[#{ @name }] Hull damage: #{damage} deck #{ decks } section #{ section }"

        hull_strength = C.HULL_STRENGTH
        damage_as_pct = damage / hull_strength

        # SIFs will absorb the stress and charge down a bit

        if do @primary_SIF.is_active
            [ passed_damage, overload ] = @primary_SIF.absorb damage

            if overload
                #console.log "    Primary SIF overload: passing #{ passed_damage } to Secondary"
                [ passed_damage, overload ] = @secondary_SIF.absorb passed_damage

        else
            [ passed_damage, overload ] = @secondary_SIF.absorb damage


        #console.log "    Passed damage to hull: #{ passed_damage }"

        # Any damage to the hull with the SIFs down is catastrophic
        if overload
            #console.log do @primary_SIF.damage_report
            #console.log do @secondary_SIF.damage_report
            console.log "[#{ @name }] Fatal damage. Ship destroyed!"
            @alive = false
            return 0

        # Divide the damage among the decks
        damage_per_deck = passed_damage / decks.length
        damage_pct_per_deck = damage_per_deck / C.HULL_STRENGTH
        for d in decks
            @hull[ d ][ section ] -= damage_pct_per_deck * ( 0.5 + 0.5 * do Math.random )
            @hull[ d ][ section ] = Math.max 0, @hull[ d ][ section ]

            if @hull[ d ][ section ] == 0

                #console.log "    Hull breach! Deck #{ d } Section #{ section }"
                @process_casualties d, section
                # the remaining damage applies to the other sections
                other_sections = ( v for k, v of @SECTIONS when v isnt section )
                for s in other_sections
                    @hull[ d ][ s ] -= damage_pct_per_deck / Object.keys(@SECTIONS).length
                    @hull[ d ][ s ] = Math.max 0, @hull[ d ][ s ]
                    if @hull[ d ][ s ] == 0
                        @process_casualties d, s

        return passed_damage


    process_casualties: ( deck, section ) ->

        for p in @internal_personnel
            if p.deck == deck and p.section == section
                p.die 1
        @_rebuild_crew_checks()


    ### Navigation
    _________________________________________________###


    navigation_report: ->

        r =
            bearing: @bearing
            rotation: @bearing_v
            impulse: @impulse
            warp: @warp_speed
            log: @navigation_log.dump()
            velocity: @velocity


    turn_port: ->

        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."

        @bearing_v.bearing = 1 / C.TIME_FOR_FULL_ROTATION
        @message @prefix_code, "Turning", do @navigation_report
        do @navigation_report


    turn_starboard: ->

        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."

        @bearing_v.bearing = -1 / C.TIME_FOR_FULL_ROTATION
        @message @prefix_code, "Turning", do @navigation_report
        do @navigation_report


    stop_turn: ->

        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."

        @bearing_v.bearing = 0
        @message @prefix_code, "Turning", do @navigation_report
        do @navigation_report


    fire_thrusters: ( direction ) ->


        check_safe_for_thrusters = =>
            if @impulse == 0 and @warp_speed == 0
                return
            @impulse == 0
            @warp_speed == 0
            @velocity.x = 0
            @velocity.y = 0
            @velocity.z = 0

        rotation = @bearing.bearing * Math.PI * 2

        switch direction

            when "forward"
                do check_safe_for_thrusters
                @velocity.x += Math.cos( rotation ) * BaseShip.THRUSTER_DELTA_V_MPS / 1000
                @velocity.y += Math.sin( rotation ) * BaseShip.THRUSTER_DELTA_V_MPS / 1000

            when "reverse"
                do check_safe_for_thrusters
                @velocity.x -= Math.cos( rotation ) * BaseShip.THRUSTER_DELTA_V_MPS / 1000
                @velocity.y -= Math.sin( rotation ) * BaseShip.THRUSTER_DELTA_V_MPS / 1000


    set_course: ( bearing, mark, callback ) =>

        if @_navigation_lock
            throw new Error "Unable to set course while navigational computer is manuvering"

        @_log_navigation_action "Setting course bearing #{ bearing } mark #{ mark }"
        @_set_course bearing, mark, callback


    _set_course: ( bearing, mark, callback ) =>

        # These are understood to be relative bearings
        if not @inertial_dampener.is_online()
            throw new Error "internal Dampener offline. Safety protocols
                prevent acceleration."

        if not @primary_SIF.is_online() or not @secondary_SIF.is_online()
            throw new Error "Structural Integrity Fields are offlne.
                Safety protocols prevent acceleration."

        if not 0 <= bearing <= 1
            throw new Error "Illegal bearing #{bearing}"

        do @_clear_rotation
        @_navigation_lock = true

        # Stop moving
        initial_impulse = @impulse
        initial_warp = @warp_speed
        @_set_impulse 0

        # Calculate new bearing
        new_bearing = ( bearing + @bearing.bearing ) % 1
        new_mark = ( mark + @bearing.mark ) % 1
        if new_mark < 0
            new_mark += 1

        # Calculate the duration of the turn
        turn_direction = C.COUNTERCLOCKWISE
        turn_distance = bearing
        if bearing > 0.5
            turn_direction = C.CLOCKWISE
            turn_distance = 1 - bearing
        duration = C.TIME_FOR_FULL_ROTATION * turn_distance

        # Do this in a timeout
        set_course_and_speed = =>

            @bearing =
                bearing: new_bearing
                mark: new_mark

            if initial_impulse > 0
                @_set_impulse initial_impulse
            if initial_warp > 0
                @_set_warp initial_warp
            @_navigation_lock = false

            if callback?
                do callback

        setTimeout set_course_and_speed, duration

        # message out to the ship
        r =
            turn_direction: turn_direction
            turn_duration: duration
            turn_distance: turn_distance


    _set_abs_course: ( heading, callback ) =>

        course = U.abs2rel_bearing @, heading, 9
        @_set_course course.bearing, course.mark, callback


    set_impulse: ( impulse_speed, callback ) ->

        if @_navigation_lock
            throw new Error "Unable to set impulse while navigational computer
            is manuvering"

        @_log_navigation_action "Setting impulse: #{ impulse_speed }"
        @_set_impulse impulse_speed, callback


    _set_impulse: ( impulse_speed, callback ) ->

        do @_clear_rotation

        # set impulse between 0 and 1, and calculate new velocity
        # TODO: make this gradual
        if not do @inertial_dampener.is_online
            throw new Error "internal Dampener offline. Safety protocols
                prevent acceleration."

        if not @primary_SIF.is_online() or not @secondary_SIF.is_online()
            throw new Error "Structural Integrity Fields are offlne.
                Safety protocols prevent acceleration."

        if not U.isNumber impulse_speed
            throw new Error 'Impulse requires a float'

        if not @impulse_drive.online
            throw new Error 'Impulse drive offline'

        @warp_speed = 0
        i = @impulse_drive
        delta = Math.abs( impulse_speed - @impulse )
        @impulse = impulse_speed
        rotation = @bearing.bearing * Math.PI * 2
        @velocity.x = Math.cos( rotation ) * @impulse * C.IMPULSE_SPEED
        @velocity.y = Math.sin( rotation ) * @impulse * C.IMPULSE_SPEED
        @power_debt += delta * i.burst_power

        if callback?
            do callback

        return @impulse


    set_warp: ( warp_speed, callback ) =>

        if @_navigation_lock
            throw new Error "Unable to set warp while navigational computer is
            manuvering"

        @_log_navigation_action "Setting warp speed: #{ warp_speed }"
        @_set_warp warp_speed, callback


    _set_warp: ( warp_speed, callback ) =>

        do @_clear_rotation

        if not U.isNumber( warp_speed )
            throw new Error 'Warp requires a Number'

        if not @warp_core.is_online()
            throw new Error 'Warp drive offline'

        if not @starboard_warp_coil.is_online()
            throw new Error 'Starboard warp coil is offline'

        if not @port_warp_coil.is_online()
            throw new Error 'Port warp coil is offline'

        if not @inertial_dampener.is_online() and @warp_speed isnt warp_speed
            throw new Error 'Inertial dampener is offline; cannot change velocity'

        if not (@primary_SIF.is_online() or @secondary_SIF.is_online()) and \
        @warp_speed isnt warp_speed
            throw new Error 'Structural Integrity Field offline; cannot change velocity'

        if not @navigational_deflectors.is_online()
            throw new Error "Navigational deflectors are offline.
                It is unsafe to go to warp."

        if warp_speed > WarpSystem.MAX_WARP
            throw new Error "Cannot exceed warp #{ WarpSystem.MAX_WARP }"

        if warp_speed < 1
            throw new Error "Minimum warp velocity is warp 1.0"

        # TODO: Check if the available power to the nacels is sufficient
        # to achieve this warp. If not, route the required power.

        @impulse = 0
        @warp_speed = warp_speed
        console.log "[#{ @name }] Setting warp to #{ warp_speed }"
        rotation = @bearing.bearing * Math.PI * 2

        # The famous trek warp speed calculation
        warp_v = Math.pow( @warp_speed, 10/3 ) * C.SPEED_OF_LIGHT
        @velocity.x = Math.cos( rotation ) * warp_v
        @velocity.y = Math.sin( rotation ) * warp_v

        if callback?
            do callback

        #TODO: power management
        return @warp_speed


    _clear_rotation: -> @bearing_v = { bearing: 0, mark: 0 }


    _log_navigation_action: ( entry ) ->

        @navigation_log.log entry
        do @navigation_log.length


    ### Operations
    _________________________________________________###


    assign_repair_crews: ( system_name, team_count, to_completion=false ) ->

        system = ( s for s in @systems when s.name == system_name )[ 0 ]
        if not system
            throw new Error "Invalid system name #{system_name}"

        teams = ( c for c in @repair_teams when not c.currently_repairing )
        if teams.length < team_count
            throw new Error "Insufficient free teams: asked for #{team_count}, only #{teams.length} available"

        damage = do system.damage_report
        if not @_check_cargo_inventory damage.repair_requirements
            throw new Error "Insufficient materials"

        @_consume_cargo_inventory damage.repair_requirements
        team.repair( system, to_completion ) for team in teams[0...team_count]


    send_team_to_deck: ( crew_id, to_deck, to_section ) ->

        team = ( t for t in @internal_personnel when t.id is crew_id )[0]
        if not team
            throw new Error "Team not found #{ crew_id }. To #{ to_deck }, #{ to_section }."

        if team.deck is to_deck and team.section is to_section
            return

        team.goto to_deck, to_section
        r = "Team enroute"


    get_cargo_status: ->

        r = {}
        for cb in @cargobays
            r[ cb.number ] = cb.inventory
        return r


    get_cargo_bay: ( number ) ->

        number = if typeof number is 'string' then parseInt( number ) else number
        bay = ( c for c in @cargobays when c.number is number )[0]


    get_internal_lifesigns_scan: -> ( team for team in @internal_personnel )


    get_systems_layout: -> ( s.layout() for s in @systems )


    get_decks: -> ( dv for dk, dv of @DECKS )


    get_sections: -> ( sv for sk, sv of @SECTIONS )


    get_bay_with_capacity: ( qty ) ->

        bays = ( c for c in @cargobays when c.remaining_capacity > qty )
        if bays.length == 0
            throw new Error "No bay with capacity"

        bays[0].number


    transport_cargo: ( origin, origin_bay_number, destination, destination_bay_number, cargo, quantity ) ->

        origin_bay = origin.get_cargo_bay origin_bay_number
        destination_bay = destination.get_cargo_bay destination_bay_number

        @transporters.beam_cargo origin, destination, origin_bay, destination_bay, cargo, quantity


    transport_crew: ( crew_id, source, source_deck, source_section, target, target_deck, target_section ) ->

        if not source is @ && not target is @
            throw new Error "Either origin or destination must be the ship."

        if target is @ and target_deck is undefined or target_section is undefined
            target_deck = @transporters.deck
            target_section = @transporters.section

        if source is @ and source_deck is undefined or target_section is undefined
            source_deck = @transporters.deck
            source_section = @transporters.section

        @transporters.beam_crew(
            crew_id, source, source_deck, source_section,
            target, target_deck, target_section)


    beam_away_crew: ( crew_id, deck, section ) ->

        # Called when personnel are being beamed away.
        if @_are_all_shields_up()
            throw new Error 'Shields are up. No transport possible'

        teams = ( t for t in @internal_personnel when t.id is crew_id )
        if teams.length == 0
            console.log @internal_personnel
            throw new Error "No such team at that location: #{ @name } #{deck} #{section}. Refresh your targeting scan."

        @_remove_crew crew_id
        do @_rebuild_crew_checks

        team = teams[ 0 ]


    beam_onboard_crew: ( crew, deck, section ) ->

        # Called when personnel are being beamed onboard.
        if do @_are_all_shields_up
            throw new Error 'Shields are up. No transport possible'

        crew.deck = deck
        crew.section = section

        if crew.assignment is @.name
            @_board_crew crew
        else
            if crew.alignment isnt @.alignment
                # TODO: Intruder alert
                @boarding_parties.push crew
            else
                @guests.push crew

        do @_rebuild_crew_checks


    transportable: ( ignore_shield=false ) ->

        if not ignore_shield
            if do @_are_all_shields_up
                return false

        t =
            name: @name
            crew: ( c.scan() for c in @internal_personnel when c.is_onboard() )
            cargo: do @get_cargo_status
            decks: @DECKS
            sections: @SECTIONS


    crew_ready_to_transport: ->

        crew = ( c for c in @internal_personnel \
            when c.deck == @transporters.deck \
            and c.section == @transporters.section )


    _remove_crew: ( id ) ->

        @repair_teams = ( t for t in @repair_teams when t.id isnt id )
        @science_teams = ( t for t in @science_teams when t.id isnt id )
        @engineering_teams = ( t for t in @engineering_teams when t.id isnt id )
        @security_teams = ( t for t in @security_teams when t.id isnt id )
        @prisoners = ( t for t in @prisoners when t.id isnt id )
        @boarding_parties = ( b for b in @boarding_parties when b.id isnt id )
        @guests = ( t for t in @guests when t.id isnt id )

        do @_rebuild_crew_checks


    _board_crew: ( crew ) ->

        # Assigned crew is coming aboard
        switch crew.description
            when "Repair Team" then @repair_teams.push crew
            when "Science Team" then @science_teams.push crew
            when "Engineering Team" then @engineering_teams.push crew
            when "Security Team" then @security_teams.push crew


    _rebuild_crew_checks: ->

        # Override to rebuild the internal personnel
        @internal_personnel = []


    _consume_cargo_inventory: ( materials ) ->

        for requirement in materials
            need = requirement.quantity
            for bay in @cargobays
                need -= bay.consume_cargo requirement.material, need


    _check_cargo_inventory: ( materials ) ->

        for requirement in materials
            count = 0
            count += c.inventory_count requirement.material for c in @cargobays
            if count < requirement.quantity
                return false
        return true


    ### Science
    _________________________________________________###


    scan_object: ( target ) ->

        # see if object is in range
        if not U.in_range target.position, @position, C.SYSTEM_SCAN_RANGE
            d = U.distance target.position, @position
            throw new Error "Target out of range #{d}"

        # see if sensors are online
        quad = @calculate_quadrant target.position
        sensor = ( s for s in @sensors when s.section == quad )[0]

        if not do sensor.is_online
            throw new Error "Required sensor grid offlne."

        # get the object's status
        r =
            timeout: C.SYSYEM_SCAN_DURATION
            result: do target.get_system_scan


    # Add a given target to the array of objects we have completed
    # a detailed scan of. Required for transporters, and advanced
    # weapons targetting
    add_scanned_object: ( target ) -> @_logged_scanned_items.push target


    get_scanned_objects: -> @_logged_scanned_items


    get_system_scan: ->

        r =
            systems: do @damage_report
            cargo: do @get_cargo_status
            lifesigns: ( c.members.length for c in @internal_personnel ).reduce ( x, y ) -> x+y
            # Eventually, power readings will be used to profile a ship
            # for now, let's simply return the power output to the nacels
            # which is feasably measured
            power_readings: [
                    do @port_warp_coil.warp_field_output,
                    do @starboard_warp_coil.warp_field_output,
                    do @warp_core.field_output,
                    do @impulse_reactors.field_output,
                    do @emergency_power.field_output ]
            mesh: @model_url
            name: @name
            mesh_scale: @model_display_scale
            registry: @serial
            hull: @hull
            name: @name
            shields: do @shield_report

        # TODO: Do we have shielding? Radiation leaks? Radioactive cargo?
        if do @_are_all_shields_up
            delete r.systems
            delete r.cargo
            delete r.lifesigns

        return r


    get_scan_configuration: ( type ) ->

        # We take the forward scanner to be the authortative settings source
        fwd_config = @forward_sensors.get_configuration type
        port_config = @port_sensors.get_configuration type
        starboard_config = @starboard_sensors.get_configuration type
        aft_config = @aft_sensors.get_configuration type

        ettcs = [
            fwd_config.ettc
            port_config.ettc
            starboard_config.ettc
            aft_config.ettc ]
        max_ettc = Math.max.apply null, ettcs

        time_estimates = [
            fwd_config.time_estimate
            port_config.time_estimate
            aft_config.time_estimate
            starboard_config.time_estimate ]
        max_time_estimate = Math.max.apply null, time_estimates

        grids = [].concat(fwd_config.grids).concat(port_config.grids).concat(
            starboard_config.grids).concat(aft_config.grids)

        r =
            grids: grids
            resolution: fwd_config.resolution
            range: fwd_config.range
            ettc: max_ettc
            time_estimate: max_time_estimate


    get_long_range_scan_configuration: ( type ) ->

        lr_config = @long_range_sensors.get_configuration type

        r =
            grids: lr_config.grids
            resolution: lr_config.resolution
            range: lr_config.range
            ettc: lr_config.ettc
            time_estimate: lr_config.time_estimate


    run_scan: ( world_scan, type, grid_start, grid_end, positive_sweep, range, resolution ) ->

        if resolution < 4
            throw new Error "Short range sensors have a minimum resolution of 4."

        valid_grids = [ 0...SensorSystem.MAX_SLICES ]
        if grid_start not in valid_grids or grid_end not in valid_grids
            throw new Error "Invalid scan ranges: #{ grid_start }, #{ grid_end }"
        # queue up the responsible scanners, per bearing
        # NB scanners take absolute bearings as arguments

        # Break the sections of the bearing to scan into segments
        # so that each can be checked for scan range
        first_segment = [ Math.min( grid_start, grid_end )..Math.max( grid_start, grid_end ) ]
        crossing_reverse_scan = grid_end > grid_start and not positive_sweep
        crossing_lapping_scan = grid_end < grid_start and positive_sweep
        second_segment = undefined

        if crossing_reverse_scan
            first_segment = [ 0...grid_start ]
            second_segment = [ grid_end...SensorSystem.MAX_SLICES ]

        if crossing_lapping_scan
            first_segment = [ 0...grid_end ]
            second_segment = [ grid_start...SensorSystem.MAX_SLICES ]

        # forward sensors (0.875 > 0.125)
        forward_segments = @_calculate_scan_segment(
           [ 0...8 ].concat( [ 56...64 ] ),
           first_segment,
           second_segment )

        # port sensors (0.125, 0.375)
        port_segments = @_calculate_scan_segment(
            [ 8...24 ],
            first_segment,
            second_segment )

        # aft sensors (0.375 > 0.625)
        aft_segments = @_calculate_scan_segment(
            [ 24...40 ],
            first_segment,
            second_segment )

        # starboard sensors (0.625 > 0.875)
        starboard_segments = @_calculate_scan_segment(
            [ 40...56 ],
            first_segment,
            second_segment )

        b = @bearing.bearing

        @forward_sensors.configure_scan type, b, forward_segments, range, resolution
        @port_sensors.configure_scan type, b, port_segments, range, resolution
        @starboard_sensors.configure_scan type, b, starboard_segments, range, resolution
        @aft_sensors.configure_scan type, b, aft_segments, range, resolution

        t1 = @forward_sensors.scan world_scan, @position, b, type
        t2 = @port_sensors.scan world_scan, @position, b, type
        t3 = @aft_sensors.scan world_scan, @position, b, type
        t4 = @starboard_sensors.scan world_scan, @position, b, type

        Math.max t1, t2, t3, t4


    _calculate_scan_segment: ( scanner_segments, first_segment, second_segment ) ->

        union = ( i for i in scanner_segments when i in first_segment )
        if second_segment?
            second_union = [ i for i in scanner_segments when i in second_segment ]
            union.concat second_union

        return union


    run_long_range_scan: ( world_scan, type, bearing_from, bearing_to, positive_sweep, range_level, resolution ) ->

        if not do @long_range_sensors.is_online
            throw new Error "Long-Range Sensors are offline"

        # NB scanners take absolute bearings as arguments
        abs_bearing_from = ( bearing_from + @bearing.bearing ) % 1
        abs_bearing_to = ( bearing_to + @bearing.bearing ) % 1
        @long_range_sensors.scan( world_scan, type, abs_bearing_from,
            abs_bearing_to, positive_sweep, range_level, resolution )


    get_scan_results: ( type ) ->

        # recombine the readings from all sensor grids
        composite_scan = []
        classifications = []
        B = @bearing.bearing
        p = @position

        for sys in @sensors
            results = sys.readings type, B, p

            # readings
            readings = results.results
            read_outs = results.readOut
            for bucket in readings
                existing_buckets = ( b for b in composite_scan when b.start == bucket.start and b.end == bucket.end )
                if existing_buckets.length == 0
                    composite_scan.push bucket
                else
                    existing_buckets[ 0 ].reading += bucket.reading

            # classifications
            classifications = classifications.concat results.classifications

            # spectra

        r =
            results: composite_scan
            classifications: classifications
            spectra: []


    get_long_range_scan_results: ( type ) ->

        @long_range_sensors.readings type, @bearing.bearing


    get_internal_scan: ->

        r =
            alerts:
                radiation: @radiological_alerts
                atmosphere: []
            mesh: @model_url
            meshScale: @model_display_scale



    ### Engineering
    _________________________________________________###


    power_distribution_report: ->

        r =
            reactors: ( reactor.power_distribution_report() for reactor in @reactors )
            primary_relays: ( relay.power_distribution_report() for relay in @primary_power_relays )
            eps_relays: ( eps.power_distribution_report() for eps in @eps_grids )


    set_power_to_system: ( system_name, pct ) ->

        # Calculates the new system power balance, and the new required
        # power levels for that system. Dials up or down reactor
        # appropriately.
        system = ( s for s in @systems when s.name == system_name )[ 0 ]
        if not system?
            throw new Error "Unable to locate system #{ system_name }"

        if not system.power_report().power_system_operational
            throw new Error "#{ system_name } system has blown it's EPS coupling. Please Repair."

        { min_power_level, max_power_level, power,
            current_power_level, operational_dynes } = system.power_report()

        dyn = operational_dynes

        delta_power_pct = pct - current_power_level
        delta_power = delta_power_pct * dyn

        parent_eps_relays = ( r for r in @eps_grids when r.is_attached system )
        if parent_eps_relays.length > 0
            parent_eps_relay = parent_eps_relays[ 0 ]

        primary_power_relays = ( r for r in @primary_power_relays when r.is_attached( system ) or r.is_attached( parent_eps_relay ) )
        if primary_power_relays.length isnt 1
            throw new Error "Unable to trace primary power relay for #{ system_name }"
        primary_power_relay = primary_power_relays[ 0 ]

        reactors = ( r for r in @reactors when r.is_attached primary_power_relay )
        if reactors.length isnt 1
            throw new Error "Unable to trace reactor power for #{ primary_power_relay.name }"

        reactor = reactors[ 0 ]

        if parent_eps_relay?
            new_eps_balance = parent_eps_relay.calculate_new_balance(
                system, delta_power )
            new_primary_balance = primary_power_relay.calculate_new_balance(
                parent_eps_relay, delta_power )
        else
            new_primary_balance = primary_power_relay.calculate_new_balance(
                system, delta_power )

        message = @message
        prefix = @prefix_code

        on_blowout = -> @bridge.damage_station BridgeSystem.STATIONS.ENGINEERING

        # If it's an increase in power, we need to set the new balance first
        # Else we need to dial down the power first

        set_new_balance = ->

            if parent_eps_relay?
                parent_eps_relay.set_system_balance new_eps_balance, on_blowout
            primary_power_relay.set_system_balance new_primary_balance, on_blowout


        power_reactor = ->

            new_level = reactor.calculate_level_for_additional_output delta_power

            if not new_level? or isNaN new_level
                throw new Error "Reactor failed to calculate power requirement
                    for #{ system_name } to #{ pct }, (#{ delta_power })"

            reactor.activate new_level, on_blowout

        if delta_power > 0
            do set_new_balance
            do power_reactor
        else
            do power_reactor
            do set_new_balance


    set_power_to_reactor: ( reactor_name, level ) ->

        reactor = ( r for r in @reactors when r.name == reactor_name )[ 0 ]
        if not reactor?
            throw new Error "Invalid reactor name #{ reactor_name }, level: #{ level }"

        reactor.activate level


    reroute_power_relay: ( eps_relay_name, primary_relay_name ) ->

        eps_relay = ( r for r in @eps_grids when r.name == eps_relay_name )[ 0 ]
        if not eps_relay?
            throw new Error "Invalid eps relay name #{ eps_relay }"

        primary_relay = ( r for r in @primary_power_relays when r.name == primary_relay_name )[ 0 ]
        if not primary_relay?
            throw new Error "Invalid primary relay name #{ primary_relay }"

        current_system = ( r for r in @primary_power_relays when r.is_attached eps_relay )[ 0 ]
        current_system.remove_route eps_relay
        primary_relay.add_route eps_relay
        reply = "#{ eps_relay_name } rerouted to #{ primary_relay_name }"


    set_online: ( system_name, is_online ) ->

        system = ( s for s in @systems when s.name == system_name )[ 0]
        if not system?
            throw new Error "Invalid system name #{ system_name }"

        if is_online
            do system.bring_online
        else
            do system.deactivate


    set_active: ( system_name, is_active ) ->

        system = ( s for s in @systems when s.name == system_name )[ 0 ]
        if not system?
            throw new Error "Invalid system name #{ system_name }"

        if is_active
            do system.power_on
        else
            do system.power_down


    ### Communications
    _________________________________________________###
    get_comms: ->

        if @communication_array?
            do @communication_array.history
        else
            []


    hail: ( message, hail_function ) ->

        if @communication_array?
            @communication_array.hail message, hail_function


    hear_hail: ( prefix, message ) ->

        if @prefix_code == prefix
            return false

        if @communication_array?
            @communication_array.log_hail message


    ### Misc.
    _________________________________________________###


    enter_captains_log: ( entry ) -> @captains_log.log entry


    get_pending_captains_logs: -> do @captains_log.pending_logs


    get_lifesigns: -> @internal_personnel


    set_viewscreen_target: ( target_name ) -> @_viewscreen_target = target_name


    _check_if_still_alive: -> @alive


    get_crew_count: ->

        crew = ( c for c in @internal_personnel when c.assignment is @name )
        count = 0
        count += team.members.length for team in crew


    calculate_quadrant: ( from_point ) ->

        # Returns which quadrant of the ship is facing a given point

        if from_point == @position
            from_point.x += 1
        b = U.bearing(
                { position : @position, bearing : @bearing },
                { position : from_point } )

        if not b?
            throw new Error "Invalid origin point #{from_point}"

        quadrant = @calculate_quadrant_from_bearing b


    calculate_quadrants: ( from_point ) ->

        # Returns the two visible quadrants from a point, as opposed to
        # calculate quadrant, which just returns the immediate facing
        # section

        if from_point == @position
            from_point.x += 1

        b = U.bearing(
            { position : @position, bearing : @bearing },
            { position : from_point } )
        if not b?
            throw new Error "Invalid origin point #{from_point}"

        if 0 < b.bearing <= 0.25
            return [ @SECTIONS.FORWARD, @SECTIONS.PORT ]
        if 0.25 < b.bearing <= 0.5
            return [ @SECTIONS.PORT, @SECTIONS.AFT ]
        if 0.5 < b.bearing <= 0.75
            return [ @SECTIONS.AFT, @SECTIONS.STARBOARD ]
        if 0.75 < b.bearing <= 1
            return [ @SECTIONS.STARBOARD, @SECTIONS.FORWARD ]


    calculate_quadrant_from_bearing: ( b ) ->

        quadrant = switch
            when ( b.bearing < 0.125 or b.bearing >= 0.875 ) then @SECTIONS.FORWARD
            when ( 0.125 <= b.bearing < 0.375 ) then @SECTIONS.PORT
            when ( 0.375 <= b.bearing < 0.625 ) then @SECTIONS.AFT
            when ( 0.625 <= b.bearing < 0.875 ) then @SECTIONS.STARBOARD


    calculate_impulse: ->

        x2 = Math.pow @velocity.x, 2
        y2 = Math.pow @velocity.y, 2
        z2 = Math.pow @velocity.z, 2

        return Math.sqrt( x2 + y2 + z2 )


    clear_ships: ( ship_prefix ) ->

        if @weapons_targeting.target.prefix_code == ship_prefix
            do @weapons_targeting.clear


    _are_all_shields_up: ->

        for s in @shields

            if not s.active || not s.online || s.charge <= 0.01
                return false

            if s.charge <= 0.01
                return false

        return true


    _set_operational_reactor_settings: ->

        for reactor in @reactors
            do reactor.set_required_output_power


    ### Time Progression
    ________________________________________________________###

    calculate_state: ( world_scan, delta ) ->

        # Allow independent or clocked syncing
        now = do Date.now
        if not delta?
            delta = now - @state_stamp
        @state_stamp = now

        @_calculate_motion delta
        @_calculate_environment delta

        engineering_locations = ( { deck : c.deck, section : c.section } for c in @internal_personnel when c.description is "Engineering Team" and not do c.is_enroute )
        @_update_system_state delta, engineering_locations

        @_update_crew delta

        if world_scan?
            @_update_scanners world_scan, now


    _calculate_motion: ( delta_t ) ->

        @position.x += @velocity.x * delta_t
        @position.y += @velocity.y * delta_t

        @bearing.bearing += @bearing_v.bearing * delta_t
        @bearing.mark += @bearing_v.mark * delta_t

        if @bearing.bearing > 1
            @bearing.bearing = @bearing.bearing % 1

        if @bearing.bearing < 0
            @bearing.bearing += 1

        # If we're currently turning, notify any clients
        if @bearing_v.bearing != 0
            @message @prefix_code, "Turning", do @navigation_report


    _calculate_environment: ( delta_t ) ->

        # skip if the environmental_conditions haven't been
        # initialized
        if not @environmental_conditions?
            return

        # check the current environment levels
        for reading in @environmental_conditions
            switch reading.parameter
                when C.ENVIRONMENT.RADIATION
                    @_process_radiation reading.readout * delta_t

        ## partical density signals to the nav computer to stop warp
        ## subspace warping signals to the nav computer to stop warp


    _update_system_state: ( delta_t, eng_locations ) -> s.update_system( delta_t, eng_locations ) for s in @systems


    _update_crew: ( delta_t ) ->


        health_locaitons = {}
        # Any crew in sickbay should get better
        health_locaitons[ @sick_bay.deck ] = [ @sick_bay.section ]
        # Any crew near a medical team member should get better
        for crew in @internal_personnel when crew.description == "Medical Team" and not do crew.is_enroute

            if health_locaitons[ crew.deck ]?
                health_locaitons[ crew.deck ].push crew.section
            else
                health_locaitons[ crew.deck ] = [ crew.section ]

        for c in @internal_personnel when c.alignment is @alignment
            if health_locaitons[ c.deck ]? and c.section in health_locaitons[ c.deck ]
                c.receive_medical_treatment delta_t


        # Intruders should move around?


        # Any security forces in the area of boarding parties will fight and win/lose
        intruders = ( crew for crew in @internal_personnel when (
            crew.alignment != @alignment and
            not do crew.is_captured and
            crew.description == "Security Team" ) )

        for crew in @internal_personnel when crew.assignment is @name

            for intruder in intruders when intruder.deck is crew.deck and intruder.section is crew.section
                # If security, you get to fight the invaders, otherwise they kill you
                if crew.description is "Security Team" and do intruder.health > 0
                    crew.fight intruder
                else
                    intruder.kill crew


        # If a repair crew is on the bridge, damaged bridge screens should be repaired




    _update_scanners: ( world_scan, now ) ->

        # Scanners are meaningless at warp speeds
        if @warp_speed == 0
            for s in @sensors
                s.run_scans world_scan, @position, @bearing.bearing, now

        @long_range_sensors.run_scans world_scan, @position, @bearing.bearing, now


exports.BaseShip = BaseShip
