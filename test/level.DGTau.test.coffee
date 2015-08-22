{Level} = require '../trek/levels/DGTauIncident'
{LevelEvent} = require '../trek/LevelEvent'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../trek/Crew'

C = require '../trek/Constants'

util = require 'util'

process.on 'uncaughtException', ( err ) -> console.log err

exports.LevelTest =

    'test can beat level': ( test ) ->

        test.expect 1
        original_level_check = LevelEvent.ConditionInterval
        LevelEvent.ConditionInterval = 100

        l = new Level 1

        game = {
            is_over : false,
            set_environment_function : -> ,
        }


        # All crew off of stations, stations destroyed, and crew rescued is a victory
        ships_and_stations = do l.get_game_objects
        # Disappear the crew and add some rescues
        for s in ships_and_stations
            if /Outpost/.test s.name
                s.crew = []
                s.alive = false
            if /Enterprise/.test s.name
                rescue = new RepairTeam 'G', 'Forward'
                rescue.set_alignment 'Federation'
                rescue.set_assignment "Outpost_1"
                s.internal_personnel.push rescue
                s.position = { x : 20 * C.AU, y : 0, z : 0 }

        events = do l.get_events
        e.listen game for e in events

        check_win = ->
            test.ok game.is_over, "Cannot beat the level; is game over: #{ game.is_over }"
            do e.kill for e in events
            LevelEvent.ConditionInterval = original_level_check
            do test.done

        setTimeout check_win, 300


    'test ship creation of level': ( test ) ->

        l2 = new Level()
        ship_prefixes = ( p for p, s of do l2.get_ships )
        test.ok ship_prefixes.length == 2, "Level gives too many ships: #{ ship_prefixes.length }"

        do test.done


    'test creation of stellar objects': ( test ) ->

        l3 = new Level
        map = do l3.get_map
        system = 'DG Tau'
        dg_tau_system = map.get_star_system system

        test.ok dg_tau_system.stars.length > 0, "Failed to create an initial star"

        stellar_objects = do dg_tau_system.get_objects

        test.ok stellar_objects.length > 0, "Failed to create any stellar objects"
        charted = ( o for o in stellar_objects when o.charted )
        test.ok charted.length > 0, "Failed to pre-chart any stellar objects"

        do test.done
