C = require './Constants'
U = require './Utility'

class LevelEvent

    @ConditionInterval = 1000

    constructor: ( @args ) ->
        ###
        Accepts an args object, with the following properties:

        name : name     the name of this event, used for logging and debugging

        every : N       trigger the event every N ms

        delay : N       trigger event after N ms

        plusMinus : N   modify the 'every' or 'delay' parameter to add or subtract N

        condition : function
                        condition gets checked on an interval and if true, 'do' is
                        triggered

        do :            the function to execute on triggering, gets passed a 'game'
                        object

        ###
        @name = if @args.name? then @args.name else "annonymous"
        @_current_timer = undefined
        @_cleared = false


    listen: ( @game ) ->

        if not @args.do?
            return

        if @args.delay?

            trigger = =>
                @args.do game

            @_current_timer = setTimeout trigger, @args.delay + do @_variance

        else if @args.every?

            # Push out the first execution.
            @_current_timer = setTimeout @_repeat, @args.every + do @_variance

        else if @args.condition?

            do @_check_condition

        if @_current_timer?
            do @_current_timer.unref


    kill: () =>

        @_cleared = true
        clearTimeout @_current_timer


    _check_condition: () =>

        if @_cleared
            return

        if @args.condition @game
            @args.do @game

        else

            @_current_timer = setTimeout @_check_condition, LevelEvent.ConditionInterval
            do @_current_timer.unref


    _repeat: () =>

        if @_cleared
            return

        @args.do @game

        @_current_timer = setTimeout @_repeat, @args.every + do @_variance
        do @_current_timer.unref


    _variance: () =>

        if not @args.plusMinus?
            return 0

        up_or_down = -1 + 2 * do Math.random

        return @args.plusMinus * up_or_down


exports.LevelEvent = LevelEvent
