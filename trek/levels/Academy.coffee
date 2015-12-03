{Level} = require "../Level"
{LevelEvent} = require "../LevelEvent"

{Constitution} = require '../ships/Constitution'
{SpaceDock} = require '../ships/SpaceDock'

{SpaceSector, StarSystem} = require '../Maps'

C = require "../Constants"
U = require "../Utility"

# Premise:
# It's training day! Lets teach everyone how to boot the ship, get crew aboard
# and work the systems.
#
# We start in spacedock with the ship powered down, and no crew or cargo
# onboard. We'll beam over all the crew and supplies, and assign them throughout
# the ship. Since warp and impulse reactors are offline, transporters,
# lifesupport, and bridge control will be operating on emergency power.
#
# We'll need engineering to activate the warp core and begin routing power to
# various systems throughout the ship, and bring systems online.
#
# Once ready, we'll need the helm to move us out of space dock, using thrusters
# only, and take us to a testing facility on the outer edge of the solar system
# where we can begin testing our weapons systems and science systems.
#
# The mission is complete when we have successfully destroyed the field targets
# and tested the science stations.
#

class Academy extends Level

    constructor: ( @team_count ) ->
        super()
        @name = "Academy"
        @stardate = do U.stardate
        do @_init_map
        do @_init_logs
        do @_init_space_objects
        do @_init_ships
        do @_init_game_objects
        do @_init_environment

        @theme = 'static/sound/khanTheme.mp3'


    get_events: =>
        # Is crew boarded
        # Is cargo boarded
        # Has requested clearance to depart
        # Has departed
        # Has destroyed first target with phasers
        # Has destroyed second target subsystem
        # Has destroyed cluster of targets with torpedos

    _init_map: ->


    _init_logs: ->
        @enterprise_logs = [
            "Captains Log, stardate #{ @stardate }\n
            \n
            We are in space dock in orbit of Altan 3, having undergone some
            routine maintenance, and in preparation of taking on our new crew.\n
            \n
            Our orders are to beam aboard the ships crew and cargo, power up,
            and head out to the firing range in orbit or Altan 5, to test our
            phasers, targeting sensors, and torpedo launchers.\n
            \n\n
            "
        ]

    _init_space_objects: ->


    _init_ships: ->


    _init_game_objects: ->


    _init_environment: ->


exports.Level = Academy
