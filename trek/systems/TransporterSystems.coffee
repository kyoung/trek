{System, ChargedSystem} = require '../BaseSystem'

U = require '../Utility'
C = require '../Constants'


class Transporters extends System

    @POWER =
        min: 0.5
        max: 2
        dyn: 9e3

    # 10,000km
    @RANGE = 10000 * 1000


    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        if not @power_thresholds?
            @power_thresholds = Transporters.POWER

        super @name, @deck, @section, @power_thresholds


    effective_range: ->

        Transporters.RANGE * do @performance


    beam_cargo: ( source, destination, source_bay, destination_bay, cargo, qty ) ->

        distance = U.distance source.position, destination.position

        if distance > do @effective_range
            throw new Error "Target is out of range: Boost power or move closer."

        if not do @is_online
            throw new Error 'Transporters not online'

        source_bay.transfer_cargo cargo, qty, destination_bay


    beam_crew: ( crew_id, source, source_deck, source_section, target, target_deck, target_section ) ->

        distance = U.distance source.position, target.position

        if distance > do @effective_range
            throw new Error "Target is out of range: Boost power or move closer."

        if not do @is_online
            throw new Error 'Transporters not online'

        crew = source.beam_away_crew crew_id, source_deck, source_section
        target.beam_onboard_crew crew, target_deck, target_section


exports.Transporters = Transporters