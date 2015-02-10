{System, ChargedSystem} = require '../BaseSystem'

class NavigationComputerSystem extends System

    @POWER = { min : 0.01, max : 2.2, dyn : 5e3 }

    constructor: ( @name, @deck, @section, @power_thresholds ) ->

        super @name, @deck, @section, NavigationComputerSystem.POWER
        @_repair_reqs[ Cargo.COMPUTER_COMPONENTS ] = up_to 40


    calculate_safe_warp_velocity: ( navigational_deflector, local_particle_density ) ->

        # What is the maximum safe warp velocity given particle density and
        # navigational deflector status and charge

        nominal_max_safe_warp = 8

        # local particle density of > 1 doesn't permit safe deflector operation
        if local_particle_density > 1
            return 0

        # warp velocity is coorelated to the local particle density
        safe_warp = nominal_max_safe_warp * local_particle_density

        # warp velocity is coorelated to deflector power levels
        safe_warp *= navigational_deflector.power

        Math.min safe_warp, nominal_max_safe_warp


exports.NavigationComputerSystem = NavigationComputerSystem
