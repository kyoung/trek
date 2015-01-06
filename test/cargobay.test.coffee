{CargoBay} = require '../trek/CargoBay'

exports.TestCargoBay =

    'test can add cargo': ( test ) ->

        c = new CargoBay()
        c.add_cargo "sensor probes", 25
        test.equal c.inventory["sensor probes"], 25, "Failed to add inventory"

        do test.done


    'test can transfer cargo': ( test ) ->

        c1 = new CargoBay 1
        c2 = new CargoBay 2

        c1.add_cargo "dilithium", 20
        c1.transfer_cargo "dilithium", 20, c2

        test.equal c2.inventory["dilithium"], 20, "Failed to transfer cargo"

        do test.done


    'test dont add too much cargo': ( test ) ->

        c = new CargoBay()

        test.throws(
            -> c.add_cargo "antimater", 120
        )

        do test.done


    'test dont transfer too much cargo': ( test ) ->

        c1 = new CargoBay 1
        c2 = new CargoBay 2

        c1.inventory = { "medical supplies" : 200 }
        test.throws(
            -> c.transfer_cargo "medical supplies", 120, c2
        )

        do test.done


    'test dont transfer nonexistent cargo': ( test ) ->

        c1 = new CargoBay 1
        c2 = new CargoBay 2

        c1.inventory = { "protomater" : 10 }
        c1.transfer_cargo "protomater", 20, c2

        test.equal c2.inventory["protomater"], 10, "Failed to restrict illegal transfer"

        do test.done

