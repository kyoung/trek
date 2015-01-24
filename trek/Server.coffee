express = require "express"
app = express()
app.use express.cookieParser( 'darmok&jalad' )
app.use express.bodyParser()

io = require "socket.io"
http = require "http"
server = http.createServer app
socket = io.listen server, { log : false }
cookie = require "cookie"

program = require "commander"

program
    .version( '0.1' )
    .option( '-l, --level [level]', 'Select a level.', 'DGTauIncident' )
    .option( '-t, --teams [count]', 'Enter the number of teams.', parseInt, 1 )
    .parse( process.argv )

{Game} = require './Game'

game = new Game program.level, program.teams

app.engine 'html', require( 'ejs' ).renderFile

landingPage = ( req, res ) ->

    res.render "index.html", { ships : do game.get_ships }


### Utilities
___________________________________________________###

validate = ( req, res ) ->

    # take a request, response and validate for a prefix code
    postfix = req.cookies.postfix
    if not postfix in ship_postfixes
        res.render "error.html"
        return false
    else
        return ships[ postfix ]


postfix_validate = ( postfix ) -> return ships[ postfix ]


atoi = ( str ) -> parseFloat str, 10


### Debug
___________________________________________________###
debug = ( req, res ) ->
    res.json { state : do game.state }

debugMap = ( req, res ) ->
    prefix = validate req, res
    res.json game.debug_space_map prefix

debugCoordinateSpace = ( req, res ) ->
    res.json do game.debug_positions

debugBearings = ( req, res ) ->
    prefix = validate req, res
    res.json game.debug_bearings prefix


### Socket Setup
___________________________________________________###

shipSockets = {}

socketAuth = ( data, accept ) ->
    if data.headers.cookie
        data.cookie = cookie.parse data.headers.cookie
        data.postfix = data.cookie[ 'postfix' ]
    else
        return accept 'No cookie transmitted', false
    accept null, true

socket.set 'authorization', socketAuth


socketConnection = ( socket ) ->
    socket.postfix = socket.handshake.postfix
    prefix = postfix_validate socket.postfix
    if not prefix
        return
    if shipSockets[ prefix ]?
        shipSockets[ prefix ].push socket
    else
        shipSockets[ prefix ] = [ socket ]

    socket.on( 'disconnect', ->
        shipSockets[ prefix ] = shipSockets[ prefix ].filter ( s ) -> s isnt socket
    )

socket.on('connection', socketConnection)


# Super socket feedback ability

sendToSockets = ( prefix, type, content ) ->

    if not shipSockets?
        throw new Error "The shipSockets object has been disappeared"

    # console.log prefix, type, content

    sockets = shipSockets[ prefix ]
    if sockets?
        s.emit( type, content ) for s in sockets

game.set_message_function sendToSockets


### API Handling
___________________________________________________###

legacy_API = ( req, res ) ->

    throw new Error "Legacy API used for #{ req.route.url }"


handle_API = ( req, res ) ->

    category = req.params.category

    if not prefix = validate req, res
        return

    method = req.route.method

    if method == 'get'
        params = req.query
    else
        params = req.body

    command = req.params.command

    resp = switch category
        when 'navigation' then navigation_api prefix, method, command, params
        when 'tactical' then tactical_api prefix, method, command, params
        when 'operations' then operations_api prefix, method, command, params
        when 'transporters' then transporters_api prefix, method, command, params
        when 'science' then science_api prefix, method, command, params
        when 'engineering' then engineering_api prefix, method, command, params
        when 'communications' then communications_api prefix, method, command, params
        # Command sets some cookies and requires the response object
        when 'command' then command_api prefix, method, command, params, res

    if resp is undefined
        throw new Error "Undefined response object for #{ category }/#{ command }"

    res.json resp


navigation_api = ( prefix, method, command, params ) ->
    q = params
    resp = switch command

        when 'position'
            if method == 'get'
                { results : game.get_position prefix }

        when 'course'
            if method == 'put'
                set_course prefix, q.bearing, q.mark

        when 'turn'
            if method == 'put'
                switch params.direction
                    when 'stop' then game.stop_turn prefix
                    when 'port' then game.turn_port prefix
                    when 'starboard' then game.turn_starboard prefix

        when 'thrust'
            switch method
                when 'post', 'put'
                    game.thrusters prefix, params.direction

        when 'status'
            game.get_navigation_report prefix

        when 'warp'
            if method == 'post'
                game.set_warp_speed prefix, atoi( q.speed )

        when 'impulse'
            if method == 'post'
                game.set_impulse_speed prefix, atoi( q.speed )

        when 'system'
            # stellar telemetry
            game.get_system_information prefix, q.system

        when 'charts'
            game.get_charted_objects prefix, q.system

        when 'stelar-telemetry'
            game.get_stelar_telemetry prefix, q.target


