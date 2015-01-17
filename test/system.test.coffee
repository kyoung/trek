{System, ChargedSystem} = require '../trek/BaseSystem'
{ShieldSystem, PhaserSystem, TorpedoSystem} = require '../trek/systems/WeaponSystems'
{WarpSystem} = require '../trek/systems/WarpSystems'
{ReactorSystem, PowerSystem} = require '../trek/systems/PowerSystems'
{SensorSystem, LongRangeSensorSystem} = require '../trek/systems/SensorSystems'
{SIFSystem} = require '../trek/systems/SIFSystems'
{Torpedo} = require '../trek/Torpedo'
C = require '../trek/Constants'
util = require 'util'

exports.SystemTest =

	'test can damage system': ( test ) ->

		s = new System 'Test', 'B', 'Port'
		s.state = 1
		s.damage 0.1 * System.STRENGTH
		test.ok s.state == 0.9, "Failed to damage system"
		do test.done


	'test initialized with state': ( test ) ->

		s = new System 'Test', 'A', 'Aft'
		test.ok s.state
		do test.done


	'test power system': ( test ) ->

		warp_relay = new PowerSystem( 'Warp Conduit', 'P' , 'Aft',
			PowerSystem.WARP_RELAY_POWER )

		warp_core = new ReactorSystem( 'Warp Core', 'P', 'Aft',
			ReactorSystem.ANTIMATTER, warp_relay, PowerSystem.ANTIMATER_SIGNATURE )

		eps1 = new PowerSystem 'EPS Junction', 'J', 'Forward', PowerSystem.EPS_RELAY_POWER

		n1 = new WarpSystem 'Port Nacel', 'B', 'Port'
		n2 = new WarpSystem 'Starboard Nacel', 'B', 'Starboard'

		s1 = new System( 'Safe System', 'C', 'Aft',
			{ min : 0.5, max : 4, dyn : ReactorSystem.ANTIMATTER.dyn * 0.01 } )

		s2 = new System( 'Blowout System', 'C', 'Aft',
			{ min : 0.5, max : 1, dyn : ReactorSystem.ANTIMATTER.dyn * 0.01 } )

		warp_relay.add_route eps1
		warp_relay.add_route n1
		warp_relay.add_route n2
		eps1.add_route s1
		eps1.add_route s2

		do warp_core.set_required_output_power
		test.ok s1.is_online and s2.is_online, "Failed to activate
		targeted systems"
		console.log "Warp core operating at #{warp_core.output} MDyn (#{warp_core.output_level()}%)"

		do test.done


	'test System Blowout': ( test ) ->

		eps_dyn = PowerSystem.EPS_RELAY_POWER.dyn
		# Test that systems encure damage and blow out properly.
		relay = new PowerSystem 'Test Relay', '1', '2', PowerSystem.EPS_RELAY_POWER
		reactor = new ReactorSystem(
			'Test Reactor',
			'1',
			'2',
			{ min : 0, max : 5, dyn : PowerSystem.EPS_RELAY_POWER.dyn },
			relay
		)
		system = new System 'Test Blowout System', '1', '2', {
			min : 0.1, max : 1.1, dyn : eps_dyn / 5
		}
		system.state = 1
		relay.add_route system

		do reactor.set_required_output_power

		# Push the system to full power
		l = reactor.calculate_level_for_additional_output eps_dyn / 5 - system.power
		reactor.activate l

		test.ok system.power == eps_dyn / 5, "Failed to set initial power
		levels for test system: #{ system.power } vs #{ eps_dyn / 5}."

		# A power level above the system's maximum
		delta_power = eps_dyn / 5 * 0.2

		# Since there's only one system attached, I expect
		# that this will still be [1,]
		new_balance = relay.calculate_new_balance system, delta_power
		relay.set_system_balance new_balance

		l = reactor.calculate_level_for_additional_output delta_power
		initial_level = do reactor.output_level
		test.ok initial_level < l, "Reactor failed to calculate a higher output level: #{ initial_level } vs #{ l }."

		reactor.activate l

		test.ok system.state < 1, "Failed to damage a system by blowing out it's power."
		test.ok not system._fuse_on, "Failed to destroy a systems power components."

		do test.done


	'test EPS overload': ( test ) ->
		###
		Test the damage that occurs to an EPS system when it is overloaded.

		###

		eps_power = PowerSystem.EPS_RELAY_POWER

		eps = new PowerSystem 'Test EPS System', '5', '7', eps_power
		reactor = new ReactorSystem(
			'Test Reactor',
			'5',
			'7',
			{ min : 0, max : 5, dyn : eps_power.dyn },
			eps
		)

		system = new System 'Test Overload System', '5', '7', {
			min : 0.1,
			max : 4,
			dyn : eps_power.dyn * eps_power.max * 0.8
		}
		system.state = 1
		eps.add_route system

		do reactor.set_required_output_power

		# Set system to full power
		full_power_delta = eps_power.dyn / 5 - system.power
		l = reactor.calculate_level_for_additional_output full_power_delta
		reactor.activate l

		# Now that we have a working circuit, let's blowout the relay and
		# ensure that we can no longer interact with it

		# Power boost sequence, beyond the rated capacity
		delta_power = eps_power.dyn * eps_power.max * 1.2

		# This part shouldn't actually make a difference
		new_balance = eps.calculate_new_balance system, delta_power
		eps.set_system_balance new_balance

		l = reactor.calculate_level_for_additional_output delta_power
		reactor.activate l

		test.ok not eps._fuse_on, "Failed to blow the eps system fuse"
		dial_down = ->
			eps.set_systems [0.9]
		test.throws dial_down, "Failed to error out when setting power levels."

		do test.done


	'test Shield systems': ( test ) ->

		s = new ShieldSystem 'Test Shield System', 'Lab A', '1'
		s.push_power ShieldSystem.POWER.dyn
		s.charge = 1
		do s.power_on

		# A shield should be able to withstand 5 direct torpedo hits before the charge fails
		# (ST VI)

		torpedo_blast = Torpedo.MAX_DAMAGE / Math.pow( 500, 2 )

		for i in [0...9]
			s.hit torpedo_blast

		test.ok s.charge > 0, "#{s.name} failed to withstand 9 blasts: #{ s.charge }"

		s.hit torpedo_blast
		test.ok s.charge == 0, "#{s.name} failed to collase after 10 blasts: #{ s.charge }"

		# A shield should be able to withstand 6 phaser hits before the charge fails
		phaser_damage = PhaserSystem.DAMAGE

		s.charge = 1
		for i in [0...5]
			s.hit(phaser_damage)
		test.ok s.charge > 0, "#{s.name} failed to withstand 6 phaser blasts: #{s.charge}"

		s.hit phaser_damage
		test.ok s.charge == 0, "#{s.name} failed to collapse after 7 phaser blasts: #{s.charge}"

		do test.done


	'test SIF': ( test ) ->

		SIF = new SIFSystem( 'Test Structural Integrity Field',
            'F', 'Forward' )

		secondary_SIF = new SIFSystem 'Secondary', 'F', 'Fwd', true

		test.ok SIF.power_thresholds.dyn > secondary_SIF.power_thresholds.dyn, "Failed to instantiate different types of SIFs"

		power = SIFSystem.PRIMARY_POWER_PROFILE

		operating_power = power.dyn
		r = SIF.push_power operating_power

		test.ok r == operating_power, "#{SIF.name} Failed to accept it's power: #{r}"

		near_overload = operating_power * power.max - 1
		r = SIF.push_power near_overload

		test.ok(r == near_overload, "#{SIF.name} Failed to operate at rated maximum: #{r}")

		do test.done


	'test charged systems': ( test ) ->

		phaser_power = PhaserSystem.POWER

		# Every charged system should have a time to full charge
		# The time to full charge should be modified by the value of the
		# energy level.
		# Charged systems should have their charges disipated during use.

		s_base = new PhaserSystem 'Test Baseline Phaser Bank', 'Lab F', '5'
		s_low_power = new PhaserSystem 'Test Underpowered Phaser Bank', 'Lab G', '4'
		s_high_power = new PhaserSystem 'Test Overpowered Phaser', 'Lab H', '5'

		# Simulate a full power source
		s_base.push_power phaser_power.dyn
		s_low_power.push_power phaser_power.dyn * phaser_power.min
		s_high_power.push_power phaser_power.dyn * phaser_power.max - 1

		test.ok s_base.charge == 0, "#{ s_base.name } failed to initialize with 0 charge"

		# Shorten the charge time
		s_base.charge_time /= 2
		s_low_power.charge_time /= 2
		s_high_power.charge_time /= 2

		#console.log "#{ s_base.name } charge time: #{ s_base.charge_time }"
		#console.log "#{ s_low_power.name } charge time: #{ s_low_power.charge_time }"
		#console.log "#{ s_high_power.name } charge time: #{ s_high_power.charge_time }"

		do s_base.power_on
		do s_low_power.power_on
		do s_high_power.power_on

		test.ok s_base.active, "#{s_base.name} failed to activate. #{util.inspect s_base}"
		test.ok s_low_power.active, "#{s_low_power.name} failed to activate."
		test.ok s_high_power.active, "#{s_high_power.name} failed to activate."

		half_charge = () ->
			s_base.update_system s_base.charge_time / 2
			s_low_power.update_system s_low_power.charge_time / 2
			s_high_power.update_system s_high_power.charge_time / 2

		do half_charge

		test.ok s_high_power.charge > s_base.charge, "#{ s_high_power.name } is failing to charge faster than #{ s_base.name }"

		do half_charge

		test.ok s_base.charge >= 0.9999, "#{s_base.name} failed to fully charge: #{s_base.charge}"
		test.ok s_low_power.charge < 1, "#{s_low_power.name} failed to limit charge speed: #{s_low_power.charge}"
		test.ok s_low_power.charge > 0, "#{s_low_power.name} failed to charge at all"

		do test.done


