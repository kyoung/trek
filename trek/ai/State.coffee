###
HOLDING
PATROLING
HUNTING
FIGHTING
EVADING
RETREATING
MOVING
DEFENDING
###

class AIState

    entry: () ->

    exit: () ->

    # receive_order handles pushed messages, as strings, and changes state
    # accordingly
    receive_order: ( ai, order ) ->

    # update is called on every update "frame" and is where the base behaviours
    # are expressed
    update: ( ai, game ) ->


class HoldingState extends AIState

    constructor: () ->

        @state_name = 'Holding'


    receive_order: ( ai, order ) ->

        patrol_re = /(P|p)atrol (the |)/
        if patrol_re.test order
            new_state = new PatrollingState order
            return new_state


    update: ( ai, game ) ->
        # Check for damaged systems and assign repair crews


class PatrollingState extends AIState

    # PatrollingState expects an order in the form of
    # ...patrol the [name] system, the [name] system, and the [name] system
    constructor: ( patrol_order, @continuous=true ) ->

        system_re = /the ([\w\-\']*) system/i
        system_strings = patrol_order.split ','

        @systems_to_patrol = for order_string in system_strings
            match = system_re.exec order_string
            match[1]

        @state_name = 'Patrolling'


    receive_order: ( ai, order ) ->

        hold_re = /hold position/i
        if hold_re.test order
            new_state = new HoldingState()
            return new_state

    # Activities when Patrolling:
    # Move to the system, fly around, and attack any unaligned ships
    # If not continuous, return to base
    update: ( ai, game ) ->


class HuntingState extends AIState

    # HuntingState expects to be initialized with a target_name and a system to
    # look in, so that it may set course.
    constructor: ( target_name, system ) ->


    # Activities when hunting:
    # Look for the target, if not found, proceed to system.
    # If in system, look around system for target.
    # If target found, begin attack.
    update: ( ai, game ) ->


exports.HuntingState = HuntingState
exports.PatrollingState = PatrollingState
exports.HoldingState = HoldingState
