{Station} = require '../trek/Station'
{Transporters} = require '../trek/systems/TransporterSystems'
{System, ChargedSystem} = require '../trek/BaseSystem'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../trek/systems/WeaponSystems'
{SensorSystem, LongRangeSensorSystem} = require '../trek/systems/SensorSystems'

{Constitution} = require '../trek/ships/Constitution'

C = require '../trek/Constants'
U = require '../trek/Utility'
Cargo = require '../trek/Cargo'
util = require 'util'


exports.ShipTest =

    'test instantiation': ( test ) ->

        s = new Constitution 'Enterprise', 1701
        test.ok s, 'Ship was not OK'
        power_sys_names = ( subsys?.name for subsys in s.power_systems )

        for subsys in s.power_systems
            test.ok subsys?, "Power systems failed to initialize!
                #{power_sys_names}"

        for sys in s.systems
            test.ok sys?, "Systems failed to initialize!"

        #console.log "Warp core operating at #{ s.warp_core.output } MDyn
        #(#{ s.warp_core.output_level() * 100 }%)"

        pow_report = do s.power_distribution_report
        # console.log util.inspect pow_report, { depth : null, colors : true }

        do test.done


    'test course setting': ( test ) ->

        test.expect 2

        C.TIME_FOR_FULL_ROTATION /= 10
        s = new Constitution 'Icarus', 'NX-091'

        s.set_warp 1

        m = s.set_course 0.250, 0

        check_turn = () ->
            test.ok s.bearing.bearing is 0.25, "Failed to turn"
            console.log s.bearing
            test.ok s.warp_speed == 1, "Failed to restore speed"
            do test.done

        setTimeout check_turn, m.turn_duration


    'test turning': ( test ) ->

        s = new Constitution 'Munnin', 'x28'

        s.bearing.bearing = 0
        do s.turn_port

        timeout = 100

        # cheat to accelerate time
        s._calculate_motion timeout

        new_bearing = s.bearing.bearing
        target_turn = timeout / C.TIME_FOR_FULL_ROTATION

        test.ok target_turn * 0.9 < new_bearing < target_turn * 1.1, "Failed
        to turn the ship correctly: #{new_bearing} vs #{target_turn}"

        do test.done


    'test targetting ability': ( test ) ->

        s = new Constitution 'Enterprise', 1701
        target = new Constitution 'Reliant', 1864

        s.set_target target
        test.ok s.weapons_target.position?,
            "Failed to read target position"
        test.ok s.weapons_target.velocity?,
            "Failed to read target velocity"

        do test.done


    'test can plot intercept courses': ( test ) ->

        test.expect 3
        original_rotation_time = C.TIME_FOR_FULL_ROTATION
        C.TIME_FOR_FULL_ROTATION = 1

        s = new Constitution 'Delta', 'x001'
        target = new Constitution 'Epsilon', 'x002'

        s.bearing.bearing = 0.5

        s.set_coordinate {
            x: -1e5,
            y: -1e5,
            z: 0
        }

        target.set_coordinate {
            x: 1e5,
            y: 1e7,
            z: 0
        }

        t = s.intercept target, {
            warp: 2,
            impulse: 0
        }

        console.log "Estimated time to intercept #{t}"

        check_interception = () ->
            do s.calculate_state

            console.log s.navigation_log

            test.ok s.bearing.bearing % 1 == target.bearing.bearing % 1, "Failed to match course:
            #{ s.bearing.bearing } mark #{ s.bearing.mark } vs.
            #{ target.bearing.bearing } mark #{ target.bearing.mark }"

            test.ok s.impulse == target.impulse, "Failed to match impulse:
            #{ s.impulse } vs #{ target.impulse }"

            test.ok s.warp_speed == target.warp_speed, "Failed to match warp:
            #{ s.warp_speed } vs #{ target.warp_speed }"

            do test.done
            C.TIME_FOR_FULL_ROTATION = original_rotation_time

        setTimeout check_interception, 1000 + t + C.TIME_FOR_FULL_ROTATION * 2


    'test firing ability': ( test ) ->

        s = new Constitution 'E', 1701
        target = new Constitution 'R', 1864

        # Line them up with the Torpedo tubes
        target.set_coordinate { x : 10000, y : 0, z : 0 }
        { bearing, mark } = U.bearing s, target
        s.set_course bearing, mark

        s.set_target target
        s.torpedo_bank_1.torpedo_state = "Loaded"

        t = s.fire_torpedo '16'
        test.ok t?, 'Torpedo was not returned'
        do t.self_destruct

        do test.done


    'test shield operability': ( test ) ->

        FFWD_MS = 5000
        EMPTY_CALLBACK = undefined

        s = new Constitution 'E', 1701
        console.log "Ship has #{s.shields.length} shields"
        s.set_shields true
        # FFWD
        s.calculate_state EMPTY_CALLBACK, FFWD_MS
        test.ok do s._are_all_shields_up, "Failed to raise shields"
        s.set_shields false
        # FFWD
        s.calculate_state EMPTY_CALLBACK, FFWD_MS
        test.ok not do s._are_all_shields_up, "Failed to lower shields"

        do test.done


    'test scanning ability': ( test ) ->

        e = new Constitution 'E', 1701
        r = new Constitution 'R', 1702

        e.set_coordinate { x : 0, y : 0, z : 0 }
        r.set_coordinate { x : C.SYSTEM_SCAN_RANGE - 1, y : 0, z : 0 }

        scan = e.scan_object r

        test.ok scan?, "Failed to get scan"

        r.set_coordinate { x : C.SYSTEM_SCAN_RANGE + 1, y : 0, z : 0 }
        test.throws(
            -> e.scan_object r
        )

        do test.done


    'test cargo transport ability': ( test ) ->

        e = new Constitution 'E', 1701
        e.set_coordinate { x : 0, y : 0, z : 0 }
        e.get_cargo_bay( 1 ).add_cargo 'special-x', 10

        r = new Constitution 'R', 1702
        effective_range = do e.transporters.effective_range
        r.set_coordinate { x : effective_range - 1 , y : 0, z : 0 }

        r.transport_cargo e, 1, r, 1, 'special-x', 5

        test.equal r.get_cargo_bay( 1 ).inventory[ 'special-x' ], 5

        r.set_coordinate { x: Transporters.RANGE + 1, y : 0, z : 0 }

        test.throws(
            -> r.transport_cargo e, 1, r, 1, 'special-x', 5
        )

        do test.done


    'test internal crew sensors': ( test ) ->

        e = new Constitution 'E'
        r = do e.get_internal_lifesigns_scan
        test.ok e.internal_personnel.length > 0, "Ship shows no internale personnel"
        test.ok r.length > 0, "Internal Scanner arent working: #{r}"
        do test.done


    'test boarding parties': ( test ) ->

        e = new Constitution 'Alpha'
        r = new Constitution 'Beta'

        e.set_alignment 'Federation'
        r.set_alignment 'Federation'

        effective_range = do e.transporters.effective_range

        s = new Station 'Gamma', { x : 0, y : effective_range-1, z : 0 }

        e.set_coordinate { x : 0, y : 0, z : 0 }
        r.set_coordinate { x : effective_range-1, y : 0, z : 0 }

        bp = ( t for t in e.security_teams )[0]
        bp.deck = e.transporters.deck
        bp.section = e.transporters.section

        #console.log "Sending initial crew over to #{ r.name }"
        e.transport_crew bp.id, e, bp.deck, bp.section, r, 'E', 'Forward'
        test.ok bp in r.guests, "Failed to send a boarding party to #{ r.name }"

        #console.log "Retrieving boarding party from r"
        e.transport_crew bp.id, r, 'E', 'Forward', e
        test.ok bp in e.security_teams && bp not in r.guests, 'Failed to retrieve away team from #{ r.name }'

        #console.log "Beaming crew to Station"
        e.transport_crew bp.id, e, bp.deck, bp.section, s, '1', '1'
        test.ok bp not in e.security_teams && bp in s.crew, "Failed to send over boarding party to #{ s.name }"

        #console.log "Retrieving crew from station"
        e.transport_crew bp.id, s, '1', '1', e
        test.ok bp in e.security_teams && bp not in s.crew, 'Failed to retrieve away team from station #{ s.name }'

        do test.done


    'test repair crews': ( test ) ->

        test.expect 3
        e = new Constitution 'e', 1701

        # Pick a system on the same deck to avoid transit time
        # The first available repair crews happen to be on F deck
        e.impulse_drive.repair 1
        e.impulse_drive.damage 0.001
        starting_inventory = e.get_cargo_status()
        starting_computer = 0
        starting_eps = 0
        for bay, inventory of starting_inventory
            starting_computer += inventory[Cargo.COMPUTER_COMPONENTS]
            starting_eps += inventory[Cargo.EPS_CONDUIT]
        e.assign_repair_crews(e.impulse_drive.name, 1, true)
        final_inventory = e.get_cargo_status()
        final_computer = 0
        final_eps = 0
        for bay, inventory of final_inventory
            final_computer += inventory[Cargo.COMPUTER_COMPONENTS]
            final_eps += inventory[Cargo.EPS_CONDUIT]
        test.ok(final_computer < starting_computer)
        test.ok(final_eps < starting_eps)
        check_repair = ->
            test.ok(e.impulse_drive.state == 1,
                "Impulse drive failed to repair. State: #{e.impulse_drive.state}")
            do test.done
        time_out = 0.002 * System.REPAIR_TIME
        setTimeout check_repair, time_out


    'test internal team movement': ( test ) ->

        test.expect 1
        e = new Constitution 'e', 1701

        t = e.security_teams[0]
        t.deck = 'G'
        t.section = 'Aft'

        e.send_team_to_deck t.id, 'H', 'Aft'

        check_movement = ->
            test.ok t.deck is 'H' and t.section is 'Aft' and t.status is 'onboard', 'Failed to order team to a different deck'
            do test.done

        setTimeout check_movement, 11*1000


    'test transporter ability': ( test ) ->

        e = new Constitution 'E', 1701
        t = do e.transportable
        test.ok t.name == 'E'
        do test.done


    'test beam guests': ( test ) ->

        e = new Constitution 'Alpha', 1701
        e.set_coordinate { x : 0, y : 0, z : 0 }

        s1 = new Station 'Beta', { x : 1000, y : 0, z : 0 }
        target_crew = s1.crew[0]

        e.transport_crew target_crew.id, s1, target_crew.deck, target_crew.section, e

        test.ok not( target_crew in s1.crew ), 'Test crew remained onboard'

        do test.done


    'test hull damage': ( test ) ->

        e = new Constitution 'E', 1701
        e.set_coordinate { x : 0, y : 0, z : 0 }
        e.set_shields true
        e.process_phaser_damage { x : 0, y : 100, z : 0 }, PhaserSystem.DAMAGE
        total_damage = 0

        # Calculate total damage
        for dr in do e.damage_report
            total_damage += 1-dr.integrity

        test.ok total_damage > 0, 'No damage incurred'
        do test.done


    'test can be destroyed in single blast': ( test ) ->

        ###
        Ships aren't invincible. We should be able to destroy
        a ship in a significantly large enough initial blast.

        ###

        e = new Constitution 'E', 1701
        e.set_coordinate { x : 0, y : 0, z : 0 }
        destruction_message = ( prefix, type, message ) ->

        big_boom = 1e15
        big_boom_point = { x : 10, y : 10, z : 0 }

        e.process_blast_damage big_boom_point, big_boom, destruction_message

        # console.log e.damage_report()
        test.ok not e._check_if_still_alive(), "Ship cannot be destroyed"
        do test.done


    'test can increase power to systems': ( test ) ->

        e = new Constitution 'E', 1701
        init_power_level = e.warp_core.output
        e.set_power_to_system 'Primary SIF', 2
        post_power_level = e.warp_core.output
        test.ok init_power_level < post_power_level,
            "Failed to increase warp reactor load:
            #{init_power_level} -> #{post_power_level}"
        do test.done


    'test can go to warp': ( test ) ->

        e = new Constitution 'E', 1701
        e.set_warp 1
        do test.done


    'test can reroute EPS relay': ( test ) ->

        e = new Constitution 'E', 1701
        e.reroute_power_relay('Port EPS', 'Impulse Relays')
        port_eps = e.port_eps
        impulse_relay = e.impulse_relay
        warp_relay = e.warp_relay
        test.ok port_eps in impulse_relay.attached_systems, "Failed to migrate EPS grid"
        test.ok port_eps not in warp_relay.attached_systems, "Failed to remove EPS grid"
        do test.done


    'test can scan SR': ( test ) ->

        test.expect 2
        SensorSystem.DURATION /= 1000
        s = new Constitution 'Munnin', 'x27'
        s.bearing = { bearing : 0, mark : 0 }

        world_scan = ( type, position, bearing_from, bearing_to, range ) ->
            all = [
                {bearing: {bearing: 0.15, mark:0}, reading: 1}
                {bearing: {bearing: 0.45, mark:0}, reading: 2}
            ]
            # Dumb condition... need to handle the possibility of a cross
            if bearing_from > bearing_to
                bearing_from -= 1
            r =
                readings: (m for m in all when bearing_from <= m.bearing.bearing < bearing_to)
                classifications:
                    ({
                        classification: 'Test Object',
                        coordinate: {x: 10, y: 10, z: 0},
                        } for m in all when bearing_from <= m.bearing.bearing < bearing_to)
            # console.log "returning #{r.readings.length} for bearing #{bearing_from} to #{bearing_to}"
            return r

        s.run_scan world_scan, 'test', 0, 63, true, 0.2, 4
        area = Math.PI * (SensorSystem.RANGE * 0.2)**2
        timeout = SensorSystem.DURATION * 64 * area * SensorSystem.SCANNER_DIVISOR
        # console.log "Scan will take #{timeout} at this resolution..."

        check_result = ->
            results = s.get_scan_results('test')
            scan_sum = 0
            scan_sum += bucket.reading for bucket in results.results
            test.ok scan_sum == 3, "Failed to find 3 targets: found #{scan_sum}"
            test.ok results.classifications.length == 2, "Failed to get the expected classifications."
            do test.done

        setTimeout check_result, timeout


    'test power signature': ( test ) ->

        s = new Constitution 'Munnin', 'x28'

        p = s.get_system_scan()
        power_readings = p.power_readings
        test.ok power_readings.length == 5, "Failed to get expected power signature"

        # console.log power_readings

        warp_coil = power_readings[0]
        sum_of_output = 0
        ( sum_of_output += n for n in warp_coil )
        test.ok sum_of_output > 0, "Failed to detect warp coil power signature"
        do test.done


    'test radiation exposure': ( test ) ->

        s = new Constitution 'Test Ship 1', 1
        s.set_shields true

        # Accelerate shield charging
        for shield in s.shields
            shield.charge = 1
            s.set_power_to_system shield.name, 0.1

        s.set_environmental_conditions [
            { parameter : C.ENVIRONMENT.RADIATION, readout : 0.8 }
        ]

        # In one mintue, sheild charges should be well below 1
        s.calculate_state undefined, 60 * 1000

        for shield in s.shields
            console.log "#{ shield.name }: #{ shield.charge }"
            test.ok shield.charge < 1, "One minute of radiation failed to drain shield"

        do test.done
