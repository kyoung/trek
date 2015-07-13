{BaseShip} = require './BaseShip'

{System, ChargedSystem} = require '../BaseSystem'
{Transporters} = require '../systems/TransporterSystems'
{ShieldSystem, PhaserSystem, TorpedoSystem, WeaponsTargetingSystem, DisruptorSystem} = require '../systems/WeaponSystems'
{WarpSystem} = require '../systems/WarpSystems'
{CloakingSystem} = require '../systems/CloakingSystem'
{ReactorSystem, PowerSystem} = require '../systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require '../systems/SensorSystems'
{NavigationComputerSystem} = require '../systems/NavigationComputerSystem'
{SIFSystem} = require '../systems/SIFSystems'
{Torpedo} = require '../Torpedo'
{CommunicationsSystems} = require '../systems/CommunicationSystems'
{BridgeSystem} = require '../systems/BridgeSystems'
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
for deck_number in [1..20]
    deck_letter = do deck_number.toString
    DECKS[deck_number] = deck_letter


class D7 extends BaseShip

    SECTIONS: SECTIONS
    DECKS: DECKS

    @REGISTRY = [
        { name : "Gr`Oth", registry : "" }
        { name : "Klothos", registry : "" }
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
            D7.launch_ship @name
        else
            # Choose a random name to go with
            { name, registry } = do D7.get_ship_name
            @name = name
            @serial = registry

        super @name, @serial
        @model_url = "d7.json"
        @model_display_scale = 2.5
        @ship_class = "D7"


    initialize_systems: () ->
        do @initialize_shileds
        do @initialize_weapons
        do @initialize_sensors
        do @initialize_power_systems

        bridge_message_interface = ( type, msg ) => @message @prefix_code, type, msg

        @bridge = new BridgeSystem(
            'Bridge',
            @DECKS['1'],
            @SECTIONS.FORWARD,
            bridge_message_interface )

        @lifesupport = new System(
            'Lifesupport',
            @DECKS['5'],
            @SECTIONS.AFT,
            System.LIFESUPPORT_POWER )

        @port_warp_coil = new WarpSystem(
            'Port Warp Coil',
            @DECKS['19'],
            @SECTIONS.PORT )

        @starboard_warp_coil = new WarpSystem(
            'Starboard Warp Coil',
            @DECKS['19'],
            @SECTIONS.STARBOARD )

        @transponder = new System(
            'Transponder',
            @DECKS['10'],
            @SECTIONS.STARBOARD,
            System.TRANSPONDER_POWER )

        @impulse_drive = new System(
            'Impulse Drive',
            @DECKS['8'],
            @SECTIONS.AFT,
            System.IMPULSE_POWER )

        @primary_SIF = new SIFSystem(
            'Primary SIF',
            @DECKS['5'],
            @SECTIONS.STARBOARD )

        @transporters = new Transporters(
            'Transporters',
            @DECKS['7'],
            @SECTIONS.PORT )

        @brig = new System(
            'Brig',
            @DECKS['12'],
            @SECTIONS.STARBOARD,
            System.BRIG_POWER )

        @sick_bay = new System(
            'Sick Bay',
            @DECKS['10'],
            @SECTIONS.PORT,
            System.SICKBAY_POWER )

        @weapons_targeting = new WeaponsTargetingSystem(
            'Weapons Targeting',
            @DECKS['3'],
            @SECTIONS.AFT )

        @communication_array = new CommunicationsSystems(
            'Communications',
            @DECKS['4'],
            @SECTIONS.PORT )

        @inertial_dampener = new System(
            'Inertial Dampener',
            @DECKS['3'],
            @SECTIONS.STARBOARD,
            System.DAMPENER_POWER )

        @cloak_system = new CloakingSystem(
            'Cloaking System',
            @DECKS[ '15' ],
            @SECTIONS.PORT
        )

        @secondary_SIF = new SIFSystem(
            'Secondary SIF',
            @DECKS['5'],
            @SECTIONS.PORT,
            true )

        @tractor_beam = new System(
            'Tractor Beam',
            @DECKS['20'],
            @SECTIONS.AFT,
            System.TRACTOR_POWER )

        @navigational_deflectors = new ShieldSystem(
            'Navigational Deflectors',
            @DECKS['18'],
            @SECTIONS.FORWARD,
            ShieldSystem.NAVIGATION_POWER )

        @navigational_computer = new NavigationComputerSystem(
            'Navigational Computer',
            @DECKS['15'],
            @SECTIONS.FORWARD )

        do @initialize_power_connections

        # Turn on power
        do @_set_operational_reactor_settings

        # Activate basic systems
        do @primary_SIF.power_on
        do @secondary_SIF.power_on

        @systems = [].concat( @shields ).concat( @phasers )
        @systems = @systems.concat( @torpedo_banks ).concat( @sensors )
        @systems = @systems.concat @power_systems
        @systems = @systems.concat( [
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
            @cloak_system
        ] )


    initialize_power_systems: ->

        # Main relays
        @impulse_relay = new PowerSystem(
            'Impulse Relays',
            @DECKS['7'],
            @SECTIONS.AFT,
            PowerSystem.IMPULSE_RELAY_POWER )

        @e_power_relay = new PowerSystem(
            'Emergency Relays',
            @DECKS['18'],
            @SECTIONS.PORT,
            PowerSystem.EMEGENCY_RELAY_POWER )

        @warp_relay = new PowerSystem(
            'Plasma Relay Conduits',
            @DECKS['8'],
            @SECTIONS.AFT,
            PowerSystem.WARP_RELAY_POWER )

        @impulse_reactors = new ReactorSystem(
            'Impulse Reactors',
            @DECKS['6'],
            @SECTIONS.AFT,
            ReactorSystem.FUSION,
            @impulse_relay,
            ReactorSystem.FUSION_SIGNATURE )

        @emergency_power = new ReactorSystem(
            'Emergency Power',
            @DECKS['17'],
            @SECTIONS.PORT,
            ReactorSystem.BATTERY,
            @e_power_relay,
            ReactorSystem.BATTERY_SIGNATURE )

        @warp_core = new ReactorSystem(
            'Warp Core',
            @DECKS['9'],
            @SECTIONS.AFT
            ReactorSystem.ANTIMATTER,
            @warp_relay,
            ReactorSystem.ANTIMATTER_SIGNATURE )

        # EPS Grids
        @forward_eps = new PowerSystem(
            'Forward EPS',
            @DECKS['7'],
            @SECTIONS.FORWARD,
            PowerSystem.EPS_RELAY_POWER )

        # All secondary hull systems (IE below deck J)
        @aft_eps = new PowerSystem(
            'Aft EPS',
            @DECKS['12'],
            @SECTIONS.AFT,
            PowerSystem.EPS_RELAY_POWER )

        @port_eps = new PowerSystem(
            'Port EPS',
            @DECKS['10'],
            @SECTIONS.PORT,
            PowerSystem.EPS_RELAY_POWER )

        @starboard_eps = new PowerSystem(
            'Starboard EPS',
            @DECKS['10'],
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


    initialize_power_connections: ->

        # Connect main power systems
        @warp_relay.add_route @forward_eps
        @warp_relay.add_route @aft_eps
        @warp_relay.add_route @port_eps
        @warp_relay.add_route @starboard_eps
        @warp_relay.add_route( phaser ) for phaser in @phasers
        @warp_relay.add_route @starboard_warp_coil
        @warp_relay.add_route @port_warp_coil
        @warp_relay.add_route @navigational_deflectors
        @warp_relay.add_route @long_range_sensors
        @warp_relay.add_route @primary_SIF
        @warp_relay.add_route @secondary_SIF
        @warp_relay.add_route @cloak_system

        # Connect impulse power systems
        @impulse_relay.add_route @impulse_drive

        # EPS Systems
        fwd_systems = [
            @bridge
            @navigational_computer
            @forward_shields
            @forward_sensors
            @torpedo_bank_1
            @torpedo_bank_2
        ]

        aft_systems = [
            @lifesupport
            @tractor_beam
            @aft_shields
            @aft_sensors
            @weapons_targeting
        ]

        port_systems = [
            @sick_bay
            @port_shields
            @port_sensors
            @communication_array
            @transporters
        ]

        starboard_systems = [
            @starboard_shields
            @starboard_sensors
            @transponder
            @brig
            @inertial_dampener
        ]

        @forward_eps.add_route r for r in fwd_systems
        @port_eps.add_route r for r in port_systems
        @starboard_eps.add_route r for r in starboard_systems
        @aft_eps.add_route r for r in aft_systems


    initialize_shileds: ->

        @port_shields = new ShieldSystem(
            'Port Shields',
            @DECKS['3'],
            @SECTIONS.PORT )

        @starboard_shields = new ShieldSystem(
            'Starboard Shields',
            @DECKS['3'],
            @SECTIONS.STARBOARD )

        @aft_shields = new ShieldSystem(
            'Aft Shields',
            @DECKS['5'],
            @SECTIONS.AFT )

        @forward_shields = new ShieldSystem(
            'Forward Shields',
            @DECKS['8'],
            @SECTIONS.FORWARD )

        @shields = [
            @port_shields
            @starboard_shields
            @aft_shields
            @forward_shields ]


    initialize_weapons: ->

        @forward_phaser_bank_a = new DisruptorSystem(
            'Port Phaser Disruptor',
            @DECKS['18'],
            @SECTIONS.FORWARD )

        @forward_phaser_bank_b = new DisruptorSystem(
            'Starboard Phaser Disruptor',
            @DECKS['18'],
            @SECTIONS.FORWARD )

        @forward_phaser_bank_c = new PhaserSystem(
            'Forward Phaser Bank',
            @DECKS['1'],
            @SECTIONS.FORWARD )

        @phasers = [
            @forward_phaser_bank_a
            @forward_phaser_bank_b
            @forward_phaser_bank_c ]

        @torpedo_bank_1 = new TorpedoSystem(
            'Torpedo Bay 1',
            @DECKS['15'],
            @SECTIONS.FORWARD,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_bank_2 = new TorpedoSystem(
            'Torpedo Bay 2',
            @DECKS['16'],
            @SECTIONS.FORWARD,
            @SECTIONS.FORWARD,
            @_consume_a_torpedo )

        @torpedo_banks = [
            @torpedo_bank_1
            @torpedo_bank_2 ]


    initialize_sensors: ->

        b = @bearing.bearing

        @_logged_scanned_items = []

        forward_scan_grid = [0...8].concat( [56...64] )
        port_scan_grid = [8...24]
        aft_scan_grid = [24...40]
        starboard_scan_grid = [40...56]

        @port_sensors = new SensorSystem(
            'Port Sensor Array',
            @DECKS['7'],
            @SECTIONS.PORT,
            b,
            port_scan_grid )

        @starboard_sensors = new SensorSystem(
            'Starboard Sensor Array',
            @DECKS['7'],
            @SECTIONS.STARBOARD,
            b,
            starboard_scan_grid )

        @forward_sensors = new SensorSystem(
            'Forward Sensor Array',
            @DECKS['13'],
            @SECTIONS.FORWARD,
            b,
            forward_scan_grid )

        @aft_sensors = new SensorSystem(
            'Aft Sensor Array',
            @DECKS['9'],
            @SECTIONS.AFT,
            b,
            aft_scan_grid )

        @long_range_sensors = new LongRangeSensorSystem(
            'Long Range Sensors',
            @DECKS['6'],
            @SECTIONS.FORWARD,
            b,
            forward_scan_grid )

        @sensors = [
            @aft_sensors
            @port_sensors
            @starboard_sensors
            @forward_sensors ]


    initialize_hull: () ->

        @hull = {}
        for deck, deck_letter of @DECKS
            @hull[ deck_letter ] = {}
            for section, section_string of @SECTIONS
                @hull[ deck_letter ][ section_string ] = 1


    initialize_cargo: () ->

        @cargobays = []
        for i in [ 1..4 ]
            @cargobays.push( new CargoBay i )


    initialize_crew: () ->

        @internal_personnel = [
            new SecurityTeam @DECKS['3'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['4'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['5'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['6'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['7'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['7'], @SECTIONS.FORWARD
            new SecurityTeam @DECKS['7'], @SECTIONS.AFT
            new SecurityTeam @DECKS['4'], @SECTIONS.AFT
            new SecurityTeam @DECKS['5'], @SECTIONS.AFT
            new SecurityTeam @DECKS['5'], @SECTIONS.AFT
            new SecurityTeam @DECKS['5'], @SECTIONS.AFT
            new SecurityTeam @DECKS['2'], @SECTIONS.AFT
            new SecurityTeam @DECKS['2'], @SECTIONS.AFT
            new SecurityTeam @DECKS['1'], @SECTIONS.AFT
            new SecurityTeam @DECKS['9'], @SECTIONS.AFT
            new SecurityTeam @DECKS['9'], @SECTIONS.AFT
            new EngineeringTeam @DECKS['11'], @SECTIONS.AFT
            new EngineeringTeam @DECKS['8'], @SECTIONS.AFT
            new EngineeringTeam @DECKS['4'], @SECTIONS.AFT
            new RepairTeam @DECKS['3'], @SECTIONS.PORT
            new RepairTeam @DECKS['2'], @SECTIONS.STARBOARD
            new RepairTeam @DECKS['1'], @SECTIONS.AFT
            new ScienceTeam @DECKS['15'], @SECTIONS.FORWARD
            new MedicalTeam @DECKS['6'], @SECTIONS.AFT
        ]

        c.set_assignment @name for c in @internal_personnel
        @crew = @internal_personnel
        @set_alignment C.ALIGNMENT.KLINGON


exports.D7 = D7
