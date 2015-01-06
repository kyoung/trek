util = require 'util'
Utility = require '../trek/Utility'

exports.UtilityTest =

    'test Distance calculations': ( test ) ->
        p1 =
            x: 1
            y: 1
            z: 1
        p2 =
            x: 1
            y: 1
            z: 1
        test.ok Utility.distance(p1, p2) == 0, "Utility fails to recognizes 0 distance"
        do test.done

    'test absolute bearing': ( test ) ->
        p1 =
            x: 0
            y: 0
            z: 0
        p2 =
            x: 1
            y: 1
            z: 0
        abs_bearing = Utility.point_bearing p1, p2
        test.ok abs_bearing.bearing == 0.125, "Failed to calculate
        correct absolute bearing: #{abs_bearing}"
        do test.done

    'test relative bearing': ( test ) ->
        p1 =
            x: 0
            y: 0
            z: 0
        p2 =
            x: 1
            y: 1
            z: 0
        bearing = {bearing: 0.25, mark: 0}
        you =
            position: p1
            bearing: bearing
        them =
            position: p2
        rel_bearing = Utility.bearing you, them
        test.ok rel_bearing.bearing == 0.875, "Failed to calculate correct
        relative bearing: #{rel_bearing.bearing}"
        do test.done