Constants = require './Constants'
Cargo = require './Cargo'

up_to = ( n ) ->
    Math.floor(Math.random() * n)

class CargoBay

    @CAPACITY = 100


    constructor: ( @number=1 ) ->

        @capacity = CargoBay.CAPACITY
        @remaining_capacity = CargoBay.CAPACITY
        @inventory = {}
        for cargo, name of Cargo
            init_count = up_to 10
            @add_cargo name, init_count


    add_cargo: ( cargo, quantity ) ->

        if @remaining_capacity - quantity < 0
            throw new Error("Insufficient capacity for cargo")

        if not quantity?
            throw new Error("Invalid quantity #{quantity}")

        if @inventory[cargo]
            @inventory[cargo] += quantity
        else
            @inventory[cargo] = quantity

        @remaining_capacity -= quantity


    transfer_cargo: ( cargo, quantity, destination ) ->

        if not quantity
            throw new Error("Invalid quantity")

        if destination.remaining_capacity < quantity
            throw new Error("Insufficient capacity for transfer")

        destination.add_cargo(cargo,
            Math.min(@inventory[cargo], quantity))
        @inventory[cargo] -= quantity
        @inventory[cargo] = Math.max(0, @inventory[cargo])
        @remaining_capacity += quantity
        r = "Transport Successful"


    inventory_count: ( cargo ) -> if @inventory[cargo]? then @inventory[cargo] else 0


    consume_cargo: ( cargo, up_to_quantity ) ->

        if not @inventory[cargo]?
            return 0
        if @inventory[cargo] > up_to_quantity
            @inventory[cargo] -= up_to_quantity
            return up_to_quantity
        consumed = @inventory[cargo]
        @inventory[cargo] = 0

        return consumed


exports.CargoBay = CargoBay
