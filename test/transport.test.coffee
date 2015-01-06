{Ship} = require '../trek/Ship'
{Station} = require '../trek/Station'
{Transporter} = require '../trek/systems/TransporterSystems'

exports.TransportTest =

    'test transport_boarding_part': ( test ) ->

        s1 = new Ship 'Shuttle 1', 'x11'
        s2 = new Ship 'Shuttle 2', 'x12'

        t = do s1.crew_ready_to_transport

        test.ok t.length > 0, "There is no crew in the tranporter room."

        c = t[ 0 ]
        s1.transport_crew c.id, s1, c.deck, c.section, s2, 'F', 'Forward'

        do test.done