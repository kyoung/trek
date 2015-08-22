{Level} = require '../trek/levels/TinkerTailor'
{LevelEvent} = require '../trek/LevelEvent'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../trek/Crew'

C = require '../trek/Constants'

util = require 'util'

process.on 'uncaughtException', ( err ) -> console.log err

exports.LevelTest =


    'test captains log population': ( test ) ->
        l = new Level 1
        ships = do l.get_player_ships
        for prefix, ship of ships
            logs = do ship.get_pending_captains_logs
            console.log logs
            log = do ship.get_pending_captains_logs
            console.log log

        do test.done
