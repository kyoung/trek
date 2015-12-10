{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{StarDock} = require '../ships/StarDock'
{Beacon} = require '../ships/Beacon'
{Station} = require '../Station'

{CelestialObject, Star, GasCloud, Planet, Lagrange} = require '../CelestialObject'
{SpaceSector, StarSystem} = require '../Maps'

C = require "../Constants"
U = require "../Utility"

# Premise:
# It's training day! Lets teach everyone how to boot the ship, get crew aboard
# and work the systems.
#
# We start in spacedock with the ship powered down, and no crew or cargo
# onboard. We'll beam over all the crew and supplies, and assign them throughout
# the ship. Since warp and impulse reactors are offline, transporters,
# lifesupport, and bridge control will be operating on emergency power.
#
# We'll need engineering to activate the warp core and begin routing power to
# various systems throughout the ship, and bring systems online.
#
# Once ready, we'll need the helm to move us out of space dock, using thrusters
# only, and take us to a testing facility on the outer edge of the solar system
# where we can begin testing our weapons systems and science systems.
#
# The mission is complete when we have successfully destroyed the field targets
# and tested the science stations.
#

class Academy extends Level

    constructor: ( @team_count ) ->
        super()
        @name = "Academy"
        @stardate = do U.stardate
        do @_init_map
        do @_init_logs
        do @_init_space_objects
        do @_init_ships
        do @_init_game_objects
        do @_init_environment

        @theme = 'static/sound/khanTheme.mp3'
        @score = 0
        @state =
            is_cleared_for_departure : false
            is_departure_requested : false


    handle_hail: ( prefix, message, response_function ) ->

        console.log "[LEVEL] message: #{ message }"
        if /request permission to depart/i.test message
            @state.is_departure_requested = true
            return


    # Level states
    _is_crew_boarded: ->
        for c in @enterprise_crew
            if c not in @enterprise.internal_personnel
                return false
        return true

    _is_cargo_secured: ->
        for c in @spacedock.cargobays
            for k, v of c
                if v > 0
                    return false
        return true

    _has_requested_departure: ->
        @state.is_departure_requested

    _has_departed: ->
        if @enterprise.velocity.x > 0 or @enterprise.velocity.y > 0 or @enterprise.velocity.z > 0
            return true
        return false

    _has_arrived_at_range: ->
        if U.distance(@enterprise.position, @range_position) < 1e6
            return true
        return false

    _has_destroyed_w_phasers: ->
        if @beacon1.is_alive
            return false
        return true

    _has_destroyed_subsystem: ->
        if @beacon2.is_alive and @beacon2.tranceiver.status = 0
            return true
        return false

    _has_destroyed_w_torpedoes: ->
        # TODO to make this harder, this should just be a check for a torp
        # detonation
        for b in [@beacon3, @beacon4, @beacon5, @beacon6, @beacon7]
            if b.is_alive
                return false
        return true

    get_events: =>

        # actions
        end_game = ( g ) =>
            g.is_over = true

        # Is crew boarded
        message_crew_boarded = ( g ) =>
            g.hail @stardock.prefix_code, "Enterprise, this is Stardock; all
crew confirmed boarded."

        # Is cargo boarded
        message_cargo_boarded = ( g ) =>
            g.hail @stardock.prefix_code, "Enterprise, this is Stardock; all
cargo secured."

        # Has requested clearance to depart
        message_departure_clearance = ( g ) =>
            if !@_is_crew_boarded()
                g.hail @stardock.prefix_code, "Negative Enterprise; you still
have disembarked crew aboard."
                return

            if !@_is_cargo_secured()
                g.hail @stardock.prefix_code, "Negative Enterprise; we still show
remaining cargo for you to transfer."
                return

            else
                @state.is_cleared_for_departure = true
                g.hail @stardock.prefix_code, "Roger that Enterprise; moorings
retracted. You are clear to depart."

        # Has departed
        verify_departure = ( g ) =>
            if !@state.is_cleared_for_departure
                # damage the enterprise and space dock

                g.hail @stardock.prefix_code, "Enterprise! Cut speed immediately.
You were not cleared for departure. Your ship and the dock have
both suffered damage."
                return

            if @enterprise.impulse > 0 or @enterprise.warp_speed > 0
                g.hail @stardock.prefix_code, "Enterprise! You will restrict
yourself to manuvering thrusters while at spacedock! We are logging this
incident in your permanent record."
                @score -= 10

            g.hail @stardock.prefix_code, "Enterprise we show you cleared from
dock. The firing range at Altan 5 is expecting you for weapons testing."

        # Has arrived at Altan 5
        welcome_to_range = ( g ) =>
            g.hail @range_station.prefix_code, "Welcome to the Altan 5 firing
range Enterprise."
            g.hail @range_station.prefix_code, "When you're ready, target beacon
563-X and fire phasers."

        # Has destroyed first target with phasers
        instruct_to_target_subsystems = ( g ) =>
            g.hail @range_station.prefix_code, "Very good Enterprise. Now
target beacon 711-D, and target the tranceiver subsystem. Destroy the subsystem
but not the beacon."

        # Has destroyed second target subsystem
        check_second_target = ( g ) =>
            if !@beacon2.is_alive
                g.hail @range_station.prefix_code, "Enterprise, you failed to
control your fire. I'm affraid that means you've failed the live-fire trial."
                @score -= 20
                do end_game
                return
            @score += 10
            g.hail @range_station.prefix_code, "Well done Enterprise. Proceed to
target the B beacon cluster, and destroy the field with a torpedo
blast. One shot at maximum yield will be sufficient."

        # Has destroyed cluster of targets with torpedos
        check_are_all_beacons_dead = ( g ) =>
            if @beacon3.is_alive or @beacon4.is_alive or @beacon5.is_alive or @beadon6.is_alive or @beacon7.is_alive
                g.hail @range_station.prefix_code, "Enterprise, you failed to
target and destroy the target beacons. I'm affraid that means you've failed the
live-fire trial."
                @score -= 20
                do end_game
                return
            @score += 20
            g.hail @range_station.prefix_code, "Excellent, well done Enterprise.
You have cleared weapons trials and are cleared for your next mission."
            do end_game

        crew_boarded = new LevelEvent {
            name : 'Crew Boarded',
            condition : @_is_crew_boarded,
            action : message_crew_boarded
        }

        cargo_secured = new LevelEvent {
            name : 'Cargo Secured',
            condition : @_is_cargo_secured,
            action : message_cargo_boarded
        }

        clearance = new LevelEvent {
            name : 'Dock Clearance',
            condition : @_has_requested_departure,
            action : message_departure_clearance
        }

        departure = new LevelEvent {
            name : 'Dock Departure',
            condition : @_has_departed,
            action : verify_departure
        }

        arrived_at_range = new LevelEvent {
            name : 'Arrived at Range',
            condition : @_has_arrived_at_range,
            action : welcome_to_range
        }

        destroy_w_phasers = new LevelEvent {
            name : 'Has destroyed the beacon with Phasers',
            condition : @_has_destroyed_w_phasers,
            action : instruct_to_target_subsystems
        }

        destroy_subsystem = new LevelEvent {
            name : 'Destroy subsystem with Phasers',
            condition : @_has_destroyed_subsystem,
            action : check_second_target
        }

        destroy_w_torpedoes = new LevelEvent {
            name : 'Destroy with torpedoes',
            condition : @_has_destroyed_w_torpedoes,
            action : check_are_all_beacons_dead
        }

        events = [
            crew_boarded,
            cargo_secured,
            clearance,
            departure,
            arrived_at_range,
            destroy_w_phasers,
            destroy_subsystem,
            destroy_w_torpedoes
        ]

    _init_map: ->

        sector = new SpaceSector "7811"
        altan = new StarSystem "Altan"

        altan_position =
            x : 14.8
            y : 2
            z : 4.7

        sector.add_star_system altan, altan_position
        @map = sector


    _init_logs: ->

        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            We are in space dock in orbit of Altan 3, having undergone some
            routine maintenance, and in preparation of taking on our new crew.\n
            \n
            Our orders are to beam aboard the ships crew and cargo, power up,
            and head out to the firing range in orbit or Altan 5, to test our
            phasers, targeting sensors, and torpedo launchers.\n
            \n\n
            "
        ]


    _init_space_objects: ->

        system = @map.get_star_system 'Altan'
        @altan = new Star 'Altan', Star.CLASSIFICATION.G, 0
        @altan.charted = true
        system.add_star @altan
        @space_objects.push @altan

        # Altan 1 - 3 are rocks
        a1 = new Planet "1", 'Altan', Planet.CLASSIFICATION.B, 0.3*C.AU
        a2 = new Planet "2", 'Altan', Planet.CLASSIFICATION.B, 0.5*C.AU
        a3 = new Planet "3", 'Altan', Planet.CLASSIFICATION.N, 0.8*C.AU

        # Altan 4 and 5 are outer gas giants
        a4 = new Planet "4", 'Altan', Planet.CLASSIFICATION.J, 5*C.AU
        a5 = new Planet "5", 'Altan', Planet.CLASSIFICATION.J, 20*C.AU

        for p in [a1, a2, a3, a4, a5]
            @space_objects.push p
            system.add_planet p

        @altan3 = a3
        @altan5 = a5


    _init_ships: ->

        system = @map.get_star_system 'Altan'

        dock_position =
            x : @altan3.position.x + @altan3.radius * 3
            y : @altan3.position.y + @altan3.radius * 2
            z : @altan3.position.z

        @stardock = new StarDock 'L', '897'
        @stardock.star_system = system
        @stardock.set_coordinate dock_position
        @stardock.set_alignment C.ALIGNMENT.FEDERATION

        @enterprise = new Constitution 'Enterprise', '1701-A'
        @enterprise.star_system = system
        @enterprise.set_coordinate dock_position
        @enterprise.set_alignment C.ALIGNMENT.FEDERATION
        @enterprise.enter_captains_log @enterprise_logs[ 0 ]

        @ships[ @enterprise.prefix_code ] = @enterprise

        # shutdown the enterprise
        @enterprise.set_power_to_system @enterprise.forward_shields.name, 0
        @enterprise.set_power_to_system @enterprise.forward_sensors.name, 0
        @enterprise.set_power_to_system @enterprise.weapons_targeting.name, 0
        @enterprise.reroute_power_relay @enterprise.forward_eps.name, @enterprise.e_power_relay.name
        do @enterprise.warp_core.deactivate
        do @enterprise.impulse_reactors.deactivate

        # get her crew onto the stardock
        @enterprise_crew = @enterprise.internal_personnel
        for c in @enterprise_crew
            t = @enterprise.beam_away_crew c.id, c.deck, c.section
            # pick one of decks 3 - 6
            d = 3 + Math.floor( Math.random() * 4 )
            @stardock.beam_onboard_crew t, d.toString(), '6'

        # empty her cargo bays
        for c in @enterprise.cargobays
            c.inventory = {}

        range_position =
            x : @altan5.position.x + @altan5.radius * 5
            y : @altan5.position.y + @altan5.radius * 5
            z : @altan5.position.z
        @range_position = range_position

        @range_station = new Station 'Range Control', range_position
        @range_station.star_system = system
        @range_station.set_alignment C.ALIGNMENT.FEDERATION

        @beacon1 = new Beacon '563-X'  # phaser target
        @beacon1.set_position range_position
        @beacon1.position.x += 1e6
        @beacon1.position.y += Math.floor( Math.random() * 1e4 )

        @beacon2 = new Beacon '711-D'  # subsystem target
        @beacon2.set_position range_position
        @beacon2.position.x += 2e6
        @beacon2.position.y += Math.floor( Math.random() * 1e4 )

        # torpedo targets
        blast_position =
            x : range_position.x + 5e7
            y : range_position.y + 5e7
            z : 0

        @beacon3 = new Beacon '31-B'
        @beacon4 = new Beacon '32-B'
        @beacon5 = new Beacon '33-B'
        @beacon6 = new Beacon '34-B'
        @beacon7 = new Beacon '35-B'
        for b in [@beacon3, @beacon4, @beacon5, @beacon6, @beacon7]
            b.set_position blast_position
            b.position.x += Math.floor( Math.random() * 2e4 - 1e4 )
            b.position.y += Math.floor( Math.random() * 2e4 - 1e4 )
            b.position.z += Math.floor( Math.random() * 2e4 - 1e4 )


    _init_game_objects: ->

    _init_environment: ->

    get_final_score: ->
        @score

exports.Level = Academy
