{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{D7} = require '../ships/D7'

{System, ChargedSystem} = require '../BaseSystem'
{Station} = require '../Station'
{CelestialObject, Star, GasCloud} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'

{Spy, EngineeringTeam} = require '../Crew'

C = require "../Constants"
U = require "../Utility"


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


    _is_ship_destroyed: => !@enterprise.alive


    _is_mission_accomplished: =>
        @spy in @enterprise.internal_personnel and !@klingon.alive


    get_events: ->

        end_game = ( game ) ->
            console.log ">>> Game Over <<<"
            game.is_over = true


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
            win
        ]



    _get_crew_count: ->

        count = 0
        for o in @game_objects
            for c in o.get_lifesigns
                count += do c.count


    _init_map: () ->

        sector = new SpaceSector "2531"
        klthos = new StarSystem "K'lthos"

        klthos_position =
            x : 3.8
            y : 2.9
            z : 14.3

        sector.add_star_system klthos, klthos_position
        @map = sector


    _init_logs: () ->

        @enterprise_logs = [
            'Captains Log, stardate #{ @stardate }\n
            \n
            Klingons!'
        ]


    _init_ships: () ->

        system = @map.get_star_system 'K\'lthos'

        system_entry_point = do @_random_start_position
        e = new Constitution 'Enterprise', '1701-A'
        e.star_sysem = system
        e.set_coordinate system_entry_point
        e.set_alignment C.ALIGNMENT.FEDERATION
        e.set_alert 'red'
        e.enter_captains_log @enterprise_logs[ 0 ]
        @ships[ e.prefix_code ] = e
        @enterprise = e

        kling_position = do @_random_start_position
        k = new D7 'Chin\'Tok'
        k.star_system = system
        k.set_coordinate kling_position
        k.set_alignment C.ALIGNMENT.KLINGON
        @ai_ships[ k.prefix_code ] = k
        @klingon = k

        @spy = new Spy k.DECKS['10'], k.SECTIONS['Aft'], EngineeringTeam
        @spy.set_true_alignment C.ALIGNMENT.FEDERATION
        @klingon.internal_personnel.push @spy


    _init_game_objects: () ->

        for k, v of @ai_ships
            @game_objects.push v

        for k, v of @ships
            @game_objects.push v


    _init_space_objects: () ->

        system = @map.get_star_system 'K\'lthos'
        s = new Star 'K\'lthos Prime', 'B', 0
        s.charted = true
        system.add_star s
        @klthos = s
        @space_objects.push s


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
