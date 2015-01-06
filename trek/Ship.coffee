{System, ChargedSystem} = require './BaseSystem'
{Transporters} = require './systems/TransporterSystems'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require './systems/WeaponSystems'
{WarpSystem} = require './systems/WarpSystems'
{ReactorSystem, PowerSystem} = require './systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require './systems/SensorSystems'
{SIFSystem} = require './systems/SIFSystems'
{Torpedo} = require './Torpedo'
{BaseObject} = require './BaseObject'
{CargoBay} = require './CargoBay'
{Log} = require './Log'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require './Crew'

U = require './Utility'
C = require './Constants'

SECTIONS =
    PORT: 'Port'
    STARBOARD: 'Starboard'
    FORWARD: 'Forward'
    AFT: 'Aft'

# DECK A..R
DECKS = {}
for deck_number in [65..85]
    deck_letter = String.fromCharCode(deck_number)
    DECKS[deck_letter] = deck_letter


class Ship extends BaseObject

    constructor: (@name, @serial="") ->
        super()
        @state_stamp = do Date.now
        @alert = 'clear'
        @repairing = false
        @prefix_code = 1e4 + Math.round( Math.random() * 9e4 )
        @postfix_code =  do U.UID
        @bearing =
            bearing: 0
            mark: 0
        @bearing_v =
            bearing: 0
            mark: 0
        @_navigation_lock = false

        do @initialize_systems
        do @initialize_hull
        do @initialize_cargo
        do @initialize_crew
        do @initialize_logs

        @radiological_alerts = {} # Deck and Section radiological state
        for d, v of DECKS

            if not @radiological_alerts[ d ]?
                @radiological_alerts[ d ] = {}

            for k, s of SECTIONS
                @radiological_alerts[ d ][ s ] = false


        @impulse = 0
        @warp_speed = 0
        @weapons_target = null
        @navigation_target = null
        @set_shields false
        @alive = true
        @torpedo_inventory = 96
        @shuttles = []
        @_viewscreen_target = ""
        @model_url = "constitution.js"
        @model_display_scale = 5
        @classification = "Starship"
        @_scan_density[SensorSystem.SCANS.HIGHRES] = Math.random() * 4
        @_scan_density[SensorSystem.SCANS.P_HIGHRES] = Math.random() * 4


    message: ( type, content ) ->
        console.log "Message to #{ @name } [#{ type }]:"
        console.log content


    set_message_function: ( new_message_function ) ->
        console.log "Setting new message hookup on #{ @name }"
        @message = new_message_function


    initialize_logs: ->
        @navigation_log = new Log "Navigation"
        @weapons_log = new Log "Tactical"
        @captains_log = new Log "Captain's"


    initialize_systems: ->

        @initialize_shileds()
        @initialize_weapons()
        @initialize_sensors()
        @initialize_power_systems()

        # Forward Sensors, Deck A
        @lifesupport = new System(
            'Lifesupport',
            DECKS.B,
            SECTIONS.FORWARD,
            System.LIFESUPPORT_POWER
        )

        @port_warp_coil = new WarpSystem(
            'Port Warp Coil',
            DECKS.C,
            SECTIONS.PORT
        )

        @starboard_warp_coil = new WarpSystem(
            'Starboard Warp Coil',
            DECKS.C,
            SECTIONS.STARBOARD
        )

        # Forward Phasers, Deck D
        @transponder = new System(
            'Transponder',
            DECKS.C,
            SECTIONS.FORWARD,
            System.TRANSPONDER_POWER
        )
        # Forward Shield Emitter, Deck E
        @impulse_drive = new System(
            'Impulse Drive',
            DECKS.F,
            SECTIONS.AFT,
            System.IMPULSE_POWER
        )

        @primary_SIF = new SIFSystem(
            'Primary SIF',
            DECKS.F,
            SECTIONS.STARBOARD
        )

        @transporters = new Transporters(
            'Transporters',
            DECKS.G,
            SECTIONS.AFT
        )

        @brig = new System(
            'Brig',
            DECKS.G,
            SECTIONS.STARBOARD,
            System.BRIG_POWER
        )

        @sick_bay = new System(
            'Sick Bay',
            DECKS.G,
            SECTIONS.PORT,
            System.SICKBAY_POWER
        )

        # Forward Phasers, Deck H
        @weapons_targeting = new System(
            'Weapons Targeting',
            DECKS.H,
            SECTIONS.FORWARD,
            System.SENSOR_POWER
        )

        @communication_array = new System(
            'Communications',
            DECKS.J,
            SECTIONS.AFT,
            System.COMMUNICATIONS_POWER
        )

        # Port and Starboard Sensors, Deck J
        @inertial_dampener = new System(
            'Inertial Dampener',
            DECKS.K,
            SECTIONS.AFT,
            System.DAMPENER_POWER
        )

        # Torpedo tubes, Deck L
        # Torpedo tubes, Deck M
        # Aft Phasers, Deck N
        @secondary_SIF = new SIFSystem(
            'Secondary SIF',
            DECKS.N,
            SECTIONS.FORWARD,
            true
        )

        # Port and Starboard Phasers, Deck P
        @tractor_beam = new System(
            'Tractor Beam',
            DECKS.U,
            SECTIONS.AFT,
            System.TRACTOR_POWER
        )

        # Port, Starboard, and Aft shield emitters are on Deck R
        @navigational_deflectors = new ShieldSystem(
            'Navigational Deflectors',
            DECKS.R,
            SECTIONS.FORWARD,
            ShieldSystem.NAVIGATION_POWER
        )

        # Decks S, T, and U now available

        do @initialize_power_connections

        # Turn on power
        do @_set_operational_reactor_settings

        # Activate basic systems
        do @primary_SIF.power_on
        do @secondary_SIF.power_on

        @systems = [].concat( @shields ).concat( @phasers )
        @systems = @systems.concat( @torpedo_banks ).concat( @sensors )
        @systems = @systems.concat( @power_systems )
        @systems = @systems.concat([
            @transporters
            @lifesupport
            @communication_array
            @impulse_drive
            @sick_bay
            @tractor_beam
            @transponder
            @port_warp_coil
            @starboard_warp_coil
            @primary_SIF
            @secondary_SIF
            @inertial_dampener
            @navigational_deflectors
            @weapons_targeting
            @brig
        ])


    initialize_power_connections: ->

        # Connect main power systems
        @warp_relay.add_route @forward_eps
        @warp_relay.add_route @aft_eps
        @warp_relay.add_route @port_eps
        @warp_relay.add_route @starboard_eps
        @warp_relay.add_route phaser for phaser in @phasers
        @warp_relay.add_route @starboard_warp_coil
        @warp_relay.add_route @port_warp_coil
        @warp_relay.add_route @navigational_deflectors
        @warp_relay.add_route @long_range_sensors
        @warp_relay.add_route @primary_SIF
        @warp_relay.add_route @secondary_SIF

        # Connect impulse power systems
        @impulse_relay.add_route @impulse_drive

        # EPS Systems
        @forward_eps.add_route @lifesupport
        @forward_eps.add_route @transponder
        @forward_eps.add_route @forward_shields
        @forward_eps.add_route @forward_sensors
        @forward_eps.add_route @weapons_targeting

        @port_eps.add_route @transporters
        @port_eps.add_route @communication_array
        @port_eps.add_route @port_shields
        @port_eps.add_route @port_sensors
        @port_eps.add_route @torpedo_bank_2
        @port_eps.add_route @torpedo_bank_4

        @starboard_eps.add_route @sick_bay
        @starboard_eps.add_route @starboard_shields
        @starboard_eps.add_route @starboard_sensors
        @starboard_eps.add_route @brig
        @starboard_eps.add_route @torpedo_bank_1
        @starboard_eps.add_route @torpedo_bank_3

        @aft_eps.add_route @tractor_beam
        @aft_eps.add_route @inertial_dampener
        @aft_eps.add_route @aft_shields
        @aft_eps.add_route @aft_sensors


    initialize_power_systems: ->

        # Main relays
        @impulse_relay = new PowerSystem(
            'Impulse Relays',
            DECKS.E,
            SECTIONS.AFT,
            PowerSystem.IMPULSE_RELAY_POWER
        )

        @e_power_relay = new PowerSystem(
            'Emergency Relays',
            DECKS.Q,
            SECTIONS.PORT,
            PowerSystem.EMEGENCY_RELAY_POWER
        )

        @warp_relay = new PowerSystem(
            'Plasma Relay Conduits',
            DECKS.P,
            SECTIONS.AFT,
            PowerSystem.WARP_RELAY_POWER
        )

        @impulse_reactors = new ReactorSystem(
            'Impulse Reactors',
            DECKS.D,
            SECTIONS.AFT,
            ReactorSystem.FUSION,
            @impulse_relay,
            ReactorSystem.FUSION_SIGNATURE
        )

        @emergency_power = new ReactorSystem(
            'Emergency Power',
            DECKS.T,
            SECTIONS.PORT,
            ReactorSystem.BATTERY,
            @e_power_relay,
            ReactorSystem.BATTERY_SIGNATURE
        )

        @warp_core = new ReactorSystem(
            'Warp Core',
            DECKS.O,
            SECTIONS.AFT,
            ReactorSystem.ANTIMATTER,
            @warp_relay,
            ReactorSystem.ANTIMATTER_SIGNATURE
        )

        # EPS Grids
        @forward_eps = new PowerSystem(
            'Forward EPS',
            DECKS.G,
            SECTIONS.FORWARD,
            PowerSystem.EPS_RELAY_POWER
        )
        # All secondary hull systems (IE below deck J)
        @aft_eps = new PowerSystem(
            'Aft EPS',
            DECKS.Q,
            SECTIONS.AFT,
            PowerSystem.EPS_RELAY_POWER
        )
        @port_eps = new PowerSystem(
            'Port EPS',
            DECKS.E,
            SECTIONS.PORT,
            PowerSystem.EPS_RELAY_POWER
        )
        @starboard_eps = new PowerSystem(
            'Starboard EPS',
            DECKS.E,
            SECTIONS.STARBOARD,
            PowerSystem.EPS_RELAY_POWER
        )

        @primary_power_relays = [
            @impulse_relay
            @e_power_relay
            @warp_relay
        ]

        @eps_grids = [
            @forward_eps
            @port_eps
            @starboard_eps
            @aft_eps
        ]

        @reactors = [
            @impulse_reactors
            @emergency_power
            @warp_core
        ]

        @power_systems = [].concat(
            @primary_power_relays ).concat(
            @eps_grids ).concat(
            @reactors )


    initialize_shileds: ->

        @port_shields = new ShieldSystem(
            'Port Shields',
            DECKS.R,
            SECTIONS.PORT
        )
        @starboard_shields = new ShieldSystem(
            'Starboard Shields',
            DECKS.R,
            SECTIONS.STARBOARD
        )
        @aft_shields = new ShieldSystem(
            'Aft Shields',
            DECKS.R,
            SECTIONS.AFT
        )
        @forward_shields = new ShieldSystem(
            'Forward Shields',
            DECKS.E,
            SECTIONS.FORWARD
        )
        @shields = [
            @port_shields
            @starboard_shields
            @aft_shields
            @forward_shields
        ]


    initialize_weapons: ->

        @forward_phaser_bank_a = new PhaserSystem(
            'Dorsal Phaser Bank',
            DECKS.D,
            SECTIONS.FORWARD
        )
        @forward_phaser_bank_b = new PhaserSystem(
            'Ventral Phaser Bank',
            DECKS.I,
            SECTIONS.FORWARD
        )
        @port_phaser_bank = new PhaserSystem(
            'Port Phaser Bank',
            DECKS.P,
            SECTIONS.PORT
        )
        @starboard_phaser_bank = new PhaserSystem(
            'Starboard Phaser Bank',
            DECKS.P,
            SECTIONS.STARBOARD
        )
        @aft_phaser_bank = new PhaserSystem(
            'Aft Phaser Bank',
            DECKS.N,
            SECTIONS.AFT
        )
        @phasers = [
            @forward_phaser_bank_a
            @forward_phaser_bank_b
            @port_phaser_bank
            @starboard_phaser_bank
            @aft_phaser_bank
        ]
        @torpedo_bank_1 = new TorpedoSystem(
            'Torpedo Bay 1',
            DECKS.L,
            SECTIONS.STARBOARD,
            SECTIONS.FORWARD,
            @_consume_a_torpedo
        )
        @torpedo_bank_2 = new TorpedoSystem(
            'Torpedo Bay 2',
            DECKS.L,
            SECTIONS.PORT,
            SECTIONS.FORWARD,
            @_consume_a_torpedo
        )
        @torpedo_bank_3 = new TorpedoSystem(
            'Torpedo Bay 3',
            DECKS.M,
            SECTIONS.STARBOARD,
            SECTIONS.FORWARD,
            @_consume_a_torpedo
        )
        @torpedo_bank_4 = new TorpedoSystem(
            'Torpedo Bay 4',
            DECKS.M,
            SECTIONS.PORT,
            SECTIONS.FORWARD,
            @_consume_a_torpedo
        )
        @torpedo_banks = [
            @torpedo_bank_1
            @torpedo_bank_2
            @torpedo_bank_3
            @torpedo_bank_4
        ]


    initialize_sensors: ->

        b = @bearing.bearing

        @_logged_scanned_items = []

        forward_scan_grid = [0...8].concat( [56...64] )
        port_scan_grid = [8...24]
        aft_scan_grid = [24...40]
        starboard_scan_grid = [40...56]

        @port_sensors = new SensorSystem(
            'Port Sensor Array',
            DECKS.J,
            SECTIONS.PORT,
            b,
            port_scan_grid
        )
        @starboard_sensors = new SensorSystem(
            'Starboard Sensor Array',
            DECKS.J,
            SECTIONS.STARBOARD,
            b,
            starboard_scan_grid
        )
        @forward_sensors = new SensorSystem(
            'Forward Sensor Array',
            DECKS.A,
            SECTIONS.FORWARD,
            b,
            forward_scan_grid
        )
        @aft_sensors = new SensorSystem(
            'Aft Sensor Array',
            DECKS.T,
            SECTIONS.AFT,
            b,
            aft_scan_grid
        )
        @long_range_sensors = new LongRangeSensorSystem(
            'Long Range Sensors',
            DECKS.Q,
            SECTIONS.FORWARD,
            b,
            forward_scan_grid
        )
        @sensors = [
            @aft_sensors
            @port_sensors
            @starboard_sensors
            @forward_sensors
        ]


    initialize_hull: ->

        @hull = {}
        for deck, deck_letter of DECKS
            @hull[ deck_letter ] = {}
            for section, section_string of SECTIONS
                @hull[ deck_letter ][ section_string ] = 1


    initialize_cargo: ->

        @cargobays = []
        for i in [1..4]
            @cargobays.push( new CargoBay i )


    initialize_crew: ->

        # Repair Lockers are on Deck F, H and Q
        @repair_teams = [
            new RepairTeam DECKS.F, SECTIONS.STARBOARD
            new RepairTeam DECKS.F, SECTIONS.PORT
            new RepairTeam DECKS.H, SECTIONS.PORT
            new RepairTeam DECKS.H, SECTIONS.STARBOARD
            new RepairTeam DECKS.Q, SECTIONS.AFT
            new RepairTeam DECKS.Q, SECTIONS.AFT
        ]
        # Science labs are on deck G
        @science_teams = [
            new ScienceTeam DECKS.D, SECTIONS.PORT
            new ScienceTeam DECKS.D, SECTIONS.PORT
            new ScienceTeam DECKS.D, SECTIONS.STARBOARD
            new ScienceTeam DECKS.D, SECTIONS.AFT
        ]
        # Engineering facilities are on Decks O - T
        @engineering_teams = [
            new EngineeringTeam DECKS.O, SECTIONS.AFT
            new EngineeringTeam DECKS.O, SECTIONS.AFT
            new EngineeringTeam DECKS.O, SECTIONS.AFT
            new EngineeringTeam DECKS.O, SECTIONS.PORT
            new EngineeringTeam DECKS.O, SECTIONS.STARBOARD
        ]
        # Security Locker is on Deck G
        # Assault transporter is also on Deck G (Aft section)
        @security_teams = [
            new SecurityTeam DECKS.G, SECTIONS.AFT
            new SecurityTeam DECKS.G, SECTIONS.FORWARD
            new SecurityTeam DECKS.G, SECTIONS.FORWARD
            new SecurityTeam DECKS.G, SECTIONS.STARBOARD
            new SecurityTeam DECKS.G, SECTIONS.STARBOARD
            new SecurityTeam DECKS.G, SECTIONS.STARBOARD
            new SecurityTeam DECKS.G, SECTIONS.STARBOARD
            new SecurityTeam DECKS.G, SECTIONS.FORWARD
        ]

        @medical_teams = [
            new MedicalTeam DECKS.G, SECTIONS.PORT
            new MedicalTeam DECKS.G, SECTIONS.PORT
            new MedicalTeam DECKS.G, SECTIONS.PORT
        ]

        @boarding_parties = []

        s = new SecurityTeam DECKS.G, SECTIONS.STARBOARD
        s.set_alignment C.ALIGNMENT.PIRATES
        do s.captured
        @prisoners = [ s ]

        g = new DiplomaticTeam DECKS.F, SECTIONS.PORT
        g.set_alignment C.ALIGNMENT.FEDERATION
        g.set_assignment "Starfleet Diplomatic Core"
        @guests = [ g ]

        @_rebuild_crew_checks()
        c.set_assignment @name  for c in @crew


    set_coordinate: ( coordinate ) ->

        @position.x = coordinate.x
        @position.y = coordinate.y
        @position.z = coordinate.z

    set_bearing: ( bearing ) ->

        @bearing.bearing = bearing.bearing
        @bearing.mark = bearing.mark


    set_alignment: ( @alignment ) ->

        c.set_alignment @alignment for c in @crew



    ### Tactical
    _________________________________________________###


    hail: ( target ) ->

        if not @communication_array.is_online()
            throw new Error("Cannot hail. Communication array is offline.")
        console.log "{@name} <<incomming hail>>"


    set_alert: ( status ) ->

        @alert = status
        # TODO: Red alert is charge shields and weapons
        # # Yellow alert is just charge shields
        # # Clear is decharge everything
        if status == 'red'
            @_power_sheilds()
            @_power_phasers()
            @_auto_load_torpedoes()
            # Power up SIFs to full charge
            @set_power_to_system @primary_SIF.name, 1
            @set_power_to_system @secondary_SIF.name, 1

        if status == 'yellow'
            @_power_sheilds()
            @set_power_to_system @primary_SIF.name, 1
            @set_power_to_system @secondary_SIF.name, 1

        else
            # If clear, drain weapons and shields
            @_power_down_shields()
            @_power_down_phasers()
            @_disable_torpedeo_autoload()


    set_target: ( target ) ->

        if not @weapons_targeting.is_online()
            throw new Error "Weapons Targeting systems offline."

        @weapons_target = target



    fire_phasers: (target=@weapons_target) ->

        if target is null
            throw new Error 'No target selected'

        distance = U.distance @position, target.position
        if distance > PhaserSystem.RANGE
            throw new Error "Target is out of phaser range."

        if @warp_speed > 0 and distance > PhaserSystem.WARP_RANGE
            # TODO: Can fire within 5km; correct
            throw new Error "Firing phasers at warp requires close proximity. Close to within 5km."

        quad = @calculate_quadrant(target.position)

        if quad == SECTIONS.FORWARD
            coin = Math.random()
            if @forward_phaser_bank_a.is_online()
                phaser = @forward_phaser_bank_a
            else
                phaser = @forward_phaser_bank_b
        else if quad == SECTIONS.PORT
            phaser = @port_phaser_bank
        else if quad == SECTIONS.STARBOARD
            phaser = @starboard_phaser_bank
        else if quad == SECTIONS.AFT
            phaser = @aft_phaser_bank

        if not do phaser.is_online
            throw new Error "Phaser system offline"

        #console.log "Firing #{ phaser.name } with #{ do phaser.energy_level } power"
        intensity = PhaserSystem.DAMAGE * do phaser.energy_level
        phaser.charge_down phaser.energy_level(), true

        target.process_phaser_damage @position, intensity


    load_torpedo: ( tube_name ) ->

        if @torpedo_inventory == 0
            throw new Error "Insufficient torpedos to load."

        tubes = ( t for t in @torpedo_banks when t.name == tube_name )
        if tubes.length isnt 1
            throw new Error "Invalid torpedo bay: #{tube_number}"

        tube = tubes[0]
        tube.load()


    fire_torpedo: (yield_level='16') ->

        if @weapons_target is null
            throw new Error 'Cannot fire without a target: Set target first'

        bearing_to_target = U.bearing @, @weapons_target
        quadrant = @calculate_quadrant_from_bearing bearing_to_target
        loaded_tubes = ( tube for tube in @torpedo_banks \
            when tube.is_loaded() \
            and tube.section_bearing == quadrant )
        if loaded_tubes.length == 0
            throw new Error "No loaded torpedo tubes in #{quadrant} section.
            Please load torpedo tubes, or turn to target."
        tube = loaded_tubes[0]

        if not @weapons_targeting.is_online()
            throw new Error "Weapons Targeting Systems are Offline."

        if @torpedo_inventory <= 0
            throw new Error 'Torpedo inventory depleted'

        torpedo = tube.fire( @weapons_target, yield_level, @position )

        if @warp_speed > 0
            torpedo.fire_at_warp @warp_speed
        else
            torpedo.fire_at_impulse Math.max( @impulse, 0.1)

        return torpedo


    damage_report: ( filter ) ->

        r = ( s.damage_report() for s in @systems )

        if filter
            r = ( s for s in r when s.integrity < 1 )

        return r


    shield_report: () ->

        r = ( s.shield_report() for s in @shields )


    tactical_report: () ->

        shield_up = false
        report = {}
        for obj in @shields
            shield_up = shield_up or obj.active
            report[ obj.name ] = obj.shield_report()


        report =
            torpedo_inventory: @torpedo_inventory
            weapons_target: @weapons_target?.name
            shields_status: shield_up
            shield_report: report
            alert_status: @alert
            phaser_range: PhaserSystem.RANGE
            torpedo_ranage: TorpedoSystem.RANGE
            torpedo_max_yeild: TorpedoSystem.MAX_DAMAGE
            torpedo_bay_status: ( bay.status_report() for bay in @torpedo_banks )


    set_shields: ( state ) ->

        if state
            do @_power_sheilds
        else
            do @_power_down_shields

        p = ( obj.active for obj in @shields )


    process_phaser_damage: (from_point, energy, target_deck, target_section) =>

        quads = @calculate_quadrants from_point
        if target_section? and target_section in quads
            quad = target_section
        else
            quad = quads[ Math.floor( Math.random() * 2 ) ]

        if not target_deck?
            deck_list = ( k for k, v of DECKS )
            deck_i = Math.floor Math.random() * deck_list.length
            target_deck = deck_list[ deck_i ]


        shield = ( s for s in @shields when s.section == quad )[0]

        damage = energy
        if shield.active and do shield.is_online
            damage = shield.hit energy
        else
            #console.log "Shields down!"

        #console.log "Phaser damage on deck #{target_deck} section #{quad}: energy level: #{ energy }. Passthrough damage: #{ damage }"

        system_passthrough = @_damage_hull [target_deck], quad, damage

        quad_systems = ( s for s in @systems when s.section == quad and s.deck == target_deck )
        for sys in quad_systems
            sys.damage system_passthrough

        do @_check_if_still_alive


    process_blast_damage: ( position, power, message_interface ) ->

        if not do @_check_if_still_alive
            return

        quad = @calculate_quadrant position
        if not quad in ( s for s, v of SECTIONS )
            throw new Error "Invalid position: #{position}"

        deck_list = ( k for k, v of DECKS )

        # Blast epicenter
        deck_i = Math.floor( deck_list.length * do Math.random )

        # Blast radius, given power
        deck_count = power / C.HULL_STRENGTH
        start_deck = deck_i - deck_count / 2
        end_deck = deck_i + deck_count / 2
        target_decks = deck_list[ start_deck..end_deck ]
        distance = Math.max U.distance( @position, position ), 1

        # Inverse square damage law
        damage = power / Math.pow( distance, 2 )

        #console.log "#{@name} detects blast of #{power} power #{distance} m away. #{ damage } damage."

        shield = ( s for s in @shields when s.section is quad )[ 0 ]
        if not shield?
            throw new Error "No shield found at quad #{quad}"

        if shield.is_online() and shield.is_active()
            #console.log "#{shield.name} hit ( #{shield.energy_level()} )"
            damage = shield.hit damage

        #console.log "Passthrough damage: #{ damage }."

        system_passthrough = @_damage_hull target_decks, quad, damage

        quad_systems = ( s for s in @systems \
            when s.section is quad \
            and s.deck in target_decks )

        # if the hull has been blow through, other
        # systems will be affected in different sections
        for d in target_decks
            if @hull[ d ][ quad ] == 0
                for s in @systems when s.deck is d and s.section isnt quad
                    quad_systems.push s

        for sys in quad_systems
            # Introduce some variability accross deck damage
            sys.damage ( 0.2 + ( Math.random() * 0.8 ) ) * system_passthrough

        if damage > 1
            #console.log "#{@name} hit! Blast. #{damage} damage"
            message_interface @prefix_code, "Display", "Blast damage!"

        do @_check_if_still_alive


    _process_radiation: ( dyns ) ->

        ### Process environmental radiation. Assumed to be global
        in this implementation.

        ###

        for k, s of SECTIONS

            # radiation drains shields
            shield = ( sh for sh in @shields when sh.section is s )[ 0 ]
            passthrough = shield.drain dyns

            if passthrough == 0
                for k, v of DECKS
                    @radiological_alerts[ v ][ s ] = false
                continue

            # for now, this affects the entire section at a time
            if not @radiological_alerts[ DECKS.A ][ s ]
                for k, v of DECKS
                    @radiological_alerts[ v ][ s ] = true
                @message(
                    @prefix_code,
                    "Environmental Alarm",
                    "Radiation Hazard in #{ s } section"
                )

            # radiation makes crew sick
            affected_crew = ( c for c in @internal_personnel when c.section is s )
            crew.radiation_exposure passthrough


    _power_sheilds: () ->

        s.power_on() for s in @shields


    _power_phasers: () ->

        p.power_on() for p in @phasers


    _auto_load_torpedoes: () ->

        t.autoload( true ) for t in @torpedo_banks


    _power_down_shields: () ->

        s.power_down() for s in @shields


    _power_down_phasers: () ->

        p.power_down() for p in @phasers


    _disable_torpedeo_autoload: () ->

        t.autoload( false ) for t in @torpedo_banks


    _consume_a_torpedo: () =>
        # Passed function to the torpedo bansk to decrement the shared
        # torpedo inventory

        if @torpedo_inventory <= 0
            return 0

        @torpedo_inventory -= 1
        return 1


    _damage_hull: ( decks, section, damage ) ->

        #console.log "[#{ @name }] Hull damage: #{damage} deck #{ decks } section #{ section }"

        hull_strength = C.HULL_STRENGTH
        damage_as_pct = damage / hull_strength

        # SIFs will absorb the stress and charge down a bit

        if do @primary_SIF.is_active
            [ passed_damage, overload ] = @primary_SIF.absorb damage

            if overload
                #console.log "    Primary SIF overload: passing #{ passed_damage } to Secondary"
                [ passed_damage, overload ] = @secondary_SIF.absorb passed_damage

        else
            [ passed_damage, overload ] = @secondary_SIF.absorb damage


        #console.log "    Passed damage to hull: #{ passed_damage }"

        # Any damage to the hull with the SIFs down is catastrophic
        if overload
            #console.log do @primary_SIF.damage_report
            #console.log do @secondary_SIF.damage_report
            console.log "[#{ @name }] Fatal damage. Ship destroyed!"
            @alive = false
            return 0

        # Divide the damage among the decks
        damage_per_deck = passed_damage / decks.length
        damage_pct_per_deck = damage_per_deck / C.HULL_STRENGTH
        for d in decks
            @hull[ d ][ section ] -= damage_pct_per_deck * ( 0.5 + 0.5 * do Math.random )
            @hull[ d ][ section ] = Math.max 0, @hull[ d ][ section ]

            if @hull[ d ][ section ] == 0

                #console.log "    Hull breach! Deck #{ d } Section #{ section }"
                @process_casualties d, section
                # the remaining damage applies to the other sections
                other_sections = ( v for k, v of SECTIONS when v isnt section )
                for s in other_sections
                    @hull[ d ][ s ] -= damage_pct_per_deck / Object.keys(SECTIONS).length
                    @hull[ d ][ s ] = Math.max 0, @hull[ d ][ s ]
                    if @hull[ d ][ s ] == 0
                        @process_casualties d, s

        return passed_damage


    process_casualties: ( deck, section ) ->

        for p in @internal_personnel
            if p.deck == deck and p.section == section
                p.die 1
        @_rebuild_crew_checks()


    ### Navigation
    _________________________________________________###


    navigation_report: () ->
        r =
            bearing: @bearing
            rotation: @bearing_v
            impulse: @impulse
            warp: @warp_speed
            log: @navigation_log.dump()


    turn_port: () ->
        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."
        @bearing_v.bearing = 1 / C.TIME_FOR_FULL_ROTATION
        @message @prefix_code, "Turning", @navigation_report()
        return @navigation_report()


    turn_starboard: () ->
        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."
        @bearing_v.bearing = -1 / C.TIME_FOR_FULL_ROTATION
        @message @prefix_code, "Turning", @navigation_report()
        return @navigation_report()


    stop_turn: () ->
        if @_navigation_lock
            throw new Error "Cannot engage thruster control while Navigational Computers are piloting."
        @bearing_v.bearing = 0
        @message @prefix_code, "Turning", @navigation_report()
        return @navigation_report()


    intercept: ( target, impulse_warp ) ->

        if @_navigation_lock
            throw new Error "Cannot plot intercept while manuvers are in progress."

        if impulse_warp.warp > WarpSystem.MAX_WARP
            throw new Error "Cannot exceed warp #{ WarpSystem.MAX_WARP }"

        { bearing, time, final_position } = U.intercept @, target, impulse_warp

        if not time > 0
            throw new Error "Impossible intercept: More speed required"

        @_navigation_lock = true
        log_id = @_log_navigation_action "Plotting intercept to #{ target.name }"

        self = @

        match_speed = () =>
            if target.warp_speed > 0
                self._set_warp target.warp_speed
            else
                self._set_impulse target.impulse
            @_navigation_lock = false

        intercept_cruise = () =>
            second_calculation = U.intercept self, target, impulse_warp
            # Jump the heading instantaneously
            intercept_heading = second_calculation.bearing
            self.bearing.bearing = ( self.bearing.bearing + intercept_heading.bearing ) % 1
            self.bearing.mark = ( self.bearing.mark + intercept_heading.mark ) % 1
            final_position = second_calculation.final_position

            halt_and_match = () =>
                # check nav log
                if self.navigation_log.length() != log_id
                    return
                @_navigation_lock = true

                # Don't collide with things
                final_position.x += 2e4
                final_position.y += 2e4

                self._set_impulse 0, ->
                    self.set_coordinate final_position
                    self._set_abs_course(
                        target.bearing
                        match_speed)

            cruise = () =>
                time = second_calculation.time
                setTimeout halt_and_match, time

            if impulse_warp.warp > 0
                self._set_warp impulse_warp.warp, cruise
            else
                self._set_impulse impulse_warp.impulse, cruise

            # Free the nav lock, but set the nav log for post-cruise check
            @_navigation_lock = false


        initial_turn = () =>
            initial_calculation = U.intercept self, target, impulse_warp
            initial_turn = initial_calculation.bearing

            self._set_course(
                initial_turn.bearing,
                initial_turn.mark,
                intercept_cruise)

        @_clear_rotation()
        @_set_impulse 0, initial_turn

        # best guess on time to intercept
        best_guess = U.intercept @, target, impulse_warp
        return best_guess.time


    set_course: (bearing, mark, callback) =>
        if @_navigation_lock
            throw new Error "Unable to set course while navigational computer is manuvering"
        @_log_navigation_action "Setting course bearing #{ bearing } mark #{ mark }"
        @_set_course bearing, mark, callback


    _set_course: (bearing, mark, callback) =>

        # These are understood to be relative bearings
        if not @inertial_dampener.is_online()
            throw new Error("internal Dampener offline. Safety protocols
                prevent acceleration.")

        if not @primary_SIF.is_online() or not @secondary_SIF.is_online()
            throw new Error("Structural Integrity Fields are offlne.
                Safety protocols prevent acceleration.")

        if not 0 <= bearing <= 1
            throw new Error "Illegal bearing #{bearing}"

        @_clear_rotation()
        @_navigation_lock = true

        # Stop moving
        initial_impulse = @impulse
        initial_warp = @warp_speed
        @_set_impulse 0

        # Calculate new bearing
        new_bearing = ( bearing + @bearing.bearing ) % 1
        new_mark = ( mark + @bearing.mark ) % 1
        if new_mark < 0
            new_mark += 1

        # Calculate the duration of the turn
        turn_direction = C.COUNTERCLOCKWISE
        turn_distance = bearing
        if bearing > 0.5
            turn_direction = C.CLOCKWISE
            turn_distance = 1 - bearing
        duration = C.TIME_FOR_FULL_ROTATION * turn_distance

        # Do this in a timeout
        set_course_and_speed = =>
            @bearing =
                bearing: new_bearing
                mark: new_mark

            if initial_impulse > 0
                @_set_impulse initial_impulse
            if initial_warp > 0
                @_set_warp initial_warp
            @_navigation_lock = false

            if callback?
                callback()

        setTimeout set_course_and_speed, duration

        # message out to the ship
        r =
            turn_direction: turn_direction
            turn_duration: duration
            turn_distance: turn_distance


    _set_abs_course: (heading, callback) =>
        course = U.abs2rel_bearing @, heading, 9
        @_set_course course.bearing, course.mark, callback


    set_impulse: ( impulse_speed, callback ) ->
        if @_navigation_lock
            throw new Error "Unable to set impulse while navigational computer
            is manuvering"
        @_log_navigation_action "Setting impulse: #{ impulse_speed }"
        @_set_impulse impulse_speed, callback


    _set_impulse: ( impulse_speed, callback ) ->
        @_clear_rotation()

        # set impulse between 0 and 1, and calculate new velocity
        # TODO: make this gradual
        if not @inertial_dampener.is_online()
            throw new Error("internal Dampener offline. Safety protocols
                prevent acceleration.")

        if not @primary_SIF.is_online() or not @secondary_SIF.is_online()
            throw new Error("Structural Integrity Fields are offlne.
                Safety protocols prevent acceleration.")

        if not U.isNumber(impulse_speed)
            throw new Error('Impulse requires a float')

        if not @impulse_drive.online
            throw new Error('Impulse drive offline')

        @warp_speed = 0
        i = @impulse_drive
        delta = Math.abs( impulse_speed - @impulse )
        @impulse = impulse_speed
        rotation = @bearing.bearing * Math.PI * 2
        @velocity.x = Math.cos( rotation ) * @impulse * C.IMPULSE_SPEED
        @velocity.y = Math.sin( rotation ) * @impulse * C.IMPULSE_SPEED
        @power_debt += delta * i.burst_power

        if callback?
            callback()

        return @impulse


    set_warp: (warp_speed, callback) =>
        if @_navigation_lock
            throw new Error "Unable to set warp while navigational computer is
            manuvering"

        @_log_navigation_action "Setting warp speed: #{ warp_speed }"
        @_set_warp warp_speed, callback


    _set_warp: (warp_speed, callback) =>
        @_clear_rotation()

        if not U.isNumber( warp_speed )
            throw new Error 'Warp requires a Number'

        if not @warp_core.is_online()
            throw new Error 'Warp drive offline'

        if not @starboard_warp_coil.is_online()
            throw new Error 'Starboard warp coil is offline'

        if not @port_warp_coil.is_online()
            throw new Error 'Port warp coil is offline'

        if not @inertial_dampener.is_online() and @warp_speed isnt warp_speed
            throw new Error 'Inertial dampener is offline; cannot change velocity'

        if not (@primary_SIF.is_online() or @secondary_SIF.is_online()) and \
        @warp_speed isnt warp_speed
            throw new Error 'Structural Integrity Field offline; cannot change velocity'

        if not @navigational_deflectors.is_online()
            throw new Error "Navigational deflectors are offline.
                It is unsafe to go to warp."

        if warp_speed > WarpSystem.MAX_WARP
            throw new Error "Cannot exceed warp #{ WarpSystem.MAX_WARP }"

        if warp_speed < 1
            throw new Error "Minimum warp velocity is warp 1.0"

        # TODO: Check if the available power to the nacels is sufficient
        # to achieve this warp. If not, route the required power.

        @impulse = 0
        @warp_speed = warp_speed
        rotation = @bearing.bearing * Math.PI * 2
        # The famous trek warp speed calculation
        warp_v = Math.pow( @warp_speed, 10/3 ) * WarpSystem.MAX_WARP
        @velocity.x = Math.cos( rotation ) * warp_v
        @velocity.y = Math.sin( rotation ) * warp_v

        if callback?
            callback()

        #TODO: power management
        return @warp_speed


    _clear_rotation: () ->
        @bearing_v = { bearing: 0, mark: 0 }


    _log_navigation_action: ( entry ) ->

        @navigation_log.log entry

        do @navigation_log.length


    ### Operations
    _________________________________________________###


    assign_repair_crews: (system_name, team_count, to_completion=false) ->

        system = ( s for s in @systems when s.name == system_name )[0]
        if not system
            throw new Error "Invalid system name #{system_name}"

        teams = ( c for c in @repair_teams when not c.currently_repairing )
        if teams.length < team_count
            throw new Error "Insufficient free teams: asked for #{team_count}, only #{teams.length} available"

        damage = system.damage_report()
        if not @_check_cargo_inventory damage.repair_requirements
            throw new Error "Insufficient materials"

        @_consume_cargo_inventory damage.repair_requirements
        team.repair( system, to_completion ) for team in teams[0...team_count]


    send_team_to_deck: ( crew_id, to_deck, to_section ) ->

        team = ( t for t in @internal_personnel when t.id is crew_id )[0]
        if not team
            throw new Error "Team not found #{ crew_id }. To #{ to_deck }, #{ to_section }."

        if team.deck is to_deck and team.section is to_section
            return

        team.goto to_deck, to_section
        r = "Team enroute"


    get_postfix_code: ( prefix ) ->

        if prefix == @prefix_code
            return @postfix_code

        # If that was an invalid prefix code, then we want to return a random one
        return  Math.round( Math.random() * 10e16 ).toString(16) + Math.round( Math.random() * 10e16 ).toString(16)


    get_cargo_status: () ->

        r = {}
        for cb in @cargobays
            r[ cb.number ] = cb.inventory
        return r


    get_cargo_bay: ( number ) ->

        c = ( c for c in @cargobays when c.number is number )[0]


    get_internal_lifesigns_scan: () ->

        crew = ( team for team in @internal_personnel )


    get_systems_layout: () ->

        systems = ( s.layout() for s in @systems )


    get_decks: () ->

        decks = ( dv for dk, dv of DECKS )


    get_sections: () ->

        sections = ( sv for sk, sv of SECTIONS )


    get_bay_with_capacity: ( qty ) ->

        bays = ( c for c in @cargobays when c.remaining_capacity > qty )
        if bays.length == 0
            throw new Error "No bay with capacity"

        bays[0].number


    transport_cargo: ( origin, origin_bay_number, destination, destination_bay_number, cargo, quantity ) ->

        origin_bay = origin.get_cargo_bay origin_bay_number
        destination_bay = destination.get_cargo_bay destination_bay_number

        @transporters.beam_cargo origin, destination, origin_bay, destination_bay, cargo, quantity


    transport_crew: ( crew_id, source, source_deck, source_section, target, target_deck, target_section ) ->

        if not source is @ && not target is @
            throw new Error "Either origin or destination must be the ship."

        if target is @ and target_deck is undefined or target_section is undefined
            target_deck = @transporters.deck
            target_section = @transporters.section

        if source is @ and source_deck is undefined or target_section is undefined
            source_deck = @transporters.deck
            source_section = @transporters.section

        @transporters.beam_crew(
            crew_id, source, source_deck, source_section,
            target, target_deck, target_section)


    beam_away_crew: ( crew_id, deck, section ) ->

        # Called when personnel are being beamed away.
        if @_are_all_shields_up()
            throw new Error 'Shields are up. No transport possible'

        teams = ( t for t in @internal_personnel when t.id is crew_id )
        if teams.length == 0
            console.log @internal_personnel
            throw new Error "No such team at that location: #{ @name } #{deck} #{section}"

        @_remove_crew crew_id
        do @_rebuild_crew_checks

        team = teams[ 0 ]


    beam_onboard_crew: ( crew, deck, section ) ->

        # Called when personnel are being beamed onboard.
        if @_are_all_shields_up()
            throw new Error 'Shields are up. No transport possible'

        crew.deck = deck
        crew.section = section

        if crew.assignment is @.name
            @_board_crew crew
        else
            if crew.alignment isnt @.alignment
                # TODO: Intruder alert
                @boarding_parties.push crew
            else
                @guests.push crew

        do @_rebuild_crew_checks


    transportable: ( ignore_shield=false ) ->

        if not ignore_shield
            if @_are_all_shields_up()
                return false

        t =
            name: @name
            crew: ( c.scan() for c in @internal_personnel when c.is_onboard() )
            cargo: @get_cargo_status()
            decks: DECKS
            sections: SECTIONS


    crew_ready_to_transport: () ->

        crew = ( c for c in @internal_personnel \
            when c.deck == @transporters.deck \
            and c.section == @transporters.section )


    _disembark: ( assignment, deck, section ) ->

        matching_teams = (p for p in @boarding_parties \
            when p.origin_party.assigned is assignment \
            and p.deck is deck \
            and p.section is section)
        if matching_teams.length == 0
            throw new Error('No such team onbard')
        team = matching_teams[0]
        @boarding_parties = (p for p in @boarding_parties when p isnt team)
        @_rebuild_crew_checks()
        team.origin_party


    _remove_crew: ( id ) ->

        @repair_teams = ( t for t in @repair_teams when t.id isnt id )
        @science_teams = ( t for t in @science_teams when t.id isnt id )
        @engineering_teams = ( t for t in @engineering_teams when t.id isnt id )
        @security_teams = ( t for t in @security_teams when t.id isnt id )
        @prisoners = ( t for t in @prisoners when t.id isnt id )
        @boarding_parties = ( b for b in @boarding_parties when b.id isnt id )
        @guests = ( t for t in @guests when t.id isnt id )
        do @_rebuild_crew_checks


    _board_crew: ( crew ) ->

        # Assigned crew is coming aboard
        switch crew.description
            when "Repair Team" then @repair_teams.push crew
            when "Science Team" then @science_teams.push crew
            when "Engineering Team" then @engineering_teams.push crew
            when "Security Team" then @security_teams.push crew


    _rebuild_crew_checks: () ->

        # Remove the dead
        @repair_teams = ( r for r in @repair_teams when do r.is_alive )
        @security_teams = ( s for s in @security_teams when do s.is_alive )
        @science_teams = ( s for s in @science_teams when do s.is_alive )
        @engineering_teams = ( e for e in @engineering_teams when do e.is_alive )
        @medical_teams = (m for m in @medical_teams when do m.is_alive )

        @crew = [].concat(
            @repair_teams ).concat(
            @security_teams ).concat(
            @science_teams ).concat(
            @engineering_teams ).concat(
            @medical_teams )

        @boarding_parties = ( b for b in @boarding_parties when do b.is_alive )
        @prisoners = ( p for p in @prisoners when do p.is_alive )
        @guests = ( g for g in @guests when do g.is_alive )

        @internal_personnel = [].concat(
            @crew ).concat(
            @boarding_parties ).concat(
            @guests ).concat(
            @prisoners )


    _consume_cargo_inventory: ( materials ) ->

        for requirement in materials
            need = requirement.quantity
            for bay in @cargobays
                need -= bay.consume_cargo requirement.material, need


    _check_cargo_inventory: ( materials ) ->

        for requirement in materials
            count = 0
            count += c.inventory_count requirement.material for c in @cargobays
            if count < requirement.quantity
                return false
        return true


    ### Science
    _________________________________________________###


    scan_object: ( target ) ->

        # see if object is in range
        if not U.in_range target.position, @position, C.SYSTEM_SCAN_RANGE
            d = U.distance target.position, @position
            throw new Error "Target out of range #{d}"

        # see if sensors are online
        quad = @calculate_quadrant target.position
        sensors = ( s for s in @sensors when s.section == quad )[0]
        if not sensors.is_online()
            throw new Error "Required sensor grid offlne."

        # get the object's status
        r =
            timeout: C.SYSYEM_SCAN_DURATION
            result: target.get_system_scan()


    add_scanned_object: ( target ) ->

        # Add a given target to the array of objects we have completed
        # a detailed scan of. Required for transporters, and advanced
        # weapons targetting
        @_logged_scanned_items.push target


    get_scanned_objects: () ->

        # Return all of the items we've scanned and are tracking
        @_logged_scanned_items


    get_system_scan: () ->
        r =
            systems: @damage_report()
            cargo: @get_cargo_status()
            lifesigns: ( c.members.length for c in @internal_personnel ).reduce ( x, y ) -> x+y
            # Eventually, power readings will be used to profile a ship
            # for now, let's simply return the power output to the nacels
            # which is feasably measured
            power_readings: [
                    @port_warp_coil.warp_field_output(),
                    @starboard_warp_coil.warp_field_output(),
                    @warp_core.field_output(),
                    @impulse_reactors.field_output(),
                    @emergency_power.field_output()
                ]
            mesh: @model_url
            name: @name
            mesh_scale: @model_display_scale
            registry: @serial
            hull: @hull
            name: @name
            shields: @shield_report()

        # TODO: Do we have shielding? Radiation leaks? Radioactive cargo?
        if @_are_all_shields_up()
            delete r.systems
            delete r.cargo
            delete r.lifesigns

        return r


    get_scan_configuration: ( type ) ->

        # We take the forward scanner to be the authortative settings source
        fwd_config = @forward_sensors.get_configuration type
        port_config = @port_sensors.get_configuration type
        starboard_config = @starboard_sensors.get_configuration type
        aft_config = @aft_sensors.get_configuration type

        ettcs = [
            fwd_config.ettc
            port_config.ettc
            starboard_config.ettc
            aft_config.ettc
        ]
        max_ettc = Math.max.apply null, ettcs

        time_estimates = [
            fwd_config.time_estimate
            port_config.time_estimate
            aft_config.time_estimate
            starboard_config.time_estimate
        ]
        max_time_estimate = Math.max.apply null, time_estimates

        grids = [].concat(fwd_config.grids).concat(port_config.grids).concat(
            starboard_config.grids).concat(aft_config.grids)

        r =
            grids: grids
            resolution: fwd_config.resolution
            range: fwd_config.range
            ettc: max_ettc
            time_estimate: max_time_estimate


    get_long_range_scan_configuration: ( type ) ->

        lr_config = @long_range_sensors.get_configuration type

        r =
            grids: lr_config.grids
            resolution: lr_config.resolution
            range: lr_config.range
            ettc: lr_config.ettc
            time_estimate: lr_config.time_estimate


    run_scan: ( world_scan, type, grid_start, grid_end, positive_sweep, range, resolution ) ->

        if resolution < 4
            throw new Error "Short range sensors have a minimum resolution of 4."

        valid_grids = [0...SensorSystem.MAX_SLICES]
        if grid_start not in valid_grids or grid_end not in valid_grids
            throw new Error "Invalid scan ranges: #{ grid_start }, #{ grid_end }"
        # queue up the responsible scanners, per bearing
        # NB scanners take absolute bearings as arguments

        # Break the sections of the bearing to scan into segments
        # so that each can be checked for scan range
        first_segment = [Math.min(grid_start, grid_end)..Math.max(grid_start, grid_end)]
        crossing_reverse_scan = grid_end > grid_start and not positive_sweep
        crossing_lapping_scan = grid_end < grid_start and positive_sweep
        second_segment = undefined

        if crossing_reverse_scan
            first_segment = [0...grid_start]
            second_segment = [grid_end...SensorSystem.MAX_SLICES]

        if crossing_lapping_scan
            first_segment = [0...grid_end]
            second_segment = [grid_start...SensorSystem.MAX_SLICES]

        # forward sensors (0.875 > 0.125)
        forward_segments = @_calculate_scan_segment(
           [0...8].concat( [56...64] ),
           first_segment,
           second_segment )

        # port sensors (0.125, 0.375)
        port_segments = @_calculate_scan_segment(
            [8...24],
            first_segment,
            second_segment )

        # aft sensors (0.375 > 0.625)
        aft_segments = @_calculate_scan_segment(
            [24...40],
            first_segment,
            second_segment )

        # starboard sensors (0.625 > 0.875)
        starboard_segments = @_calculate_scan_segment(
            [40...56],
            first_segment,
            second_segment )

        b = @bearing.bearing

        @forward_sensors.configure_scan type, b, forward_segments, range, resolution
        @port_sensors.configure_scan type, b, port_segments, range, resolution
        @starboard_sensors.configure_scan type, b, starboard_segments, range, resolution
        @aft_sensors.configure_scan type, b, aft_segments, range, resolution

        t1 = @forward_sensors.scan world_scan, @position, b, type
        t2 = @port_sensors.scan world_scan, @position, b, type
        t3 = @aft_sensors.scan world_scan, @position, b, type
        t4 = @starboard_sensors.scan world_scan, @position, b, type

        Math.max t1, t2, t3, t4


    _calculate_scan_segment: ( scanner_segments, first_segment, second_segment ) ->

        union = (i for i in scanner_segments when i in first_segment)
        if second_segment?
            second_union = [i for i in scanner_segments when i in second_segment]
            union.concat second_union

        return union


    run_long_range_scan: (world_scan, type, bearing_from, bearing_to, positive_sweep, range_level, resolution) ->

        if not @long_range_sensors.is_online()
            throw new Error("Long-Range Sensors are offline")
        # NB scanners take absolute bearings as arguments
        abs_bearing_from = (bearing_from + @bearing.bearing) % 1
        abs_bearing_to = (bearing_to + @bearing.bearing) % 1
        @long_range_sensors.scan(world_scan, type, abs_bearing_from,
            abs_bearing_to, positive_sweep, range_level, resolution)


    get_scan_results: ( type ) ->

        # recombine the readings from all sensor grids
        composite_scan = []
        classifications = []
        B = @bearing.bearing
        p = @position

        for sys in @sensors
            results = sys.readings type, B, p

            # readings
            readings = results.results
            read_outs = results.readOut
            for bucket in readings
                existing_buckets = ( b for b in composite_scan when b.start == bucket.start and b.end == bucket.end )
                if existing_buckets.length == 0
                    composite_scan.push bucket
                else
                    existing_buckets[0].reading += bucket.reading

            # classifications
            classifications = classifications.concat results.classifications

            # spectra

        r =
            results: composite_scan,
            classifications: classifications
            spectra: []


    get_long_range_scan_results: ( type ) ->

        @long_range_sensors.readings type, @bearing.bearing


    get_internal_scan: () ->

        r =
            alerts:
                radiation: @radiological_alerts
                atmosphere: []
            mesh: @model_url
            meshScale: @model_display_scale



    ### Engineering
    _________________________________________________###


    power_distribution_report: () ->

        r =
            reactors: ( reactor.power_distribution_report() for reactor in @reactors )
            primary_relays: ( relay.power_distribution_report() for relay in @primary_power_relays )
            eps_relays: ( eps.power_distribution_report() for eps in @eps_grids )


    set_power_to_system: ( system_name, pct ) ->

        # Calculates the new system power balance, and the new required
        # power levels for that system. Dials up or down reactor
        # appropriately.
        system = ( s for s in @systems when s.name == system_name )[0]
        if not system?
            throw new Error "Unable to locate system #{system_name}"

        { min_power_level, max_power_level, power,
            current_power_level, operational_dynes } = system.power_report()

        dyn = operational_dynes

        delta_power_pct = pct - current_power_level
        delta_power = delta_power_pct * dyn

        parent_eps_relays = ( r for r in @eps_grids when r.is_attached system )
        if parent_eps_relays.length > 0
            parent_eps_relay = parent_eps_relays[0]

        primary_power_relays = ( r for r in @primary_power_relays when r.is_attached( system ) or r.is_attached( parent_eps_relay ) )
        if primary_power_relays.length isnt 1
            throw new Error "Unable to trace primary power relay for
                #{system_name}"
        primary_power_relay = primary_power_relays[0]

        reactors = ( r for r in @reactors when r.is_attached primary_power_relay )
        if reactors.length isnt 1
            throw new Error("Unable to trace reactor power for
                #{primary_power_relay.name}")
        reactor = reactors[0]

        if parent_eps_relay?
            new_eps_balance = parent_eps_relay.calculate_new_balance(
                system, delta_power )
            new_primary_balance = primary_power_relay.calculate_new_balance(
                parent_eps_relay, delta_power )
        else
            new_primary_balance = primary_power_relay.calculate_new_balance(
                system, delta_power )

        # If it's an increase in power, we need to set the new balance first
        # Else we need to dial down the power first

        set_new_balance = ->
            if parent_eps_relay?
                parent_eps_relay.set_system_balance new_eps_balance
            primary_power_relay.set_system_balance new_primary_balance

        power_reactor = ->
            new_level = reactor.calculate_level_for_additional_output delta_power
            if not new_level? or isNaN new_level
                throw new Error "Reactor failed to calculate power requirement
                    for #{system_name} to #{pct}, (#{delta_power})"

            reactor.activate new_level

        if delta_power > 0
            do set_new_balance
            do power_reactor
        else
            do power_reactor
            do set_new_balance


    set_power_to_reactor: ( reactor_name, level ) ->

        reactor = ( r for r in @reactors when r.name == reactor_name )[0]
        if not reactor?
            throw new Error "Invalid reactor name #{reactor_name}, level: #{level}"
        reactor.activate level


    reroute_power_relay: ( eps_relay_name, primary_relay_name ) ->

        eps_relay = ( r for r in @eps_grids when r.name == eps_relay_name )[0]
        if not eps_relay?
            throw new Error "Invalid eps relay name #{eps_relay}"
        primary_relay = ( r for r in @primary_power_relays when r.name == primary_relay_name )[0]
        if not primary_relay?
            throw new Error "Invalid primary relay name #{primary_relay}"
        current_system = ( r for r in @primary_power_relays when r.is_attached eps_relay )[0]
        current_system.remove_route eps_relay
        primary_relay.add_route eps_relay
        reply = "#{eps_relay_name} rerouted to #{primary_relay_name}"


    set_online: ( system_name, is_online ) ->

        system = ( s for s in @systems when s.name == system_name )[0]
        if not system?
            throw new Error "Invalid system name #{system_name}"
        if is_online
            system.bring_online()
        else
            system.deactivate()


    set_active: ( system_name, is_active ) ->

        system = ( s for s in @systems when s.name == system_name )[0]
        if not system?
            throw new Error "Invalid system name #{system_name}"

        if is_active
            do system.power_on
        else
            do system.power_down


    ### Misc.
    _________________________________________________###


    enter_captains_log: ( entry ) ->

        @captains_log.log entry


    get_pending_captains_logs: () ->

        do @captains_log.pending_logs


    get_lifesigns: () ->

        r = @internal_personnel


    set_viewscreen_target: ( target_name ) ->

        @_viewscreen_target = target_name


    _check_if_still_alive: () ->

        # You die when structural integrity collapses.
        # If SIFs are down and you warp, change speed, or get hit
        #   with weapons fire, then the ship disintegrates.
        # A large enough explosion will overwhelm the SFIs as well.
        # @callback(@prefix_code, 'destruct')
        @alive


    calculate_quadrant: ( from_point ) ->

        if from_point == @position
            from_point.x += 1
        b = U.bearing(
                {position: @position, bearing: @bearing},
                {position:from_point}
        )
        if not b?
            throw new Error "Invalid origin point #{from_point}"

        quadrant = @calculate_quadrant_from_bearing b


    calculate_quadrants: ( from_point ) ->
        # Returns the two visible quadrants from a point, as opposed to
        # calculate quadrant, which just returns the immediate facing
        # section

        if from_point == @position
            from_point.x += 1
        b = U.bearing(
            { position: @position, bearing: @bearing },
            { position: from_point }
        )
        if not b?
            throw new Error "Invalid origin point #{from_point}"

        if 0 < b.bearing <= 0.25
            return [ SECTIONS.FORWARD, SECTIONS.PORT ]
        if 0.25 < b.bearing <= 0.5
            return [ SECTIONS.PORT, SECTIONS.AFT ]
        if 0.5 < b.bearing <= 0.75
            return [ SECTIONS.AFT, SECTIONS.STARBOARD ]
        if 0.75 < b.bearing <= 1
            return [ SECTIONS.STARBOARD, SECTIONS.FORWARD ]


    calculate_quadrant_from_bearing: ( b ) ->

        quadrant = switch
            when (b.bearing < 0.125 or b.bearing >= 0.875) then SECTIONS.FORWARD
            when (0.125 <= b.bearing < 0.375) then SECTIONS.PORT
            when (0.375 <= b.bearing < 0.625) then SECTIONS.AFT
            when (0.625 <= b.bearing < 0.875) then SECTIONS.STARBOARD


    calculate_impulse: () ->

        x2 = Math.pow @velocity.x, 2
        y2 = Math.pow @velocity.y, 2
        z2 = Math.pow @velocity.z, 2
        return Math.sqrt( x2 + y2 + z2 )


    clear_ships: ( ship_prefix ) ->

        if @weapons_target.prefix_code == ship_prefix
            @weapons_target = null


    _are_all_shields_up: () ->

        for s in @shields
            if not s.active
                return false
        return true


    _set_operational_reactor_settings: () ->

        for reactor in @reactors
            reactor.set_required_output_power()


    ### Time Progression
    ________________________________________________________###

    calculate_state: ( world_scan, delta ) ->

        now = new Date().getTime()
        if not delta?
            delta = now - @state_stamp
        @state_stamp = now

        @_calculate_motion delta
        @_calculate_environment delta
        @_update_system_state delta

        if world_scan isnt undefined
            @_update_scanners world_scan, now


    _calculate_motion: ( delta_t ) ->

        @position.x += @velocity.x * delta_t
        @position.y += @velocity.y * delta_t

        @bearing.bearing += @bearing_v.bearing * delta_t
        @bearing.mark += @bearing_v.mark * delta_t

        if @bearing.bearing > 1
            @bearing.bearing = @bearing.bearing % 1

        if @bearing.bearing < 0
            @bearing.bearing += 1

        if @bearing_v.bearing != 0
            @message @prefix_code, "Turning", @navigation_report()


    _calculate_environment: ( delta_t ) ->

        # skip if the environmental_conditions haven't been
        # initialized
        if not @environmental_conditions?
            return

        # check the current environment levels
        for reading in @environmental_conditions
            switch reading.parameter
                when C.ENVIRONMENT.RADIATION
                    @_process_radiation reading.readout * delta_t

        ## partical density signals to the nav computer to stop warp
        ## subspace warping signals to the nav computer to stop warp


    _update_system_state: ( delta_t ) -> s.update_system( delta_t ) for s in @systems


    _update_scanners: ( world_scan, now ) ->

        # Scanners are meaningless at warp speeds
        if @warp_speed == 0
            for s in @sensors
                s.run_scans world_scan, @position, @bearing.bearing, now

        @long_range_sensors.run_scans world_scan, @position, @bearing.bearing, now


exports.Ship = Ship

