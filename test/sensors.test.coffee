{SensorSystem, LongRangeSensorSystem} = require '../trek/systems/SensorSystems'
C = require '../trek/Constants'

process.on 'uncaughtException', ( err ) -> console.log(err)

world_callback = ( type, position, bearing_from, bearing_to, range ) ->
    r =
        readings: [
            {bearing: {bearing: 0.1, mark: 0}, reading: 1}
            {bearing: {bearing: 0.2, mark: 0}, reading: 1}
            {bearing: {bearing:  0.3, mark: 0}, reading: 1}
            {bearing: {bearing:  0.4, mark: 0}, reading: 1}
            {bearing: {bearing:  0.7, mark: 0}, reading: 1}
        ]
        classifications: [
            {classification: 'thing', coordinate: {x: 1, y: 1, z: 0}}
        ]


exports.SensorTest =

    'test can read back expected worldscan': ( test ) ->

        test.expect 3

        pos = {x: 0, y:0, z:0}
        resolution = 8
        range = 0.1
        grids = [0...64]
        bearing = 0

        position = {x: 0, y: 0, z: 0}

        SensorSystem.DURATION /= 100
        s = new SensorSystem("Test sensor", "Lab 17", "5", 0, grids)
        s.push_power SensorSystem.POWER.dyn

        area = grids.length / SensorSystem.MAX_SLICES * Math.PI * ( range * SensorSystem.RANGE )**2
        s.configure_scan 'test', bearing, grids, range, resolution
        s_area = s.scan_area('test')
        # console.log "Sensors says #{s_area} vs #{area}"
        t = s.scan world_callback, pos, bearing, 'test'
        # console.log "Scan says it will take #{t} ms"
        time = Math.ceil(SensorSystem.DURATION * resolution * area * SensorSystem.SCANNER_DIVISOR)
        # console.log "Waiting for #{time}"
        sum = 0
        sum += b.reading for b in s.readings('test', 0, position).results
        test.ok sum == 0, "Sensor results were available early."

        check_final_scan = ->
            new_sum = 0
            results = s.readings('test', 0, position)
            # console.log results
            new_sum += b.reading for b in results.results
            test.ok new_sum == 5, "Failed to get final scan sum: #{new_sum}"
            classif_dist = results.classifications[0].distance
            # Distance will be rounded down
            test.ok classif_dist == 1, "Failed to calculate proper distance."
            do test.done

        setTimeout check_final_scan, time


    'test can calculate absolute bearings': ( test ) ->

        bearing = 0.25
        grids = [0...16]
        s = new SensorSystem 'test sensor', 'lab 18', '5', bearing, grids

        s.push_power SensorSystem.POWER.dyn
        s.configure_scan 'test', bearing, grids, 1, 64
        abs_sweeps = s._calculate_abs_sweeps 'test', bearing
        test.ok abs_sweeps.length == 1, "Failed to calculate the correct number
            of sweeps"
        test.ok abs_sweeps[0].start == 0.25 and abs_sweeps[0].end == 0.5, "Failed
            to calculate the correct absolute bearing"

        do test.done


    'test can split ranges': ( test ) ->

        grids = [0...8].concat([56...64])
        bearing = 0

        s = new SensorSystem 'test sensor', 'lab 18', '5', bearing, grids
        s.push_power SensorSystem.POWER.dyn
        s.configure_scan 'test', bearing, grids, 1, 64
        r = s._calculate_abs_sweeps 'test', bearing
        test.ok r.length == 2, "Failed to identify multiple scan segments"

        do test.done
