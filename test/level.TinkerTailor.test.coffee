{Level} = require '../trek/levels/TinkerTailor'
{LevelEvent} = require '../trek/LevelEvent'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../trek/Crew'
{D7} = require '../trek/ships/D7'

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


    'test cloaking behaviour (special case)': ( test ) ->

        k = new D7
        k.calculate_state undefined, 2000

        # test that the cloak isn't enabled by default
        test.ok !k.cloak_system.active, "Cloaking system was active on startup"
        k.set_alert 'red'
        for p in k.phasers
            test.ok p.active, "Phasers failed to activate in uncloaked mode"

        k.set_active "Cloaking System", true

        k.calculate_state undefined, 2000

        test.ok k.cloak_system.active, "Cloak failed to activate"
        for p in k.phasers
            test.ok !p.active, "Phasers failed to deactivate in cloak"
            test.ok p.charge == 0, "Phasers failed to discharge in cloak"
        for s in k.shields
            test.ok !s.active, "Shields failed to deactivate in cloak"
            test.ok s.charge == 0, "Shields failed to discharge in cloak"

        do k.warp_core.deactivate
        k.warp_core.state = 0.1
        # # vent warp plasma
        k.port_warp_coil.charge = 0
        k.starboard_warp_coil.charge = 0
        # # deactivate the cloak system, and hide it in the cargo bay
        do k.decloak
        k.calculate_state undefined, 15*1000
        k.reroute_power_relay k.port_eps.name, k.e_power_relay.name
        for p in k.phasers
            test.ok p.charge == 0, "Phasers failed to discharge in cloak"
        for s in k.shields
            test.ok s.charge == 0, "Shields failed to discharge in cloak"


        do test.done
