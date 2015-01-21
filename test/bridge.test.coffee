{BridgeSystem} = require '../trek/systems/BridgeSystems'


exports.BridgeSystemTest =

    'test can start system': ( test ) ->

        cb = ->
        s = new BridgeSystem 'Bridge', 'A', 23, cb

        do test.done