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
        test.ok abs_bearing.bearing == 0.125, "Failed to calculate correct absolute bearing: #{ abs_bearing.bearing }"

        p3 =
            x : 1
            y : 0
            z : -1

        p4 =
            x : 1
            y : 0
            z : 1

        abs_bearing_2 = Utility.point_bearing p1, p3
        abs_bearing_3 = Utility.point_bearing p1, p4
        test.ok abs_bearing_2.mark == 0.875, "Failed to calculate a correct absolute downward mark: #{ abs_bearing_2.mark }"
        test.ok abs_bearing_3.mark == 0.125, "Failed to calculate a correct absolute upward mark: #{ abs_bearing_3.mark }"

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


    'test scalars': ( test ) ->

        bearing = 0
        mark = 0

        are_close = ( n, to ) -> Math.abs( n - to ) < 0.00001

        # Straight_ahead
        {x, y, z} = Utility.scalar_from_bearing 0, 0
        test.ok are_close( x, 1 ) and are_close( y, 0 ) and are_close( z, 0 ), "Failed to set fwd scalar #{ x }, #{ y }, #{ z }"

        # Left
        {x, y, z} = Utility.scalar_from_bearing .25, 0
        test.ok are_close( x, 0 ) and are_close( y, 1 ) and are_close( z, 0 ), "Failed to set left scalar #{ x }, #{ y }, #{ z }"

        # Back
        {x, y, z} = Utility.scalar_from_bearing .5, 0
        test.ok are_close( x, -1 ) and are_close( y, 0 ) and are_close( z, 0 ), "Failed to set backward scalar #{ x }, #{ y }, #{ z }"

        # Right
        {x, y, z} = Utility.scalar_from_bearing .75, 0
        test.ok are_close( x, 0 ) and are_close( y, -1 ) and are_close( z, 0 ), "Failed to set right scalar #{ x }, #{ y }, #{ z }"

        # Up
        {x, y, z} = Utility.scalar_from_bearing 0, .25
        test.ok are_close( x, 0 ) and are_close( y, 0 ) and are_close( z, 1 ), "Failed to set upward scalar #{ x }, #{ y }, #{ z }"

        #Down
        {x, y, z} = Utility.scalar_from_bearing 0, .75
        test.ok are_close( x, 0 ) and are_close( y, 0 ) and are_close( z, -1 ), "Failed to set downward scalar #{ x }, #{ y }, #{ z }"

        do test.done
