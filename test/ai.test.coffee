ai = require '../trek/AI'
{HuntingState, PatrollingState, HoldingState, BattleState} = require '../trek/ai/State.coffee'


# Mock game object
game = {
    get_startup_stats : () ->
        {
            ai_ships : [
                {
                    prefix : "0000",
                    name : "C'Tag",
                    star_system : 'Chin\'ta System',
                    weapons_targeting : { target : 'Enterprise' },
                    alignment : 'Klingon'
                }
            ]
        }

    get_internal_lifesigns_scan : () ->
        [
            { description : 'Repair Team', currently_repairing : undefined },
            { description : 'Repair Team', currently_repairing : "something" }
        ]

    get_damage_report : () ->
        [
            { name : "do-hikky", integrity : 0.1, repair_requirements : [
                { material : "unobtainium", quantity : 1 } ]
            }
        ]

    get_cargo_status : () ->
        {
            1 : [
                { unobtainium : 5 }
            ]
        }

    assign_repair_crews : ( prefix, system, crew_count, to_completion ) ->
        @repair =
            prefix : prefix
            system : system
            crew_count : crew_count
            to_completion : to_completion

    scan : ( prefix ) ->
        [
            { name : 'Enterprise',
              alignment : 'Federation',
              classification : 'Starship' }
        ]

}
prefix = "0000"


exports.HoldingTest =

    'test autorepairs': ( test ) ->

        ai_ = new ai.AI game, prefix
        do ai_.update
        test.ok game.repair?, "Never called repair crew command"
        test.ok game.repair.system is "do-hikky", "Failed to send order to repair do-hikky"
        do test.done


exports.BattleTest =

    'test initialization': ( test ) ->

        ai_ = new ai.AI game, prefix
        test.ok ai_.state_stack.push new BattleState

        do test.done


exports.PatrolTest =

    'test initialization': ( test ) ->

        ai_  = new ai.AI game, prefix
        test.ok ai_.state_stack.length > 0, "Failed to initialize with a state"
        test.ok ai_.current_state() is "Holding", "Failed to start in a holding state"
        test.ok ai_.ship_name is "C'Tag", "Failed to get the correct ship name: #{ ai_.ship_name }"
        do test.done


    'test the transition from hold to patrol': ( test ) ->

        ai_ = new ai.AI game, prefix
        ai_.receive_order 'Command to C\'Tag: your orders are to patrol the Ancara System, the Nedra System, and the K\'ta System'
        new_state = do ai_.current_state
        test.ok new_state is "Patrolling", "Failed to set the correct status: #{ new_state }"
        patrol_systems = ai_.state_stack[ 1 ].systems_to_patrol
        test.ok patrol_systems[ 0 ] is "Ancara", "Failed to set the correct patrol target: #{ patrol_systems[ 0 ] }"
        test.ok patrol_systems[ 1 ] is "Nedra", "Failed to set the second patrol target: #{ patrol_systems[ 1 ] }"
        test.ok patrol_systems[ 2 ] is "K'ta", "Failed to set the third patrol target: #{ patrol_systems[ 2 ] }"
        test.ok patrol_systems.length is 3, "Failed to identify mission patrol route"
        do test.done


    'test the transition from patroling to holding': ( test ) ->

        ai_ = new ai.AI game, prefix
        ai_.receive_order 'patrol the Chin\'ta System'
        new_state = do ai_.current_state
        test.ok new_state is "Patrolling", "Failed to set the initial state: #{ new_state }"
        ai_.receive_order 'hold position'
        new_state = do ai_.current_state
        test.ok new_state is "Holding", "Failed to revert to hold state: #{ new_state }"
        test.ok ai_.state_stack.length is 3, "Failed to set the expected number of states"
        do test.done


    'test system scanning': ( test ) ->

        ai_ = new ai.AI game, prefix
        # Ship is already in the Chin'ta System
        ai_.receive_order 'patrol the Chin\'ta System'
        test.ok false, "Finish this test"

        do test.done
