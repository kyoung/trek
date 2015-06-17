{System, ChargedSystem} = require '../BaseSystem'

U = require '../Utility'

class CloakingSystem extends ChargedSystem

    @POWER = { min : 1, max : 1.1, dyn : 4.4e4 }



exports.CloakingSystem = CloakingSystem
