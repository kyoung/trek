###
TODO:

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


    # Check for damaged systems and assign repair crews
    update: ( ai, game ) ->

        repair_teams = ( team for team in game.get_internal_lifesigns_scan( ai.prefix ) when ( team.description is "Repair Team" and not team.currently_repairing? ) )
        if repair_teams.length is 0
            return

        damaged_systems = game.get_damage_report ai.prefix # [ {name:, integrity:, repair_requirements:, } ]
        if damaged_systems.length is 0
            return

        resources = game.get_cargo_status ai.prefix # { 1 : [{item : qty}] }
        inventory = {}
        for bay in resources
            for item, qty of bay
                if inventory[ item ]?
                    inventory[ item ] += qty
                else
                    inventory[ item ] = qty

        can_fix = ( system, resources ) ->
            for material, qty of system.repair_requirements
                if resources[ material ] < qty
                    return false
            return true

        possible_to_fix_systems = ( sys for sys in damaged_systems when can_fix sys, inventory )

        # find the most damaged system which we have the materials to repair
        most_damaged_system = undefined
        for sys in damaged_systems
            if not most_damaged_system?
                most_damaged_system = sys
                continue
            if sys.integrity < most_damaged_system.integrity
                most_damaged_system = sys

        if not most_damaged_system?
            return

        to_completion = most_damaged_system.operability is "Operable"
        game.assign_repair_crews ai.prefix, most_damaged_system.name, 1, to_completion


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
