{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'

{Station} = require '../Station'
{CelestialObject, Star, GasCloud} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'
Constants = require "../Constants"

C= Constants
U = require "../Utility"



class DGTauIncident extends Level

    background_radiation: ShieldSystem.POWER.dyn / ShieldSystem.CHARGE_TIME * .2

    constructor: () ->
        super()
        @name = "DG Tau Incident"
        @stardate = do U.stardate
        do @_init_map
        do @_init_logs
        do @_init_ships
        do @_init_game_objects
        do @_init_space_objects
        do @_init_environment

        @_safe_distance = 5 * C.AU
        @_initial_lives = do @_get_crew_count


    get_environment: () ->
        @game_environment


    get_ships: () ->
        @ships


    get_space_objects: () ->
        @space_objects


    get_game_objects: () ->
        @game_objects


    get_map: () ->
        @map


    _get_crew_count: () ->

        count = 0
        for o in @game_objects
            for c in do o.get_lifesigns
                count += do c.count


    _is_mission_impossible: () =>

        # Is everyone dead?
        everyone_is_dead = true
        for prefix, ship of @ships
            if ship._check_if_still_alive()
                everyone_is_dead = false

        if everyone_is_dead
            return true

        return false


    _is_mission_accomplished: () =>

        # Are all miners off of existing stations, and
        # the ships are clear of the system
        all_miners_are_off_the_stations = true
        for s in @stations
            if do s._check_if_still_alive and s.crew.length > 0
                all_miners_are_off_the_stations = false

        ships_are_clear_of_system = true
        #for prefix, ship of @ships
        #    if U.distance_between( @dgtau, ship ) < @_safe_distance
        #        ships_are_clear_of_system = false

        if all_miners_are_off_the_stations and ships_are_clear_of_system
            console.log "Missiong is accomplished!"
            return true

        # console.log "Mission is not accomplished"
        return false


    get_events: () ->

        end_game = ( game ) ->
            game.is_over = true

        radiation_spike = ( game ) ->

            shield_charge_rate = ShieldSystem.POWER.dyn / ShieldSystem.CHARGE_TIME
            high_level = 1 + do Math.random
            low_level = do Math.random * 0.5

            _high_radiation = ( p ) ->
                wiggle = 0.98 + 0.04 * do Math.random
                return shield_charge_rate * high_level * wiggle

            _low_radiation = ( p ) ->
                wiggle = 0.98 + 0.04 * do Math.random
                return shield_charge_rate * low_level * wiggle

            _end_spike = () ->
                game.set_environment_function(
                    C.ENVIRONMENT.RADIATION,
                    _low_radiation )

            game.set_environment_function(
                C.ENVIRONMENT.RADIATION,
                _high_radiation )

            setTimeout _end_spike, 2 * 60 * 1000 * do Math.random

        impossible = new LevelEvent {
            name : "Impossiblility",
            condition : @_is_mission_impossible,
            do : end_game }

        win = new LevelEvent {
            name : "Victory",
            condition : @_is_mission_accomplished,
            do : end_game }

        radiation = new LevelEvent {
            name : "Radiation Timing",
            every : 5 * 60 * 1000,
            plusMinus : 2 * 60 * 1000,
            do : radiation_spike }

        events = [
            impossible,
            win,
            radiation ]


    get_final_score: () ->

        score = {}
        for k, s of @ships
            crew_count = 0
            for c in do s.get_lifesigns
                crew_count += do c.count
            score[ s.name ] = Math.floor( crew_count / @_initial_lives * 100 )

        return score


    _random_start_position: () ->

        board_size = C.SYSTEM_WIDTH / 3
        x = Math.round((Math.random() - 0.5) * board_size)
        y = Math.round((Math.random() - 0.5) * board_size)
        z = 0
        r = {x: x, y: y, z: z}


    _random_bearing: () ->

        b =
            bearing: Math.floor( Math.random() *  1000 ) / 1000
            mark: 0


    _init_map: () ->

        sector = new SpaceSector "2298"
        dg_tau = new StarSystem "DG Tau"
        dg_tau_b = new StarSystem "DG Tau B"

        dg_tau_position =
            x: 7
            y: 5
            z: 6
        dg_tau_b_position =
            x: 7.4
            y: 5.6
            z: 6.2

        sector.add_star_system dg_tau, dg_tau_position
        sector.add_star_system dg_tau_b, dg_tau_b_position
        @map = sector


    _init_logs: () ->

        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            We've rendevued with the USS Lexington in the DG Tau system
            to assist in the evacuation of the mining teams in the
            area. The young star has entered a dangerously volatile stage
            in it's development and has been emitting unpredictable bursts
            of radiation beyond the capacity of the mining stations shielding.\n
            \n
            The Enterprise is even less equiped to handle such hostile
            conditions, and as such we will be required to route as much
            additional power to shields as possible for the duration of the
            mission.\n
            \n
            The captain of the Lexington has issued a wager to see who
            has rescued more of the miners by the time we complete our mission;
            I intend, not, to lose.\n
            " ]

        @lexington_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            The Enterprise has arrived to assist us in our rescue operations
            in the DG Tau System. Recent radiation surges have prompted us to move
            in and evacuate the miners in the area. Owing to the high levels of radiation,
            our engineering chief has had to advance the scheduled overhaul of our
            shielding system, and we are now ready to begin the operation.\n
            \n
            Enterprise has entered a friendly wager with us that she will have completed
            the rescue with more hands on board than ourselves. I intend to prove
            otherwise.\n
            " ]


    _init_ships: () ->

        system = @map.get_star_system 'DG Tau'

        system_entry_point = do @_random_start_position
        ent_entry_point =
            x: system_entry_point.x + 3000
            y: system_entry_point.y
            z: 0
        lex_entry_point =
            x: system_entry_point.x
            y: system_entry_point.y
            z: 0

        initial_bearing = do @_random_bearing

        e = new Constitution "Enterprise", "1701-A"
        e.star_system = system
        e.set_coordinate ent_entry_point
        e.set_bearing initial_bearing
        e.set_alignment C.ALIGNMENT.FEDERATION
        e.set_shields true
        e.set_impulse 0.5
        e.enter_captains_log @enterprise_logs[ 0 ]

        x = new Constitution "Lexington", "1709"
        x.star_system = system
        x.set_coordinate lex_entry_point
        x.set_bearing initial_bearing
        x.set_alignment C.ALIGNMENT.FEDERATION
        x.set_shields true
        x.set_impulse 0.5
        x.enter_captains_log @lexington_logs[ 0 ]

        @ships[ x.prefix_code ] = x
        @ships[ e.prefix_code ] = e


    _init_game_objects: () ->

        system = @map.get_star_system 'DG Tau'

        @stations = []
        for i in [1..10]
            s = new Station "Outpost_#{i}", do @_random_start_position
            s.star_system = system
            s.set_alignment C.ALIGNMENT.FEDERATION
            @stations.push s
            @game_objects.push s

        for k, v of @ships
            @game_objects.push v


    _init_space_objects: () ->

        system = @map.get_star_system 'DG Tau'
        # Central star
        s = new Star "DG Tau", "D"
        s.star_system = system

        @dgtau = s

        @space_objects.push s

        # Gas clouds
        for i in [0...1e4]
            g = new GasCloud( C.AU * Math.random(), C.AU / 8 )
            g.star_system = system
            {x, y, z} = do @_random_start_position
            g.set_position x, y, z
            @space_objects.push g


    _init_environment: () ->

        @game_environment = {}
        for k, v of C.ENVIRONMENT
            _null = ( p ) ->
                return 0
            @game_environment[ v ] = _null

        bg_radiation = @background_radiation

        initial_radiation = ( p ) ->
            bg_radiation

        @game_environment[ C.ENVIRONMENT.RADIATION ] = initial_radiation


exports.Level = DGTauIncident