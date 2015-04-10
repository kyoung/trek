{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{D7} = require '../ships/D7'

{System, ChargedSystem} = require '../BaseSystem'
{Station} = require '../Station'
{CelestialObject, Star, GasCloud} = require '../CelestialObject'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../systems/WeaponSystems'
{SpaceSector, StarSystem} = require '../Maps'

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


    _init_map: () ->


    _init_logs: () ->


    _init_ships: () ->


    _init_game_objects: () ->


    _init_space_objects: () ->


    _init_environment: () ->



exports.Level = TinkerTaylor
