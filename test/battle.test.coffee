{Ship} = require '../trek/Ship'
{PhaserSystem, TorpedoSystem, ShieldSystem} = require '../trek/systems/WeaponSystems'

C = require '../trek/Constants'

process.on 'uncaughtException', ( err ) -> console.log(err)

exports.BattleTest =

    'test shields vs torpedoes': ( test ) ->

        s = new Ship "Icarus", "NX-992"
        s.set_coordinate { x: 0, y: 0, z: 0 }

        # Raise sheilds, set to full power
        s.set_shields true

        # Accelerate shield charge
        for shield in s.shields
            s.set_power_to_system shield.name, 0.25
            shield.charge = 1

        # Accelerate SIF charge
        s.primary_SIF.charge = 1
        s.secondary_SIF.charge = 1

        blast_point =
            x: 500
            y: 0
            z: 0

        s.process_blast_damage blast_point, TorpedoSystem.MAX_DAMAGE, ->
        test.ok s.alive, "Ship failed to survive single blast"

        #console.log s.shield_report()

        s.process_blast_damage blast_point, TorpedoSystem.MAX_DAMAGE, ->
        # console.log s.damage_report true
        test.ok s.alive, "Ship failed to survive second blast"

        #console.log s.shield_report()

        s.process_blast_damage blast_point, TorpedoSystem.MAX_DAMAGE, ->
        # console.log s.damage_report true
        test.ok s.alive, "Ship failed to survive third blast"

        #console.log s.shield_report()

        for i in [0...15]
            s.process_blast_damage blast_point, TorpedoSystem.MAX_DAMAGE, ->

        # console.log s.damage_report true
        test.ok not s.alive, "Ship failed to be destroyed by torpedo barage"

        do test.done


    'test phaser vs shields': ( test ) ->
        s = new Ship "Icarus", "NX-992"
        s.set_coordinate { x: 0, y: 0, z: 0 }

        # Raise sheilds, set to full power
        s.set_shields true

        # Accelerate shield charge
        for shield in s.shields
            s.set_power_to_system shield.name, 0.25
            shield.charge = 1

        # Accelerate SIF charge
        s.primary_SIF.charge = 1
        s.secondary_SIF.charge = 1

        fire_point =
            x: 1000
            y: -1000
            z: 0

        phaser_power = PhaserSystem.POWER.dyn

        s.process_phaser_damage fire_point, phaser_power
        # console.log do s.shield_report

        test.ok s.alive, "Ship failed to survive a phaser blast"

        # Phasers are targeted weapons... we should specify a deck for SIFs
        for i in [0...10]
            if not s.alive
                continue
            deck = [ "N", "F" ][ i % 2 ]
            section = [ "Forward", "Starboard" ][ i % 2 ]
            s.process_phaser_damage fire_point, phaser_power, deck, section

            #console.log s.shield_report()
            #console.log s.primary_SIF.damage_report()
            #console.log s.secondary_SIF.damage_report()

        # console.log s.damage_report true
        test.ok (not s.alive), "Ship failed to be destroyed by targetted phaser blasts"

        do test.done


    'test two-ship phaser combat': ( test ) ->

        s1 = new Ship "Icarus", "NX-992"
        s1.set_coordinate { x : 0, y : 0, z : 0 }

        s2 = new Ship "Daedalus", "NX-991"
        s2.set_coordinate { x : 0, y : PhaserSystem.RANGE * 0.8, z : 0 }

        # Mimic Red Alert, and accelerate the charge times

        for shield in s1.shields
            s1.set_power_to_system shield.name, 1
            #console.log shield.name
            do shield.bring_online
            shield.charge = 1

        s1.set_power_to_system s1.primary_SIF.name, 1
        s1.set_power_to_system s1.secondary_SIF.name, 1
        s1.primary_SIF.charge = 1
        s1.secondary_SIF.charge = 1

        s2.set_target s1
        for phaser_bank in s2.phasers
            s2.set_power_to_system phaser_bank.name, 1
            do phaser_bank.bring_online
            phaser_bank.charge = 1

        initial_shield_charge = 0
        initial_shield_charge += s.charge for s in s1.shields

        #console.log do s1.shield_report

        for i in [0...10]
            do s2.fire_phasers
            if not s1.alive
                console.log "#{ s1.name } killed after #{ i+1 } blasts"
                break
            for phaser_bank in s2.phasers
                phaser_bank.charge = 1

        post_shield_charge = 0
        post_shield_charge += s.charge for s in s1.shields

        #console.log do s1.shield_report

        test.ok post_shield_charge < initial_shield_charge, "Phaser fire failed
        to lower shield charge: #{ initial_shield_charge } vs #{ post_shield_charge }"

        do test.done





