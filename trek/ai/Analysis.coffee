C = require '../Constants'


identify_unexpected_readings = ( readings, charted_objects, reference_bearing ) ->
    # Return anomalies in the format:
    # [ { range: "long", type: "EM Field", bearing: 0.430 } ]

select_appropriate_speed = ( distance ) ->
    # Returns a recommended speed to close a distance
    # { scale : ['warp', 'impulse'], value : [0.2, 6 etc] }
    # TODO: Abstract this into a formula
    AUs = distance / C.AU

    switch
        when AUs < 0.00001 then { scale : 'impulse', value : 0.001 }
        when AUs < 0.0001 then { scale : 'impulse', value : 0.001 }
        when AUs < 0.001 then { scale : 'impulse', value : 0.05 }
        when AUs < 0.01 then { scale : 'impulse', value : 0.05 }
        when AUs < 0.03 then { scale : 'impulse', value : 0.3 }
        when AUs < 0.05 then { scale : 'impulse', value : 0.5 }
        when AUs < 0.2 then { scale : 'impulse', value : 1 }
        when AUs < 1 then { scale : 'warp', value : 2 }
        when AUs < 2 then { scale : 'warp', value : 3 }
        when AUs < 5 then { scale : 'warp', value : 4 }
        when AUs < 20 then { scale : 'warp', value : 5 }
        else { scale : 'warp', value : 6 }


exports.identify_unexpected_readings = identify_unexpected_readings
exports.select_appropriate_speed = select_appropriate_speed
