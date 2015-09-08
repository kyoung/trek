{Level} = require '../trek/levels/TinkerTailor'
{LevelEvent} = require '../trek/LevelEvent'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../trek/Crew'

C = require '../trek/Constants'

util = require 'util'

process.on 'uncaughtException', ( err ) -> console.log err

exports.LevelTest =

    'test that the ChinTok Shields dont charge on sabotage': ( test ) ->
        l = new Level 1

        # Let everyone charge up and get ready
        delta_t = 10 * 1000
        o.calculate_state undefined, delta_t for o in do l.get_game_objects
        l.code_word_said = true

        # We'll find the ChinTok some time later
        o.calculate_state undefined, delta_t*100 for o in do l.get_game_objects

        for o in do l.get_game_objects
            if /ChinTok/i.test o.name
                for s in o.shields
                    test.ok s.charge == 0, "ChinTok managed to charge #{ s.name } to #{ s.charge }"

        do test.done
