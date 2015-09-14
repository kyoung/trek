Analysis = require './Analysis'

C = require '../Constants'
U = require '../Utility'

###
TODO:

FIGHTING
EVADING
RETREATING
MOVING
DEFENDING
###

class AIState

    constructor: ->

        @state_name = 'BaseState'

    # receive_order handles pushed messages, as strings, and changes state
    # accordingly. A new state (or states) returned pushes onto the stack;
    # otherwise this state may terminate itself by poping the ai object's state
    # stack.
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


class MovingToPointState extends AIState

    # Moving to Point expects a coordinate { x : , y : , z : }
    constructor: ( @move_to_point ) ->

        @state_name = 'Moving'

        @substates =
            TURNING : 'Turning'
            CLOSING : 'Closing'
            ARRIVED : 'Arrived'

        @substate = @substates.TURNING
        @overshot_speed = ""


    update: ( ai, game ) ->

        console.log "   >>> AI substate #{ @substate }"

        switch @substate
            when @substates.TURNING then @turn ai, game
            when @substates.CLOSING then @close ai, game
            when @substates.ARRIVED then do ai.current_state_complete


    turn: ( ai, game ) ->

        ship = game.ai_ships[ ai.prefix ]
        abs_bearing = U.point_bearing ship.position, @move_to_point
        rel_bearing = U.abs2rel_bearing ship, abs_bearing, 3

        if rel_bearing.bearing > 0.99 or rel_bearing.bearing < 0.01
            console.log "    >>> >>> AI rel bearing: #{ rel_bearing.bearing }"
            @substate = @substates.CLOSING
        else
            game.set_course ai.prefix, rel_bearing.bearing, rel_bearing.mark


    close: ( ai, game ) ->

        ship = game.ai_ships[ ai.prefix ]
        distance = U.distance ship.position, @move_to_point
        abs_bearing = U.point_bearing ship.position, @move_to_point
        rel_bearing = U.abs2rel_bearing ship, abs_bearing, 3

        # am I misaligned?
        if 0.1 < rel_bearing.bearing < 0.9
            game.set_impulse_speed ai.prefix, 0
            @substate = @substates.TURNING
            return

        tactical_report = do ship.tactical_report
        if distance < tactical_report.phaser_range
            console.log "    >>> AI: As close as needed"
            # we're there; begin attack
            @substate = @substates.ARRIVED
            game.set_impulse_speed ai.prefix, 0
            return

        recommended_speed = Analysis.select_appropriate_speed distance
        current_speed = game.get_position ai.prefix
        console.log "    >>> AI: target ahead, setting speed #{ recommended_speed.scale } #{ recommended_speed.value }"
        if ship.pretty_print_speed() == @overshot_speed
            recommended_speed.value /= 2
            console.log "    >>> AI: trimming speed from overshot"
        switch recommended_speed.scale
            when 'warp'
                if current_speed.warp != recommended_speed.value
                    game.set_warp_speed ai.prefix, recommended_speed.value
            when 'impulse'
                if current_speed.impulse != recommended_speed.value
                    game.set_impulse_speed ai.prefix, recommended_speed.value


