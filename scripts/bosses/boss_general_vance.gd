class_name BossGeneralVance
extends BossController

## 3-Phase Modern Era Boss: General Vance (MOD-ERA).
## Phase 1: Tactical Heavy Shotgun Blast & Combat Maneuvers.
## Phase 2: Powered Exoskeleton Armor (16 HP) + Raining Airstrike Missiles.
## Phase 3: Redline Combat Adrenaline Frenzy (+35% speed, glowing cybernetic visor, 3 damage bayonet cleaves).

const MISSILE_SCENE = preload("res://scenes/bosses/falling_airstrike_missile.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

enum VanceAction { IDLE, SHOTGUN_TELEGRAPH, SHOTGUN_BLAST, LEAP_TELEGRAPH, LEAP_SLAM, REDLINE_BURST, RECOVERY }
var current_action: VanceAction = VanceAction.IDLE
var action_timer: float = 0.0
var missile_rain_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/general_vance.tres") as BossData
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

	# Phase 2 & 3: Airstrike missile rain
	if current_phase >= 2 and not is_staggered:
		missile_rain_timer += delta
		var missile_rate = 1.6 if current_phase == 2 else 1.1
		if missile_rain_timer >= missile_rate:
			missile_rain_timer = 0.0
			_spawn_falling_missile()

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [VanceAction.IDLE, VanceAction.SHOTGUN_TELEGRAPH, VanceAction.LEAP_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		VanceAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			var idle_time = 0.8 if current_phase < 3 else 0.45
			if action_timer >= idle_time:
				_choose_next_attack()

		VanceAction.SHOTGUN_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.42 if current_phase < 3 else 0.28
			if action_timer >= telegraph_time:
				current_action = VanceAction.SHOTGUN_BLAST
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * (120.0 if current_phase < 3 else 170.0)

		VanceAction.SHOTGUN_BLAST:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.30:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = VanceAction.RECOVERY
				action_timer = 0.0

		VanceAction.LEAP_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = VanceAction.LEAP_SLAM
				action_timer = 0.0
				velocity = Vector2(facing_direction * 160.0, -280.0)

		VanceAction.LEAP_SLAM:
			if is_on_floor() and action_timer >= 0.22:
				_trigger_slam_shockwave()
				current_action = VanceAction.RECOVERY
				action_timer = 0.0

		VanceAction.REDLINE_BURST:
			velocity.x = facing_direction * 220.0
			if action_timer >= 0.45:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = VanceAction.RECOVERY
				action_timer = 0.0

		VanceAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			var rec_time = 0.50 if current_phase < 3 else 0.30
			if action_timer >= rec_time:
				current_action = VanceAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_attack() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = VanceAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if current_phase == 3 and roll < 0.45:
		current_action = VanceAction.REDLINE_BURST
		hitbox.damage = 3
		hitbox.monitoring = true
	elif dist > 120.0:
		current_action = VanceAction.LEAP_TELEGRAPH
	else:
		current_action = VanceAction.SHOTGUN_TELEGRAPH

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

func _spawn_falling_missile() -> void:
	var missile = MISSILE_SCENE.instantiate() as FallingAirstrikeMissile
	var spawn_x = global_position.x + randf_range(-180.0, 180.0)
	if player_ref and randf() < 0.5:
		spawn_x = player_ref.global_position.x + randf_range(-40.0, 40.0)

	missile.global_position = Vector2(spawn_x, global_position.y - 180.0)
	missile.target_ground_y = global_position.y + 4.0
	get_parent().add_child(missile)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	if phase == 2:
		# Equip Exoskeleton Armor
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		# Redline Combat Adrenaline Frenzy
		current_armor = 0
		hitbox.damage = 3
		hitbox.knockback_force = 220.0
	queue_redraw()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.85, 0.72, 0.60)
	var col_camo = Color.WHITE if is_flashing else (Color(1.0, 0.35, 0.35) if current_phase == 3 else Color(0.22, 0.25, 0.28))
	var col_exo = Color.WHITE if is_flashing else Color(0.35, 0.75, 0.95)
	var col_vest = Color.WHITE if is_flashing else Color(0.12, 0.14, 0.18)
	var col_shotgun = Color.WHITE if is_flashing else Color(0.20, 0.22, 0.25)

	var f = float(facing_direction)

	# Heavy Combat Armor / Exoskeleton Legs
	draw_rect(Rect2(-10, -14, 8, 14), col_camo)
	draw_rect(Rect2(2, -14, 8, 14), col_camo)
	# Exoskeleton struts
	draw_line(Vector2(-6, -14), Vector2(-6, 0), col_exo, 2.0)
	draw_line(Vector2(6, -14), Vector2(6, 0), col_exo, 2.0)

	# Heavy Ballistic Torso & Medals
	draw_rect(Rect2(-12, -36, 24, 22), col_vest)
	draw_rect(Rect2(-8, -32, 16, 6), col_camo)
	# Commander Stars / Medals
	draw_circle(Vector2(-f * 4, -30), 1.5, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(-f * 1, -30), 1.5, Color(1.0, 0.85, 0.2))

	# Head with Military Officer Cap & Cyber Visor
	draw_circle(Vector2(0, -42), 6.0, col_skin)
	# Officer cap
	draw_rect(Rect2(-8, -48, 16, 4), col_vest)
	draw_line(Vector2(f * 2, -45), Vector2(f * 10, -44), col_vest, 2.0) # Visor bill
	# Glowing Cyan Cyber Visor
	draw_rect(Rect2(f * 1, -43, 6, 3), col_exo)

	# Heavy Shotgun with Tactical Bayonet
	var hand_pos = Vector2(f * 8, -26)
	if current_action == VanceAction.SHOTGUN_BLAST:
		var tip = Vector2(f * 36, -26)
		draw_line(hand_pos - Vector2(f * 10, 0), tip, col_shotgun, 3.5)
		draw_line(tip, tip + Vector2(f * 10, 0), Color(0.85, 0.9, 0.95), 2.5) # Bayonet
		draw_circle(tip, 6.0, Color(1.0, 0.8, 0.3, 0.8)) # Muzzle blast
	elif current_action == VanceAction.LEAP_SLAM:
		draw_line(hand_pos + Vector2(0, -18), hand_pos + Vector2(0, 26), col_shotgun, 3.5)
	else:
		draw_line(hand_pos + Vector2(-f * 8, 8), hand_pos + Vector2(f * 18, -14), col_shotgun, 3.0)
		draw_line(hand_pos + Vector2(f * 18, -14), hand_pos + Vector2(f * 26, -14), Color(0.85, 0.9, 0.95), 2.0)

	# Phase 2: Exoskeleton Armor kinetic shield ring
	if current_armor > 0:
		draw_arc(Vector2(0, -26), 28.0, 0, TAU, 16, Color(0.2, 0.8, 1.0, 0.7), 2.5)

	# Phase 3: Redline Adrenaline crimson energy aura
	if current_phase == 3:
		draw_arc(Vector2(0, -26), 32.0, 0, TAU, 16, Color(1.0, 0.2, 0.3, 0.5 + sin(action_timer * 12.0) * 0.25), 3.0)
