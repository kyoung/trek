Constants = require './Constants'
util = require 'util'


exports.warp_speed = ( w ) -> Constants.WARP_SPEED * Math.pow( w, 10/3 )


exports.distance = ( p1, p2, round=true ) ->

    if not p1? or not p1.x? or not p1.y? or not p1.x?
        throw new Error "p1 Not a valid position: #{ util.inspect p1 }"

    if not p2? or not p2.x? or not p2.y? or not p2.z?
        throw new Error "p2 Not a valid position: #{ util.inspect p2 }"

    if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z
        return 0

    d = Math.sqrt(
        Math.pow( ( p1.x - p2.x ), 2 ) +
        Math.pow( ( p1.y - p2.y ), 2 ) +
        Math.pow( ( p1.z - p2.z ), 2 ) )

    if round
        return Math.round d
    else
        return d


exports.distance_between = ( object1, object2 ) ->
    @distance object1.position, object2.position


exports.in_range = ( p1, p2, range ) -> @distance( p1, p2 ) < range


exports.bearing = ( you, them, accuracy=3 ) ->

    abs_bearing = @point_bearing you.position, them.position
    @abs2rel_bearing you, abs_bearing, accuracy


exports.abs2rel_bearing = ( you, abs_bearing, accuracy ) ->

    rel_bearing = abs_bearing.bearing - you.bearing.bearing

    if rel_bearing < 0
        rel_bearing += 1
    if rel_bearing >= 1
        rel_bearing -= 1

    mark = abs_bearing.mark

    r =
        bearing : Math.round( rel_bearing * Math.pow( 10, accuracy ) ) / Math.pow( 10, accuracy )
        mark : mark


exports.point_bearing = ( p1, p2 ) ->

    dx = p2.x - p1.x
    dy = p2.y - p1.y
    dz = p2.z - p1.z

    dxy = Math.sqrt( dx * dx + dy * dy )

    abs_bearing = Math.atan2( dy, dx ) / ( 2 * Math.PI )

    if abs_bearing >= 1
        abs_bearing -= 1

    if abs_bearing < 0
        abs_bearing += 1

    mark = Math.atan2( dz, dxy ) / ( 2 * Math.PI )

    if mark < 0
        mark += 1

    r =
        bearing: abs_bearing
        mark: mark


exports.abs_bearing = ( you, them ) -> @point_bearing you.position, them.position


exports.intercept = ( you, them, { impulse, warp } ) ->

    impulse = if isNaN( impulse ) then 0 else impulse
    warp = if isNaN( warp ) then 0 else warp

    velocity = @warp_speed( warp ) + ( impulse * Constants.IMPULSE_SPEED )

    delta_s =
        x : them.position.x - you.position.x
        y : them.position.y - you.position.y
        z : them.position.z - you.position.z

    a = Math.pow( them.velocity.x, 2 ) + Math.pow( them.velocity.y, 2 ) +
        Math.pow( them.velocity.z, 2 ) - Math.pow( velocity, 2 )
    b = 2 * ( them.velocity.x * delta_s.x + them.velocity.y * delta_s.y +
        them.velocity.z * delta_s.z )
    c = Math.pow( delta_s.x, 2 ) + Math.pow( delta_s.y, 2 ) +
        Math.pow( delta_s.z, 2 )
    p = -b / ( 2 * a )
    q = Math.sqrt( ( b * b ) - 4 * a * c ) / ( 2 * a )
    t1 = p - q
    t2 = p + q
    t = if t1 > t2 and t2 > 0 then t2 else t1
    i =
        x : them.position.x + them.velocity.x * t
        y : them.position.y + them.velocity.y * t
        z : them.position.z + them.velocity.z * t
    r =
        bearing : @bearing you, { position : i }, 9
        time : t
        final_position : i


exports.intercept_distance = ( you, them ) ->

    # NB. This doesn't work for 3D, but that's fine, since there's no
    # longer any interception functionality. We let the pilot do that.

    rel_velocity =
        x : them.velocity.x - you.velocity.x,
        y : them.velocity.y - you.velocity.y,
        z : them.velocity.z - you.velocity.z

    rel_position =
        x : them.position.x - you.position.x,
        y : them.position.y - you.position.y,
        z : them.position.z - you.position.z

    target_slope = rel_velocity.y / rel_velocity.x
    intercept_slope = -1 / target_slope
    x_intercept = ( rel_position.y - target_slope * rel_position.x ) / ( intercept_slope - target_slope )
    y_intercept = intercept_slope * x_intercept
    distance = Math.round( Math.sqrt( Math.pow( x_intercept, 2 ) +
        Math.pow( y_intercept, 2 ) ) ) + 1


exports.isNumber = ( n ) ->
    !isNaN( parseFloat( n ) ) && isFinite( n )


exports.atoi = ( n ) ->
    parseFloat n, 10


exports.round = ( n, digit ) ->
    Math.floor( n * Math.pow( 10, digit ) ) / Math.pow( 10, digit )


exports.round_up = ( n, digit ) ->
    Math.ceil( n * Math.pow( 10, digit ) ) / Math.pow( 10, digit )


exports.norm_bearing = ( bearing ) ->

    if bearing < 0
        bearing += 100
    bearing % 1


exports.stardate = ->

    d = new Date()
    sd = 8500 + d.getYear() + d.getMonth() + d.getDay() / 100


exports.UID = ->

    v = Math.round( Math.random() * 10e16 ).toString( 16 ) +
            Math.round( Math.random() * 10e16 ).toString( 16 )


exports.shuffle = ( array ) ->

    i = array.length

    while --i > 0
        j = ~~( Math.random() * ( i + 1 ) )
        t = array[ j ]
        array[ j ] = array[ i ]
        array[ i ] = t
    array


exports.scalar_from_bearing = ( bearing, mark ) ->

    b = bearing * Math.PI * 2
    m = mark * Math.PI * 2

    z_vector = Math.sin m
    xy_vector = Math.cos m
    x_vector = xy_vector * Math.cos b
    y_vector = xy_vector * Math.sin b

    scalar =
        x : x_vector
        y : y_vector
        z : z_vector


exports.up_to = ( n ) ->
    Math.floor Math.random() * n
