{Station} = require '../trek/Station'
{Transporters} = require '../trek/systems/TransporterSystems'
{System, ChargedSystem} = require '../trek/BaseSystem'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../trek/systems/WeaponSystems'
{SensorSystem, LongRangeSensorSystem} = require '../trek/systems/SensorSystems'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../trek/Crew'


{Constitution} = require '../trek/ships/Constitution'
{D7} = require '../trek/ships/D7'

C = require '../trek/Constants'
U = require '../trek/Utility'
Cargo = require '../trek/Cargo'
util = require 'util'


exports.ShipTest =

    'test instantiation': ( test ) ->

        s = new Constitution
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

        d = new D7
        test.ok d, 'D7 failed to initialize'


    'test course setting': ( test ) ->

        test.expect 2

        C.TIME_FOR_FULL_ROTATION /= 10
        s = new Constitution
        s.port_warp_coil.charge = 1
        s.starboard_warp_coil.charge = 1

        s.set_warp 1

        m = s.set_course 0.250, 0

        check_turn = () ->
            test.ok s.bearing.bearing is 0.25, "Failed to turn"
            console.log s.bearing
            test.ok s.warp_speed == 1, "Failed to restore speed"
            do test.done

        setTimeout check_turn, m.turn_duration


    'test turning': ( test ) ->

        s = new Constitution

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

        s = new Constitution
        target = new Constitution

        s.set_target target
        test.ok s.weapons_targeting.target.position?,
            "Failed to read target position"
        test.ok s.weapons_targeting.target.velocity?,
            "Failed to read target velocity"

        do test.done



    'test firing ability': ( test ) ->

        s = new Constitution
        target = new Constitution

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

        s = new Constitution

        #console.log "Ship has #{ s.shields.length } shields"

        s.set_shields true
        # FFWD
        s.calculate_state EMPTY_CALLBACK, FFWD_MS
        test.ok do s._are_all_shields_up, "Failed to raise shields"
        for shield in s.shields
            test.ok shield.online and shield.active, "Shield failed to be both online (#{ shield.online }) and active (#{ shield.active })"

        s.set_shields false
        # FFWD
        s.calculate_state EMPTY_CALLBACK, FFWD_MS
        test.ok not do s._are_all_shields_up, "Failed to lower shields"

        do test.done


    'test scanning ability': ( test ) ->

        e = new Constitution
        r = new Constitution

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

        e = new Constitution
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

        e = new Constitution
        r = do e.get_internal_lifesigns_scan
        test.ok e.internal_personnel.length > 0, "Ship shows no internale personnel"
        test.ok r.length > 0, "Internal Scanner arent working: #{r}"
        do test.done


    'test boarding parties': ( test ) ->

        e = new Constitution
        r = new Constitution

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
        test.ok bp in r.internal_personnel, "Failed to send a boarding party to #{ r.name }"

        #console.log "Retrieving boarding party from r"
        e.transport_crew bp.id, r, 'E', 'Forward', e
        test.ok bp in e.internal_personnel && bp not in r.internal_personnel, 'Failed to retrieve away team from #{ r.name }'

        #console.log "Beaming crew to Station"
        e.transport_crew bp.id, e, bp.deck, bp.section, s, '1', '1'
        test.ok bp not in e.internal_personnel && bp in s.crew, "Failed to send over boarding party to #{ s.name }"

        #console.log "Retrieving crew from station"
        e.transport_crew bp.id, s, '1', '1', e
        test.ok bp in e.internal_personnel && bp not in s.crew, 'Failed to retrieve away team from station #{ s.name }'

        do test.done


    'test repair crews': ( test ) ->

        test.expect 3
        e = new Constitution

        original_repair_time = System.REPAIR_TIME
        System.REPAIR_TIME /= 500

        # Pick a system on the same deck to avoid transit time
        # The first available repair crews happen to be on F deck
        e.impulse_drive.repair 1
        e.impulse_drive.damage 0.001
        starting_inventory = do e.get_cargo_status
        starting_computer = 0
        starting_eps = 0
        for bay, inventory of starting_inventory
            starting_computer += inventory[ Cargo.COMPUTER_COMPONENTS ]
            starting_eps += inventory[ Cargo.EPS_CONDUIT ]

        e.assign_repair_crews e.impulse_drive.name, 1, true

        final_inventory = do e.get_cargo_status
        final_computer = 0
        final_eps = 0
        for bay, inventory of final_inventory
            final_computer += inventory[ Cargo.COMPUTER_COMPONENTS ]
            final_eps += inventory[ Cargo.EPS_CONDUIT ]

        test.ok final_computer < starting_computer, "Failed to consume computer components"
        test.ok final_eps < starting_eps, "Failed to consume EPS components"

        close_to = ( n, v ) ->
            0.99 * v < n < 1.01 * v

        check_repair = ->
            test.ok close_to( e.impulse_drive.state, 1 ), "Impulse drive failed to repair. State: #{e.impulse_drive.state}"
            System.REPAIR_TIME = original_repair_time
            do test.done

        time_out = 0.002 * System.REPAIR_TIME
        setTimeout check_repair, time_out


    'test internal team movement': ( test ) ->

        crew_t_per_deck = C.CREW_TIME_PER_DECK
        C.CREW_TIME_PER_DECK /= 100

        test.expect 1
        e = new Constitution

        t = e.security_teams[ 0 ]
        t.deck = 'G'
        t.section = 'Aft'

        e.send_team_to_deck t.id, 'H', 'Aft'

        check_movement = ->
            test.ok t.deck is 'H' and t.section is 'Aft' and t.status is 'onboard', 'Failed to order team to a different deck'
            C.CREW_TIME_PER_DECK = crew_t_per_deck
            do test.done

        setTimeout check_movement, 11*10


    'test beam guests': ( test ) ->

        e = new Constitution
        e.set_coordinate { x : 0, y : 0, z : 0 }

        s1 = new Station 'Beta', { x : 1000, y : 0, z : 0 }
        target_crew = s1.crew[ 0 ]

        e.transport_crew target_crew.id, s1, target_crew.deck, target_crew.section, e

        test.ok not( target_crew in s1.crew ), 'Test crew remained onboard'

        do test.done


    'test hull damage': ( test ) ->

        e = new Constitution
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

        e = new Constitution
        e.set_coordinate { x : 0, y : 0, z : 0 }
        destruction_message = ( prefix, type, message ) ->

        big_boom = 1e15
        big_boom_point = { x : 10, y : 10, z : 0 }

        e.process_blast_damage big_boom_point, big_boom, destruction_message

        # console.log e.damage_report()
        test.ok not e._check_if_still_alive(), "Ship cannot be destroyed"
        do test.done


    'test can increase power to systems': ( test ) ->

        e = new Constitution
        init_power_level = e.warp_core.output
        e.set_power_to_system 'Primary SIF', 2
        post_power_level = e.warp_core.output
        test.ok init_power_level < post_power_level,
            "Failed to increase warp reactor load:
            #{ init_power_level } -> #{ post_power_level }"

        do test.done


    'test can go to warp': ( test ) ->

        e = new Constitution
        e.port_warp_coil.charge = 1
        e.starboard_warp_coil.charge = 1
        e.set_warp 1

        do test.done


    'test cant turn at warp': ( test ) ->

        e = new Constitution
        e.port_warp_coil.charge = 1
        e.starboard_warp_coil.charge = 1
        e.set_warp 1

        test.throws -> do e.turn_port

        do test.done


    'test warp power balance': ( test ) ->

        s = new Constitution
        tic = 250
        tok = 60 * 1000
        s.port_warp_coil.charge = 1
        s.starboard_warp_coil.charge = 1
        s.set_power_to_system s.port_warp_coil.name, 0.01
        s.set_power_to_system s.starboard_warp_coil.name, 0.01

        s.calculate_state undefined, tic

        # warp 5 should require a power alotment of 5/6 to maintain full charge
        s.set_warp 6

        s.calculate_state undefined, tic
        test.ok s.port_warp_coil.charge < 1, "Failed to drain warp plasma: #{ s.port_warp_coil.charge }"

        s.calculate_state undefined, tok
        test.ok s.port_warp_coil.charge < 0.51, "Failed to drain warp plasma (extended): #{ s.port_warp_coil.charge }"


        do test.done


    'test can reroute EPS relay': ( test ) ->

        e = new Constitution
        e.reroute_power_relay 'Port EPS', 'Impulse Relays'
        port_eps = e.port_eps
        impulse_relay = e.impulse_relay
        warp_relay = e.warp_relay
        test.ok port_eps in impulse_relay.attached_systems, "Failed to migrate EPS grid"
        test.ok port_eps not in warp_relay.attached_systems, "Failed to remove EPS grid"

        do test.done


    'test can scan SR': ( test ) ->

        test.expect 2
        SensorSystem.DURATION /= 1000
        s = new Constitution
        s.bearing = { bearing : 0, mark : 0 }

        world_scan = ( type, position, bearing_from, bearing_to, range ) ->
            all = [
                { bearing : { bearing : 0.15, mark : 0 }, reading : 1 }
                { bearing : { bearing : 0.45, mark : 0 }, reading : 2 }
            ]
            # Dumb condition... need to handle the possibility of a cross
            if bearing_from > bearing_to
                bearing_from -= 1
            r =
                readings: ( m for m in all when bearing_from <= m.bearing.bearing < bearing_to )
                classifications:
                    ( {
                        classification: 'Test Object',
                        coordinate: { x : 10, y : 10, z : 0 },
                        } for m in all when bearing_from <= m.bearing.bearing < bearing_to )
            # console.log "returning #{r.readings.length} for bearing #{bearing_from} to #{bearing_to}"
            return r

        s.run_scan world_scan, 'test', 0, 63, true, 0.2, 4
        area = Math.PI * ( SensorSystem.RANGE * 0.2 )**2
        timeout = SensorSystem.DURATION * 64 * area * SensorSystem.SCANNER_DIVISOR
        # console.log "Scan will take #{timeout} at this resolution..."

        check_result = ->
            results = s.get_scan_results 'test'
            scan_sum = 0
            scan_sum += bucket.reading for bucket in results.results
            test.ok scan_sum == 3, "Failed to find 3 targets: found #{scan_sum}"
            test.ok results.classifications.length == 2, "Failed to get the expected classifications."

            do test.done

        setTimeout check_result, timeout


    'test power signature': ( test ) ->

        s = new Constitution

        p = do s.get_system_scan
        power_readings = p.power_readings
        test.ok power_readings.length == 5, "Failed to get expected power signature"

        # console.log power_readings

        warp_coil = power_readings[ 0 ]
        sum_of_output = 0
        sum_of_output += n for n in warp_coil
        test.ok sum_of_output > 0, "Failed to detect warp coil power signature"

        do test.done


    'test radiation exposure': ( test ) ->

        s = new Constitution
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


    'test medical facilities': ( test ) ->

        s = new Constitution

        # find a team on the ship
        c = ( i for i in s.internal_personnel when i.deck isnt s.sick_bay.deck and i.alignment is s.alignment )[ 0 ]
        c.radiation_exposure RepairTeam.RADIATION_TOLERANCE * 0.25

        initial_health = do c.health

        # tick one
        s.calculate_state undefined, 250
        sustained_health = do c.health
        test.ok initial_health is sustained_health, "Team's health changed on their own!"

        # move team to sick bay
        c.deck = s.sick_bay.deck
        c.section = s.sick_bay.section

        # tick two
        s.calculate_state undefined, 250
        improved_health = do c.health
        test.ok improved_health > sustained_health, "Being in sickbay did not improve health: #{ initial_health } > #{ improved_health }"

        do test.done


    'test security teams': ( test ) ->

        s = new Constitution

        # find a security team
        c = ( i for i in s.internal_personnel when i.description is "Security Team" )[ 0 ]

        intruder = new SecurityTeam 'x', '5'
        intruder.set_alignment C.ALIGNMENT.KLINGON

        initial_security_health = do c.health
        initial_klingon_health = do intruder.health

        # send boarding team
        s.beam_onboard_crew intruder, c.deck, c.section

        # tick
        s.calculate_state undefined, 250

        final_klingon_health = do intruder.health

        # we only test the klingon health, as it's possible we've beamed into the midst of many
        # security teams and we don't know which we fought
        test.ok final_klingon_health < initial_klingon_health, "Failed to fight intruder"

        do test.done


    'test alert setting': ( test ) ->

        s = new Constitution
        tic = 250

        is_close = ( n1, n2 ) ->
            n1 * 0.99 < n2 < n1 * 1.01

        shields_are_up = ( ship ) ->
            r = true
            r = r and h.online and h.active for h in ship.shields
            return r

        sifs_are_powered = ( ship ) -> is_close ship.primary_SIF.power, ship.primary_SIF.power_thresholds.dyn

        phasers_are_charging = ( ship ) -> ship.phasers[ 0 ].active and ship.phasers[ 0 ].online

        tubes_are_autoloading = ( ship ) -> ship.torpedo_banks[ 0 ]._autoload

        s.set_alert "red"
        s.calculate_state undefined, tic

        #console.log "Shields: #{ shields_are_up s  }"
        #console.log "Phasers: #{ phasers_are_charging s }"
        #console.log "SIFs: #{ sifs_are_powered s }"
        #console.log "Tubes: #{ tubes_are_autoloading s }"

        test.ok shields_are_up( s ) and phasers_are_charging( s ) and sifs_are_powered( s ) and tubes_are_autoloading( s ), "Failed to set condition one"

        s.set_alert "yellow"
        s.calculate_state undefined, tic
        test.ok shields_are_up( s ) and not phasers_are_charging( s ) and sifs_are_powered( s ) and not tubes_are_autoloading( s ), "Failed to set condition two"

        s.set_alert "blue"
        s.calculate_state undefined, tic
        test.ok not shields_are_up( s ) and not phasers_are_charging( s ) and not tubes_are_autoloading( s ) and sifs_are_powered( s ), "Failed to set condition three"

        s.set_alert "clear"
        s.calculate_state undefined, tic
        test.ok not shields_are_up( s ) and not phasers_are_charging( s ) and not tubes_are_autoloading( s ) and not sifs_are_powered( s ), "Failed to stand down"

        do test.done


    'test can turn in the z-axis': ( test ) ->

        test.expect 1

        s = new Constitution
        bearing = 0
        mark = 0.010

        r = s.set_course bearing, mark

        check_turn = ->

            s.calculate_state undefined, r.turn_duration
            test.ok s.bearing.mark isnt 0

            do test.done

        setTimeout check_turn, r.turn_duration


    'test can move in the z-axis': ( test ) ->

        s = new Constitution
        tic = 250
        s.bearing = { bearing : 0, mark : 0.2 }

        s.set_impulse 0.5
        s.calculate_state undefined, tic

        test.ok s.position.z isnt 0

        do test.done


    'test cloaking behaviour': ( test ) ->

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
        for s in k.shields
            test.ok !s.active, "Shileds failed to deactivate in cloak"

        do test.done
