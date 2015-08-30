{BaseObject} = require './BaseObject'
{SensorSystem, LongRangeSensorSystem} = require './systems/SensorSystems'


C = require './Constants'

up_to = (n) ->
    n * do Math.random

between = (a, b) ->
    a + ( ( b - a ) * do Math.random )

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


class Lagrange extends CelestialObject


    constructor: ( @planet, @lagrange_position ) ->

        super()
        @charted = true
        @name = "#{ @planet.name } L #{ @lagrange_position }"
        @classification = "Lagrange Point"
        @_scan_density = {}
        @_scan_density[ SensorSystem.SCANS.HIGHRES ] = up_to 2e2
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES ] = up_to 1e2
        @_scan_density[ SensorSystem.SCANS.MAGNETON ] = up_to 20
        @_scan_density[ LongRangeSensorSystem.SCANS.GRAVIMETRIC ] = up_to 0.5

        @model_url = "lagrange.json"
        @model_display_scale = 0.5

        # lagranges are set pi/3 radians ahead and behind the planet
        rotation = switch @lagrange_position
            when 3
                @planet.rotation - Math.PI/3
            when 4
                @planet.rotation + Math.PI/3
            else
                throw new Error "#{ @lagrange_position } is an unsupported lagrange point"
        x = @planet.orbit * Math.cos rotation
        y = @planet.orbit * Math.sin rotation
        @position = { x : x, y : y, z : 0 }


    get_detail_scan: ->

        misc = if @misc? then @misc else []

        r =
            classification : @classification
            name : @name
            mesh : @model_url
            mesh_scale : @model_display_scale
            misc : misc



class Planet extends CelestialObject

    # NB on names:
    # Most planets in Star Trek get named in the convention system number,
    # eg Ceti Alpha 6, so we pass in the system name here so that a complete
    # name can be given, though the name argument only expects a number
    #
    # If a planet is named, for cultural or historical reasons, the name will
    # be returned, rather than a system-number designation.

    # http://en.memory-alpha.wikia.com/wiki/Star_Trek:_Star_Charts
    @CLASSIFICATION =
        B : {
            code : 'B',
            min_radius : 5e2,
            max_radius : 5e3,
            surface_color : '#73655F',
            atmosphere : undefined,
            description : 'Geothermal'  # AKA Mercury
            }
        D :	{
            code : 'D',
            min_radius : 1e3,
            max_radius : 1.5e6,
            surface_color : '#666666',
            atmosphere : undefined,
            description : 'Planetoid or moon; little to no atmosphere. Uninhabitable.'
            }
        H :	{
            code : 'H',
            min_radius : 4e6,
            max_radius : 7.5e6,
            surface_color : '#FFD5C7',  # desert
            atmosphere : '#FFBBB1',  # pink?
            description : 'Generally uninhabitable.'
            }
        J : {
            code : 'J',
            min_radius : 2.5e7,
            max_radius : 7e7,
            surface_color : '#FFB968',  # jupiter
            atmosphere : '#FF5625',  # reddish?
            description : 'Gas giant.'  # AKA Jupiter
            }
        K : {
            code : 'K',
            min_radius : 2.5e6,
            max_radius : 5e6,
            surface_color : '#FF9C48',
            atmosphere : '#FFDB8E',
            description : 'Adaptable with pressure dome.'  # AKA Mars
            }
        L : {
            code : 'L',
            min_radius : 5e6,
            max_radius : 7.5e6,
            surface_color : '#A0FF87',
            atmosphere : '#BDFFF6',
            description : 'Marginally habitable. No animal life. Only vegetation life.'
            }
        M : {
            code : 'M',
            min_radius : 5e6,
            max_radius : 7.5e6,
            surface_color : '#378C11',
            atmosphere : '#BDFFF6',
            description : 'Terrestrial.'
            }
        N : {
            code : 'N',
            min_radius : 5e6,
            max_radius : 7.5e6,
            surface_color : '#C79D5A',
            atmosphere : '#B6F7EF',
            description : 'Sulfuric.'  # AKA Venus
            }
        P : {
            code : 'P',
            min_radius : 5e6,
            max_radius : 7.5e6,
            surface_color : '#EBFFF7',
            atmosphere : '#BDFFE0',
            description : 'Glaciated.'  # AKA Venus
            }
        T : {
            code : 'T',
            min_radius : 2.5e10,
            max_radius : 6e10,
            surface_color : '#B6F7EF',
            atmosphere : '#B5C2F7',
            description : 'Gas giant.'  # Weird alternate gas giant
            }
        Y : {
            code : 'Y',
            min_radius : 5e6,
            max_radius : 7.5e6,
            surface_color : '#B21B17',
            atmosphere : '#B2540B',
            description : 'Demon'
            }

    constructor: ( name, @system_name, @planet_class, @orbit ) ->

        super()
        @charted = true
        # Set name this way because super overrides it
        if /[0-9]/.test name
            @name = "#{ @system_name } #{ name }"
        else
            @name = name

        @classification = "#{ @planet_class.code } class planet"
        @_scan_density = {}
        @_scan_density[ LongRangeSensorSystem.SCANS.GRAVIMETRIC ] = switch @planet_class.code
            when 'D' then between 0.1, 1
            when 'M', 'L', 'K', 'N' then between 1, 1e2
            when 'J' then between 3e4, 3e6
            when 'T' then between 3e6, 3e8
            when 'Y' then between 3, 3e3
            else
                between 2e3, 3e4

        @_scan_density[ SensorSystem.SCANS.HIGHRES ] = up_to 2e8
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES ] = up_to 1e8
        @_scan_density[ SensorSystem.SCANS.MAGNETON ] = up_to 20

        if /^[JT]/.test @classification
            @_scan_density[ SensorSystem.SCANS.WIDE_EM ] = up_to 300

        if /^[MLN]/.test @classification
            @_scan_density[ SensorSystem.SCANS.WIDE_EM ] = up_to 30

        @model_url = "planet.json"
        @model_display_scale = 0.5

        # set position assuming 0, 0 is the center of gravity for the system
        @rotation = 2 * Math.PI * do Math.random
        x = @orbit * Math.cos @rotation
        y = @orbit * Math.sin @rotation

        @position = { x : x, y : y, z : 0 }

        # TODO have these vary a bit
        @radius = @planet_class.min_radius + ( Math.random() * ( @planet_class.max_radius - @planet_class.min_radius ) )
        @surface_color = @planet_class.surface_color
        @atmosphere_color = @planet_class.atmosphere_color
        @type = /gas/i.test @planet_class.description ? 'gas' : 'rock'
        @rings = []


    block_for: ( type ) ->

        blocks = [
            SensorSystem.SCANS.HIGHRES
            SensorSystem.SCANS.P_HIGHRES
            SensorSystem.SCANS.WIDE_EM
        ]

        type in blocks


    get_detail_scan: ->

        misc = if @misc? then @misc else []

        nomen = @name
        if /^[1-9]\d*$/.test @name
            nomen = "#{ @system_name } #{ @name }"

        r =
            classification : @classification
            name : nomen
            mesh : @model_url
            mesh_scale : @model_display_scale
            misc : misc



