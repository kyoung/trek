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

        if @_scan_density[type]?
            return @_scan_density[type]

        return false


    block_for: ( type ) -> false

    get_detail_scan: ->

        r =
            classification: @classification
            name: @name


    process_blast_damage: ( position, power, message_callback ) -> @alive = true


class Star extends CelestialObject

    constructor: ( name, star_class ) ->

        super()
        @charted = true
        @classification = "star:#{star_class}"
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


    block_for: ( type ) ->

        blocks = [
            SensorSystem.SCANS.HIGHRES
            SensorSystem.SCANS.P_HIGHRES
            SensorSystem.SCANS.WIDE_EM
        ]
        if type in blocks
            return true
        return false


class GasCloud extends CelestialObject
    # Assumed to block sensors

    constructor: ( @radius, @thickness ) ->

        super()
        @classification = "Plasma Cloud"
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


exports.CelestialObject = CelestialObject
exports.Star = Star
exports.GasCloud = GasCloud