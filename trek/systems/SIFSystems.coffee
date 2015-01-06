{System, ChargedSystem} = require '../BaseSystem'
Cargo = require '../Cargo'
C = require '../Constants'


up_to = ( n ) -> Math.floor(Math.random() * n)


class SIFSystem extends ChargedSystem

    # Structural Integrity Field Systems--don't leave home without them
    @PRIMARY_POWER_PROFILE =
        min : 0.01
        max : 2.3
        dyn : 6e4

    @SECONDARY_POWER_PROFILE =
        min : 0.01
        max : 2.3
        dyn : 6e3

    @CHARGE_TIME = 120e3


    constructor: ( @name, @deck, @section, secondary = false ) ->

        power_profile = if secondary then SIFSystem.SECONDARY_POWER_PROFILE else SIFSystem.PRIMARY_POWER_PROFILE
        super @name, @deck, @section, power_profile
        @_repair_reqs = []
        @_repair_reqs[Cargo.EPS_CONDUIT] = up_to 50
        @_repair_reqs[Cargo.HULL_PLATING] = up_to 50
        @charge_time = SIFSystem.CHARGE_TIME


    absorb: ( amt ) ->
        ###
        Absorb 'amt' of damage.

        Returns excess energy passed onto hull, and whether or not a blowout occurred.

        ###

        initial_charge = @charge * @power_thresholds.dyn

        @charge_down amt

        if @active
            passed_damage = amt * ( 1 - @charge )
        else
            passed_damage = amt - initial_charge

        return [ passed_damage, not @active ]


exports.SIFSystem = SIFSystem