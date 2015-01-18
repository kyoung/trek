{System, ChargedSystem} = require './BaseSystem'

C = require './Constants'
U = require './Utility'

STATUS =
    ONBOARD: 'onboard'
    OFFSHIP: 'offship'
    ENROUTE: 'enroute'
    PRISONER: 'prisoner'
    DEAD: 'dead'


class BaseTeam

    # Tuned to allow 5 * 5 minutes of exposure to 20% of shield energy radiation
    # (As per DGTau mission)
    @RADIATION_TOLERANCE = 240000 * 5

    # Amount of time to heal to full strength
    @HEALING_RATE = 240000

    @id_counter = 0
    @get_id: ->
        @id_counter += 1

    constructor: ( @size ) ->

        @members = []
        for i in [ 0...@size ]
            @members.push 1
        @deck
        @section
        @status = STATUS.ONBOARD
        @alignment = undefined
        @assignment = undefined
        @id = do BaseTeam.get_id


    offship: ->

        @status = STATUS.OFFSHIP
        @deck = NaN
        @section = NaN


    captured: ( is_captured=true ) ->

        if is_captured
            @status = STATUS.PRISONER
        else
            @status = STATUS.ONBOARD


    is_captured: -> @status == STATUS.PRISONER


    onboard: ( @deck, @section ) -> @status = STATUS.ONBOARD


    is_onboard: -> @status == STATUS.ONBOARD or @status == STATUS.ENROUTE


    is_enroute: -> @status == STATUS.ENROUTE


    goto: ( new_deck, new_section, on_arrival=NaN ) ->

        @status = STATUS.ENROUTE
        decks_to_go = Math.abs(
            do new_deck.charCodeAt - do @deck.charCodeAt
        )
        @deck = new_deck
        @section = new_section
        time_to_travel = C.CREW_TIME_PER_DECK * decks_to_go

        if not on_arrival
            on_arrival = => @status = STATUS.ONBOARD

        setTimeout on_arrival, time_to_travel


    scan: ->

        # What do other ships scanning see?
        r =
            deck: @deck
            section: @section
            size: @members.length
            assignment: @assignment
            alignment: @alignment
            id: @id


    count: -> @members.length


    set_alignment: ( @alignment ) ->


    set_assignment: ( @assignment ) ->


    radiation_exposure: ( dyns ) ->

        if dyns < 0
            console.log "#{ @description } on deck #{ @deck }, section
            #{ @section } reports negative radiation..."
            return

        rads = dyns / BaseTeam.RADIATION_TOLERANCE
        @members = ( n - rads for n in @members )
        @members = ( n for n in @members when n > 0 )
        if @members.length == 0
            @status = STATUS.DEAD


    be_injured: ( percentage ) ->

        # Amount of injury
        n = Math.ceil percentage * @size

        if n > @members.length
            @members = []
            return @members

        # Distribute injury randomly
        # Fate is cruel
        damage = ( Math.random() for i in @members )
        sum_of_random = 0
        sum_of_random += d for d in damage
        damage = ( d / sum_of_random * n for d in damage )
        for i in [0...damage.length]
            @members[i] -= damage[i]

        # cull the zeroes
        @members = ( i for i in @members when i > 0 )
        if @members.length == 0
            @status = STATUS.DEAD


    receive_medical_treatment: ( time ) ->

        pct_recovery = time / BaseTeam.HEALING_RATE
        @members = ( Math.min(1, i + pct_recovery) for i in @members when i > 0 )


    die: ( percentage ) ->

        # Percentage of the team dead
        n = Math.ceil( percentage * @size )
        @members = @members[n...]


    is_alive: -> @members.length > 0


    health: ->

        health = 0
        health += i for i in @members
        return health


### Specialization Teams
_________________________________________________###

class RepairTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 5
        @description = "Repair Team"
        @code = "R"
        @currently_repairing = undefined


    goto: ( new_deck, new_section, on_arrival=NaN ) ->

        super new_deck, new_section, on_arrival
        @currently_repairing = undefined


    repair: ( system, complete=false ) ->

        team = @
        on_arrival = ->
            team.status = STATUS.ONBOARD
            repair_system_cycle = ->
                system.repair ( 1 / System.REPAIR_TIME ) * 1000
                operable = system.state > C.SYSTEM_OPERABILITY_CUTOFF and not complete
                complete_repair = system.state == 1
                if operable or complete_repair
                    team.currently_repairing = undefined
                    return
                setTimeout repair_system_cycle, 1000
            setTimeout repair_system_cycle, 1000
        @goto system.deck, system.section, on_arrival
        @currently_repairing = system.name


class ScienceTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 3
        @description = "Science Team"
        @code = "S"


class EngineeringTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 3
        @description = "Engineering Team"
        @code = "E"


class SecurityTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 3
        @description = "Security Team"
        @code = "F"


    fight: ( foe ) ->

        winner = @
        looser = foe

        if do Math.random > 0.5
            winner = foe
            looser = @

        looser.die 1

        injury = do Math.random
        winner.be_injured injury


    kill: ( crew ) -> crew.die 1


class DiplomaticTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 5
        @description = "Diplomatic Team"
        @code = "D"


class MedicalTeam extends BaseTeam

    constructor: ( @deck, @section ) ->

        super 3
        @description = "Medical Team"
        @code = "M"



exports.RepairTeam = RepairTeam
exports.ScienceTeam = ScienceTeam
exports.EngineeringTeam = EngineeringTeam
exports.SecurityTeam = SecurityTeam
exports.DiplomaticTeam = DiplomaticTeam
exports.MedicalTeam = MedicalTeam