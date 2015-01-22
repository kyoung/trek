{BaseObject} = require './BaseObject'
Utility = require './Utility'
C = require './Constants'
{CargoBay} = require './CargoBay'
{RepairTeam, ScienceTeam, EngineeringTeam, SecurityTeam, BoardingParty} = require './Crew'
{ReactorSystem, PowerSystem} = require './systems/PowerSystems'
{System, ChargedSystem} = require './BaseSystem'
{SensorSystem, LongRangeSensorSystem} = require './systems/SensorSystems'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require './systems/WeaponSystems'


# LEVELS
LEVELS = {}
for level_number in [1..82]
    level_str = level_number.toString()
    LEVELS[level_str] = level_str

#SECTIONS
SECTIONS = {}
for sec_number in [1..17]
    sec_str = sec_number.toString()
    SECTIONS[sec_str] = sec_str


random_level = ->

    k = Math.floor(Math.random() * Object.keys(LEVELS).length)
    k.toString()


random_section = ->

    k = Math.floor(Math.random() * Object.keys(SECTIONS).length)
    k.toString()



class Station extends BaseObject

    constructor: ( @name, starting_position ) ->

        super()
        @position.x = starting_position.x
        @position.y = starting_position.y
        @position.z = starting_position.z
        @classification = "Space Station"
        @serial = Math.round( 1e6 * do Math.random )
        @cargobays = []
        for i in [ 1..10 ]
            @cargobays.push( new CargoBay( i ) )

        do @initialize_crew
        do @initialize_hull
        do @initialize_systems

        @model_url = "outpost.js"
        @model_display_scale = 1
        @_scan_density[ SensorSystem.SCANS.HIGHRES ] = 4 * do Math.random
        @_scan_density[ SensorSystem.SCANS.P_HIGHRES ] = 4 * do Math.random


    initialize_crew: ->

        @crew = [
            new ScienceTeam random_level(), random_section()
            new ScienceTeam random_level(), random_section()
            new ScienceTeam random_level(), random_section()
            new EngineeringTeam random_level(), random_section()
            new RepairTeam random_level(), random_section() ]

        c.set_assignment @name for c in @crew


    initialize_systems: ->

        @lifesupport = new System(
            "Lifesupport",
            LEVELS[ '5' ],
            SECTIONS[ '2' ],
            System.STATION_LIFESUPPORT_POWER )

        @shields = new ShieldSystem(
            "Station Shielding",
            LEVELS[ '40' ],
            SECTIONS[ '10' ],
            ShieldSystem.POWER )

        @plasma_relay = new PowerSystem(
            "Plasma Relay",
            LEVELS[ '32' ],
            SECTIONS[ '15' ],
            PowerSystem.WARP_RELAY_POWER )

        @plasma_relay.add_route( @lifesupport )
        @plasma_relay.add_route( @shields )

        @reactor = new ReactorSystem(
            "Fusion Reactor",
            LEVELS[ '30' ],
            SECTIONS[ '17' ],
            ReactorSystem.ANTIMATTER,
            @plasma_relay,
            ReactorSystem.ANTIMATTER_SIGNATURE )

        do @reactor.set_required_output_power

        @systems = [
            @plasma_relay
            @reactor
            @shields
            @lifesupport ]


    initialize_hull: ->

        @hull = {}
        for level, level_number of LEVELS
            @hull[ level_number ] = {}
            for section, section_string of SECTIONS
                @hull[ level_number ][ section_string ] = 1


    _check_if_still_alive: ->

        holes_in_decks =  0
        decks = 0

        for level, section_list of @hull
            for section, i of section_list
                if i == 0
                    holes_in_decks += 1
                decks += 1

        # Check if still alive
        # Assume if 15% of the hull is breached, catastrophic failure
        if holes_in_decks / decks > C.STATION_CATASTROPHIC_HULL_BREACH
            @alive = false

        return @alive


    set_alignment: ( @alignment ) ->
        c.set_alignment @alignment for c in @crew


    damage_report: ->
        return ( s.damage_report() for s in @systems )


    get_cargo_status: ->

        r = {}
        for cb in @cargobays
            r[cb.number] = cb.inventory
        return r


    get_system_scan: ->

        lifesigns = 0
        if @crew.length > 0
            lifesigns = ( c.members.length for c in @crew ).reduce ( x, y ) -> x+y

        r =
            systems: @damage_report()
            cargo: @get_cargo_status()
            lifesigns: lifesigns
            # Eventually, power readings will be used to profile a ship
            # for now, let's simply return the power output to the nacels
            # which is feasably measured
            power_readings: [
                    @reactor.field_output()
                ]
            mesh: @model_url
            mesh_scale: @model_display_scale
            name: @name
            registry: @serial
            hull: @hull


        if @shields.active and @shields.charge >= 0.01
            delete r.cargo
            delete r.lifesigns
            delete r.systems

        return r


    get_bay_with_capacity: ( qty ) ->

        bays = ( c for c in @cargobays when c.remaining_capacity > qty )
        if bays.length == 0
            throw new Error "No bays with capacity #{ qty }"

        bays[0].number


    get_cargo_bay: ( n ) ->

        n = if typeof n is 'string' then parseInt( n ) else n
        c = ( c for c in @cargobays when c.number is n )[ 0 ]
        if not c?
            throw new Error "Invalid cargo bay number #{ n }"

        return c


    transportable: ->

        if @shields.active and @shields.charge >= 0.01
            return false

        t =
            name: @name
            crew: ( c.scan() for c in @crew when c.is_onboard() )
            cargo: do @get_cargo_status
            decks: LEVELS
            sections: SECTIONS


    beam_away_crew: ( crew_id, level, section ) ->

        if @_are_all_shields_up()
            throw new Error('Shields are up. No transport possible')

        teams = (t for t in @crew when t.id == crew_id)

        if teams.length == 0
            throw new Error("No team at that location: #{ level } #{section}")

        team = teams[0]

        @crew = ( t for t in @crew when t isnt team )

        return team


    beam_onboard_crew: ( team, level, section ) ->

        if level not in (l for k, l of LEVELS)
            throw new Error 'Invalid level'

        if section not in (s for k, s of SECTIONS)
            throw new Error 'Invalid section'

        team.deck = level
        team.section = section

        @crew.push team


    _disembark: ( assignment, level, section ) ->

        matching_teams = (p for p in @crew when p.origin_party?.assigned is assignment)
        if matching_teams.length == 0
            boarding_parties = (p for p in @crew when p.origin_party?)
            console.log boarding_parties
            throw new Error("No such team onbard: #{assignment} level #{level} section #{section}")

        @crew = (p for p in @crew when p isnt matching_teams[0])
        matching_teams[0].origin_party


    get_lifesigns: -> @crew


    _are_all_shields_up: -> false


    process_phaser_damage: ( from_point, energy, target_level, target_section ) =>

        sections = @calculate_sections from_point

        if target_section?
            section = target_section
        else
            section = sections[ Math.floor( Math.random() * sections.length ) ]

        if not target_level?
            level_list = ( k for k, v of LEVELS )
            level_i = Math.floor( Math.random() * level_list.length )
            target_level = level_list[ level_i ]

        shield = @shields
        damage = energy
        if shield.active and do shield.is_online
            damage = shield.hit energy
        else
            #console.log "Shields down!"

        #console.log "Phaser damage on level #{ target_level } section #{ section }: energy level: #{ energy }. Passthrough damage: #{ damage }"


        system_passthrough = @_damage_hull [ target_level ], section, damage

        section_systems = ( s for s in @systems when s.section == section and s.deck == target_level )

        for sys in section_systems
            sys.damage system_passthrough

        do @_check_if_still_alive


    _damage_hull: ( levels, section, damage ) ->

        #console.log "[#{ @name }] Hull damage: #{damage} deck #{ decks } section #{ section }"

        hull_strength = C.STATION_HULL_STRENGTH
        damage_as_pct = damage / hull_strength

        # No SIFs on stations (?)

        # Divide the damage among the decks
        damage_per_deck = damage / levels.length
        damage_pct_per_deck = damage_per_deck / hull_strength
        for d in levels
            @hull[ d ][ section ] -= damage_pct_per_deck * ( 0.5 + 0.5 * do Math.random )
            @hull[ d ][ section ] = Math.max 0, @hull[ d ][ section ]

            if @hull[ d ][ section ] == 0

                #console.log "    Hull breach! Deck #{ d } Section #{ section }"
                @process_casualties d, section

                # the remaining damage applies to the other sections
                other_sections = ( v for k, v of SECTIONS when v isnt section )
                for s in other_sections
                    @hull[ d ][ s ] -= damage_pct_per_deck / Object.keys( SECTIONS ).length
                    @hull[ d ][ s ] = Math.max 0, @hull[ d ][ s ]
                    if @hull[ d ][ s ] == 0
                        @process_casualties d, s

        return damage


    process_blast_damage: ( position, power, message_callback ) ->

        sections = @calculate_sections position

        distance = Utility.distance @position, position

        damage = power / Math.pow( distance, 2 )

        damage_as_pct = damage / C.STATION_HULL_STRENGTH

        # Assume the damage occurred on all decks... seems realistic
        for level, sections of @hull
            for section, i of sections
                i -= damage_as_pct * 2 * do Math.random
                i = Math.max 0, i
                @hull[ level ][ section ] = i
                if i is 0
                    @process_casualties level, section

        do @_check_if_still_alive


    process_casualties: ( level, section ) ->

        for c in @crew
            if c.deck == level and c.section == section
                c.die 1

        @crew = ( c for c in @crew when c.is_alive() )


    calculate_sections: ( position ) ->

        if position == @position
            position.x += 1

        bearing = Utility.bearing @, { position: position }

        if not bearing?
            throw new Error "Invalid origin point #{position}"

        epicenter_i = Math.floor bearing.bearing * SECTIONS.length

        # Assume about a half of the sections would be exposed
        # Numbers are modulus SECTIONS.length
        half_sections = Math.floor( SECTIONS.length / 2 )
        damage_start = epicenter_i - half_sections
        damage_end = epicenter_i + half_sections

        sections_indexes = [ damage_start .. damage_end ]
        sections = ( SECTIONS[ i ] for i in sections_indexes )


exports.Station = Station