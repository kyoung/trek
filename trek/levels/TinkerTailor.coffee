{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{D7} = require '../ships/D7'

{System, ChargedSystem} = require '../BaseSystem'
{Station} = require '../Station'
{CelestialObject, Star, GasCloud, Planet, Lagrange} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'

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
        do @_init_ships
        do @_init_game_objects
        do @_init_space_objects
        do @_init_environment

        @_initial_lives = do @_get_crew_count

        @code_word = /tinker tailor/i


    _is_ship_destroyed: => !@enterprise.alive


    _is_mission_accomplished: =>

        @spy in @enterprise.internal_personnel and !@klingon.alive


    _is_message_sent: =>

        message_sent = do @enterprise.get_comms
        for m in message_sent
            if m.type is 'sent'
                if @code_word.test m.message
                    console.log "[[LVL]] trigger word detected!"
                    return true
        return false


    get_events: =>

        end_game = ( game ) ->
            console.log ">>> Game Over <<<"
            game.is_over = true

        commit_sabotage = ( game ) =>
            console.log ">>> Sabott <<<"

            k = @klingon

            # damage the klingon ship
            # # destroy primary power systems (warp core breach?)
            do k.warp_core.deactivate
            k.warp_core.state = 0.2 * do Math.random

            # # vent warp plasma
            k.port_warp_coil.charge = 0
            k.starboard_warp_coil.charge = 0

            # # deactivate the cloak system, and hide it in the cargo bay
            do k.decloak
            k.cloak_system = undefined
            k.cargobays[0].add_cargo "Cloaking Device", 1

            send_distress = ->
                # route emergency power to the communications systems
                # route port eps to emergency power
                k.reroute_power_relay k.port_eps.name, k.e_power_relay.name
                k.set_power_to_system k.communication_array.name, 1

                # TODO activate the transponder

                # have the klingon ship send out a distress call
                game.hail k.prefix_code, "[Translated from Klingon] This is the
                #{ k.name } hailing the ChoRe. We have suffered damage to our
                warp core. [ STATIC ] breach [ STATIC ] immenent; the crew has
                [ STATIC ] sabota[ END TRANSMISSION ]"

            setTimeout send_distress, 15000 * Math.random()


        sabotage = new LevelEvent {
            name : 'Sabotage',
            condition : @_is_message_sent,
            do : commit_sabotage
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

        events = [
            loose,
            win,
            sabotage
        ]



    _get_crew_count: ->

        count = 0
        for o in @game_objects
            for c in o.get_lifesigns
                count += do c.count


    _init_map: () ->

        sector = new SpaceSector "2531"
        klthos = new StarSystem "Klthos"

        klthos_position =
            x : 3.8
            y : 2.9
            z : 14.3

        sector.add_star_system klthos, klthos_position
        @map = sector


    _init_logs: () ->

        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            Starfleet intelligence has an operative aboard the Klingon cruiser
            KDF ChinTok, in an effort to retrieve one of their new cloaking
            devices. The operative has signaled that he requires extraction and
            has a plan to take the cloaking device with him.\n
            \n
            We are hiding the Enterprise in the Klthos system. The Klthos star
            puts out an intense amount of Kreller radiation, which masks our
            ship's power signature. Our intel indicates that the ChinTok will
            be patrolling the system.\n
            \n
            Once in the system, our operative will sabotage the ChinTok,
            causing the crew to flee in escape pods. In it's disabled state, we
            will be able to approach and recover both the operative and cloaking
            device.\n
            \n
            Starfleet intelligence warns that there may be a second battle
            cruiser in the area, and any distress call from the ChinTok might
            draw them near. We will have to act fast if we want to avoid an all
            out war with the Klingons.\n
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
        @enterprise = e

        kling_position = do @_random_start_position
        k = new D7 'ChinTok'
        k.star_system = system
        k.set_coordinate kling_position
        k.set_alignment C.ALIGNMENT.KLINGON
        @ai_ships[ k.prefix_code ] = k
        @klingon = k

        @spy = new Spy k.DECKS['15'], k.SECTIONS.PORT, EngineeringTeam
        @spy.set_true_alignment C.ALIGNMENT.FEDERATION
        @klingon.internal_personnel.push @spy

        # kling2_position = do @_random_start_position
        # k2 = new D7 'ChoRe'
        # k2.star_system = system
        # k2.set_coordinate kling2_position
        # k2.set_alignment C.ALIGNMENT.KLINGON
        # @ai_ships[ k2.prefix_code ] = k2
        # @klingon2 = k2


    _init_game_objects: () ->

        for k, v of @ai_ships
            @game_objects.push v

        for k, v of @ships
            @game_objects.push v


    _init_space_objects: () ->

        system = @map.get_star_system 'Klthos'
        s = new Star 'Klthos', 'B', 0
        s.charted = true
        system.add_star s
        @klthos = s
        @space_objects.push s

        # Add 2 gas giants w/ moons and lagrange points
        @gas_planet_1 = new Planet 'alpha', 'T', 10 * C.AU
        @gas_planet_2 = new Planet 'beta', 'J', 22 * C.AU

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

        # Add up to 5 smaller planets
        init_orbit = 0.3 * C.AU
        for i in [ 0..Math.floor( Math.random() * 6 ) ]
            p = new Planet "k#{ i }", 'D', init_orbit
            @space_objects.push p
            system.add_planet p
            init_orbit *= 2


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
