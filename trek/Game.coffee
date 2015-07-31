fs = require 'fs'

{SensorSystem, LongRangeSensorSystem} = require './systems/SensorSystems'
{Torpedo} = require './Torpedo'
{Transporters} = require './systems/TransporterSystems'

C = require './Constants'
U = require './Utility'


class Game

    @TICK_MS = 250

    constructor: ( level_name, team_count ) ->

        @is_over = false

        level_files = fs.readdirSync "./trek/levels"
        lfs = ( l[ 0...l.indexOf( "." ) ] for l in level_files when l.indexOf( ".coffee" ) > 0 )

        # ...
        {Level} = require "./levels/#{ level_name }"
        @level = new Level team_count
        @load_level @level

        @_clock = new Date().getTime()

        @i = setInterval @update_state, Game.TICK_MS

        @uid = do U.UID


    message: ( prefix, type, content ) ->

        to = @ships[ prefix ].name
        console.log "Message to #{ to } [#{ type }]:"
        console.log content


    set_message_function: ( message_function ) ->

        console.log "Connecting socket messaging..."
        @message = message_function
        for prefix, s of @ships
            s.set_message_function message_function


    load_level: ( level ) ->

        @ships = do level.get_ships

        # two seperate lists for convenience
        @ai_ships = do level.get_ai_ships
        @player_ships = do level.get_player_ships

        @game_objects = do level.get_game_objects
        @space_objects = do level.get_space_objects
        @map = do level.get_map

        @level_events = do level.get_events
        for event in @level_events
            event.listen @

        @environment_functions = do level.get_environment


    state: ->
        # return a station
        s = ( o for o in @game_objects when not o.prefix_code? )[0]


    debug_space_map: ( prefix ) ->

        ship = @ships[ prefix ]
        r = (
            for x in @space_objects
                U.distance( ship.position, x.position ) / C.AU
        ).sort()


    debug_positions: ->

        p = (
            for o in @game_objects
                { name : o.name, position: o.position }
        )


    debug_bearings: ( prefix ) ->

        b = (
            for o in @game_objects
                {
                    name : o.name,
                    rel_bearing : U.bearing( @ships[ prefix ], o ),
                    abs_bearing : o.bearing
                }
        )


    random_start_coordinates: ->

        board_size = C.SYSTEM_WIDTH / 3
        x = Math.round( ( Math.random() - 0.5 ) * board_size )
        y = Math.round( ( Math.random() - 0.5 ) * board_size )
        z = 0
        r = { x : x, y : y, z : z }


    get_startup_stats: ->

        player_ships = for k, s of @player_ships
            {
                name : s.name,
                prefix : s.prefix_code,
                postfix : s.postfix_code,
                position : s.position
            }

        ai_ships = for k, s of @ai_ships
            {
                name : s.name,
                prefix : s.prefix_code,
                postfix : s.postfix_code,
                position : s.position

            }

        r =
            player_ships : player_ships
            ai_ships : ai_ships


    get_ships: -> ( { name : s.name, registry : s.serial } for k, s of @player_ships )


    ### Prefix Requisit Codes
    ________________________________________________###

    get_captains_log: ( prefix ) -> do @ships[ prefix ].get_pending_captains_logs


    get_position: ( prefix ) ->

        p =
            position: @ships[ prefix ].position
            heading: @ships[ prefix ].bearing
            velocity: @ships[ prefix ].velocity
            impulse: @ships[ prefix ].impulse
            warp: @ships[ prefix ].warp_speed


    get_map: ( prefix, zoom_level, zoom_x, zoom_y, zoom_z ) ->

        zoom_level ?= 1
        zoom_x ?= 0
        zoom_y ?= 0
        zoom_z ?= 0

        width = C.SYSTEM_WIDTH / zoom_level

        # centered on 0, 0
        system = {
            min_x: zoom_x - width / 2
            max_x: width / 2
            min_y: zoom_y - width / 2
            max_y: width / 2
            min_z: 0 - width / 2
            max_z: width / 2
            charted_objects: ( o for o in @space_objects when o.charted == true )
        }


    get_charted_objects: ( prefix, system_name ) ->

        star_system = @map.get_star_system system_name
        if not star_system?
            throw new Error "Cannot find star system #{ system_name }"

        you = @ships[ prefix ]

        # Get charted objects,
        ## Don't pass gas clouds, as these get handled by the system scan
        ## TODO: Fix this^ gas clouds should be considered charted system objects
        r = ( @get_public_space o, you, "Star" for o in star_system.stars when o.charted )
        p = ( @get_public_space o, you, "Planet" for o in star_system.planets when o.charted )
        a = ( @get_public_space o, you, "Asteroids" for o in star_system.asteroids when o.charted )

        # Overlay any subspace becons
        s = ( @get_public o, you for o in @game_objects when @get_public o, you )

        # Overlay points that you have scanned and are tracking
        # tracking = ( @get_tracking_data o, you for o in you.get_scanned_objects() )

        resp = r.concat( s ).concat( p ).concat( a )


    get_system_information: ( prefix, system_name ) ->
        # Stellar system, not systems system
        @map.get_star_system system_name


    get_sector_telemetry: ( prefix ) ->
        # Sector informaiton
        do @map.index


    scan: ( prefix ) ->

        do @update_state
        # Scan for subspace transceivers and mapped objects
        # TODO: Check scan systems; also, isn't this a function of the object?
        #       Ship should be told to scan, and should use it's callback to scan the world
        you = @ships[ prefix ]
        space_objects = ( @get_public_space o, you for o in @space_objects when @get_public_space( o, you ) )
        objects = ( @get_public o, you for o in @game_objects when @get_public( o, you ) )
        results = objects.concat space_objects


    get_system_scan: ( prefix, target_name ) ->

        o = ( o for o in @game_objects when o.name == target_name )[0]
        @ships[ prefix ].scan_object o


    get_navigation_report: ( prefix ) -> do @ships[ prefix ].navigation_report


    set_course: ( prefix, bearing, mark ) ->

        if isNaN mark
            mark = 0
        console.log "Setting course #{ bearing } #{ mark }"
        message = @ships[ prefix ].set_course bearing, mark
        @message prefix, "Navigation", message

        return message


    full_stop: ( prefix ) ->

        @ships[ prefix ].set_impulse 0
        do @ships[ prefix ].stop_turn


    stop_turn: ( prefix ) -> do @ships[ prefix ].stop_turn


    turn_port: ( prefix ) -> do @ships[ prefix ].turn_port


    turn_starboard: ( prefix ) -> do @ships[ prefix ].turn_starboard


    thrusters: ( prefix, direction ) -> @ships[ prefix ].fire_thrusters direction


    plot_course_and_engage: ( prefix, target_name, {impulse, warp} ) ->

        # TODO Move this internal to the ship--it belongs there
        you = @ships[ prefix ]
        impulse = if isNaN( impulse ) then 0 else impulse
        warp = if isNaN( warp ) then 0 else warp

        target = ( o for o in @game_objects when o.name == target_name )[ 0 ]
        if not target
            target = ( o for o in @space_objects when o.name == target_name )[ 0 ]
        if not target
            throw new Error 'Invalid target'

        imp_warp =
            impulse: impulse
            warp: warp

        you.intercept target, imp_warp


    match_course_and_speed: ( prefix, target_name ) =>

        target = ( o for o in @game_objects when o.name == target_name )[ 0 ]
        if not target
            target = ( o for o in @space_objects when o.name == target_name )[ 0 ]

        # TODO: Techincally, we should be matching the heading
        # first, but it mucks with test timing.

        # TODO: Move this into the ships

        # Match speed first
        if target.warp_speed != 0
            @set_warp_speed prefix, target.warp_speed
        else
            @set_impulse_speed prefix, target.impulse

        m = @ships[ prefix ]._set_abs_course target.bearing
        @message prefix, "Navigation", m



    set_warp_speed: ( prefix, warp ) ->

        @message prefix, "Navigation", { set_speed : "warp", value : warp }
        @ships[ prefix ].set_warp warp


    set_impulse_speed: ( prefix, impulse ) ->

        @message prefix, "Navigation", { set_speed : "impulse", value: impulse }
        @ships[ prefix ].set_impulse impulse


    set_shields: ( prefix, is_online ) -> @ships[ prefix ].set_shields is_online


    get_shield_status: ( prefix ) -> do @ships[ prefix ].shield_report


    target: ( prefix, name, deck, section ) ->

        target = ( s for s in @game_objects when s.name == name )[ 0 ]
        @ships[ prefix ].set_target target, deck, section


    get_target_subsystems: ( prefix ) -> do @ships[ prefix ].get_target_subsystems


    fire_phasers: ( prefix, threshold ) -> @ships[ prefix ].fire_phasers threshold


    get_phaser_status: ( prefix ) -> do @ships[ prefix ].phaser_report


    detonation_event: ( position, blast_power ) =>

        console.log "Blast event at #{ position.x } #{ position.y } #{ position.z }: yield #{ blast_power }"
        # Calculate damage to everything
        for o in @game_objects
            o.process_blast_damage position, blast_power, @message
        # for thing in @space_objects
        #    thing.process_blast_damage(position, blast_power)
        things_that_died = ( o for o in @game_objects when not o.alive )
        for death in things_that_died
            for prefix, ship of @ships
                @message prefix, "Display", "Destroyed:#{ death.name }"

        @game_objects = ( o for o in @game_objects when o.alive )


    two_second_torpedo_event: ( target_name ) =>

        for prefix, ship of @ships
            @message prefix, "Display", "Torpedo hitting:#{ target_name }"


    fire_torpedo: ( prefix, yield_level ) =>

        torpedo = @ships[ prefix ].fire_torpedo( yield_level=yield_level )

        if torpedo instanceof Torpedo
            torpedo.detonation_callback = @detonation_event
            torpedo._two_second_callback = @two_second_torpedo_event
            @game_objects.push torpedo
            return "torpedo fired"
        else
            return "torpedo launch failed: #{ torpedo }"


    load_torpedo_tube: ( prefix, tube_number ) -> @ships[ prefix ].load_torpedo tube_number


    set_alert: ( prefix, color ) ->

        m = @ships[ prefix ].set_alert color
        # @message( prefix, "alert", color )
        return m


    get_alert: ( prefix ) -> @ships[ prefix ].alert


    get_damage_report: ( prefix ) -> @ships[ prefix ].damage_report()


    get_tactical_status: ( prefix ) -> @ships[ prefix ].tactical_report()


    get_targets_in_visual_range: ( prefix ) ->

        ship = @ships[ prefix ]
        objects = ( o.name for o in @game_objects when U.distance( ship.position, o.position ) < C.VISUAL_RANGE )


    get_stelar_telemetry: ( prefix, target_name ) ->

        ship = @ships[ prefix ]
        stars = ( o for o in @space_objects when o.classification.indexOf( "Star" ) >= 0 )

        telemetry =
            bearing_to_star : U.bearing( ship, stars[ 0 ] )

            skybox : ship.star_system.skybox

        target = ( o for o in @game_objects when o.name == target_name )[ 0 ]
        if target?
            telemetry[ 'bearing_to_viewer' ] = U.bearing( target, ship )
            telemetry[ 'bearing_to_target' ] = U.bearing( ship, target )
            telemetry[ 'target_model' ] = target.model_url
            telemetry[  'distance_from_star' ] = U.distance( target.position, stars[ 0 ].position )

        return telemetry


    get_internal_lifesigns_scan: ( prefix ) -> do @ships[ prefix ].get_internal_lifesigns_scan


    get_systems_layout: ( prefix ) -> do @ships[ prefix ].get_systems_layout


    get_cargo_status: ( prefix ) -> do @ships[ prefix ].get_cargo_status


    get_decks: ( prefix ) -> do @ships[ prefix ].get_decks


    get_sections: ( prefix ) -> do @ships[ prefix ].get_sections


    send_team_to_deck: ( prefix, crew_id, to_deck, to_section ) ->

        if to_deck is undefined
            throw new Error "Undefined destination deck."
        if to_section is undefined
            throw new Error "Undefined destination section."

        @ships[ prefix ].send_team_to_deck crew_id, to_deck, to_section


    assign_repair_crews: ( prefix, system_name, team_count, to_completion ) ->
        @ships[ prefix ].assign_repair_crews system_name, team_count, to_completion


    in_transporter_range: ( prefix ) ->

        ship = @ships[ prefix ]

        in_range = ( o for o in @game_objects when U.distance_between( ship, o ) < Transporters.RANGE )
        scanned_in_range = ( o for o in in_range when o in ship._logged_scanned_items )

        r = ( do o.transportable for o in scanned_in_range when o.transportable() )

        ignore_own_shiled = true
        r.push ship.transportable( ignore_own_shiled )

        return r


    crew_ready_to_transport: ( prefix ) -> do @ships[ prefix ].crew_ready_to_transport


    transport_crew: ( prefix, transport_args ) ->

        { crew_id, source_name, source_deck, source_section,
            target_name, target_deck, target_section } = transport_args

        ship = @ships[ prefix ]
        source = ( s for s in @game_objects when s.name == source_name )[ 0 ]
        target = ( s for s in @game_objects when s.name == target_name )[ 0 ]

        ship.transport_crew crew_id, source, source_deck, source_section, target, target_deck, target_section


    transport_cargo: ( prefix, origin_name, origin_bay, destination_name, destination_bay, cargo, qty ) ->

        ship = @ships[ prefix ]
        origin = ( o for o in @game_objects when o.name == origin_name )[ 0 ]
        destination = ( d for d in @game_objects when d.name == destination_name )[ 0 ]
        ship.transport_cargo origin, origin_bay, destination, destination_bay, cargo, qty


    get_power_report: ( prefix ) -> do @ships[ prefix ].power_distribution_report


    set_power_to_system: ( prefix, system_name, level ) ->
        @ships[ prefix ].set_power_to_system system_name, level


    set_power_to_reactor: ( prefix, reactor_name, level ) ->
        @ships[ prefix ].set_power_to_reactor reactor_name, level


    reroute_power_relay: ( prefix, eps_relay_name, primary_relay_name ) ->
        @ships[ prefix ].reroute_power_relay eps_relay_name, primary_relay_name


    set_system_online: ( prefix, system, is_online ) ->
        @ships[ prefix ].set_online system, is_online


    set_system_active: ( prefix, system, is_active ) ->
        @ships[ prefix ].set_active system, is_active


    run_scan: ( prefix, type, grid_start, grid_end, positive_sweep, range, resolution ) ->
        # depreciated... use configure instead
        @configure_scan prefix, type, grid_start, grid_end, positive_sweep, range, resolution


    configure_scan: ( prefix, type, grid_start, grid_end, positive_sweep, range, resolution ) ->

        @ships[ prefix ].run_scan(
            @world_scan,
            type,
            grid_start,
            grid_end,
            positive_sweep,
            range,
            resolution )


    run_long_range_scan: ( prefix, type, range_level, resolution ) ->
        # depreciated... use configure instead
        @configure_long_range_scan prefix, type, range_level, resolution


    configure_long_range_scan: ( prefix, type, range_level, resolution ) ->

        @ships[ prefix ].configure_long_range_scan(
            @world_scan,
            type,
            range_level,
            resolution
        )

    get_scan_results: ( prefix, type ) ->

        if type == ""
            return ""
        @ships[ prefix ].get_scan_results type


    get_scan_configuration: ( prefix, type ) -> @ships[ prefix ].get_scan_configuration type


    get_lr_scan_results: ( prefix, type ) ->

        if type == ""
            return ""

        @ships[ prefix ].get_long_range_scan_results type


    get_lr_scan_configuration: ( prefix, type ) ->
        @ships[ prefix ].get_long_range_scan_configuration type


    get_internal_scan: ( prefix ) -> do @ships[ prefix ].get_internal_scan


    set_environment_function: ( parameter, reading ) ->
        ###
        Set the environment value for 'parameter' to the function
        'reading', which takes a position value and returns a scalar.

        ###

        if parameter not in ( v for k, v of C.ENVIRONMENT )
            return

        @environment_functions[ parameter ] = reading


    get_environment_conditions: ( game_object ) ->

        @_get_environmental_conditions_at_position game_object.position


    get_environmental_scan: ( prefix ) ->

        # Display the local spatial information
        position = @ships[ prefix ].position
        @_get_environmental_conditions_at_position position


    get_environmental_condition_at_position: ( parameter, position ) ->

        if not @environment_functions[ parameter ]?
            keys = []
            for k, v of @environment_functions
                keys.push k
            throw new Error "Unrecognized parameter #{ parameter }, out of #{ keys }"

        @environment_functions[ parameter ] position


    _get_environmental_conditions_at_position: ( position ) ->

        r = (
            for k, v of @environment_functions
                {
                    parameter : k,
                    readout : v position
                } )


    get_active_scan: ( prefix, classification, distance, bearing, tag ) ->

        s = @ships[ prefix ]

        # find target
        space_matches = ( o for o in @space_objects when o.sensor_tag == tag )
        game_matches = ( o for o in @game_objects when o.sensor_tag == tag )

        matches = space_matches.concat game_matches

        if matches.length == 0
            throw new Error "Could not resolve active scan target,
            for #{ classification } at #{ Math.round( distance / 1e3 ) }km
            bearing #{ Math.round( bearing * 1e3 ) }"

        target = matches[ 0 ]

        if target.is_cloaked?()
            throw new Error "Cannot detect target"

        # is relevant sensor array online?
        # NM. It has to be, or you wouldn't have gotten the passive scan
        # TODO: validate that assumption later

        # TODO: Demeter says don't do this... expose a public method to get this info
        if not target._are_all_shields_up? or not do target._are_all_shields_up
            s.add_scanned_object target

        if target.get_system_scan?
            return do target.get_system_scan
        else
            return do target.get_detail_scan


    world_scan: ( type, position, bearing_from, bearing_to, range ) =>
        ###
        Scanner Callback: Interfaces the ships scanners with the world

        Returns:
            readings
            spectra
            classifications
                classification
                bearing (abs)
                coordinate (abs)
        ###

        # Find all objects in range, that respond to type
        game_hits = ( o for o in @game_objects when 0 < U.distance( position, o.position ) < range )
        space_hits = ( o for o in @space_objects when 0 < U.distance( position, o.position ) < range or o.charted )
        hits = game_hits.concat space_hits
        hits = ( h for h in hits when h.scan_for type )
        count_show_up_on_scan = hits.length

        # Find subset in arc of bearing
        crossing_lapping_scan = bearing_to < bearing_from
        min_bearing = Math.min bearing_to, bearing_from
        max_bearing = Math.max bearing_to, bearing_from

        if crossing_lapping_scan
            hits = ( h for h in hits when min_bearing > U.point_bearing( position, h.position ).bearing or max_bearing < U.point_bearing( position, h.position ).bearing )
        else
            hits = ( h for h in hits when min_bearing < U.point_bearing( position, h.position ).bearing < max_bearing )
        # For each object, see if blocked by space objects
        count_pre_block = hits.length

        final_hits = ( h for h in hits when not @_is_object_blocked( h, type, position ) )

        if type == SensorSystem.SCANS.P_HIGHRES
            classifications = (
                {
                    classification: h.classification,
                    coordinate: h.position,
                    tag: h.sensor_tag
                } for h in final_hits when !( h.is_cloaked? and h.is_cloaked() ) )
        else
            classifications = []

        r =
            readings: ( { bearing : U.point_bearing( position, h.position ), reading : h.scan_for type } for h in final_hits )
            classifications: classifications
            spectra: []


    debug_neutrinos: ->

        r =
            neutrinos : [ ship.scan_for LongRangeSensorSystem.SCANS.NEUTRINO for prefix, ship of @ai_ships ]
            is_cloaked : [ do ship.is_cloaked for prefix, ship of @ai_ships ]
            cloaking_system : [ do ship._get_cloak_system for prefix, ship of @ai_ships ]


    set_main_view_target: ( prefix, target_name ) ->

        @ships[ prefix ].set_viewscreen_target target_name


    ### Communications Functions
    ____________________________________________###
    get_comms_history: ( prefix ) -> do @ships[ prefix ].get_comms


    hail: ( prefix, message ) =>

        hail_function = ( msg ) =>
            for pfix, ship of @ships when pfix isnt prefix
                if ship.hear_hail prefix, message
                    @message pfix, "hail", msg

        response_function = ( msg ) =>
            for pfix, ship of @ships
                if ship.hear_hail "", msg
                    @message pfix, "hail", msg

        @level.handle_hail prefix, message, response_function

        @ships[ prefix ].hail message, hail_function



    ### Utility Functions
    ____________________________________________###
    update_state: =>

        # Hack: passing in world scan here is such a cop-out...
        # only the player ships need it. And even then, it might be better
        # to just set this on the construction of the ships, and hope the
        # reference holds

        now = do Date.now
        delta_t = now - @_clock
        @_clock = now

        o.set_environmental_conditions( @get_environment_conditions o ) for o in @game_objects
        o.calculate_state @world_scan, delta_t for o in @game_objects

        if @is_over
            console.log "[GAME] OVER!"
            clearInterval @i
            score = do @level.get_final_score
            for prefix, ship of @ships
                @message prefix, "gameover", score


    _is_object_blocked: ( object, type, from_position ) ->

        for o in @space_objects when o.radius? and o isnt object

            # Does the object block this type?
            if not o.block_for type
                return false
            # Is one of the points within the radius?
            if U.distance( o.position, from_position ) < o.radius
                return true
            if U.distance( o.position, object.position ) < o.radius
                return true

            # Is the closest point on the line within r?
            points = [ from_position, object.position ]
            points.sort ( a, b ) -> return if a.x >= b.x then 1 else -1
            pA = points[ 0 ]
            pB = points[ 1 ]
            m = ( pB.y - pA.y ) / ( pB.x - pA.x )
            m_inverse = - 1 / m
            intercept_offset = o.position.y - m_inverse * o.position.x
            pI_x = ( pA.y - m * pA.x - intercept_offset ) / ( m_inverse - m )
            pI_y = m_inverse * pI_x + intercept_offset

            # If the pI is closer to o than it's radius, and
            # pI is on the segment pA > pB then it is blocked
            if U.distance( { x : pI_x, y : pI_y, z : 0 }, o.position ) < o.radius
                if pA.x < pI_x < pB.x
                    return true
            return false


    get_public: ( object, you ) ->

        # TODO: Should we know the name? Transponders? Silent running?
        if object.transponder? and not object.transponder.is_online() and object isnt you
            return false

        if do object.is_cloaked
            return false

        if not object.alive
            return false

        p =
            name : object.name
            classification : object.classification
            alignment : object.alignment
            heading : object.bearing
            velocity : object.velocity
            impulse : object.impulse
            warp : object.warp
            bearing : U.bearing you, object
            distance : U.distance object.position, you.position
            position : object.position


    get_public_space: ( object, you, descriptor ) ->

        # TODO: this obviously needs to be folded into the objects
        if not object.charted
            return false

        if not you?
            console.log @ships
            throw new Error "No ship instantiated"

        if not object?
            throw new Error "Undefined object; dark mater?"

        if not descriptor?
            descriptor = "unidentified"

        p =
            name : object.name
            bearing : U.bearing you, object
            distance : U.distance you.position, object.position
            position : object.position
            classification : object.classification
            radius : object.radius
            descriptor : descriptor


    get_tracking_data: ( object, you ) ->

        # Return sensor data on objects you've identified and are tracking
        p =
            name : object.name
            bearing : U.bearing you, object
            distance : U.distance you.position, object.position
            position : object.position
            classification : object.classification


    ship_event: ( prefix, event ) =>

        switch event
            when "destruct" then @destroy_ship prefix


    destroy_ship: ( prefix ) ->

        # TODO: Make debris
        # TODO: Call explosion event
        console.log "BOOM! [Ship destroyed #{ @ships[ prefix ].name }]"
        v.clear_ships( prefix ) for k, v of @ships
        @game_objects = @game_objects.filter ( o ) -> o is @ships[ prefix ]
        @detonation_event @ships[ prefix ], C.SHIP_EXPLOSIVE_DAMAGE
        delete @ships[ prefix ]


    destroy_all_objects: ->

        # Utility function to clear anything that may have a timeout
        @game_objects = []
        @space_objects = []


    over: ->

        # Kill the game
        clearInterval @i
        do @destroy_all_objects
        do e.kill for e in @level_events


    get_alignment: ( prefix ) -> @ships[ prefix ].alignment


    ### Environment Functions
    ______________________________________________###

    get_local_scan_range: ( p ) -> C.SYSTEM_WIDTH


exports.Game = Game
