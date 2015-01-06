class Level
    constructor: () ->
        @name = "BaseLevel"
        @game_time_start = new Date().getTime()
        @ships = {}
        @space_objects = []
        @game_objects = []
        @map = {}

    get_ships: () ->
    get_space_objects: () ->
    get_game_objects: () ->
    get_map: () ->
    get_events: () ->
    get_environment: () ->
    get_final_score: () ->
        return false

exports.Level = Level