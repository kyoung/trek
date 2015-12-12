{BaseShip} = require './BaseShip'

{System, ChargedSystem} = require '../BaseSystem'
{Transporters} = require '../systems/TransporterSystems'
{ShieldSystem} = require '../systems/WeaponSystems'
{ReactorSystem, PowerSystem} = require '../systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require '../systems/SensorSystems'
{SIFSystem} = require '../systems/SIFSystems'
{CommunicationsSystems} = require '../systems/CommunicationSystems'
{BaseObject} = require '../BaseObject'
{CargoBay} = require '../CargoBay'
{Log} = require '../Log'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, DiplomaticTeam, MedicalTeam} = require '../Crew'

C = require '../Constants'

SECTIONS = {}
for section_number in [1..20]
    section_letter = do section_number.toString
    SECTIONS[section_number] = section_letter

DECKS = {}
for deck_number in [1..10]
    deck_letter = do deck_number.toString
    DECKS[deck_number] = deck_letter


class StarDock extends BaseShip

    SECTIONS: SECTIONS
    DECKS: DECKS

    @REGISTRY = [
        { name : "J", registry : "57" }
        { name : "K", registry : "63" }
    ]

    @get_ship_name: ->

        if @REGISTRY.length is 0
            # Start making up dummy names, as this is probably a test
            n = Math.floor( 1e3 * do Math.random )
            return { name : "Z", registry : "#{ n }" }

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
            StarDock.launch_ship @name
        else
            # Choose a random name to go with
            { name, registry } = do StarDock.get_ship_name
            @name = name
            @serial = registry

        super @name, @serial
        @model_url = "spacedock.json"
        @model_display_scale = 7
        @ship_class = "SpaceDock"


    initilize_systems: ->

        do @initialize_shileds
        do @initialize_weapons
        do @initialize_sensors
        do @initialize_power_systems

        @lifesupport = new System(
            'Lifesupport',
            @DECKS['5'],
            @SECTIONS['3'],
            System.LIFESUPPORT_POWER )

        @transponder = new System(
            'Transponder',
            @DECKS['9'],
            @SECTIONS['2'],
            System.TRANSPONDER_POWER )

        @transporters = new Transporters(
            'Transporters',
            @DECKS['7'],
            @SECTIONS['14'] )

        @communication_array = new CommunicationsSystems(
            'Communications',
            @DECKS['4'],
            @SECTIONS['4'])

        @inertial_dampener = new System(
            'Inertial Dampener',
            @DECKS['3'],
            @SECTIONS['17'],
            System.DAMPENER_POWER )

        @primary_SIF = new SIFSystem(
            'Primary SIF',
            @DECKS['5'],
            @SECTIONS['15'] )

        @secondary_SIF = new SIFSystem(
            'Secondary SIF',
            @DECKS['5'],
            @SECTIONS['3'],
            true )

        @tractor_beam = new System(
            'Tractor Beam',
            @DECKS['3'],
            @SECTIONS['1'],
            System.TRACTOR_POWER )

        # connect power systems
        @main_relay.add_route @primary_eps

        # Turn on power
        do @_set_operational_reactor_settings

        # Activate basic systems
        do @primary_SIF.power_on
        do @secondary_SIF.power_on

        systems = [
            @lifesupport, @transponder, @transporters, @communication_array,
            @inertial_dampener, @primary_SIF, @secondary_SIF, @tractor_beam
        ]
        for s in systems
            @primary_eps.add_route s
        @systems = systems.concat( [ @fusion_reactors, @main_relay,
            @emergency_power, @e_power_relay, @primary_eps ] )


    initialize_power_systems: ->

        # Main relays
        @main_relay = new PowerSystem(
            'Station Primary Relays',
            @DECKS['7'],
            @SECTIONS['14'],
            PowerSystem.IMPULSE_RELAY_POWER )

        @e_power_relay = new PowerSystem(
            'Emergency Relays',
            @DECKS['8'],
            @SECTIONS['1'],
            PowerSystem.EMEGENCY_RELAY_POWER )

        @fusion_reactors = new ReactorSystem(
            'Fusion Reactors',
            @DECKS['6'],
            @SECTIONS['15'],
            ReactorSystem.FUSION,
            @main_relay,
            ReactorSystem.FUSION_SIGNATURE )

        @emergency_power = new ReactorSystem(
            'Emergency Power',
            @DECKS['7'],
            @SECTIONS['1']
            ReactorSystem.BATTERY,
            @e_power_relay,
            ReactorSystem.BATTERY_SIGNATURE )

        # EPS Grids
        @primary_eps = new PowerSystem(
            'Primary EPS',
            @DECKS['3'],
            @SECTIONS['9'],
            PowerSystem.EPS_RELAY_POWER )

        @primary_power_relays = [
            @main_relay
            @e_power_relay ]

        @eps_grids = [
            @primary_eps ]

        @reactors = [
            @fusion_reactors
            @emergency_power ]

        @power_systems = [].concat(
            @primary_power_relays ).concat(
            @eps_grids ).concat(
            @reactors )

    initialize_cargo: ->
        @cargobays = []
        for i in [ 1..5 ]
            @cargobays.push( new CargoBay i )

    initialize_crew: ->
        @internal_personnel = [
            new RepairTeam @DECKS['3'], @SECTIONS['11']
            new RepairTeam @DECKS['3'], @SECTIONS['4']
            new RepairTeam @DECKS['3'], @SECTIONS['4']
            new RepairTeam @DECKS['3'], @SECTIONS['11']
            new RepairTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['4']
            new EngineeringTeam @DECKS['3'], @SECTIONS['11']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['8']
            new EngineeringTeam @DECKS['3'], @SECTIONS['4']
            new EngineeringTeam @DECKS['3'], @SECTIONS['11']
        ]

        c.set_assignment @name for c in @internal_personnel
        @crew = @internal_personnel
        @set_alignment C.ALIGNMENT.FEDERATION

    initialize_hull: ->
        @hull = {}
        for deck, deck_letter of @DECKS
            @hull[ deck_letter ] = {}
            for section, section_string of @SECTIONS
                @hull[ deck_letter ][ section_string ] = 1

    # things a dock can't do
    turn_port: ->
    turn_starboard: ->
    set_course: ->
    set_impulse: ->
    computer_set_impulse: ->
    set_warp: ->
    computer_set_warp: ->
    set_shields: ->
    fire_torpedo: ->
    load_torpedo: ->
    fire_phasers: ->
    set_target: ->

    set_alert: ( status ) ->

        @alert = status
        @message @prefix_code, "alert", status

        switch status
            when 'red'
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            when 'yellow'
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            when 'blue'
                @set_power_to_system @primary_SIF.name, 1
                @set_power_to_system @secondary_SIF.name, 1

            else
                @set_power_to_system @primary_SIF.name, SIFSystem.PRIMARY_POWER_PROFILE.min * 1.1
                @set_power_to_system @secondary_SIF.name, SIFSystem.SECONDARY_POWER_PROFILE.min * 1.1


exports.StarDock = StarDock