tactical_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command
        when 'alert'
            switch method
                when 'post'
                    game.set_alert prefix, q.status
                when 'get'
                    game.get_alert prefix

        when 'scan'
            game.scan prefix

        when 'status'
            game.get_tactical_status prefix

        when 'shields'
            switch method
                when 'post'
                    game.set_shields prefix, q.online
                when 'get'
                    game.get_shield_status prefix

        when 'target'
            switch method
                when 'post'
                    game.target prefix, q.target, q.deck, q.section
                when 'get'
                    game.get_target_subsystems prefix

        when 'fireTorpedo'
            game.fire_torpedo prefix, q.yield

        when 'loadTorpedo'
            game.load_torpedo_tube prefix, q.tube

        when 'phasers'
            switch method
                when 'post'
                    game.fire_phasers prefix
                when 'get'
                    game.get_phaser_status prefix


communications_api = ( prefix, method, command, params ) ->

    resp = switch command
        when 'comms'
            switch method
                when 'get' then game.get_comms_history prefix
                when 'post'
                    game.hail prefix, params.message


operations_api = ( prefix, method, command, params ) ->

    resp = switch command

        when 'internalScan', 'internal-scan'
            game.get_internal_lifesigns_scan prefix

        when 'systems-layout'
            game.get_systems_layout prefix

        when 'cargo'
            game.get_cargo_status prefix

        when 'decks'
            game.get_decks prefix

        when 'sections'
            game.get_sections prefix

        when 'sendTeamToDeck', 'send-team-to-deck'
            switch method
                when 'post'
                    game.send_team_to_deck(
                        prefix,
                        atoi( params.crew_id ),
                        params.to_deck,
                        params.to_section
                    )

        when 'repairTeam'
            game.assign_repair_crews(
                prefix,
                params.system_name,
                atoi( params.teams) ,
                ( params.to == 'completion' )
            )


transporters_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command

        when 'transporterRange'
            game.in_transporter_range prefix

        when 'crewReadyToTransport'
            game.crew_ready_to_transport prefix

        when 'transportCargo'
            switch method
                when 'post'
                    game.transport_cargo(
                        prefix,
                        q.origin, q.origin_bay,
                        q.destination, atoi( q.destination_bay ),
                        q.cargo, atoi( q.qty ) )

        when 'transportCrew'
            switch method
                when 'post'
                    transporter_args =
                        crew_id: q.crew_id
                        source_name: q.origin
                        source_deck: q.origin_deck
                        source_section: q.origin_section
                        target_name: q.target
                        target_deck: q.target_deck
                        target_section: q.target_section
                    game.transport_crew prefix, transporter_args


science_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command
        when 'runScan'
            switch method
                when 'put'
                    game.run_scan(
                        prefix,
                        q.type,
                        atoi( q.grid_start ),
                        atoi( q.grid_end ),
                        true,
                        q.range,
                        q.resolution )

        when 'scanResults'
            game.get_scan_results prefix, q.type

        when 'scanConfiguration'
            game.get_scan_configuration prefix, q.type

        when 'LRScanResults'
            game.get_lr_scan_results prefix, q.type

        when 'LRScanConfiguration'
            game.get_lr_scan_configuration prefix, q.type

        when 'internal-scan'
            game.get_internal_scan prefix

        when 'environmental-scan'
            game.get_environmental_scan prefix

        when 'activeScan'
            game.get_active_scan( prefix, q.classification, q.distance,
                q.bearing, q.tag )


engineering_api = ( prefix, method, command, params ) ->

    q = params

    resp = switch command
        when 'getStatus', 'status'
             game.get_damage_report prefix

        when 'getPowerReport'
            game.get_power_report prefix

        when 'setPowerToSystem'
            game.set_power_to_system prefix, q.system_name, q.level

        when 'power'
            switch method
                when 'get'
                    game.get_power_report prefix
                when 'post'
                    game.set_power_to_system prefix, q.system_name, q.level

        when 'reactor'
            switch method
                when 'post'
                    game.set_power_to_reactor prefix, q.reactor, q.level

        when 'eps-route'
            switch method
                when 'post'
                    game.reroute_power_relay prefix, q.eps_relay, q.primary_power_relay

        when 'online'
            switch method
                when 'post'
                    game.set_system_online prefix, q.system, ( q.online != "offline" )

        when 'active'
            switch method
                when 'post'
                    game.set_system_active prefix, q.system, ( q.active != "inactive" )