class PatrollingState extends AIState

    # PatrollingState expects an order in the form of
    # ...patrol the [name] system, the [name] system, and the [name] system
    constructor: ( patrol_order, @continuous=true ) ->

        system_re = /the ([\w\-\']*) system/i
        system_strings = patrol_order.split ','

        @systems_to_patrol = for order_string in system_strings
            match = system_re.exec order_string
            match[1]
        # The system to visit in this tour
        @systems_to_visit = ( s for s in @systems_to_patrol )
        @systems_visited = []

        @state_name = 'Patrolling'


    receive_order: ( ai, order ) ->

        hold_re = /hold position/i
        if hold_re.test order
            new_state = new HoldingState()
            return new_state


    # Activities when Patrolling:
    # Move to the next system,
    # Scan the system for EM and Subspace
    # Approach anything uncharted
    # Attack any hostiles
    # If not continuous, return to base
    update: ( ai, game ) ->

        ship = game.ai_ships[ ai.prefix ]

        # Tell the AI to go to the system, when it's done it will pop off and we
        # can resume the scan
        if ship.star_system? or not ship.star_system in @systems_to_visit
            return new MoveToSystemState @systems_to_visit[ 0 ]

        # Arrived in the next system
        if ship.star_system? is @systems_to_visit[ 0 ] and not ship.star_system in @systems_visited
            # Check if we've completed a scan of the system
            last_log = ship.sensor_log.retrieve -1
            if last_log.text is ship.star_system
                # If anything is out of the ordinary, investigate
                charts = game.get_charted_objects ai.prefix, ship.star_system
                anomalies = Analysis.identify_unexpected_readings(
                    last_log.data,
                    charts,
                    ship.bearing )
                if anomalies.length > 0
                    return new InvestigateCourseState anomalies[ 0 ]

                # Otherwise, time to leave
                @systems_visited.push do @systems_to_visit.pop
                return

            # Yes, strings are bad, but to avoid the circular dependency
            # non-sense, let's just leave it and see what happens
            return new SystemScannningState [], [ "EM Field Scan", "Subspace Field Stressor Scan" ]

        if @systems_to_patrol.length is @systems_visited.length and not @continuous
            # We're done! return to base, or hold position, or whatever
            do ai.state_stack.pop
            return


class InvestigateCourseState extends AIState

    # InvestigateCourseState sets a course for the anomaly while continuously
    # scanning to ensure it doesn't pass the origin. When within range of the
    # passive SR detection grid, scans for origin.
    # If none found, pop state.
    constructor: ( @anomaly ) ->

        @range = @anomaly.range
        @type = @anomaly.type
        @initial_bearing = @anomaly.bearing
        @state_name = 'Investigating'


    update: ( ai, game ) ->
        # set cource to match the bearing
        # set a slow speed; we need to run SR passive highres scans
        # re-reader the range/type to make sure it's still in front us


class SystemScannningState extends AIState

    # ScannningState scans the current system for the passed in fields
    constructor: ( @sr_fields_to_scan, @lr_fields_to_scan ) ->

        @state_name = 'Scanning System'

        # Substates are used as a soft internal state-machine for time-consuming
        # activities.
        @substates =
            TURNING: 'Turning'
            SCANING: 'Scanning'

    receive_order: ( ai, order ) ->

    # Scan the system for the fields provided
    update: ( ai, game ) ->

        switch @substate
            when @substates.TURNING
                return @turning ai, game
            when @substates.SCANING
                return @scanning ai, game


        # Orient the long range sensors at the system's interior
        # Configure the sensors for an in-system scan (for LR sensors)
        # Scan for the given fields
        # Compare against the expected charted data
        # Enter a log in the ship's sensor_log
        # # Text: system_name
        # # Data:
        # # {
        # #   EM Field (bucket and reading): { 2 : 20, 3 : 1 },
        # #   Subspace : { 1 : 0 }
        # # }

    turning: ( ai, game ) ->


    scanning: ( ai, game ) ->


class BattleState extends AIState

    # BattleState is used for AI combat
    constructor: () ->

        @state_name = 'Battle'

        @target_name

        @substates =
            CLOSING: 'Closing'
            ATTACKING: 'Attacking'
            EVADING: 'Evading'
            TARGETING: 'Targeting'

        @substate = @substates.TARGETING

        @overshot_speed = ''


    receive_order: ( ai, order ) ->


    update: ( ai, game ) ->

        # ensure we're at Red Alert
        if game.get_alert( ai.prefix ) isnt 'red'
            game.set_alert ai.prefix, 'red'

        # Is target destroyed? pop state

        ship = game.ai_ships[ ai.prefix ]
        switch @substate
            when @substates.CLOSING then @close ai, game
            when @substates.ATTACKING then @attack ai, game
            when @substates.EVADING then @evade ai, game
            when @substates.TARGETING then @target ai, game


    target: ( ai, game ) ->

        # console.log ">>> AI: targetting"

        self = game.ai_ships[ ai.prefix ]

        ships_in_area = ( t for t in game.scan( ai.prefix ) when /starship|space station/i.test( t.classification ) )

        friendly_alignments = [ self.alignment ]
        if not ai.is_agro
            friendly_alignments.push C.ALIGNMENT.NEUTRAL
        hostiles_in_area = ( t for t in ships_in_area when t.alignment not in friendly_alignments )

        if not hostiles_in_area.length
            # nothing to target, exit battle state
            # do ai.state_stack.pop
            return

        # find the closest target
        closest_target = hostiles_in_area[0]
        for h in hostiles_in_area
            if h.distance < closest_target.distance
                closest_target = h

        @target_name = closest_target.name
        game.target ai.prefix, closest_target.name
        @substate = @substates.CLOSING

        return


    close: ( ai, game ) ->

        # what is the bearing to the target?
        i = game.scan ai.prefix
        targets = ( t for t in i when t.name is @target_name )
        if targets.length <= 0
            # identified target is not in area... retarget
            game.set_impulse_speed ai.prefix, 0  # halt
            @substate = @substates.TARGETING
            return
        target = targets[ 0 ]

        console.log ">>> AI: closing on target #{ target.distance / C.AU } AU"

        ship = game.ai_ships[ ai.prefix ]
        tactical_report = do ship.tactical_report

        if target.distance < tactical_report.torpedo_range
            console.log "    >>> AI: closing on target: Firing torpedoes"
            # fire torpedoes as we close
            game.fire_torpedo ai.prefix, 12

        if target.distance < tactical_report.phaser_range
            console.log "    >>> AI: beginning phaser attack"
            # we're there; begin attack
            @substate = @substates.ATTACKING
            game.set_impulse_speed ai.prefix, 0
            return

        if ( 0.9 <  target.bearing.bearing ) or ( target.bearing.bearing < 0.1 )
            # approch
            recommended_speed = Analysis.select_appropriate_speed target.distance
            current_speed = game.get_position ai.prefix
            console.log "    >>> AI: target ahead, setting speed #{ recommended_speed.scale } #{ recommended_speed.value }"
            if ship.pretty_print_speed() == @overshot_speed
                recommended_speed.value /= 2
                console.log "    >>> AI: trimming speed from overshot"
            switch recommended_speed.scale
                when 'warp'
                    if current_speed.warp != recommended_speed.value
                        game.set_warp_speed ai.prefix, recommended_speed.value
                when 'impulse'
                    if current_speed.impulse != recommended_speed.value
                        game.set_impulse_speed ai.prefix, recommended_speed.value
        else
            console.log "    >>> AI: turning for target"
            console.log "    >>> >>> #{ @overshot_speed }"
            console.log "    >>> >>> #{ do ship.pretty_print_speed }"
            if target.distance / C.AU <  1
                @overshot_speed = do ship.pretty_print_speed
            game.set_course ai.prefix, target.bearing.bearing, target.bearing.mark

        return


    attack: ( ai, game ) ->

        # console.log ">>> AI: Attacking"

        i = game.scan ai.prefix
        targets = ( t for t in i when t.name is @target_name )
        if targets.length == 0
            # lost target
            @substate = @substates.TARGETING
            return
        target = targets[ 0 ]

        # if target is out of range, switch to closing
        ship = game.ai_ships[ ai.prefix ]
        tactical_report = do ship.tactical_report

        if do ship.is_cloaked
            do ship.decloak

            # magic handy wavy compensation
            do ship._power_shields
            do ship._power_phasers
            do ship._auto_load_torpedoes

        if target.distance > tactical_report.phaser_range
            @substate = @substates.CLOSING
            return

        # if target is ahead, fire
        if ( 0.75 < target.bearing.bearing ) or ( target.bearing.bearing < 0.25 )
            phaser_stats = game.get_phaser_status ai.prefix
            for p in phaser_stats
                if ( p.targetting is 'Forward' ) and p.charge > 0.8
                    game.fire_phasers ai.prefix, 0.8
                    console.log "    >>> firing #{ p.name }"
                else
                    # console.log "    >>> charging #{ p.name }"

            # Torpedoes?

        else
            game.set_course ai.prefix, target.bearing.bearing, target.bearing.mark

        return


    evade: ( ai, game ) ->

        # soooo... when do we evade?


class TurningState extends AIState

    # TurningState is used to set course and rotate by X
    constructor: ( @bearing, @mark ) ->

        @state_name = 'Turning'


    update: ( ai, game ) ->


class MoveToSystemState extends AIState

    # MoveToSystemState gets us from wherever we are to the destination system,
    # and then removes itself from the ai's stack.
    constructor: ( @destination_system ) ->

        @state_name = 'MovingToSystem'


    receive_order: ( ai, order ) ->

    update: ( ai, order ) ->


class HuntingState extends AIState

    # HuntingState expects to be initialized with a target_name and a system to
    # look in, so that it may set course.
    constructor: ( target_name, system ) ->

        @state_name = 'Hunting'


    # Activities when hunting:
    # Look for the target, if not found, proceed to system.
    # If in system, look around system for target.
    # If target found, begin attack.
    update: ( ai, game ) ->


exports.AIState = AIState
exports.HuntingState = HuntingState
exports.PatrollingState = PatrollingState
exports.HoldingState = HoldingState
exports.BattleState = BattleState
exports.MovingToPointState = MovingToPointState
