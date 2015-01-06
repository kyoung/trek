{Torpedo} = require '../trek/Torpedo'
{BaseObject} = require '../trek/BaseObject'
{Ship} = require '../trek/Ship'

exports.TorpedoTest =

    'test can instantiate with target': ( test ) ->

        target = new Ship "Reliant", 27012
        target.set_position 0, 1e8
        t = new Torpedo target, '16'
        test.equal t.bearing.bearing, 0.25, 'Expected target bearing was wrong'

        do test.done


    'test can fire at impulse': ( test ) ->

        target = new Ship "Reliant", 27012
        target.set_position 1e8, 1e8
        target.set_warp 1
        torpedo = new Torpedo target, '16'
        torpedo.armed = true
        torpedo.fire_at_warp 1
        do torpedo.self_destruct

        do test.done


    'test can fire at warp': ( test ) ->

        target = new Ship "Reliant", 27012
        target.set_position 1e8, 1e8
        torpedo = new Torpedo target, '16'
        torpedo.armed = true
        torpedo.fire_at_impulse 1
        do torpedo.self_destruct

        do test.done
