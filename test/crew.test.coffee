{BaseTeam, RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam} = require '../trek/Crew'
{System, ChargedSystem} = require '../trek/BaseSystem'
Constants = require '../trek/Constants'


exports.CrewTest =

	'test can create crews with IDs': ( test ) ->

		r = new RepairTeam 'A', 'Forward'
		r2 = new RepairTeam 'D', 'Starboard'
		s = new SecurityTeam 'B', 'Aft'
		test.ok(
			r2.id - r.id == 1,
			"Failed to increment ID within class." )
		test.ok(
			r.id < r2.id < s.id,
			"Failed to keep unique ids accross inheritance: #{ r.id }, #{ s.id }" )

		do test.done


	'test can move crews': ( test ) ->

		r = new RepairTeam 'A', 'starboard'
		r.goto 'B', 'aft'
		test.expect 2

		check_movement = ->
			test.ok r.deck == 'B', 'Failed to move to deck'
			test.ok r.is_onboard(), 'Failed to arrive at deck'
			do test.done

		setTimeout check_movement, Constants.CREW_TIME_PER_DECK + 10


	'test can assign repair crew for partial repair': ( test ) ->

		s = new System 'Test System', 'A', 'Forward'
		r = new RepairTeam 'A', 'Forward'
		s.repair 1
		s.damage( 1 - System.OPERABILITY_CUTOFF - 0.001 )
		r.repair s

		original_repair_time = System.REPAIR_TIME
		System.REPAIR_TIME /= 100

		test.expect 2

		check_operational_repair = ->

			test.ok( s.state > System.OPERABILITY_CUTOFF,
				"Failed to get system operational: #{ s.state }" )
			test.ok( not r.currently_repairing,
				"Failed to free up repair team: #{ r.currently_repairing }" )
			System.REPAIR_TIME = original_repair_time
			do test.done

		time_out = 0.05 * System.REPAIR_TIME
		setTimeout check_operational_repair, time_out


	'test can assign repair crew for complete repair': ( test ) ->

		s = new System 'Test System', 'A', 'Forward'
		r = new RepairTeam 'A', 'Forward'
		s.repair 1
		s.damage 0.002
		r.repair s, true
		test.expect 2

		check_complete_repair = ->

			test.ok s.state == 1, "Failed to complete repair state: #{ s.state }"
			test.ok( not r.currently_repairing,
				"Failed to free up repair team: #{ r.currently_repairing } when state is #{ s.state }" )
			do test.done

		time_out = 0.004 * System.REPAIR_TIME
		setTimeout check_complete_repair, time_out


	'test move and repair': ( test ) ->

		s = new System 'Test System', 'B', 'Forward'
		r = new RepairTeam 'A', 'Forward'
		s.repair 1
		s.damage 0.001
		r.repair s, true
		test.expect 2

		check_complete_repair = ->
			test.ok s.state == 1, "Failed to move and repair: #{ s.state }"
			test.ok(not r.currently_repairing,
				"Failed to report complete: #{ r.currently_repairing } when state is #{ s.state }")
			do test.done

		time_out = 0.002 * System.REPAIR_TIME + Constants.CREW_TIME_PER_DECK
		setTimeout check_complete_repair, time_out


	'test is affected by radiation': ( test ) ->

		c = new ScienceTeam 'A', 'Forward'

		initial_health = 0
		initial_health += m for m in c.members

		c.radiation_exposure ScienceTeam.RADIATION_TOLERANCE / 4

		final_health = 0
		final_health += m for m in c.members

		test.ok final_health < initial_health, "Radiation failed to sicken crew."

		do test.done

