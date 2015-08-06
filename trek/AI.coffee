{ AIState, HoldingState, PatrollingState, HuntingState, BattleState, MovingToPointState } = require './ai/State'


class AI

    @RESPONSE_TIME = 5000

    constructor: ( @game, @prefix ) ->

        startup_stats = do @game.get_startup_stats
        @ship_name = ( s for s in startup_stats.ai_ships when s.prefix is @prefix )[ 0 ].name

        # Initial state is Holding position
        # Look ma! A push-down automaton!
        @state_stack = [ new HoldingState() ]


    set_agro: ( @is_agro ) ->

    # Typical NPC behaviours

    move_to: ( position ) ->

        @state_stack.push new MovingToPointState position


    attack_move_to: ( position ) ->

        @state_stack.push new BattleState()
        @state_stack.push new MovingToPointState position

    # ? I'm not sure what I was thinking this would be used for
    # Don't use this
    receive_order: ( order ) ->

        ai = @
        new_state = @state_stack[ @state_stack.length - 1 ].receive_order ai, order
        if new_state instanceof AIState
            @state_stack = @state_stack.concat new_state


    update: () =>

        # Am I dead?
        ship = @game.ai_ships[ @prefix ]
        if not ship.alive
            return

        # Wrap all of this in a try statement, to prevent it
        # from crashing the main event loop
        try
            ai = @
            new_state = @state_stack[ @state_stack.length - 1 ].update ai, @game
            if new_state instanceof AIState
                @state_stack = @state_stack.concat new_state
        catch error
            console.log error


    current_state_complete: () -> @state_stack.pop


    play: () ->

        setInterval @update, AI.RESPONSE_TIME


    current_state: () ->

        @state_stack[ @state_stack.length - 1 ].state_name


play = ( game, prefixes, init_states ) ->

    AIs = []
    for prefix, i in prefixes
        m5 = new AI game, prefix
        # Allow the passing of initial states
        if init_states?
            m5.state_stack.push init_states[ i ]
        do m5.play
        AIs.push m5
    return AIs


exports.play = play
exports.AI = AI
