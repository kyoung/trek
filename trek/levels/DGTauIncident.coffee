{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'

{System, ChargedSystem} = require '../BaseSystem'
{Station} = require '../Station'
{CelestialObject, Star, GasCloud} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'
Constants = require "../Constants"

C= Constants
U = require "../Utility"



class DGTauIncident extends Level

    background_radiation: ShieldSystem.POWER.dyn / ShieldSystem.CHARGE_TIME * .2

    constructor: ( @team_count ) ->

        super()
        @name = "DG Tau Incident"
        @stardate = do U.stardate
        do @_init_map
        do @_init_logs
        do @_init_ships
        do @_init_game_objects
        do @_init_space_objects
        do @_init_environment

        @_safe_distance = 10 * C.AU
        @_initial_lives = do @_get_crew_count


    get_environment: -> @game_environment


    get_ships: -> @ships


    get_space_objects: -> @space_objects


    get_game_objects: -> @game_objects


    get_map: -> @map


    _get_crew_count: ->

        count = 0
        for o in @game_objects
            for c in do o.get_lifesigns
                count += do c.count


    _is_mission_impossible: =>

        # Is everyone dead?
        everyone_is_dead = true
        for prefix, ship of @ships
            ship_ok = ( do ship._check_if_still_alive ) #and 0 < do ship.get_crew_count )
            if ship_ok
                everyone_is_dead = false

        if everyone_is_dead
            return true

        return false


    _is_mission_accomplished: ( game ) =>

        # Are all miners off of existing stations, and
        # the ships are clear of the system
        all_miners_are_off_the_stations = true
        all_stations_destroyed = true
        for s in @stations
            if do s._check_if_still_alive and s.crew.length > 0
                all_miners_are_off_the_stations = false
            all_stations_destroyed = all_stations_destroyed and not s.alive

        # Did you rescure miners
        miners_rescued = false
        ships_are_clear_of_system = true
        for prefix, ship of @ships

            if U.distance_between( @dgtau, ship ) < @_safe_distance
                ships_are_clear_of_system = false

            for c in ship.internal_personnel
                if /Outpost/.test c.assignment
                    miners_rescued = true

        if all_miners_are_off_the_stations and all_stations_destroyed and ships_are_clear_of_system and miners_rescued
            console.log "Missiong complete."
            return true

        # console.log "Mission is not accomplished"
        return false


    get_events: ->


        end_game = ( game ) -> game.is_over = true


        set_particle_density = ( game ) ->

            _particle_density_at_point = ( p ) ->

                # if you're outside of the accretion disk, particle density is a non-issue
                if ( -C.AU / 16 ) > p.z or p.z > ( C.AU / 16 )
                    return 0.043214

                # box-y-x method of finding local dust clouds
                dust = ( o for o in game.space_objects when o.quick_fits p )
                net_density = 0
                net_density += p.density for p in dust

                return net_density

            game.set_environment_function C.ENVIRONMENT.PARTICLE_DENSITY, _particle_density_at_point


        radiation_spike = ( game ) ->

            shield_charge_rate = ShieldSystem.POWER.dyn / ShieldSystem.CHARGE_TIME
            high_level = 1 + do Math.random
            low_level = do Math.random * 0.2


            _base_radiation_level = ( p ) ->
                r = shield_charge_rate * 1e12
                d = U.distance p, { x : 0, y : 0, z : 0 }
                # Raditation doesn't come from a point, but a line (the star jets)
                r / d


            _high_radiation = ( p ) ->
                wiggle = 0.98 + 0.04 * do Math.random
                r = _base_radiation_level p
                dust = game.get_environmental_condition_at_position C.ENVIRONMENT.PARTICLE_DENSITY, p
                return Math.max( r * high_level * wiggle * ( 1 - dust ), 0 )


            _low_radiation = ( p ) ->
                wiggle = 0.98 + 0.04 * do Math.random
                r = _base_radiation_level p
                dust = game.get_environmental_condition_at_position C.ENVIRONMENT.PARTICLE_DENSITY, p
                return Math.max( r * low_level * wiggle * ( 1 - dust ), 0 )


            _end_spike = ->
                game.set_environment_function C.ENVIRONMENT.RADIATION, _low_radiation


            game.set_environment_function C.ENVIRONMENT.RADIATION, _high_radiation

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

        particle_density = new LevelEvent {
            name : "Particle Density Init",
            delay : 500,
            do : set_particle_density }

        events = [
            impossible,
            win,
            radiation,
            particle_density
        ]


    get_final_score: ->

        score = {}
        for k, s of @ships
            crew_count = 0
            for c in do s.get_lifesigns
                crew_count += do c.count
            score[ s.name ] = Math.floor( crew_count / @_initial_lives * 100 )

        return score


    handle_hail: ( prefix, message, response_function ) ->

        console.log "[LEVEL] message: #{ message }"

        # Allow ships to request outposts to lower their shields for transport
        outpost_number = message.match /outpost (\d+)/i
        lower = message.match /lower/i
        raise = message.match /raise/i

        if not outpost_number? or outpost_number.length is 0 or ( lower?.length is 0 and raise?.length is 0 )
            return

        outpost_num = outpost_number[1]
        outpost = ( s for s in @stations when s.name is 'Outpost_' + outpost_num )[ 0 ]

        if lower?.length > 0
            do outpost.shields.power_down

        else
            if raise?.length > 0
                do outpost.shields.power_on

        respond = ->
            if lower?.length > 0
                response_function "Acknowledged, lowering shields."

            if raise?.length > 0
                response_function "Understood, raising shields."

        setTimeout respond, ( 4000 * Math.random() )

        return true


    _random_start_position: ( z_axis=false, harmonic=false, max_radius ) ->

        board_size = C.SYSTEM_WIDTH / 2

        rotation = 2 * Math.PI * do Math.random

        radius = if max_radius? then ( 3 * C.AU + max_radius * do Math.random ) else ( 3 * C.AU + ( board_size / 2 * do Math.random ) )
        if harmonic
            ring_harmonics = [ 2, 3, 5, 7, 11, 13, 17, 19, 23 ]
            radius = ring_harmonics[ Math.floor( Math.random() * ring_harmonics.length ) ] * C.AU

        x = radius * Math.cos rotation
        y = radius * Math.sin rotation
        z = if z_axis then Math.round( ( Math.random() - 0.5 ) * ( C.AU / 8 ) ) else 0

        r = { x : x, y : y, z : z }


    _random_bearing: ->

        b =
            bearing: Math.floor( Math.random() *  1000 ) / 1000
            mark: 0


    _init_map: ->

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


    _init_logs: ->

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

        if @team_count is 2
            return

        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            We've entered the DG Tau system
            to carry out the evacuation of the mining team in the
            area. The young star has entered a dangerously volatile stage
            in it's development and has been emitting unpredictable bursts
            of radiation beyond the capacity of the mining station's shielding.\n
            \n
            The Enterprise is even less equiped to handle such hostile
            conditions, and as such we will be required to route as much
            additional power to shields as possible for the duration of the
            mission.\n
            \n
            Starfleet Command has stressed that the mining station in DG Tau is
            highly experimental, and classified. We have order to ensure that the
            station is destroyed after we complete it's evacuation.
            \n
            I'm not certain how much longer the miners can hold out under these
            conditions; time, it seems, is not on our side.\n
            " ]


    _init_ships: ->

        system = @map.get_star_system 'DG Tau'

        system_entry_point = @_random_start_position true
        ent_entry_point =
            x : system_entry_point.x + 3000
            y : system_entry_point.y
            z : system_entry_point.z
        lex_entry_point =
            x : system_entry_point.x
            y : system_entry_point.y
            z : system_entry_point.z

        initial_bearing = do @_random_bearing

        e = new Constitution "Enterprise", "1701-A"
        e.star_system = system
        e.set_coordinate ent_entry_point
        e.set_bearing initial_bearing
        e.set_alignment C.ALIGNMENT.FEDERATION
        e.set_alert 'yellow'

        for s in e.shields
            s.charge = 1

        # e.set_impulse 0.5
        e.enter_captains_log @enterprise_logs[ 0 ]
        @ships[ e.prefix_code ] = e

        if @team_count is 1
            return

        x = new Constitution "Lexington", "1709"
        x.star_system = system
        x.set_coordinate lex_entry_point
        x.set_bearing initial_bearing
        x.set_alignment C.ALIGNMENT.FEDERATION
        x.set_alert 'yellow'

        for s in x.shields
            s.charge = 1

        x.set_impulse 0.5
        x.enter_captains_log @lexington_logs[ 0 ]
        @ships[ x.prefix_code ] = x


    _init_game_objects: ->

        system = @map.get_star_system 'DG Tau'

        @stations = []
        has_z_coordinate = true
        at_harmonic = false
        max_radius = 12 * C.AU
        for i in [ 1 ]
            p = @_random_start_position has_z_coordinate, at_harmonic, max_radius
            s = new Station "Outpost_#{ i }", p
            s.star_system = system
            s.set_alignment C.ALIGNMENT.FEDERATION
            do s.shields.power_on
            s.shields.charge = 1
            @stations.push s
            @game_objects.push s

        for k, v of @ships
            @game_objects.push v


    _init_space_objects: ->

        system = @map.get_star_system 'DG Tau'
        # Central star
        s = new Star "DG Tau", "D", ShieldSystem.POWER.dyn / ShieldSystem.CHARGE_TIME * 1e12
        s.charted = true
        s.misc = [ { name : 'Accretion Disk', value : "#{ Math.round( C.AU / 8 / 1000 ) } km" } ]
        system.add_star s
        @dgtau = s
        @space_objects.push s

        # Gas clouds
        has_z_coordinate = false
        for i in [0...1e3]
            g = new GasCloud( C.AU * ( 0.3 + Math.random() ), C.AU / 8 )
            g.charted = true
            on_harmonic = if i % 4 > 0 then true else false
            { x, y, z } = @_random_start_position has_z_coordinate, on_harmonic
            g.set_position x, y, z
            @space_objects.push g
            system.add_clouds g


    _init_environment: ->

        @game_environment = {}
        for k, v of C.ENVIRONMENT
            _null = ( p ) ->
                return 0
            @game_environment[ v ] = _null

        bg_radiation = @background_radiation
        initial_radiation = ( p ) -> bg_radiation

        initial_particle_density = ( p ) -> 1

        @game_environment[ C.ENVIRONMENT.RADIATION ] = initial_radiation
        @game_environment[ C.ENVIRONMENT.PARTICLE_DENSITY] = initial_particle_density


exports.Level = DGTauIncident
