{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{D7} = require '../ships/D7'

{System, ChargedSystem} = require '../BaseSystem'
{Station} = require '../Station'
{CelestialObject, Star, GasCloud, Planet, Lagrange} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'

{BattleState, HoldingState} = require '../ai/State'

{Spy, EngineeringTeam} = require '../Crew'

C = require "../Constants"
U = require "../Utility"

# Premise:
# There's an agent undercover onboard a Klingon D7 trying to get a new
# cloak off of the ship to starfleet intelligence. As part of his plan,
# he's sent instructions to starfleet to have a starship in a disputed
# system that his ship will be assigned to chase off. Once in the system,
# he will sabotage his ship, and take the cloaking device in an escape
# pod. The Enterprise will have to race to rescue the pod and agent, as
# he reports that a second D7 is enroute.
#
# The second D7 will be cloaked, so the Enterprise will have to remain
# at red alert while hunting for the escape pod (?).

# Problem: why does the E need to linger in the system (smash and grab?),
# why fight?
#
# Ans: the operative destroyed a klingon ship, this is an act of war if
# the Klingon cruiser finds the E with the device. They have no choice
# but to engage and destroy the ship.


class TinkerTaylor extends Level

    constructor: ( @team_count ) ->

        super()
        @name = "Tinker Taylor"
        @stardate = do U.stardate
        do @_init_map
        do @_init_logs
        do @_init_space_objects
        do @_init_ships
        do @_init_game_objects
        do @_init_environment

        @theme = 'static/sound/klingonTheme.mp3'

        @_initial_lives = do @_get_crew_count

        @code_word = /tinker tailor soldier spy/i
        @code_word_said = false
        @marco_said = false


    _is_ship_destroyed: => !@enterprise.alive


    _is_mission_accomplished: =>

        @spy in @enterprise.internal_personnel and !@klingon.alive


    _is_message_sent: => @code_word_said


    _is_marco_said: => @marco_said


    handle_hail: ( prefix, message, response_function ) ->

        console.log "[LEVEL] message: #{ message }"
        if @code_word.test message
            @code_word_said = true

        if /marco/i.test message
            @marco_said = true


    get_final_score: ->

        if do @_is_mission_accomplished
            return 100

        return 0


    get_events: =>

        end_game = ( game ) ->

            console.log ">>> Game Over <<<"
            game.is_over = true


        say_polo = ( game ) =>

            game.hail @klingon.prefix_code, "#{ @klingon.name }: #{ @klingon.polo }"
            game.hail @klingon2.prefix_code, "#{ @klingon2.name }: #{ @klingon2.polo }"


        debug_sheilds = ( game ) =>

            sheild_report = ( { name : s.name, charge : s.charge } for s in @klingon.shields )
            console.log sheild_report


        commit_sabotage = ( game ) =>
            console.log ">>> Sabott <<<"

            k = @klingon
            k2 = @klingon2

            # damage the klingon ship
            # # destroy primary power systems (warp core breach?)
            k.set_power_to_reactor k.warp_core.name, 0
            do k.warp_core.deactivate
            k.warp_core.state = 0.2 * do Math.random

            # # vent warp plasma
            k.port_warp_coil.charge = 0
            k.starboard_warp_coil.charge = 0

            # # deactivate the cloak system, and hide it in the cargo bay
            do k.decloak
            k.cloak_system = undefined
            k.cargobays[0].add_cargo "Cloaking Device", 1

            k2_ai = ( ai for ai in @AIs when ai.prefix == k2.prefix_code )[ 0 ]

            send_distress = ->
                # route emergency power to the communications systems
                # route port eps to emergency power
                k.reroute_power_relay k.port_eps.name, k.e_power_relay.name
                k.set_power_to_system k.communication_array.name, 1

                # TODO activate the transponder
                k.set_online k.transponder.name, true

                # have the klingon ship send out a distress call
                game.hail k.prefix_code, "[Translated from Klingon] This is the
                #{ k.name } hailing the ChoRe. We have suffered damage to our
                warp core. [ STATIC ] breach [ STATIC ] immenent; the crew has
                [ STATIC ] sabota[ END TRANSMISSION ]"

                # initiate a 5 - 7 minute countdown to BOOM

                # have the other klingon ship come and help
                k2_ai.move_to k.position



            setTimeout send_distress, 15000 * Math.random()


        sabotage = new LevelEvent {
            name : 'Sabotage',
            condition : @_is_message_sent,
            do : commit_sabotage
        }

        marco_polo = new LevelEvent {
            name : 'Marco Polo',
            condition : @_is_marco_said,
            do : say_polo
        }

        loose = new LevelEvent {
            name : 'Defeat',
            condition : @_is_ship_destroyed,
            do : end_game
        }

        win = new LevelEvent {
            name : 'Victory',
            condition : @_is_mission_accomplished,
            do : end_game }

        # Helpful debug events
        #
        # debug = new LevelEvent {
        #     name : 'Debug',
        #     every : 5000,
        #     do : debug_sheilds
        # }
        #
        # auto_trigger = new LevelEvent {
        #     name : 'Sabot Trigger',
        #     delay : 10000,
        #     do : commit_sabotage
        # }

        events = [
            loose,
            win,
            sabotage,
            marco_polo,
            # debug, auto_trigger  # debug events
        ]



    _get_crew_count: ->

        count = 0
        for o in @game_objects
            for c in o.get_lifesigns
                count += do c.count


    _init_map: ->

        sector = new SpaceSector "2531"
        klthos = new StarSystem "Klthos"

        klthos_position =
            x : 3.8
            y : 2.9
            z : 14.3

        sector.add_star_system klthos, klthos_position
        @map = sector


    _init_logs: ->

        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            Starfleet intelligence has an operative aboard the Klingon cruiser
            KDF ChinTok, in an effort to retrieve one of their new cloaking
            devices. The operative has signaled that he requires extraction and
            has a plan to take the cloaking device with him.\n
            \n
            We are hiding the Enterprise in the Klthos system to hide our ship's
            power signature. Our intel indicates that the ChinTok will be
            patrolling the system.\n
            \n
            Once signaled, our operative will sabotage the ChinTok, allowing us
            to approach and recover both the operative and cloaking device.\n
            \n
            Starfleet intelligence warns that there may be a second battle
            cruiser in the area, and any distress call from the ChinTok might
            draw them near. We will have to act fast if we want to avoid
            discovery.\n
            \n
            It goes without saying that we can't afford to have the Klingons
            reporting back to the High Council what we do here today.\n\n
            "
        ]


    _init_ships: () ->

        system = @map.get_star_system "Klthos"
        console.log "Loading game in the #{ system.name } system"

        system_entry_point = do @_random_start_position
        e = new Constitution 'Enterprise', '1701-A'
        e.star_system = system
        e.set_coordinate system_entry_point
        e.set_alignment C.ALIGNMENT.FEDERATION
        e.set_alert 'red'
        e.enter_captains_log @enterprise_logs[ 0 ]
        @ships[ e.prefix_code ] = e
        e.set_online e.transponder.name, false  # let's be sneaky
        @enterprise = e

        if !( @space_objects.length > 0 )
            throw new Error "WTF space objects"

        start_point = @space_objects[ 1 + Math.floor( Math.random() * ( @space_objects.length - 1 ) ) ]
        p = start_point.position  # this is a planet... at least be in orbit
        if start_point.radius?
            start_distance = start_point.radius + Math.random() * 10 * start_point.radius
        else
            start_distance = Math.random() * 1e6
        start_rotation = Math.random() * Math.PI * 2
        x_rand = Math.cos( start_rotation ) * start_distance
        y_rand = Math.sin( start_rotation ) * start_distance
        k_position = { x : p.x + x_rand, y : p.y + y_rand, z: 0 }
        k = new D7 'ChinTok'
        k.star_system = system
        k.set_coordinate k_position
        k.set_alignment C.ALIGNMENT.KLINGON
        k.polo = start_point.name  # for debugging
        @ai_ships[ k.prefix_code ] = k
        do k.cloak
        @klingon = k

        @spy = new Spy k.DECKS['15'], k.SECTIONS.PORT, EngineeringTeam
        @spy.set_true_alignment C.ALIGNMENT.FEDERATION
        @klingon.internal_personnel.push @spy

        start_point = @space_objects[ 1 + Math.floor( Math.random() * ( @space_objects.length - 1 ) ) ]
        p = start_point.position
        if start_point.radius?
            start_distance = start_point.radius + Math.random() * 10 * start_point.radius
        else
            start_distance = Math.random() * 1e6
        start_rotation = Math.random() * Math.PI * 2
        x_rand = Math.cos( start_rotation ) * start_distance
        y_rand = Math.sin( start_rotation ) * start_distance
        k2_position = { x : p.x + x_rand, y : p.y + y_rand, z: 0 }
        k2 = new D7 'ChoRe'
        k2.star_system = system
        k2.set_coordinate k2_position
        k2.set_alignment C.ALIGNMENT.KLINGON
        k2.polo = start_point.name  # for debuggin
        @ai_ships[ k2.prefix_code ] = k2
        do k2.cloak
        @klingon2 = k2

        # two klingon AIs
        @ai_states = [ new BattleState(), new BattleState() ]


    _init_game_objects: () ->

        for k, v of @ai_ships
            @game_objects.push v

        for k, v of @ships
            @game_objects.push v


    _init_space_objects: () ->

        system = @map.get_star_system 'Klthos'
        s = new Star 'Klthos', Star.CLASSIFICATION.B, 0
        s.charted = true
        system.add_star s
        @klthos = s
        @space_objects.push s

        # Add up to 5 smaller planets
        init_orbit = 0.3 * C.AU
        inner_orbit_count = 1 + Math.floor( Math.random() * 6 )
        for i in [ 1..inner_orbit_count ]
            p = new Planet "#{ i }", system.name, Planet.CLASSIFICATION.D, init_orbit
            @space_objects.push p
            system.add_planet p
            init_orbit *= 2

        # Add 2 gas giants w/ moons and lagrange points
        @gas_planet_1 = new Planet "#{ inner_orbit_count + 1 }", system.name, Planet.CLASSIFICATION.J, 10 * C.AU
        @gas_planet_2 = new Planet "#{ inner_orbit_count + 2 }", system.name, Planet.CLASSIFICATION.T, 22 * C.AU

        # lagrange: +/- pi/3 radians of orbit
        alpha_lagrange_3 = new Lagrange @gas_planet_1, 3
        alpha_lagrange_4 = new Lagrange @gas_planet_1, 4
        beta_lagrange_3 = new Lagrange @gas_planet_2, 3
        beta_lagrange_4 = new Lagrange @gas_planet_2, 4

        for o in [ @gas_planet_1, @gas_planet_2 ]
            system.add_planet o
            @space_objects.push o

        for o in [ alpha_lagrange_3, alpha_lagrange_4, beta_lagrange_3,
            beta_lagrange_4 ]
            system.add_asteroids o
            @space_objects.push o


    _init_environment: () ->

        @game_environment = {}
        @game_environment[ C.ENVIRONMENT.PARTICLE_DENSITY ] = 0.3


    _random_start_position: ->

        board_size = C.SYSTEM_WIDTH / 2
        rotation = 2 * Math.PI * do Math.random

        radius = board_size * do Math.random
        x = radius * Math.cos rotation
        y = radius * Math.sin rotation
        z = 0

        r = { x : x, y : y, z : z }



exports.Level = TinkerTaylor