command_api = ( prefix, method, command, params, res ) ->

    q = params

    resp = switch command
        when 'getPostfixCode'
            get_postfix_code prefix, q.ship, res

        when 'getScan'
            { results: game.scan prefix }

        when 'getMap'
            { results: game.get_map prefix }

        when 'mainViewer', 'main-viewer'
            if method == 'put'or method == 'post'
                set_main_viewer prefix, q

        when 'getSystemScan'
            game.get_system_scan prefix, q.target

        when 'targets-in-visual-range'
            game.get_targets_in_visual_range prefix

        when 'captains-log'
            game.get_captains_log prefix


set_course = ( prefix, bearing, mark ) ->

    b = atoi "0." + bearing
    m = atoi mark
    game.set_course prefix, b, m


plot_intercept = ( prefix, target, impulse, warp ) ->

    impulse_i = atoi impulse
    warp_i = atoi warp
    intTime = game.plot_course_and_engage prefix, target, {impulse: impulse_i, warp: warp_i}
    return { timeToIntercept: intTime }


set_main_viewer = ( prefix, params ) ->

    url = params.screen
    query = ""

    for k, v of params
        if k is "screen" then continue
        query += "&#{ k }=#{ v }"

    if query isnt ""
        url += "?" + query


    for consoleSocket in shipSockets[ prefix ]
        consoleSocket.emit "setScreen", { screen : url }

    return { status : 'OK' }


###
  View handling
___________________________________________________###

get_postfix_code = ( req, res ) ->

    prefix = req.query.prefix
    ship_name = req.query.ship
    console.log "Getting postfix code"

    for ship in game.get_startup_stats()
        if ship.name == ship_name and ship.prefix.toString() == prefix
            res.cookie "postfix", ship.postfix
            res.cookie "ship", ship.name

            # Allow resetting a damaged console on start of new game
            res.cookie "cracked", false

            res.json { status: "OK" }

    res.json {status: "FAIL"}


shipPage = ( req, res ) ->

    postfix = req.cookies.postfix
    if ships[postfix] is undefined
        res.render "error.html"
    shipname = req.cookies.ship
    res.render "ship.html", {ship: {name: shipname}}


error = ( req, res ) ->

    res.render "error.html"


mainviewer = ( req, res ) ->

    prefix = validate req, res
    r =
        ship: {name: req.cookies.ship}
        port: PORT
        title: "#{ req.cookies.ship } Main Viewscreen"
    res.render "mainviewer.html", r


viewscreen = ( req, res ) ->

    prefix = validate req, res
    direction = req.query.direction
    r =
        direction: direction
        ship: {name: req.cookies.ship}
        title: "#{ req.cookies.ship } viewscreen"
    res.render "viewscreen.html", r


viewscreen_screen = ( req, res ) ->

    prefix = validate req, res
    target_name = req.query.target

    game.set_main_view_target prefix, target_name

    r =
        title: "#{ req.cookies.ship } viewscreen"
        target: target_name
    res.render "viewscreen_screen.html", r


ops = ( req, res ) ->

    prefix = validate req, res
    r =
        title: "#{req.cookies.ship} Ops"
        ship: {name: req.cookies.ship}
    res.render "ops.html", r


ops_crew_screen = ( req, res ) ->

    prefix = validate req, res
    r =
        ship : { name : req.cookies.ship }
        title : "Crew Display"
        alignment : game.get_alignment prefix
    res.render "ops_crew_screen.html", r


ops_cargo_screen = ( req, res ) ->

    prefix = validate req, res
    r =
        ship : { name : req.cookies.ship }
        title : "Cargo"
    res.render "ops_cargo_screen.html", r


ops_trans_screen = ( req, res ) ->

    prefix = validate req, res
    origin = req.query.origin
    destination = req.query.destination
    trans_type = req.query.trans_type
    r =
        ship : { name : req.cookies.ship }
        title : "Transporter"
        origin : origin
        destination : destination
        trans_type : trans_type
    res.render "ops_trans_screen.html", r


ops_repair_screen = ( req, res ) ->

    prefix = validate req, res
    sys_name = req.query.system_name
    r =
        ship : { name : req.cookies.ship }
        system_name : sys_name
        title : "Repair Screen"
    res.render "ops_repair_screen.html", r


tactical = ( req, res ) ->

    prefix = validate req, res
    r =
        title : "#{req.cookies.ship} Tactical"
        ship : { name : req.cookies.ship }
        port : PORT
    res.render "tactical.html", r


