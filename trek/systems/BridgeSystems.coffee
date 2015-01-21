{System, ChargedSystem} = require '../BaseSystem'}


class BridgeSystem extends System

    @POWER = { min : 0.1, max : 1.1, dyn : 7.24e3 }

    @STATIONS =
        ENGINEERING : 'Engineering'
        CONN : 'Conn'
        SCIENCE : 'Science'
        TACTICAL : 'Tactical'
        OPS : 'Ops'
        VIEWSCREEN : 'Viewscreen'


    constructor: ( @name, @deck, @section, @messaging_inteface ) ->

        super @name, @deck, @section, BridgeSystem.POWER

        @station_damaged = {}
        for station_key, _ of BridgeSystem.STATIONS
            @station_damaged[ station_key ] = false


    damage_station: ( station ) ->

        @messaging_inteface 'Display', 'Blast Damage:#{ station }'
        _set_station station, true


    damage_all_stations: ->

        @messaging_inteface 'Display', 'Blast Damage:All'
        _set_all_stations true


    get_damage: -> @station_damaged


    repair_damage: ( station ) ->

        @messaging_inteface 'Display', 'Repair:#{ station }'
        _set_station station, false


    repair_all_damage: ->

        @messaging_inteface 'Display', 'Repair:All'
        _set_all_stations false


    _set_station: ( station, value ) -> @station_damaged[ station ] = value


    _set_all_stations: ( value ) -> @station_damaged[ s ] = value for s, _ of BridgeSystem.STATIONS