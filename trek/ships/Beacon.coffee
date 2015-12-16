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
for section_number in [1..4]
    section_letter = do section_number.toString
    SECTIONS[section_number] = section_letter

DECKS = {}
for deck_number in [1..2]
    deck_letter = do deck_number.toString
    DECKS[deck_number] = deck_letter


class Beacon extends BaseShip

    SECTIONS: SECTIONS
    DECKS: DECKS

    constructor: ( @name, @serial="" ) ->

        super @name, @serial
        @model_url = "beacon.json"
        @model_display_scale = 1
        @ship_class = "Beacon"


    initialize_systems: ->

        @main_relay = new PowerSystem(
            'Station Primary Relays',
            @DECKS['2'],
            @SECTIONS['1'],
            PowerSystem.EMEGENCY_RELAY_POWER )

        @battery_power = new ReactorSystem(
            'Power Cells',
            @DECKS['2'],
            @SECTIONS['1']
            ReactorSystem.BATTERY,
            @main_relay,
            ReactorSystem.BATTERY_SIGNATURE )

        @eps = new PowerSystem(
            'EPS',
            @DECKS['2'],
            @SECTIONS['2'],
            PowerSystem.EPS_RELAY_POWER )

        @eps_grids = [ @eps ]
        @reactors = [ @battery_power ]
        @power_systems = [ @eps, @battery_power ]

        @transponder = new System(
            'Transponder',
            @DECKS['1'],
            @SECTIONS['2'],
            System.TRANSPONDER_POWER )

        @main_relay.add_route @eps
        @eps.add_route @transponder

        @systems = [ @main_relay, @battery_power, @eps, @transponder ]

        # Turn on power
        do @_set_operational_reactor_settings


exports.Beacon = Beacon
