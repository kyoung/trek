{System, ChargedSystem} = require '../BaseSystem'
Cargo = require '../Cargo'

C = require '../Constants'
U = require '../Utility'

class NavigationComputerSystem extends System

    @POWER = { min : 0.01, max : 2.2, dyn : 5e3 }

    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        super @name, @deck, @section, NavigationComputerSystem.POWER
        @_repair_reqs[ Cargo.COMPUTER_COMPONENTS ] = U.up_to 40


    calculate_safe_warp_velocity: ( navigational_deflector, environmental_readings ) ->

        pd_key = C.ENVIRONMENT.PARTICLE_DENSITY
        nominal_max_safe_warp = 8

        if not environmental_readings[ pd_key ]?
            return nominal_max_safe_warp

        local_particle_density = environmental_readings[  pd_key ]

        # local particle density of > 1 doesn't permit safe deflector operation
        if local_particle_density > 1
            return 0

        # warp velocity is coorelated to the local particle density
        safe_warp = nominal_max_safe_warp * local_particle_density

        # warp velocity is coorelated to deflector power levels
        safe_warp *= navigational_deflector.power

        Math.min safe_warp, nominal_max_safe_warp


exports.NavigationComputerSystem = NavigationComputerSystem
