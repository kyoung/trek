{HoldingState, PatrollingState, HuntingState} = require './ai/State'


class AI

    @RESPONSE_TIME = 1000

    constructor: ( @game, @prefix ) ->

        startup_stats = do @game.get_startup_stats
        @ship_name = ( s for s in startup_stats.ai_ships when s.prefix is @prefix )[ 0 ].name

        # Initial state is Holding position
        # Look ma! A push-down automaton!
        @state_stack = [ new HoldingState() ]


    receive_order: ( order ) ->

        ai = @
        new_state = @state_stack[ @state_stack.length - 1 ].receive_order ai, order
        if new_state?
            @state_stack.push new_state


    update: () ->

        ai = @
        @state_stack[ @state_stack.length - 1 ].update ai, @game


    play: () ->

        setInterval @update, AI.RESPONSE_TIME


    current_state: () ->

        @state_stack[ @state_stack.length - 1 ].state_name


play = ( game, prefixes ) ->

    for prefix in prefixes
        m5 = new AI game, prefix
        do m5.play


exports.play = play
exports.AI = AI
