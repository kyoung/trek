C = require "./Constants"
U = require "./Utility"


class BaseMap
    constructor: ( @name ) ->


class SpaceSector extends BaseMap
    # All coordinates in Sectors are expressed in LY

    constructor: ( @name ) ->
        @systems = {}
        super(@name)

    add_star_system: ( star_system, sector_position ) ->
        if sector_position?
            star_system.set_position sector_position
        @systems[star_system.name] = star_system

    get_star_system: ( star_system_name ) ->
        @systems[star_system_name]


class StarSystem extends BaseMap
    constructor: ( @name ) ->
        super(@name)
        @width = C.SYSTEM_WIDTH

    set_position: ( @position ) ->


exports.SpaceSector = SpaceSector
exports.StarSystem = StarSystem