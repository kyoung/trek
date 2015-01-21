{BaseShip} = require './BaseShip'

{System, ChargedSystem} = require '../BaseSystem'
{Transporters} = require '../systems/TransporterSystems'
{ShieldSystem, PhaserSystem, TorpedoSystem, WeaponsTargetingSystem} = require '../systems/WeaponSystems'
{WarpSystem} = require '../systems/WarpSystems'
{ReactorSystem, PowerSystem} = require '../systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require '../systems/SensorSystems'
{SIFSystem} = require '../systems/SIFSystems'
{Torpedo} = require '../Torpedo'
{CommunicationsSystems} = require '../systems/CommunicationSystems'
{BridgeSystem} = require '../systems/BridgeSystem'
{BaseObject} = require '../BaseObject'
{CargoBay} = require '../CargoBay'
{Log} = require '../Log'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../Crew'

C = require '../Constants'

SECTIONS =
    PORT: 'Port'
    STARBOARD: 'Starboard'
    FORWARD: 'Forward'
    AFT: 'Aft'

# DECK A..R
DECKS = {}
for deck_number in [65..85]
    deck_letter = String.fromCharCode deck_number
    DECKS[deck_letter] = deck_letter


class Constitution extends BaseShip

    SECTIONS: SECTIONS
    DECKS: DECKS

    @REGISTRY = [
        { name : "Ahwahnee", registry : "2048" }
        { name : "Eagle", registry : "956" }
        { name : "Emden", registry : "1856" }
        { name : "Endeavour", registry : "1895" }
        { name : "Excalibur", registry : "1664" }
        { name : "Exeter", registry : "1672" }
        { name : "Hood", registry : "1703" }
        { name : "Korolev", registry : "2014" }
        { name : "Lexington", registry : "1709" }
        { name : "Potemkin", registry : "1657" }
        { name : "Merrimac", registry : "1715" }
        { name : "Kongo", registry : "1710" }
        { name : "Enterprise", registry : "1701-A" }
    ]


    @get_ship_name: ->

        if @REGISTRY.length is 0
            # Start making up dummy names, as this is probably a test
            n = Math.floor( 1e3 * do Math.random )
            return { name : "Zulu", registry : "X-#{ n }" }

        coin = Math.floor( @REGISTRY.length * do Math.random )
        ship_details = @REGISTRY[ coin ]
        @REGISTRY.splice coin, 1
        return ship_details


    @launch_ship: ( name, serial ) ->

        ship_record = ( i for i in @REGISTRY when i.name is name )[ 0 ]
        if not ship_record?
            return
        idx = @REGISTRY.indexOf ship_record
        @REGISTRY.splice idx, 1


    constructor: ( @name, @serial="" ) ->

        if @name?
            Constitution.launch_ship @name
        else
            # Choose a random name to go with
            { name, registry } = do Constitution.get_ship_name
            @name = name
            @serial = registry

        super @name, @serial
        @model_url = "constitution.js"
        @model_display_scale = 5
        @ship_class = "Constitution"


    initialize_systems: ->

        do @initialize_shileds
        do @initialize_weapons
        do @initialize_sensors
        do @initialize_power_systems

        message = @message
        prefix = @prefix_code
        bridge_message_interface = ( type, msg ) ->
            message prefix, type, msg

        @bridge = new BridgeSystem(
            'Bridge',
            @DECKS.A,
            @SECTIONS.FORWARD,
            bridge_message_interface )

        # Forward Sensors, Deck B
        @lifesupport = new System(
            'Lifesupport',
            @DECKS.B,
            @SECTIONS.PORT,
            System.LIFESUPPORT_POWER )

        @port_warp_coil = new WarpSystem(
            'Port Warp Coil',
            @DECKS.C,
            @SECTIONS.PORT )

        @starboard_warp_coil = new WarpSystem(
            'Starboard Warp Coil',
            @DECKS.C,
            @SECTIONS.STARBOARD )

        # Forward Phasers, Deck D
        @transponder = new System(
            'Transponder',
            @DECKS.C,
            @SECTIONS.FORWARD,
            System.TRANSPONDER_POWER )
        # Forward Shield Emitter, Deck E
        @impulse_drive = new System(
            'Impulse Drive',
            @DECKS.F,
            @SECTIONS.AFT,
            System.IMPULSE_POWER )

        @primary_SIF = new SIFSystem(
            'Primary SIF',
            @DECKS.F,
            @SECTIONS.STARBOARD )

        @transporters = new Transporters(
            'Transporters',
            @DECKS.G,
            @SECTIONS.AFT )

        @brig = new System(
            'Brig',
            @DECKS.G,
            @SECTIONS.STARBOARD,
            System.BRIG_POWER )

        @sick_bay = new System(
            'Sick Bay',
            @DECKS.G,
            @SECTIONS.PORT,
            System.SICKBAY_POWER )

        # Forward Phasers, Deck H
        @weapons_targeting = new WeaponsTargetingSystem(
            'Weapons Targeting',
            @DECKS.H,
            @SECTIONS.FORWARD )

        @communication_array = new CommunicationsSystems(
            'Communications',
            @DECKS.J,
            @SECTIONS.AFT )

        # Port and Starboard Sensors, Deck J
        @inertial_dampener = new System(
            'Inertial Dampener',
            @DECKS.K,
            @SECTIONS.AFT,
            System.DAMPENER_POWER )

        # Torpedo tubes, Deck L
        # Torpedo tubes, Deck M
        # Aft Phasers, Deck N
        @secondary_SIF = new SIFSystem(
            'Secondary SIF',
            @DECKS.N,
            @SECTIONS.FORWARD,
            true )

        # Port and Starboard Phasers, Deck P
        @tractor_beam = new System(
            'Tractor Beam',
            @DECKS.U,
            @SECTIONS.AFT,
            System.TRACTOR_POWER )

        # Port, Starboard, and Aft shield emitters are on Deck R
        @navigational_deflectors = new ShieldSystem(
            'Navigational Deflectors',
            @DECKS.R,
            @SECTIONS.FORWARD,
            ShieldSystem.NAVIGATION_POWER )

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
            @bridge
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
        @forward_eps.add_route @bridge

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
            @DECKS.E,
            @SECTIONS.AFT,
            PowerSystem.IMPULSE_RELAY_POWER )

        @e_power_relay = new PowerSystem(
            'Emergency Relays',
            @DECKS.Q,
            @SECTIONS.PORT,
            PowerSystem.EMEGENCY_RELAY_POWER )

        @warp_relay = new PowerSystem(
            'Plasma Relay Conduits',
            @DECKS.P,
            @SECTIONS.AFT,
            PowerSystem.WARP_RELAY_POWER )

        @impulse_reactors = new ReactorSystem(
            'Impulse Reactors',
            @DECKS.D,
            @SECTIONS.AFT,
            ReactorSystem.FUSION,
            @impulse_relay,
            ReactorSystem.FUSION_SIGNATURE )

        @emergency_power = new ReactorSystem(
            'Emergency Power',
            @DECKS.T,
            @SECTIONS.PORT,
            ReactorSystem.BATTERY,
            @e_power_relay,
            ReactorSystem.BATTERY_SIGNATURE )

        @warp_core = new ReactorSystem(
            'Warp Core',
            @DECKS.O,
            @SECTIONS.FORWARD,
            ReactorSystem.ANTIMATTER,
            @warp_relay,
            ReactorSystem.ANTIMATTER_SIGNATURE )

        # EPS Grids
        @forward_eps = new PowerSystem(
            'Forward EPS',
            @DECKS.G,
            @SECTIONS.FORWARD,
            PowerSystem.EPS_RELAY_POWER )

        # All secondary hull systems (IE below deck J)
        @aft_eps = new PowerSystem(
            'Aft EPS',
            @DECKS.Q,
            @SECTIONS.AFT,
            PowerSystem.EPS_RELAY_POWER )

        @port_eps = new PowerSystem(
            'Port EPS',
            @DECKS.E,
            @SECTIONS.PORT,
            PowerSystem.EPS_RELAY_POWER )

        @starboard_eps = new PowerSystem(
            'Starboard EPS',
            @DECKS.E,
            @SECTIONS.STARBOARD,
            PowerSystem.EPS_RELAY_POWER )

        @primary_power_relays = [
            @impulse_relay
            @e_power_relay
            @warp_relay ]

        @eps_grids = [
            @forward_eps
            @port_eps
            @starboard_eps
            @aft_eps ]

        @reactors = [
            @impulse_reactors
            @emergency_power
            @warp_core ]

        @power_systems = [].concat(
            @primary_power_relays ).concat(
            @eps_grids ).concat(
            @reactors )


    initialize_shileds: ->

        @port_shields = new ShieldSystem(
            'Port Shields',
            @DECKS.R,
            @SECTIONS.PORT )

        @starboard_shields = new ShieldSystem(
            'Starboard Shields',
            @DECKS.R,
            @SECTIONS.STARBOARD )

        @aft_shields = new ShieldSystem(
            'Aft Shields',
            @DECKS.R,
            @SECTIONS.AFT )

        @forward_shields = new ShieldSystem(
            'Forward Shields',
            @DECKS.E,
            @SECTIONS.FORWARD )

        @shields = [
            @port_shields
            @starboard_shields
            @aft_shields
            @forward_shields ]


    initialize_weapons: ->

        @forward_phaser_bank_a = new PhaserSystem(
            'Dorsal Phaser Bank',
            @DECKS.D,
            @SECTIONS.FORWARD )

        @forward_phaser_bank_b = new PhaserSystem(
            'Ventral Phaser Bank',
            @DECKS.I,
            @SECTIONS.FORWARD )

        @port_phaser_bank = new PhaserSystem(
            'Port Phaser Bank',
            @DECKS.P,
            @SECTIONS.PORT )

        @starboard_phaser_bank = new PhaserSystem(
            'Starboard Phaser Bank',
            @DECKS.P,
            @SECTIONS.STARBOARD )

        @aft_phaser_bank = new PhaserSystem(
            'Aft Phaser Bank',
            @DECKS.N,
            @SECTIONS.AFT )

        @phasers = [
            @forward_phaser_bank_a
            @forward_phaser_bank_b
            @port_phaser_bank
            @starboard_phaser_bank
            @aft_phaser_bank ]

        @torpedo_bank_1 = new TorpedoSystem(
            'Torpedo Bay 1',
            @DECKS.L,
            @SECTIONS.STARBOARD,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_bank_2 = new TorpedoSystem(
            'Torpedo Bay 2',
            @DECKS.L,
            @SECTIONS.PORT,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_bank_3 = new TorpedoSystem(
            'Torpedo Bay 3',
            @DECKS.M,
            @SECTIONS.STARBOARD,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_bank_4 = new TorpedoSystem(
            'Torpedo Bay 4',
            @DECKS.M,
            @SECTIONS.PORT,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_banks = [
            @torpedo_bank_1
            @torpedo_bank_2
            @torpedo_bank_3
            @torpedo_bank_4 ]


    initialize_sensors: ->

        b = @bearing.bearing

        @_logged_scanned_items = []

        forward_scan_grid = [0...8].concat( [56...64] )
        port_scan_grid = [8...24]
        aft_scan_grid = [24...40]
        starboard_scan_grid = [40...56]

        @port_sensors = new SensorSystem(
            'Port Sensor Array',
            @DECKS.J,
            @SECTIONS.PORT,
            b,
            port_scan_grid )

        @starboard_sensors = new SensorSystem(
            'Starboard Sensor Array',
            @DECKS.J,
            @SECTIONS.STARBOARD,
            b,
            starboard_scan_grid )

        @forward_sensors = new SensorSystem(
            'Forward Sensor Array',
            @DECKS.B,
            @SECTIONS.FORWARD,
            b,
            forward_scan_grid )

        @aft_sensors = new SensorSystem(
            'Aft Sensor Array',
            @DECKS.T,
            @SECTIONS.AFT,
            b,
            aft_scan_grid )

        @long_range_sensors = new LongRangeSensorSystem(
            'Long Range Sensors',
            @DECKS.Q,
            @SECTIONS.FORWARD,
            b,
            forward_scan_grid )

        @sensors = [
            @aft_sensors
            @port_sensors
            @starboard_sensors
            @forward_sensors ]


    initialize_hull: ->

        @hull = {}
        for deck, deck_letter of @DECKS
            @hull[ deck_letter ] = {}
            for section, section_string of @SECTIONS
                @hull[ deck_letter ][ section_string ] = 1


    initialize_cargo: ->

        @cargobays = []
        for i in [ 1..4 ]
            @cargobays.push( new CargoBay i )


    initialize_crew: ->

        # Repair Lockers are on Deck F, H and Q
        @repair_teams = [
            new RepairTeam @DECKS.F, @SECTIONS.STARBOARD
            new RepairTeam @DECKS.F, @SECTIONS.PORT
            new RepairTeam @DECKS.H, @SECTIONS.PORT
            new RepairTeam @DECKS.H, @SECTIONS.STARBOARD
            new RepairTeam @DECKS.Q, @SECTIONS.AFT
            new RepairTeam @DECKS.Q, @SECTIONS.AFT ]

        # Science labs are on deck G
        @science_teams = [
            new ScienceTeam @DECKS.D, @SECTIONS.PORT
            new ScienceTeam @DECKS.D, @SECTIONS.PORT
            new ScienceTeam @DECKS.D, @SECTIONS.STARBOARD
            new ScienceTeam @DECKS.D, @SECTIONS.AFT ]

        # Engineering facilities are on Decks O - T
        @engineering_teams = [
            new EngineeringTeam @DECKS.O, @SECTIONS.AFT
            new EngineeringTeam @DECKS.O, @SECTIONS.AFT
            new EngineeringTeam @DECKS.O, @SECTIONS.AFT
            new EngineeringTeam @DECKS.O, @SECTIONS.PORT
            new EngineeringTeam @DECKS.O, @SECTIONS.STARBOARD ]

        # Security Locker is on Deck G
        # Assault transporter is also on Deck G (Aft section)
        @security_teams = [
            new SecurityTeam @DECKS.G, @SECTIONS.AFT
            new SecurityTeam @DECKS.G, @SECTIONS.FORWARD
            new SecurityTeam @DECKS.G, @SECTIONS.FORWARD
            new SecurityTeam @DECKS.G, @SECTIONS.STARBOARD
            new SecurityTeam @DECKS.G, @SECTIONS.STARBOARD
            new SecurityTeam @DECKS.G, @SECTIONS.STARBOARD
            new SecurityTeam @DECKS.G, @SECTIONS.STARBOARD
            new SecurityTeam @DECKS.G, @SECTIONS.FORWARD ]

        @medical_teams = [
            new MedicalTeam @DECKS.G, @SECTIONS.PORT
            new MedicalTeam @DECKS.G, @SECTIONS.PORT
            new MedicalTeam @DECKS.G, @SECTIONS.PORT ]

        @boarding_parties = []

        s = new SecurityTeam @DECKS.G, @SECTIONS.STARBOARD
        s.set_alignment C.ALIGNMENT.PIRATES
        do s.captured
        @prisoners = [ s ]

        g = new DiplomaticTeam @DECKS.F, @SECTIONS.PORT
        g.set_alignment C.ALIGNMENT.FEDERATION
        g.set_assignment "Starfleet Diplomatic Core"
        @guests = [ g ]

        @_rebuild_crew_checks()
        c.set_assignment @name  for c in @crew


    _rebuild_crew_checks: ->

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


exports.Constitution = Constitution