class Star extends CelestialObject

    # http://www.enchantedlearning.com/subjects/astronomy/stars/startypes.shtml
    @CLASSIFICATION =
        O : { type : 'O', size : 15, color : '#3355ff', luminosity : 1.4e6 }
        B : { type : 'B', size : 7.0, color : '#3355ff', luminosity : 2e4 }
        A : { type : 'A', size : 2.5, color : '#3355ff', luminosity : 80 }
        F : { type : 'F', size : 1.3, color : '#FF00FF', luminosity : 6 }
        G : { type : 'G', size : 1.1, color : '#FF99FF', luminosity : 1.2 }
        K : { type : 'K', size : 0.9, color : '#FF5555', luminosity : 0.4 }
        M : { type : 'M', size : 0.4, color : '#FF0000', luminosity : 0.04 }
        # RED_GIANT :
        # RED_SUPERGIANT :
        # WHITE_DWARF :
        # BLUE_DWARF :
        # BROWN_DWARF :


    constructor: ( name, @star_class, @radiation_output ) ->

        super()
        @charted = true
        @classification = "#{ star_class.type } Class Star"

        # TODO: Deviate from the norm
        @radius = @star_class.size * C.SOLAR_RADIUS
        @color = @star_class.color
        @luminosity = @star_class.luminosity

        # Set name this way because super overrides it
        @name = name
        @_scan_density = {}
        @_scan_density[ LongRangeSensorSystem.SCANS.GRAVIMETRIC ] = up_to 3e8
        @_scan_density[ LongRangeSensorSystem.SCANS.GAMMA_SCAN ] = up_to 1000
        @_scan_density[ LongRangeSensorSystem.SCANS.EM_SCAN ] = up_to 400
        @_scan_density[ SensorSystem.SCANS.WIDE_EM ] = up_to 300
        @_scan_density[ LongRangeSensorSystem.SCANS.NEUTRINO ] = up_to 30

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

        misc = if @misc? then @misc else []

        r =
            classification : @classification
            name : @name
            mesh : @model_url
            mesh_scale : @model_display_scale
            radiation_output : @radiation_output
            radiation_safe_distance : 20 * C.AU
            misc : misc
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

        @density = up_to 0.3

        @_scan_density = {}
        @_scan_density[ SensorSystem.SCANS.HIGHRES] = up_to 20
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES] = up_to 20
        @_scan_density[ SensorSystem.SCANS.WIDE_EM] = up_to 100
        @_scan_density[ SensorSystem.SCANS.MAGNETON] = up_to 30
        @_scan_density[ LongRangeSensorSystem.SCANS.EM_SCAN] = up_to 100
        @_scan_density[ LongRangeSensorSystem.SCANS.GAMMA_SCAN] = up_to 100



    scan_for: ( type ) ->

        if @_scan_density[ type ]?
            return @_scan_density[ type ]

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
exports.Planet = Planet
exports.Lagrange = Lagrange
