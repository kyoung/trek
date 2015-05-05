Analysis = require '../trek/ai/Analysis'

C = require '../trek/Constants'

exports.AnalysisTest =

    'test can guess velocities': ( test ) ->

        x = Analysis.select_appropriate_speed( 30 * C.AU )
        test.ok x.scale is 'warp' and x.value is 6, "Failed to set a high-speed warp value"

        do test.done
