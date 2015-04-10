class Level

    constructor: ->

        @name = "BaseLevel"
        @game_time_start = new Date().getTime()
        @ships = {}
        @ai_ships = {}
        @space_objects = []
        @game_objects = []
        @map = {}


    get_ships: -> @ships


    get_ai_ships: -> @ai_ships


    get_space_objects: -> @space_objects


    get_game_objects: -> @game_objects


    get_map: -> @map


    get_events: ->
    get_environment: ->
    get_final_score: ->
        return false
    handle_hail: ( prefix, message ) ->


exports.Level = Level