tactical_screen = ( req, res ) ->

    prefix = validate req, res
    zoom = req.query.zoom
    zoom_level = req.query.zoom_level
    zoom_level ?= 1
    render =
        title : "#{ req.cookies.ship } Tactical Screen"
        ship :
            name : req.cookies.ship
        zoom : zoom
        zoom_level : zoom_level
    res.render "tactical_screen.html", render


comm_screen = ( req, res ) ->

    prefix = validate req, res
    r =
        port : PORT
        title : "Communications"
    res.render "communications_screen.html", r


conn = ( req, res ) ->

    prefix = validate req, res
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Conn"
        currentSystem : game.ships[ prefix ].star_system.name
    res.render "conn.html", render


conn_screen = ( req, res ) ->

    prefix = validate req, res
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Helm View"
        system_name : req.query.system
    res.render "conn_screen.html", render


science = ( req, res ) ->

    prefix = validate req, res
    res.render "science.html", {title: "#{req.cookies.ship} Science"}


engineering = ( req, res ) ->

    prefix = validate req, res
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Engineering"
    res.render "engineering.html", render


engineering_screen = ( req, res ) ->

    prefix = validate req, res
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } System Status"
    res.render "engineering_screen.html", render


engineering_power = ( req, res ) ->

    prefix = validate req, res
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Power Distribution"
        component : req.query.component
        power_type : req.query.power_type
    res.render "engineering_power.html", render


science_scans = ( req, res ) ->

    prefix = validate req, res
    type = if req.query.type? then req.query.type else ""
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Primary Scans"
        type : type
    res.render "science_scans.html", render


science_scans_lr = ( req, res ) ->

    prefix = validate req, res
    type = if req.query.type? then req.query.type else ""
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Long Range Scans"
        type : type
    res.render "science_scans_lr.html", render


science_details = ( req, res ) ->

    prefix = validate req, res
    {classification, distance, bearing, tag} = req.query
    render =
        ship :
            name : req.cookies.ship
        title : "#{ req.cookies.ship } Detail Scan"
        classification : classification
        bearing : bearing
        distance : distance
        tag : tag
    res.render "science_details.html", render


science_environmental = ( req, res ) ->

    prefix = validate req, res
    r =
        ship :
            name : req.cookies.ship
        title : "Environmental Scan"
    res.render "science_environmental.html", r


science_internal = ( req, res ) ->

    prefix = validate req, res
    r =
        ship :
            name : req.cookies.ship
        title : "Internal Scan"
    res.render "science_internal.html", r


# Debug views
test_socket = ( req, res ) ->

    res.cookie "postfix", "test_postfix"
    res.render "test_socket.html"


###
  Routing
___________________________________________________###

# Views
app.use '/static', express.static('static')
app.get '/', landingPage
app.get '/postfix', get_postfix_code
app.get '/ship', shipPage
app.get '/mainviewer', mainviewer
app.get '/viewscreen', viewscreen
app.get '/viewscreen_screen', viewscreen_screen
app.get '/ops', ops
app.get '/ops_crew_screen', ops_crew_screen
app.get '/ops_cargo_screen', ops_cargo_screen
app.get '/ops_repair_screen', ops_repair_screen
app.get '/ops_trans_screen', ops_trans_screen
app.get '/tactical', tactical
app.get '/tactical_screen', tactical_screen
app.get '/conn', conn
app.get '/conn_screen', conn_screen
app.get '/science', science
app.get '/engineering', engineering
app.get '/engineering_screen', engineering_screen
app.get '/engineering_power', engineering_power
app.get '/comm_screen', comm_screen
app.get '/science_scans', science_scans
app.get '/science_scans_lr', science_scans_lr
app.get '/science_details', science_details
app.get '/science_environmental', science_environmental
app.get '/science_internal', science_internal
app.get '/error', error

# API
app.get '/api/:category/:command', handle_API
app.put '/api/:category/:command', handle_API
app.post '/api/:category/:command', handle_API
app.get '/api/:command', legacy_API

# Debug
app.get '/debug', debug
app.get '/debugMap', debugMap
app.get '/debugCoordinateSpace', debugCoordinateSpace
app.get '/debugBearings', debugBearings
app.get '/test_socket', test_socket


###
  Startup
___________________________________________________###

console.log "Stardate #{ game.level.stardate }"
console.log "Ships in game..."
ships = {}
ship_postfixes = []

for ship in game.get_startup_stats()
    console.log "#{ship.name} #{ship.prefix}"
    ships[ship.postfix] = ship.prefix
    ship_postfixes.push ship.postfix

PORT = 8080
server.listen PORT, "0.0.0.0"
