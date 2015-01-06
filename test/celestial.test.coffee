{CelestialObject, Star, GasCloud} = require '../trek/CelestialObject'
{SensorSystem} = require '../trek/systems/SensorSystems'


exports.CelestialObjectTest =

    'test can scan Gas Cloud': ( test ) ->

        g = new GasCloud 10, 20
        g.set_position 0, 0, 0
        mag_results = g.scan_for SensorSystem.SCANS.MAGNETON
        test.ok mag_results, "Failed to find Magnetons #{ mag_results }"

        do test.done