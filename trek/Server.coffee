express = require "express"
app = express()
app.use express.cookieParser( "darmok&jalad" )
app.use express.bodyParser()

io = require "socket.io"
http = require "http"
server = http.createServer app
socket = io.listen server, { log : false }
cookie = require "cookie"

program = require "commander"

fs = require "fs"


program
    .version( "0.21" )
    .option( "-l, --level [level]", "Select a level.", "DGTauIncident" )
    .option( "-t, --teams [count]", "Enter the number of teams.", parseInt, 1 )
    .parse( process.argv )

{Game} = require "./Game"
ai = require "./AI"

game = new Game program.level, program.teams

app.engine "html", require( "ejs" ).renderFile

landingPage = ( req, res ) ->

    res.render "index.html", { ships : do game.get_ships }


### Utilities
___________________________________________________###

validate = ( req, res ) ->

    # take a request, response and validate for a prefix code
    postfix = req.cookies.postfix
    if postfix of ships
        return ships[ postfix ]
    else
        res.render "error.html"
        return false


postfix_validate = ( postfix ) -> return ships[ postfix ]


atoi = ( str ) -> parseFloat str, 10


itoa = ( n ) -> do n.toString


### State
___________________________________________________###
players = JSON.parse( do fs.readFileSync("brain/players.json").toString )

save_state = () ->

    fs.writeFile "brain/players.json", JSON.stringify( players, null, 4 )


### Debug
___________________________________________________###

debug = ( req, res ) ->
    prefix = validate req, res
    res.json { debug : 'debug' }


debugMap = ( req, res ) ->

    prefix = validate req, res
    res.json game.debug_space_map prefix


debugCoordinateSpace = ( req, res ) -> res.json do game.debug_positions


debugBearings = ( req, res ) ->

    prefix = validate req, res
    res.json game.debug_bearings prefix


### Socket Setup
___________________________________________________###

shipSockets = {}

socketAuth = ( data, accept ) ->
    if data.headers.cookie
        data.cookie = cookie.parse data.headers.cookie
        data.postfix = data.cookie[ "postfix" ]
    else
        return accept "No cookie transmitted", false
    accept null, true

socket.set "authorization", socketAuth


socketConnection = ( socket ) ->
    socket.postfix = socket.handshake.postfix
    prefix = postfix_validate socket.postfix
    if not prefix
        return
    if shipSockets[ prefix ]?
        shipSockets[ prefix ].push socket
    else
        shipSockets[ prefix ] = [ socket ]

    socket.on( "disconnect", ->
        shipSockets[ prefix ] = shipSockets[ prefix ].filter ( s ) -> s isnt socket
    )

socket.on("connection", socketConnection)


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

    if method == "get"
        params = req.query
    else
        params = req.body

    command = req.params.command

    resp = switch category
        when "navigation" then navigation_api prefix, method, command, params
        when "tactical" then tactical_api prefix, method, command, params
        when "operations" then operations_api prefix, method, command, params
        when "transporters" then transporters_api prefix, method, command, params
        when "science" then science_api prefix, method, command, params
        when "engineering" then engineering_api prefix, method, command, params
        when "communications" then communications_api prefix, method, command, params
        # Command sets some cookies and requires the response object
        when "command" then command_api prefix, method, command, params, res
        when "academy" then academy_api prefix, method, command, params

    if resp is undefined
        console.log params
        throw new Error "Undefined response object for #{ category }/#{ command }"

    res.json resp


academy_api = ( prefix, method, command, params ) ->

    classes = fs.readdirSync 'views/academy'
    screen = do params.screen.toLowerCase

    resp = switch command

        when "courses"
            if method == "get"
                for c in classes when c.split( "_" )[ 0 ] is screen
                    screen : c.split( '_' )[ 0 ],
                    sequence : c.split( '_' )[ 1 ],
                    hash : c.split( '_' )[ 2 ].split( '.' )[ 0 ]
                    html : String( fs.readFileSync( 'views/academy/' + c ) )


