{BaseObject} = require './BaseObject'
{SensorSystem, LongRangeSensorSystem} = require './systems/SensorSystems'


C = require './Constants'

up_to = (n) ->
    n * do Math.random

# Possible classifications:
#  star:[CLASS]
#  singularity
#  annomaly
#  planetoid
#  planet:[CLASS]
#  asteroid
#  comet
#  gas

class CelestialObject extends BaseObject


    constructor: ->

        super()
        @charted = false
        @classification = ""
        @name = ""


    scan_for: ( type ) ->

        if @_scan_density[ type ]?
            return @_scan_density[ type ]

        return false


    block_for: ( type ) -> false


    get_detail_scan: ->

        r =
            classification: @classification
            name: @name


    process_blast_damage: ( position, power, message_callback ) -> @alive = true


    quick_fits: ( p ) ->

        # fast method for finding if point is withing self
        false


class Star extends CelestialObject

    constructor: ( name, star_class, @radiation_output ) ->

        super()
        @charted = true
        @classification = "#{star_class} Class Star"
        # Set name this way because super overrides it
        @name = name
        @_scan_density = {}
        @_scan_density[ LongRangeSensorSystem.SCANS.GRAVIMETRIC ] = up_to 3e8
        @_scan_density[ LongRangeSensorSystem.SCANS.GAMMA_SCAN ] = up_to 1000
        @_scan_density[ LongRangeSensorSystem.SCANS.EM_SCAN ] = up_to 400
        @_scan_density[ SensorSystem.SCANS.WIDE_EM ] = up_to 300

        # Stars blind you
        @_scan_density[ SensorSystem.SCANS.HIGHRES ] = up_to 2e8
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES ] = up_to 1e8
        @_scan_density[ SensorSystem.SCANS.MAGNETON ] = up_to 20
        @_scan_density[ SensorSystem.SCANS.MULTIPHASIC ] = up_to 800

        @model_url = "star_tau.json"
        @model_display_scale = 0.5


    block_for: ( type ) ->

        blocks = [
            SensorSystem.SCANS.HIGHRES
            SensorSystem.SCANS.P_HIGHRES
            SensorSystem.SCANS.WIDE_EM
        ]
        if type in blocks
            return true
        return false


    get_detail_scan: ->

        random_energy = -> ( Math.random() for i in [ 0...10 ] )

        r =
            classification : @classification
            name : @name
            mesh : @model_url
            mesh_scale : @model_display_scale
            radiation_output : @radiation_output
            radiation_safe_distance : 20 * C.AU
            power_readings : [
                do random_energy,
                do random_energy,
                do random_energy,
                do random_energy,
                do random_energy,
                do random_energy,
                do random_energy
            ]


class GasCloud extends CelestialObject
    # Assumed to block sensors

    constructor: ( @radius, @thickness ) ->

        super()
        @classification = "Plasma Cloud"

        @density = up_to 1

        @_scan_density = {}
        @_scan_density[SensorSystem.SCANS.HIGHRES] = up_to 20
        @_scan_density[SensorSystem.SCANS.P_HIGHRES] = up_to 20
        @_scan_density[SensorSystem.SCANS.WIDE_EM] = up_to 100
        @_scan_density[SensorSystem.SCANS.MAGNETON] = up_to 30
        @_scan_density[LongRangeSensorSystem.SCANS.EM_SCAN] = up_to 100
        @_scan_density[LongRangeSensorSystem.SCANS.GAMMA_SCAN] = up_to 100



    scan_for: ( type ) ->

        if @_scan_density[type]?
            return @_scan_density[type]

        return false


    block_for: ( type ) ->

        blocks = [
            SensorSystem.SCANS.HIGHRES
            SensorSystem.SCANS.P_HIGHRES
            SensorSystem.SCANS.WIDE_EM
        ]

        if type in blocks
            return true
        return false


    get_detail_scan: ->

        r =
            classification: @classification
            name: @name
            radius: @radius
            thickness: @thickness


    quick_fits: ( p ) ->

        in_x = @position.x - @radius < p.x < @position.x + @radius
        in_y = @position.y - @radius < p.y < @position.y + @radius

        # skip z check for now... we can more efficiently handle that in the game

        in_x and in_y


exports.CelestialObject = CelestialObject
exports.Star = Star
exports.GasCloud = GasCloud
