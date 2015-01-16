{Station} = require '../trek/Station'
{Torpedo} = require '../trek/Torpedo'


exports.StationTest =

    'test can be destroyed': ( test ) ->

        starting_at = { x : 0, y : 0, z : 0 }
        station = new Station "Test", starting_at

        blast_position = { x : 500, y : 0, z : 0 }
        blast_yeild = Torpedo.MAX_DAMAGE
        callback = ( m ) ->
            console.log m

        station.process_blast_damage blast_position, blast_yeild, callback

        # console.log station.hull
        has_damage_occured = false
        for deck, sections of station.hull
            for section, status of sections
                if status isnt 1
                    has_damage_occured = true

        test.ok has_damage_occured, "Damaged failed to occurr from direct torpedo blast!"

        station.process_blast_damage blast_position, blast_yeild * 4, callback

        test.ok not station.alive, "Station failed to die"

        do test.done