navigation_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command

        when "position"
            if method == "get"
                { results : game.get_position prefix }

        when "course"
            if method == "put"
                set_course prefix, q.bearing, q.mark

        when "turn"
            if method == "put"
                switch params.direction
                    when "stop" then game.stop_turn prefix
                    when "port" then game.turn_port prefix
                    when "starboard" then game.turn_starboard prefix

        when "thrust"
            switch method
                when "post", "put"
                    game.thrusters prefix, params.direction

        when "status"
            game.get_navigation_report prefix

        when "warp"
            if method == "post"
                game.set_warp_speed prefix, atoi( q.speed )

        when "impulse"
            if method == "post"
                game.set_impulse_speed prefix, atoi( q.speed )

        when "system"
            # stellar telemetry
            game.get_system_information prefix, q.system

        when "charts"
            game.get_charted_objects prefix, q.system

        when "stelar-telemetry"
            game.get_stellar_telemetry prefix, q.target

        when "sector-telemetry"
            game.get_sector_telemetry prefix


tactical_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command
        when "alert"
            switch method
                when "post"
                    game.set_alert prefix, q.status
                when "get"
                    game.get_alert prefix

        when "scan"
            game.scan prefix

        when "status"
            game.get_tactical_status prefix

        when "shields"
            switch method
                when "post"
                    game.set_shields prefix, q.online
                when "get"
                    game.get_shield_status prefix

        when "target"
            switch method
                when "post"
                    game.target prefix, q.target, q.deck, q.section
                when "get"
                    game.get_target_subsystems prefix

        when "fireTorpedo"
            game.fire_torpedo prefix, q.yield

        when "loadTorpedo"
            game.load_torpedo_tube prefix, q.tube

        when "phasers"
            switch method
                when "post"
                    game.fire_phasers prefix
                when "get"
                    game.get_phaser_status prefix


communications_api = ( prefix, method, command, params ) ->

    resp = switch command
        when "comms"
            switch method
                when "get" then game.get_comms_history prefix
                when "post"
                    # HTML escape user input
                    msg = params.message.replace( /</g, "&lt;" ).replace( />/g, "&gt;" )
                    game.hail prefix, msg


operations_api = ( prefix, method, command, params ) ->

    resp = switch command

        when "internalScan", "internal-scan"
            game.get_internal_lifesigns_scan prefix

        when "systems-layout"
            game.get_systems_layout prefix

        when "cargo"
            game.get_cargo_status prefix

        when "decks"
            game.get_decks prefix

        when "sections"
            game.get_sections prefix

        when "sendTeamToDeck", "send-team-to-deck"
            switch method
                when "post"
                    game.send_team_to_deck(
                        prefix,
                        atoi( params.crew_id ),
                        params.to_deck,
                        params.to_section
                    )

        when "repairTeam"
            game.assign_repair_crews(
                prefix,
                params.system_name,
                atoi( params.teams) ,
                ( params.to == "completion" )
            )


transporters_api = ( prefix, method, command, params ) ->

    q = params
    resp = switch command

        when "transporterRange"
            game.in_transporter_range prefix

        when "crewReadyToTransport"
            game.crew_ready_to_transport prefix

        when "transportCargo"
            switch method
                when "post"
                    game.transport_cargo(
                        prefix,
                        q.origin, q.origin_bay,
                        q.destination, atoi( q.destination_bay ),
                        q.cargo, atoi( q.qty ) )

        when "transportCrew"
            switch method
                when "post"
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
        when "runScan"
            switch method
                when "put"
                    game.run_scan(
                        prefix,
                        q.type,
                        atoi( q.grid_start ),
                        atoi( q.grid_end ),
                        true,
                        q.range,
                        q.resolution )

        when "scanResults"
            game.get_scan_results prefix, q.type

        when "scanConfiguration"
            game.get_scan_configuration prefix, q.type

        when "LRScanResults"
            game.get_lr_scan_results prefix, q.type

        when "LRScanConfiguration"
            switch method
                when "get"
                    game.get_lr_scan_configuration prefix, q.type
                when "put"
                    game.configure_long_range_scan(
                        prefix,
                        q.type,
                        q.range,
                        q.resolution )

        when "internal-scan"
            game.get_internal_scan prefix

        when "environmental-scan"
            game.get_environmental_scan prefix

        when "activeScan"
            game.get_active_scan( prefix, q.classification, q.distance,
                q.bearing, q.tag )


