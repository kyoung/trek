{BaseObject} = require './BaseObject'
Constants = require './Constants'
Utility = require './Utility'


class Torpedo extends BaseObject

    @MAX_DAMAGE = 1.5e9

    constructor: ( @target, yield_level ) ->

        @yield_level = parseInt yield_level

        if ( @target.position is undefined or @target.velocity is undefined )
            throw new Error "Torpedo fired without a target"

        if @yield_level not in [ 0...17 ]
            throw new Error "Torpedo fired with illegal yield: #{ yield_level }"

        super()
        @yield = Math.pow( 2, @yield_level ) / Math.pow( 2, 16 )
        @warp = 0
        @armed = false
        @impulse = 0
        @state_stamp = new Date().getTime()
        @bearing = Utility.abs_bearing @, @target
        @fire_interval = null
        @detonation_callback = ->
        @_two_second_callback = ->
        @last_distance = null
        @alive = true
        @name = "Torpedo " + @get_serial_number()


    get_serial_number: ->
        Math.round( Math.random() * 10e8 ).toString( 16 )


    self_destruct: =>

        clearTimeout @_timeout
        @detonate


    detonate: =>

        console.log "[TORPEDO] Detonation!"
        clearInterval @fire_interval
        if not @armed
            console.log "[TORPEDO] Not armed :-("
            return
        @alive = false

        # Probably a station or something
        if not @target.navigation_log?
            @detonation_callback @target.position, @yield * Torpedo.MAX_DAMAGE
            return

        [..., last_target_nav] = @target.navigation_log
        if last_target_nav == @_last_target_navigation
            # Assume we'll hit, 100m from position
            d_y = @target.position.y - @position.y
            d_x = @target.position.x - @position.x
            d_hyp = Math.sqrt( Math.pow( d_y, 2 ) + Math.pow( d_x, 2 ) )
            hyp_ratio = d_hyp / 500
            d_y /= hyp_ratio
            d_x /= hyp_ratio
            det_position =
                x: @target.position.z - d_x
                y: @target.position.y - d_y
                z: @target.position.z
            @detonation_callback det_position, @yield * Torpedo.MAX_DAMAGE
            return

        @detonation_callback @_detonation_position, @yield * Torpedo.MAX_DAMAGE


    fire_at_warp: ( warp_speed ) =>

        if not warp_speed > 0
            throw new Error("Illegal Warp Speed Set")
        @warp = warp_speed
        @fire({warp: @warp})


    fire_at_impulse: ( impulse_speed ) =>

        @impulse = impulse_speed * 1.75
        @fire({impulse: @impulse})


    fire: ( { impulse, warp } ) ->

        impulse = if isNaN( impulse ) then 0 else impulse
        warp = if isNaN( warp ) then 0 else warp

        @last_distance = Utility.distance_between @, @target
        { bearing, time, final_position } = Utility.intercept( @, @target, { impulse : impulse, warp : warp } )
        @set_bearing bearing.bearing, bearing.mark
        @set_velocity()
        @_detonation_position = final_position
        if @target.navigation_log?
            [..., @_last_target_navigation] = @target.navigation_log
        setTimeout @_two_second_warning, time - 2000
        @_timeout = setTimeout @detonate, time


    set_bearing: ( bearing, mark ) =>

        @bearing.bearing += bearing
        if @bearing.bearing >= 1
            @bearing.bearing -= 1
        if @bearing.bearing < 0
            @bearing.bearing += 1

        @bearing.mark = mark


    set_velocity: =>

        v = 0
        if @warp > 0
            v = Utility.warp_speed( @warp ) + Constants.IMPULSE_SPEED / 4
        else
            v = Constants.IMPULSE_SPEED * @impulse

        if v == 0
            throw new Error "Velocity error: warp #{ @warp } impulse #{ @impulse }"

        rotation = @bearing.bearing * Math.PI * 2

        vectors = Utilty.scalar_from_bearing @bearing.bearing, @bearing.mark

        @velocity.x = vectors.x * v
        @velocity.y = vectors.y * v
        @velocity.z = vectors.z * v


    calculate_state: ( _, delta ) =>

        now = do Date.now
        if not delta?
            delta = now - @state_stamp

        @state_stamp = now
        @calculate_motion delta


    calculate_motion: ( delta_t ) =>

        @position.x += @velocity.x * delta_t
        @position.y += @velocity.y * delta_t
        @position.z += @velocity.z * delta_t


    process_blast_damage: ( position, power, message_callback ) ->
        # unaffected by blast damage...


    _two_second_warning: =>

        # Probably a station or something
        if not @target.navigation_log?
            @_two_second_callback @target.name
            return

        [..., last_target_nav] = @target.navigation_log
        if last_target_nav == @_last_target_navigation
            # Assume we'll hit
            @_two_second_callback @target.name


exports.Torpedo = Torpedo
