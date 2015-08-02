{Constitution} = require '../trek/ships/Constitution'
{Station} = require '../trek/Station'
{Transporter} = require '../trek/systems/TransporterSystems'

exports.TransportTest =

    'test transport_boarding_part': ( test ) ->

        s1 = new Constitution 'Shuttle 1', 'x11'
        s2 = new Constitution 'Shuttle 2', 'x12'

        t = do s1.crew_ready_to_transport

        test.ok t.length > 0, "There is no crew in the tranporter room."

        c = t[ 0 ]
        s1.transport_crew c.id, s1, c.deck, c.section, s2, 'F', 'Forward'

        do test.done


    'test cannot beam cargo with shields up': ( test ) ->

        s1 = new Constitution
        s2 = new Constitution
        s1.set_alert 'red'

        # give shields a moment to raise
        s1.calculate_state undefined, 10000

        test.ok do s1._are_all_shields_up
        test.throws(
            -> s1.transport_cargo s2, '1', s1, '1', 'Warp Plasma', 1
        )

        s1.set_alert 'clear'
        s2.set_alert 'red'

        s1.calculate_state undefined, 10000
        s2.calculate_state undefined, 20000

        test.ok do s2._are_all_shields_up
        test.ok not do s1._are_all_shields_up
        test.throws(
            -> s1.transport_cargo s2, '1', s1, '1', 'Warp Plasma', 1
        )

        do test.done


    'test cannot beam crew with shields up': ( test ) ->

        s1 = new Constitution
        s2 = new Constitution
        s1.set_alert 'red'

        s1.calculate_state undefined, 10000

        test.ok do s1._are_all_shields_up
        target_crew = s2.internal_personnel[ 0 ]
        id = target_crew.id_counter
        s_deck = target_crew.deck
        s_section = target_crew.section

        test.throws(
            -> s1.transport_crew id, s2, s_deck, s_section, s1, 5, 'Aft'
        )

        # make sure crew doesn't disapear when you fail to beam them off
        test.ok target_crew in s2.internal_personnel, 'Crew killed during aborted transport [1]'

        s1.set_alert 'clear'
        s2.set_alert 'red'

        s1.calculate_state undefined, 10000
        s2.calculate_state undefined, 10000

        test.ok not do s1._are_all_shields_up
        test.ok do s2._are_all_shields_up

        target_crew = s2.internal_personnel[ 1 ]
        id = target_crew.id_counter
        s_deck = target_crew.deck
        s_section = target_crew.section

        test.throws(
            -> s1.transport_crew id, s2, s_deck, s_section, s1, 5, 'Aft'
        )

        # make sure we havn't lost crew...
        test.ok target_crew in s2.internal_personnel, 'Crew killed during aborted transport [2]'
        console.log target_crew

        do test.done