engineering_api = ( prefix, method, command, params ) ->

    q = params

    resp = switch command
        when "getStatus", "status"
            game.get_damage_report prefix

        when "getPowerReport"
            game.get_power_report prefix

        when "setPowerToSystem"
            game.set_power_to_system prefix, q.system_name, q.level

        when "power"
            switch method
                when "get"
                    game.get_power_report prefix
                when "post"
                    game.set_power_to_system prefix, q.system_name, q.level

        when "reactor"
            switch method
                when "post"
                    game.set_power_to_reactor prefix, q.reactor, q.level

        when "eps-route"
            switch method
                when "post"
                    game.reroute_power_relay prefix, q.eps_relay, q.primary_power_relay

        when "online"
            switch method
                when "post"
                    game.set_system_online prefix, q.system, ( q.online != "offline" )

        when "active"
            switch method
                when "post"
                    game.set_system_active prefix, q.system, ( q.active != "inactive" )


command_api = ( prefix, method, command, params, res ) ->

    q = params

    resp = switch command
        when "getPostfixCode"
            get_postfix_code prefix, q.ship, res

        when "getScan"
            { results: game.scan prefix }

        when "getMap"
            { results: game.get_map prefix }

        when "mainViewer", "main-viewer"
            if method == "put" or method == "post"
                set_main_viewer prefix, q

        when "getSystemScan"
            game.get_system_scan prefix, q.target

        when "targets-in-visual-range"
            game.get_targets_in_visual_range prefix

        when "captains-log"
            game.get_captains_log prefix

        when "game"
            game.uid

        when "theme"
            game.theme_music


set_course = ( prefix, bearing, mark ) ->

    b = atoi( bearing ) / 1000
    m = atoi( mark ) / 1000
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

    return { status : "OK" }


###
  View handling
___________________________________________________###


handle_view = ( req, res ) ->

    if not prefix = validate req, res
        # DEBUG
        console.log "View: ", req.params.view
        console.log "Debug prefix lookup failure\nGame.ships:"
        console.log (k for k, v of game.ships)
        console.log "Postfix: #{ req.cookies.postfix }"
        console.log "Ship prefixes: ", ship_postfixes
        console.log "Ships: ", ships
        return

    ship_name = req.cookies.ship

    view = req.params.view

    r =
        ship : { name : req.cookies.ship }
        title : ship_name
        alignment : game.get_alignment prefix
        port : PORT

    switch view
        when "ship" then shipPage req, res, prefix, r
        when "mainviewer" then mainviewer req, res, prefix, r
        when "viewscreen" then viewscreen req, res, prefix, r
        when "viewscreen_screen" then viewscreen_screen req, res, prefix, r
        when "ops" then ops req, res, prefix, r
        when "ops_crew_screen" then ops_crew_screen req, res, prefix, r
        when "ops_cargo_screen" then ops_cargo_screen req, res, prefix, r
        when "ops_repair_screen" then ops_repair_screen req, res, prefix, r
        when "ops_trans_screen" then ops_trans_screen req, res, prefix, r
        when "tactical" then tactical req, res, prefix, r
        when "tactical_screen" then tactical_screen req, res, prefix, r
        when "conn" then conn req, res, prefix, r
        when "conn_screen" then conn_screen req, res, prefix, r
        when "science" then science req, res, prefix, r
        when "engineering" then engineering req, res, prefix, r
        when "engineering_screen" then engineering_screen req, res, prefix, r
        when "engineering_power" then engineering_power req, res, prefix, r
        when "comm_screen" then comm_screen req, res, prefix, r
        when "science_scans" then science_scans req, res, prefix, r
        when "science_scans_lr" then science_scans_lr req, res, prefix, r
        when "science_details" then science_details req, res, prefix, r
        when "science_environmental" then science_environmental req, res, prefix, r
        when "science_internal" then science_internal req, res, prefix, r
        when "error" then error req, res, prefix, r


get_postfix_code = ( req, res ) ->

    prefix = req.query.prefix
    ship_name = req.query.ship
    console.log "Getting postfix code"

    for ship in game.get_startup_stats().player_ships
        if ship.name == ship_name and ship.prefix.toString() == prefix
            res.cookie "postfix", ship.postfix
            res.cookie "ship", ship.name

            # Allow resetting a damaged console on start of new game
            res.cookie "cracked", false

            res.json { status : "OK" }

    res.json { status : "FAIL" }


shipPage = ( req, res, prefix, r ) ->

    postfix = req.cookies.postfix
    if ships[ postfix ] is undefined
        res.render "error.html"

    res.render "ship.html", r


error = ( req, res, prefix, r ) -> res.render "error.html"


mainviewer = ( req, res, prefix, r ) ->

    r.title = "Main Viewscreen"
    res.render "mainviewer.html", r


