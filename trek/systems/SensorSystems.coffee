{System, ChargedSystem} = require '../BaseSystem'
C = require '../Constants'
U = require '../Utility'
Cargo = require '../Cargo'


up_to = ( n ) ->
    Math.floor Math.random() * n

GRID_START = 0.875

class SensorSystem extends System

    @POWER = { min : 0.1, max : 1.7, dyn : 1e4 }

    @SCANS =
        WIDE_EM: "Wide Angle EM Field Scan"
        ANTIPROTON: "Active Antiproton Beam Scan"
        HIGHRES: "Active High-Resolution Scan"
        P_HIGHRES: "Passive High-Resolution Scan"
        MAGNETON: "Magneton Scan"
        MULTIPHASIC: "Multiphasic Scan"
        TACHYON: "Active Inverse Tachyon Pulse"
        POSITRON: "Virtual Positron Imaging Scan"

    @RANGE = 3 * C.AU

    @MAX_SLICES = 64
    @MIN_SLICES = 4

    @DURATION = 2e4

    # Magic number required to offset the area of the scan being so large
    @SCANNER_DIVISOR = 1/1e23


    constructor: ( @name, @deck, @section, bearing, @visible_grids ) ->

        super @name, @deck, @section, SensorSystem.POWER
        @_repair_reqs = []
        @_repair_reqs[ Cargo.COMPUTER_COMPONENTS ] = up_to 40
        @_repair_reqs[ Cargo.EPS_CONDUIT ] = up_to 5

        # data
        @results = {}
        @spectra = {}
        @classifications = {}
        # ...

        @duration = SensorSystem.DURATION
        @max_range = SensorSystem.RANGE

        @configured_scans = []
        @resolution = {}
        @range_levels = {}
        @scan_grids = {}
        @reference_bearing = {}
        @etc_for_scans = {}
        @_time_for_scan = {}

        # Objects for tracking when to overwrite existing scan data
        @_expected_result_sets = {}
        @_recieved_result_sets = {}

        @_initialize_scans bearing


    _initialize_scans: ( bearing ) ->

        bearing ?= 0
        for key, type of SensorSystem.SCANS
            @configure_scan type, bearing, @visible_grids


    scan_area: ( type ) ->

        if not @scan_grids[ type ]?
            console.log @scan_grids
            throw new Error "Invalid scan grid for #{type}"

        area = @scan_grids[type].length / SensorSystem.MAX_SLICES * Math.PI * (@range_levels[type]*@max_range)**2


    _calculate_abs_sweeps: ( type, bearing ) ->

        grids = @scan_grids[ type ]
        if grids.length == 0
            return []

        sweeps = []
        grids.sort( ( a, b ) -> a - b )
        sweeps[0] = { start_grid : grids[ 0 ] }

        for grid, i in grids
            # Check if this is the last of a continuous set
            if grids[ i + 1 ] > grid + 1
                # Start a new sweep
                sweeps[ sweeps.length - 1 ].end_grid = grid
                sweeps.push { start_grid : grids[i+1] }

        # Close off the last sweep
        sweeps[ sweeps.length - 1 ].end_grid = grids[ grids.length - 1 ]

        # Get bearing alignment set with the current ship bearing
        for s in sweeps
            s.start = ( s.start_grid / SensorSystem.MAX_SLICES + bearing ) % 1
            s.end = ( ( s.end_grid + 1 ) / SensorSystem.MAX_SLICES + bearing ) % 1

        if s.end == 0
            s.end = 1

        # Sanity check
        if Math.abs( sweeps[0].start - sweeps[0].end ) < 0.015625
            console.log @scan_grids
            throw new Error("Failed to properly set sweeps from bearing #{bearing}:
                #{sweeps[0].start}, #{sweeps[0].end}.")

        return sweeps


    configure_scan: ( type, bearing, scan_grids, range_level, resolution ) ->

        if type not in @configured_scans
            @configured_scans.push type

        resolution ?= 8
        if type.indexOf('High-Resolution') > 0
            resolution = 64

        # TODO validate against @visible_grids
        scan_grids ?= @visible_grids

        range_level ?= 0.1

        @resolution[ type ] = resolution
        @scan_grids[ type ] = scan_grids
        @range_levels[ type ] = range_level
        @reference_bearing[ type ] = bearing
        @etc_for_scans[ type ] = 0
        @_time_for_scan[ type ] = 0
        @_check_buckets type


    get_configuration: ( type ) ->

        n = new Date().getTime()
        r =
            resolution: @resolution[ type ]
            grids: @scan_grids[ type ]
            range: @range_levels[ type ]
            ettc: @etc_for_scans[ type ] - n
            time_estimate: @_time_for_scan[ type ]


    run_scans: ( world_scan, position, bearing, timestamp ) ->

        # Runs all scans, as a default startup, and every 100ms
        # as part of ship operations
        if not do @is_online
            return 0

        for key, type of SensorSystem.SCANS
            if not @_expected_result_sets[ type ]? or @_expected_result_sets[ type ]?.length == 0
                range = @range_levels[ type ] * @max_range * do @performance
                @scan world_scan, position, bearing, type, range


    scan: ( world_scan, position, bearing, type ) ->

        if not do @is_online
            return 0

        if not type in @configured_scans
            @configure_scan type, bearing

        area = @scan_area type
        if not area? or not area > 0
            console.log "Scan grid count: #{ @scan_grids[ type ].length }"
            console.log "Max slices: #{ SensorSystem.MAX_SLICES }"
            console.log "Range level #{ @range_levels[ type ] } over max #{ @max_range }"
            throw new Error "Failed to calculate scan area."

        time_to_scan = @duration * @resolution[ type ] * area * ( 1 /
            do @performance ) * SensorSystem.SCANNER_DIVISOR

        if not time_to_scan > 0
            console.log "Duration: #{ @duration }"
            console.log "Resolution: #{ @resolution[ type ] }"
            console.log "Area: #{ area }"
            console.log "Performance: #{ @performance() }"
            console.log "Divisor: #{ SensorSystem.SCANNER_DIVISOR }"
            throw new Error "Failed to calculate time to scan"

        range = @range_levels[ type ] * @max_range * do @performance

        sweeps = @_calculate_abs_sweeps type, bearing

        # It's possible that this sensor grid isn't being used in this
        # scan
        if sweeps.length == 0
            return 0

        # Configuration debug
        #console.log "#{@name} configuration"
        #console.log "\t Sweep 1 #{sweeps[0].start} to #{sweeps[0].end}"
        #if sweeps.length == 2
        #    console.log "\t Sweep 2 #{sweeps[1].start} to #{sweeps[1].end}"
        #console.log "\t Grids:"
        #console.log @scan_grids[type]

        @_expected_result_sets[ type ] = []
        @_recieved_result_sets[ type ] = []

        # Hack to avoid the problem of late binding on the callbacks
        # NB there will only ever be 1 or 2 sweeps
        scan_id = up_to 1e8
        first_result = world_scan type, position, sweeps[ 0 ].start, sweeps[ 0 ].end, range

        sweep_callback = =>
            @scan_back type, first_result, scan_id

        @_expected_result_sets[ type ].push scan_id
        setTimeout sweep_callback, time_to_scan

        if sweeps.length == 2
            second_scan_id = up_to 1e8
            second_result = world_scan type, position, sweeps[ 1 ].start, sweeps[ 1 ].end, range

            second_callback = =>
                @scan_back type, second_result, second_scan_id

            @_expected_result_sets[ type ].push second_scan_id
            setTimeout second_callback, time_to_scan

        n = new Date().getTime()
        @etc_for_scans[ type ] = n + time_to_scan
        @_time_for_scan[ type ] = time_to_scan

        return time_to_scan


    clear: ( type ) ->

        @results[ type ] = []
        @spectra[ type ] = []
        @classifications[ type ] = []


    _fit_resolution: ( type ) ->

        # Resolution must be an integer in the series 2**n, between
        # 4 and 64.
        valid_settings = [ 4, 8, 16, 32, 64 ]
        round_down = ( v for v in valid_settings when v <= @resolution[type] )
        @resolution[type] = Math.max.apply null, round_down
        if @resolution[type] not in valid_settings
            throw new Error "Failed to calculate resolution for #{type} from above"


    _check_buckets: ( type ) ->

        # Ensure that the structure of @results reflects @resolution
        if not @resolution[ type ]?
            throw new Error "Unconfigured scan #{type}"

        @_fit_resolution type
        if @results[ type ]?.length == @resolution[ type ]
            return

        @clear type

        cell_step = 1 / @resolution[ type ]

        # GRID_START(0.875) is the start bearing of the forward grid
        # We start offsetting here to keep the resolution aligned
        #
        # These buckets are absolute, so that they are still valid
        # after the ship changes course, in between scans.
        #
        # Relative translation only occurs on the reading.

        offset = @reference_bearing[ type ]
        if @resolution[ type ] < 0
            throw new Error "Invalid resolution: #{@resolution[type]}"

        for i in [ 0...@resolution[ type ] ]
            bucket =
                start: ( GRID_START + i * cell_step + offset ) % 1
                end: ( GRID_START + ( i + 1 ) * cell_step + offset ) % 1
                reading: 0
            @results[ type ].push bucket


    scan_back: ( type, results, scan_id ) =>

        @_check_buckets type

        # Clear existing results if this is a new set of scans
        if scan_id not in @_expected_result_sets[type]
            return

        @_expected_result_sets[type] = (i for i in @_expected_result_sets[type] when i != scan_id)

        if @_recieved_result_sets[type].length == 0
            @clear type
            @_check_buckets type
        @_recieved_result_sets[type].push scan_id

        # NB: Results come in as a list of absolute bearings and readings
        for r in results.readings
            bearing = r.bearing.bearing
            # Find the appropriate bucket and add the reading
            buckets = (b for b in @results[type] when b.start <= bearing < b.end)
            # Check if in the crossover segment
            if buckets.length < 1
                buckets = (b for b in @results[type] when b.start > b.end)
            if buckets.length == 0
                console.log r
                console.log @results[type]
                throw new Error("Sensor System Error. Unknown spatial ranges #{bearing}")
            buckets[0].reading += r.reading

        @classifications[type] = @classifications[type].concat results.classifications


    readings: ( type, bearing, position ) ->

        # Results are stored in absolute bearings: Convert them back to relative
        # for calls.
        # Scans buckets were calibrated off of grids and buckets at a given
        # reference bearing.

        if not @results[type]?
            console.log @results
            throw new Error "Can't parse results for #{type} from above"
        clone_results = JSON.parse JSON.stringify @results[type]
        for bucket in clone_results
            bucket.start -= bearing
            if bucket.start < 0
                bucket.start += 1
            bucket.end -= bearing
            if bucket.end < 0
                bucket.end += 1

        # Adjust any bearing information in classifications
        # NB you need to convert coordinate to
        if not @classifications[type]?
            console.log @results
            throw new Errror "Can't parse classifications for #{type} from above"
        cloned_classifications = JSON.parse JSON.stringify @classifications[type]

        for c in cloned_classifications
            c.distance = U.distance position, c.coordinate

            c.bearing = U.point_bearing position, c.coordinate
            c.bearing.bearing -= bearing
            if c.bearing.bearing < 0
                c.bearing.bearing += 1
            delete c.coordinate

        r =
            results: clone_results
            classifications: cloned_classifications
            spectra: []



class LongRangeSensorSystem extends SensorSystem

    @POWER = { min : 0.1, max : 4, dyn : 5e4 }

    @SCANS =
        EM_SCAN: "EM Field Scan"
        GAMMA_SCAN: "Gamma Radiation Scan"
        SUBSPACE: "Subspace Field Stressor Scan"
        GRAVIMETRIC: "Gravimetric Distortion Scan"
        NEUTRINO: "Passive Neutrino Imaging Scan"

    @RANGE = 17 * C.LY

    # Time for a highres scan at maximum distance is 45 minutes
    @DURATION = 45 * 60 * 1000

    # Magic number required to offset the area of the scan being so large
    @SCANNER_DIVISOR = 3/1e8


    constructor: ( @name, @deck, @section, bearing, @visible_grids ) ->

        super @name, @deck, @section, bearing, @visible_grids

        @power_thresholds = LongRangeSensorSystem.POWER
        @duration = LongRangeSensorSystem.DURATION
        @max_range = LongRangeSensorSystem.RANGE
        @_lr_grids = [0...8].concat( [56...64] )


    _initialize_scans: ( bearing ) ->

        bearing ?= 0
        for key, type of LongRangeSensorSystem.SCANS
            @configure_scan type, bearing


    scan_area: ( type ) ->

        if not @scan_grids[type]?
            console.log @scan_grids
            throw new Error "Invalid scan grid for #{type}"

        max_range_mod = @max_range * LongRangeSensorSystem.SCANNER_DIVISOR
        area = @scan_grids[type].length / SensorSystem.MAX_SLICES * Math.PI * (@range_levels[type]*max_range_mod)**2


    run_scans: ( world_scan, position, bearing, timestamp ) ->

        # Runs all scans, as a default startup, and every 100ms
        # as part of ship operations
        if not do @is_online
            return 0

        for key, type of LongRangeSensorSystem.SCANS
            if not @_expected_result_sets[type]? or @_expected_result_sets[type]?.length == 0
                range = @range_levels[ type ] * @max_range * do @performance
                @scan world_scan, position, bearing, type, range


    configure_scan: ( type, bearing, range_level, resolution ) ->

        if type not in @configured_scans
            @configured_scans.push type

        resolution ?= 64
        scan_grids = @visible_grids
        range_level ?= 0.5

        @resolution[ type ] = resolution
        @scan_grids[ type ] = scan_grids
        @range_levels[ type ] = range_level
        @reference_bearing[ type ] = bearing
        @etc_for_scans[ type ] = 0
        @_check_buckets type
        "#{ type } updated"


exports.SensorSystem = SensorSystem
exports.LongRangeSensorSystem = LongRangeSensorSystem
