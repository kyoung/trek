{AIState, HoldingState, PatrollingState, HuntingState} = require './ai/State'


class AI

    @RESPONSE_TIME = 5000

    constructor: ( @game, @prefix ) ->

        startup_stats = do @game.get_startup_stats
        @ship_name = ( s for s in startup_stats.ai_ships when s.prefix is @prefix )[ 0 ].name

        # Initial state is Holding position
        # Look ma! A push-down automaton!
        @state_stack = [ new HoldingState() ]


    set_agro: ( @is_agro ) ->


    receive_order: ( order ) ->

        ai = @
        new_state = @state_stack[ @state_stack.length - 1 ].receive_order ai, order
        if new_state instanceOf AIState
            @state_stack = @state_stack.concat new_state


    update: () =>

        ai = @
        new_state = @state_stack[ @state_stack.length - 1 ].update ai, @game
        if new_state instanceof AIState
            @state_stack = @state_stack.concat new_state


    play: () ->

        setInterval @update, AI.RESPONSE_TIME


    current_state: () ->

        @state_stack[ @state_stack.length - 1 ].state_name


play = ( game, prefixes, init_states ) ->

    for prefix, i in prefixes
        m5 = new AI game, prefix
        # Allow the passing of initial states
        if init_states?
            m5.state_stack.push init_states[ i ]
        do m5.play


exports.play = play
exports.AI = AI
