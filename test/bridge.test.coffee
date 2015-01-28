{BridgeSystem} = require '../trek/systems/BridgeSystems'
{System} = require '../trek/BaseSystem'


exports.BridgeSystemTest =

    'test can start system': ( test ) ->

        cb = ->
        s = new BridgeSystem 'Bridge', 'A', 23, cb

        test.ok s, "Failed to instantiate bridge"

        do test.done


    'test can repair bridge': ( test ) ->

        damage_messages = []
        repair_messages = []

        message_interface = ( type, msg ) ->

            msg_parts = msg.split ":"
            event = msg_parts[0]
            screen = msg_parts[1]
            if event is "Repair"
                repair_messages.push screen
            else
                damage_messages.push screen

        s = new BridgeSystem 'Bridge', 'A', 1, message_interface
        s.damage System.STRENGTH * 0.5
        s.repair System.STRENGTH * 0.5

        for screen in damage_messages
            test.ok screen in repair_messages, "Failed to repair #{ screen }"

        do test.done


    'test can damage bridge': ( test ) ->

        damage_messages = []

        message_interface = ( type, msg ) ->

            msg_parts = msg.split ":"
            event = msg_parts[0]
            screen = msg_parts[1]
            test.ok event is "Blast Damage", "Received incorrect message"
            damage_messages.push screen

        s = new BridgeSystem 'Bridge', 'A', 1, message_interface
        s.damage System.STRENGTH * 0.5

        # There are currently 6 stations on the bridge
        test.ok damage_messages.length == 3, "Failed to damage the expecte number of stations."

        do test.done
