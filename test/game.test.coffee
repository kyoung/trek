{Game} = require '../trek/Game'
{SensorSystem} = require '../trek/systems/SensorSystems'
C = require '../trek/Constants'
U = require '../trek/Utility'

process.on 'uncaughtException', ( err ) -> console.log err

exports.GameTest =

    'test init of game': ( test ) ->

        g = new Game ''
        ship_prefixes = ( p for p, s of g.ships )
        test.ok ship_prefixes.length == 2, "Too many ships!"
        do g.over
        do test.done


    'test can fire single Torpedo': ( test ) ->

        MAX_DELAY = 100
        game = new Game ""
        ent = ''
        rel = ''
        for prefix, ship of game.ships
            if ship.name is 'Enterprise'
                ent = ship
            else
                rel = ship

        # fire torpedoes
        game.target ent.prefix_code, rel.name
        test.ok ent.weapons_target, 'Enterprise target not set'

        t1 = new Date().getTime()
        # # Set course to bear on target
        ent.bearing = U.abs_bearing ent, rel
        # # Load tube
        ent.torpedo_bank_1.torpedo_state = "Loaded"

        torpedo_1_status = game.fire_torpedo ent.prefix_code, '16'

        do game.over
        do test.done


    'test can fire multiple Torpedoes': ( test ) ->

        test.expect 2
        MAX_DELAY_MS = 20
        game = new Game ''
        ent = ''
        rel = ''

        for prefix, ship of game.ships
            if ship.name is 'Enterprise'
                ent = ship
            else
                rel = ship

        # face target
        ent.bearing = U.abs_bearing ent, rel
        # load tubes
        ent.torpedo_bank_1.torpedo_state = "Loaded"
        ent.torpedo_bank_2.torpedo_state = "Loaded"

        # fire torpedoes
        game.target ent.prefix_code, rel.name
        t1 = new Date().getTime()

        torpedo_1_status = game.fire_torpedo ent.prefix_code, '16'
        t2 = new Date().getTime()

        torpedo_2_status = game.fire_torpedo ent.prefix_code, '16'
        t3 = new Date().getTime()

        test.ok(t2 - t1 <= MAX_DELAY_MS, "It took too long to return
            from firing the initial torpedo: #{t2 - t1}")
        test.ok(t3 - t2 <= MAX_DELAY_MS, "It took too long to fire the
            second torpedo: #{t3 - t2}")

        do game.over

        do test.done


    'test can get obects within visual range': ( test ) ->

        game = new Game ''
        e_prefix = ''
        e_ship = undefined
        o_prefix = ''
        o_ship = undefined

        for prefix, ship of game.ships
            if ship.name is 'Enterprise'
                e_ship = ship
                e_prefix = prefix
            else
                o_prefix = prefix
                o_ship = ship

        o_ship.position.x = e_ship.position.x
        o_ship.position.y = e_ship.position.y + C.VISUAL_RANGE - 1
        scan = game.get_targets_in_visual_range e_prefix
        test.ok( o_ship.name in scan,
            'The visual range scanner failed to report a nearby ship' )

        do game.over
        do test.done


    'test world scan callback': ( test ) ->

        game = new Game ''

        class Mock_Gas_Cloud
            constructor: ( @position ) ->
                @radius = 1
            scan_for: ( t ) -> return 1
            block_for: ( t ) -> return true

        # (7, 7) should be behind (5, 5), and thus blocked
        game.space_objects = [
            new Mock_Gas_Cloud { x: 5, y: 5, z: 0 }
            new Mock_Gas_Cloud { x: 7, y: 7, z: 0 }
            new Mock_Gas_Cloud { x: -5, y: 5, z: 0 }
            new Mock_Gas_Cloud { x: 5, y: -5, z: 0 }
        ]
        game.game_objects = [
        ]
        full_scan = game.world_scan(
            'testtype',
            { x: 0, y: 0, z: 0 },
            0,
            1,
            15
        )

        test.ok full_scan.readings.length == 3, "Failed to scan all objects"

        do game.over
        do test.done


    'test can plot intercept courses': ( test ) ->
        ###
        This is complicated behaviour, as the ship will
        turn to face the target before moving

        ###

        test.expect 1
        game = new Game ''
        ships = do game.get_startup_stats
        e = (s for s in ships when s.name == "Enterprise")[0]
        d = (s for s in ships when s.name != "Enterprise")[0]

        game.ships[ e.prefix ].set_coordinate { x : 1e6, y : 1e7, z : 0 }

        distance_initial = U.distance e.position, d.position
        t = game.plot_course_and_engage(
            e.prefix,
            d.name,
            { impulse: undefined, warp: 6 }
        )

        measure_distance_travelled = ->
            distance_final = U.distance e.position, d.position
            test.ok distance_final < distance_initial, "Failed to move
                toward target: started at #{distance_initial} ended at
                #{distance_final}"
            do game.over
            do test.done

        console.log "Interception expected to take #{t} ms"

        setTimeout measure_distance_travelled, C.TIME_FOR_FULL_ROTATION + t * 1.1


    'test can run active scans': ( test ) ->

        test.expect 2
        SensorSystem.DURATION /= 100
        g = new Game ''
        ships = do g.get_startup_stats
        e = ( s for s in ships when s.name == "Enterprise" )[ 0 ]
        d = ( s for s in ships when s.name != "Enterprise" )[ 0 ]

        e_pre = e.prefix
        d_pre = d.prefix

        c =
            x: e.position.x + 10000
            y: e.position.y
            z: e.position.z

        g.ships[ d_pre ].set_coordinate c
        g.ships[ d_pre ].set_shields false

        # First tick to force the scanners to run
        do g.update_state

        console.log "Getting scans for E: #{ e_pre } and D: #{ d_pre }"

        allow_startup = ->
            console.log "Starting startup and scan"
            config = g.get_scan_configuration e.prefix, 'Passive High-Resolution Scan'
            # console.log config
            console.log "Waiting #{ config.time_estimate } for results"
            timeout = if config.time_estimate? then config.time_estimate else 0
            setTimeout check_active_scan, timeout * 1.1

        check_active_scan = ->
            results = g.get_scan_results e_pre, 'Passive High-Resolution Scan'
            target_ship = ( r for r in results.classifications when r.classification != "Plasma Cloud" )[ 0 ]
            # console.log "Scanning for:"
            # console.log target_ship
            active_scan = g.get_active_scan(
                e_pre,
                target_ship.classification,
                target_ship.distance,
                target_ship.bearing.bearing,
                target_ship.tag
            )
            test.ok active_scan, "Failed to get back an active scan"
            test.ok g.ships[ e_pre ]._logged_scanned_items.length == 1, "Failed to log the scanned item."

            SensorSystem.DURATION *= 100
            do g.over
            do test.done

        # Grant some time for the system to boot
        setTimeout allow_startup, 1000

