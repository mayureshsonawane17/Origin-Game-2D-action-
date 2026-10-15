class_name BossApexNexus
extends BossController

## 3-Phase Futuristic Era Boss: Unit 00-NEXUS (FUT-ERA).
## Phase 1: Aerial Plasma Sweeps & Seismic Repulsor Waves.
## Phase 2: Quantum Hardlight Barrier (18 HP) + Descending Orbital Laser Strikes.
## Phase 3: Singularity Overload (+35% speed, reality glitch aura, 3 damage antimatter pulses).

const ORBITAL_LASER_SCENE = preload("res://scenes/bosses/orbital_laser_strike.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")
const PLASMA_ORB_SCENE = preload("res://scenes/combat/plasma_orb_projectile.tscn")

enum NexusAction { IDLE, PLASMA_TELEGRAPH, PLASMA_SWEEP, LEAP_TELEGRAPH, LEAP_SLAM, SINGULARITY_BURST, RECOVERY }
var current_action: NexusAction = NexusAction.IDLE
var action_timer: float = 0.0
var laser_strike_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/apex_nexus.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 180.0
	hitbox.hitstop_frames = 4

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	if not is_on_floor():
		velocity.y += 900.0 * delta

	# Phase 2 & 3: Orbital Laser Strikes
	if current_phase >= 2 and not is_staggered:
		laser_strike_timer += delta
		var laser_rate = 1.5 if current_phase == 2 else 1.0
		if laser_strike_timer >= laser_rate:
			laser_strike_timer = 0.0
			_spawn_orbital_laser()

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [NexusAction.IDLE, NexusAction.PLASMA_TELEGRAPH, NexusAction.LEAP_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		NexusAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			var idle_time = 0.75 if current_phase < 3 else 0.40
			if action_timer >= idle_time:
				_choose_next_attack()

		NexusAction.PLASMA_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.40 if current_phase < 3 else 0.25
			if action_timer >= telegraph_time:
				current_action = NexusAction.PLASMA_SWEEP
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * (140.0 if current_phase < 3 else 190.0)

		NexusAction.PLASMA_SWEEP:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.30:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = NexusAction.RECOVERY
				action_timer = 0.0

		NexusAction.LEAP_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.32:
				current_action = NexusAction.LEAP_SLAM
				action_timer = 0.0
				velocity = Vector2(facing_direction * 170.0, -290.0)

		NexusAction.LEAP_SLAM:
			if is_on_floor() and action_timer >= 0.20:
				_trigger_slam_shockwave()
				current_action = NexusAction.RECOVERY
				action_timer = 0.0

		NexusAction.SINGULARITY_BURST:
			velocity.x = facing_direction * 230.0
			if action_timer >= 0.45:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = NexusAction.RECOVERY
				action_timer = 0.0

		NexusAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			var rec_time = 0.45 if current_phase < 3 else 0.28
			if action_timer >= rec_time:
				current_action = NexusAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_attack() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = NexusAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if current_phase == 3 and roll < 0.45:
		current_action = NexusAction.SINGULARITY_BURST
		hitbox.damage = 3
		hitbox.monitoring = true
	elif dist > 120.0:
		current_action = NexusAction.LEAP_TELEGRAPH
	else:
		current_action = NexusAction.PLASMA_TELEGRAPH

func _trigger_slam_shockwave() -> void:
	hitbox.monitoring = false
	var left_wave = SHOCKWAVE_SCENE.instantiate()
	left_wave.global_position = global_position + Vector2(-14, 0)
	left_wave.direction = Vector2.LEFT
	left_wave.caster = self
	get_parent().add_child(left_wave)

	var right_wave = SHOCKWAVE_SCENE.instantiate()
	right_wave.global_position = global_position + Vector2(14, 0)
	right_wave.direction = Vector2.RIGHT
	right_wave.caster = self
	get_parent().add_child(right_wave)

func _spawn_orbital_laser() -> void:
	var laser = ORBITAL_LASER_SCENE.instantiate() as OrbitalLaserStrike
	var spawn_x = global_position.x + randf_range(-180.0, 180.0)
	if player_ref and randf() < 0.5:
		spawn_x = player_ref.global_position.x + randf_range(-30.0, 30.0)

	laser.global_position = Vector2(spawn_x, global_position.y)
	laser.caster = self
	get_parent().add_child(laser)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	if phase == 2:
		# Quantum Hardlight Barrier (18 HP)
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		# Singularity Overload
		current_armor = 0
		hitbox.damage = 3
		hitbox.knockback_force = 230.0
	queue_redraw()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_chassis = Color.WHITE if is_flashing else Color(0.08, 0.10, 0.15)
	var col_frame = Color.WHITE if is_flashing else (Color(1.0, 0.2, 0.4) if current_phase == 3 else Color(0.18, 0.22, 0.32))
	var col_cyan = Color.WHITE if is_flashing else Color(0.1, 0.95, 1.0)
	var col_magenta = Color.WHITE if is_flashing else Color(0.9, 0.15, 0.95)

	var f = float(facing_direction)

	# Heavy Cybernetic Chassis Legs & Energy Struts
	draw_rect(Rect2(-10, -14, 8, 14), col_frame)
	draw_rect(Rect2(2, -14, 8, 14), col_frame)
	draw_line(Vector2(-6, -14), Vector2(-6, 0), col_cyan, 2.0)
	draw_line(Vector2(6, -14), Vector2(6, 0), col_cyan, 2.0)

	# Floating Core Torso with Holographic Wings
	draw_rect(Rect2(-12, -36, 24, 22), col_chassis)
	draw_rect(Rect2(-8, -32, 16, 6), col_frame)
	# Central Pulsing AI Core
	draw_circle(Vector2(0, -25), 6.0, col_cyan)
	draw_circle(Vector2(0, -25), 3.5, col_magenta)

	# Head with Holographic Crown & Optics
	draw_circle(Vector2(0, -42), 6.5, col_chassis)
	draw_rect(Rect2(f * 1, -43, 6, 3), col_cyan)
	# Holographic crest
	draw_line(Vector2(-6, -48), Vector2(0, -54), col_cyan, 2.0)
	draw_line(Vector2(6, -48), Vector2(0, -54), col_cyan, 2.0)

	# Twin Particle Blades
	var hand_pos = Vector2(f * 10, -24)
	if current_action == NexusAction.PLASMA_SWEEP:
		var tip = Vector2(f * 36, -24)
		draw_line(hand_pos - Vector2(f * 10, 0), tip, col_cyan, 4.0)
		draw_arc(Vector2(f * 20, -24), 22.0, -PI * 0.45, PI * 0.45, 8, Color(0.1, 0.95, 1.0, 0.8), 3.0)
	else:
		draw_line(hand_pos + Vector2(-f * 6, 8), hand_pos + Vector2(f * 20, -12), col_cyan, 3.0)

	# Phase 2: Quantum Hardlight Barrier shield ring
	if current_armor > 0:
		draw_arc(Vector2(0, -26), 30.0, 0, TAU, 16, Color(0.1, 0.95, 1.0, 0.75), 3.0)
		draw_arc(Vector2(0, -26), 34.0, 0, TAU, 16, Color(0.9, 0.15, 0.95, 0.5), 1.5)

	# Phase 3: Singularity Overload reality distortion aura
	if current_phase == 3:
		var pulse = sin(action_timer * 14.0) * 4.0
		draw_arc(Vector2(0, -26), 34.0 + pulse, 0, TAU, 16, Color(1.0, 0.1, 0.35, 0.7), 3.0)
		draw_arc(Vector2(0, -26), 40.0 - pulse, 0, TAU, 16, Color(0.8, 0.1, 1.0, 0.5), 2.0)
