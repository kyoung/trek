{Level} = require '../trek/levels/DGTauIncident'
util = require 'util'

exports.LevelTest =

	'test can beat level': ( test ) ->

		test.expect 1

		l = new Level()

		game = {
			is_over : false,
			set_environment_function : -> ,
		}
		events = do l.get_events
		e.listen game for e in events

		# All crew off of stations is a victory

		ships_and_stations = do l.get_game_objects
		# Disappear the crew
		for s in ships_and_stations
			if /Outpost/.test s.name
				s.crew = []

		check_win = ->
			test.ok game.is_over, "Cannot beat the level; is game over: #{ game.is_over }"
			do e.kill for e in events
			do test.done

		setTimeout check_win, 2000


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
