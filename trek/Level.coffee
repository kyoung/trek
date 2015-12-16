class Level

    constructor: ->

        @name = "BaseLevel"
        @game_time_start = new Date().getTime()
        @ships = {}
        @ai_ships = {}
        @ai_states = {}
        @space_objects = []
        @game_objects = []
        @map = {}
        @theme = 'static/sound/theme.mp3'


    get_ships: ->

        ships = {}
        for p, s of @ships
            ships[ p ] = s
        for p, s of @ai_ships
            ships[ p ] = s
        return ships


    get_player_ships: -> @ships


    get_ai_ships: -> @ai_ships


    get_ai_states: -> @ai_states


    set_AIs: ( @AIs ) ->


    get_space_objects: -> @space_objects


    get_game_objects: -> @game_objects


    get_map: -> @map


    get_events: -> []

    get_environment: ->
    get_final_score: -> return 0

    handle_hail: ( prefix, message ) ->


exports.Level = Level
