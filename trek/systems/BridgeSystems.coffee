{System, ChargedSystem} = require '../BaseSystem'

U = require '../Utility'

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
        for _, station of BridgeSystem.STATIONS
            @station_damaged[ station ] = false


    damage: ( amt ) ->

        super( amt )

        # check the status, and ensure an appropriate number of screens
        # are damaged

        screens_that_should_be_damaged = Math.ceil( ( 1 - @state ) * Object.keys( BridgeSystem.STATIONS ).length )
        screens_that_are_damaged = ( s for s, damaged of @station_damaged when damaged ).length

        # console.log "...identified [D] #{ screens_that_should_be_damaged } screens should be damaged: #{ @state }"

        if screens_that_should_be_damaged > screens_that_are_damaged
            @_damage_n_screens screens_that_should_be_damaged - screens_that_are_damaged


    repair: ( amt ) ->

        super amt

        # check the status, and ensure an appropriate number of screens
        # are repaired

        screens_that_should_be_fixed = Math.floor( @state * Object.keys( BridgeSystem.STATIONS ).length )
        screens_that_are_operational = ( s for s, damaged of @station_damaged when not damaged ).length

        # console.log "...identified [F] #{ screens_that_should_be_fixed } screens should be fixed: #{ @state }"

        if screens_that_are_operational < screens_that_should_be_fixed
            @_repair_n_screens screens_that_should_be_fixed - screens_that_are_operational


    damage_station: ( station ) ->

        # console.log "Damaging bridge station #{ station }"
        @messaging_inteface 'Display', "Blast Damage:#{ station }"
        @_set_station station, true


    damage_all_stations: ->

        @messaging_inteface 'Display', 'Blast Damage:All'
        @_set_all_stations true


    get_damage: -> @station_damaged


    repair_damage: ( station ) ->

        @messaging_inteface 'Display', "Repair:#{ station }"
        @_set_station station, false


    repair_all_damage: ->

        @messaging_inteface 'Display', 'Repair:All'
        @_set_all_stations false


    _set_station: ( station, value ) -> @station_damaged[ station ] = value


    _set_all_stations: ( value ) -> @station_damaged[ s ] = value for s, _ of BridgeSystem.STATIONS


    _damage_n_screens: ( count ) ->

        # Find 'count' screens that are not damaged and damage them
        # Choose randomly.

        undamaged_screens = ( s for s, damaged of @station_damaged when not damaged )
        candidate_screens = U.shuffle undamaged_screens
        chosen_screens = candidate_screens[ ... count ]
        @damage_station s for s in chosen_screens


    _repair_n_screens: ( count ) ->

        # Find 'count' screens to repair

        damaged_screens = ( s for s, damaged of @station_damaged when damaged )
        candidate_screens = U.shuffle damaged_screens
        chosen_screens = candidate_screens[ ... count ]
        @repair_damage s for s in chosen_screens


exports.BridgeSystem = BridgeSystem
