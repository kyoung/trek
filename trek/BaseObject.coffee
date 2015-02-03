class BaseObject

    constructor: ->

        @position = { x : 0, y : 0, z : 0 }
        @velocity = { x : 0, y : 0, z : 0 }
        @bearing = { bearing : 0, mark : 0 }
        @bearing_v = { bearing : 0, mark : 0 }
        @warp_speed = 0
        @impulse = 0
        @alive = true

        @model_url = ""
        @classification = ""
        @_scan_density = {}
        @sensor_tag = Math.round( Math.random() * 10e16 ).toString( 16 ) +
            Math.round( Math.random() * 10e16 ).toString( 16 )


    process_torpedo_damage: ( from_point, damage ) -> console.log "HIT! Total damage: #{damage}"


    process_phaser_damage: ( from_point, damage ) -> console.log "HIT! Total damage: #{damage}"


    process_blast_damage: ( position, power, message_callback ) ->

        # I'll kill you by default! Override!
        @alive = false


    set_position: ( x, y=0, z=0 ) -> @position = {x:x, y:y, z:z}


    calculate_state: ->


    transportable: -> false


    scan_for: ( type ) ->

        if @_scan_density[type]?
            return @_scan_density[type]
        return false


    block_for: ( type ) ->

        # Does this object block this type of scan
        return false


    set_environmental_conditions: ( @environmental_conditions ) ->


root = exports ? window
root.BaseObject = BaseObject