viewscreen = ( req, res, prefix, r ) ->

    r.direction = req.query.direction
    res.render "viewscreen.html", r


viewscreen_screen = ( req, res, prefix, r ) ->

    r.target = req.query.target or req.query.direction
    res.render "viewscreen_screen.html", r


ops = ( req, res, prefix, r ) ->

    r.title += " Ops"
    res.render "ops.html", r


ops_crew_screen = ( req, res, prefix, r ) -> res.render "ops_crew_screen.html", r


ops_cargo_screen = ( req, res, prefix, r ) -> res.render "ops_cargo_screen.html", r


ops_trans_screen = ( req, res, prefix, r ) ->

    r.origin = req.query.origin
    r.destination = req.query.destination
    r.trans_type = req.query.trans_type
    res.render "ops_trans_screen.html", r


ops_repair_screen = ( req, res, prefix, r ) ->

    r.system_name = req.query.system_name
    res.render "ops_repair_screen.html", r


tactical = ( req, res, prefix, r ) ->

    r.title += " Tactical"
    res.render "tactical.html", r


tactical_screen = ( req, res, prefix, r ) ->

    zoom_level = req.query.zoom_level
    zoom_level ?= 1
    r.zoom = req.query.zoom
    r.zoom_level = zoom_level
    res.render "tactical_screen.html", r


comm_screen = ( req, res, prefix, r ) -> res.render "communications_screen.html", r


conn = ( req, res, prefix, r ) ->

    r.currentSystem = game.ships[ prefix ].star_system.name
    r.title += " Conn"
    res.render "conn.html", r


conn_screen = ( req, res, prefix, r ) ->

    r.system_name = req.query.system
    res.render "conn_screen.html", r


science = ( req, res, prefix, r ) ->

    r.title += " Science"
    res.render "science.html", r


engineering = ( req, res, prefix, r ) ->

    r.title += " Engineering"
    res.render "engineering.html", r


engineering_screen = ( req, res, prefix, r ) -> res.render "engineering_screen.html", r


engineering_power = ( req, res, prefix, r ) ->

    r.power_type = req.query.power_type
    r.component = req.query.component
    res.render "engineering_power.html", r


science_scans = ( req, res, prefix, r ) ->

    type = if req.query.type? then req.query.type else ""
    r.type = type
    res.render "science_scans.html", r


science_scans_lr = ( req, res, prefix, r ) ->

    type = if req.query.type? then req.query.type else ""
    r.type = type
    res.render "science_scans_lr.html", r


science_details = ( req, res, prefix, r ) ->

    {classification, distance, bearing, tag} = req.query
    r.classification = classification
    r.bearing = bearing
    r.distance = distance
    r.tag = tag
    res.render "science_details.html", r


science_environmental = ( req, res, prefix, r ) -> res.render "science_environmental.html", r


science_internal = ( req, res, prefix, r ) -> res.render "science_internal.html", r


# Debug views
test_socket = ( req, res ) ->

    res.cookie "postfix", "test_postfix"
    res.render "test_socket.html"


###
  Routing
___________________________________________________###


app.use "/static", express.static("static")
app.get "/favicon.ico", ( req, res ) ->
    res.status( 200 ).end()

# API
app.get "/api/:category/:command", handle_API
app.put "/api/:category/:command", handle_API
app.post "/api/:category/:command", handle_API

app.get "/api/:command", legacy_API

# Debug
app.get "/debug", debug
app.get "/debugMap", debugMap
app.get "/debugCoordinateSpace", debugCoordinateSpace
app.get "/debugBearings", debugBearings
app.get "/test_socket", test_socket

# Views
app.get "/postfix", get_postfix_code
app.get "/:view", handle_view
app.get "/", landingPage


###
  Startup
___________________________________________________###

console.log "Stardate #{ game.level.stardate }"
console.log "Ships in game..."
ships = {}
ship_postfixes = []

game_stats = do game.get_startup_stats
for ship in game_stats.player_ships
    console.log "#{ship.name} #{ship.prefix}"
    ships[ship.postfix] = ship.prefix
    ship_postfixes.push ship.postfix

# Setup AI
ai_prefixes = ( s.prefix for s in game_stats.ai_ships )
ai_states = game_stats.ai_states
AIs = ai.play game, ai_prefixes, ai_states
for s in game_stats.ai_ships
    console.log "#{s.name} #{s.prefix}"

game.set_AIs AIs


PORT = 8088
server.listen PORT, "0.0.0.0"
