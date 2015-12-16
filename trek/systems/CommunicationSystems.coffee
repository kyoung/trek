{System, ChargedSystem} = require '../BaseSystem'


class CommunicationsSystems extends System

    @POWER = { min : 0.01, max : 2.2, dyn : 5e3 }

    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        super @name, @deck, @section, CommunicationsSystems.POWER
        @messages = [ { type : 'recieved', message : "" } ]


    history: ->

        if not @online
            throw new Error "Communications Array not online."

        @messages


    hail: ( message, hail_funciton ) ->

        if not @online
            throw new Error "Communications Array not online."

        @messages.push { type : 'sent', message : message }
        hail_funciton message
        return true


    log_hail: ( message ) ->

        if not @online
            return false

        @messages.push { type : 'recieved', message : message }
        return true


exports.CommunicationsSystems = CommunicationsSystems
