class_name BossBaronSteinhardt
extends BossController

## 3-Phase Industrial Era Boss: Baron Von Steinhardt (IND-ERA).
## Phase 1: Heavy Steam Wrench Cleave & Ground Pneumatic Quake.
## Phase 2: Riveted Brass Armor (14 HP) + Raining Molten Slag Barrage.
## Phase 3: Boiler Meltdown Overdrive (+35% speed, white-hot boiler steam, 3 damage).

const SLAG_SCENE = preload("res://scenes/bosses/falling_molten_slag.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

enum SteinhardtAction { IDLE, WRENCH_TELEGRAPH, WRENCH_SWEEP, POUND_TELEGRAPH, POUND_SLAM, MELTDOWN_BURST, RECOVERY }
var current_action: SteinhardtAction = SteinhardtAction.IDLE
var action_timer: float = 0.0
var slag_rain_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/baron_steinhardt.tres") as BossData
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

	# Phase 2 & 3: Molten slag rain
	if current_phase >= 2 and not is_staggered:
		slag_rain_timer += delta
		var slag_rate = 1.6 if current_phase == 2 else 1.1
		if slag_rain_timer >= slag_rate:
			slag_rain_timer = 0.0
			_spawn_falling_slag()

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [SteinhardtAction.IDLE, SteinhardtAction.WRENCH_TELEGRAPH, SteinhardtAction.POUND_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		SteinhardtAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			var idle_time = 0.8 if current_phase < 3 else 0.45
			if action_timer >= idle_time:
				_choose_next_attack()

		SteinhardtAction.WRENCH_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.45 if current_phase < 3 else 0.28
			if action_timer >= telegraph_time:
				current_action = SteinhardtAction.WRENCH_SWEEP
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * (120.0 if current_phase < 3 else 170.0)

		SteinhardtAction.WRENCH_SWEEP:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = SteinhardtAction.RECOVERY
				action_timer = 0.0

		SteinhardtAction.POUND_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.38:
				current_action = SteinhardtAction.POUND_SLAM
				action_timer = 0.0
				velocity = Vector2(facing_direction * 150.0, -270.0)

		SteinhardtAction.POUND_SLAM:
			if is_on_floor() and action_timer >= 0.22:
				_trigger_slam_shockwave()
				current_action = SteinhardtAction.RECOVERY
				action_timer = 0.0

		SteinhardtAction.MELTDOWN_BURST:
			velocity.x = facing_direction * 200.0
			if action_timer >= 0.45:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = SteinhardtAction.RECOVERY
				action_timer = 0.0

		SteinhardtAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			var rec_time = 0.50 if current_phase < 3 else 0.30
			if action_timer >= rec_time:
				current_action = SteinhardtAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_attack() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = SteinhardtAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if current_phase == 3 and roll < 0.45:
		current_action = SteinhardtAction.MELTDOWN_BURST
		hitbox.damage = 3
		hitbox.monitoring = true
	elif dist > 120.0:
		current_action = SteinhardtAction.POUND_TELEGRAPH
	else:
		current_action = SteinhardtAction.WRENCH_TELEGRAPH

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

func _spawn_falling_slag() -> void:
	var slag = SLAG_SCENE.instantiate() as FallingMoltenSlag
	var spawn_x = global_position.x + randf_range(-180.0, 180.0)
	if player_ref and randf() < 0.5:
		spawn_x = player_ref.global_position.x + randf_range(-45.0, 45.0)

	slag.global_position = Vector2(spawn_x, global_position.y - 170.0)
	slag.target_ground_y = global_position.y + 4.0
	get_parent().add_child(slag)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	if phase == 2:
		# Equip Riveted Brass Armor
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		# Enraged Meltdown Overdrive
		current_armor = 0
		hitbox.damage = 3
		hitbox.knockback_force = 220.0
	queue_redraw()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.85, 0.72, 0.60)
	var col_iron = Color.WHITE if is_flashing else (Color(1.0, 0.35, 0.15) if current_phase == 3 else Color(0.28, 0.30, 0.34))
	var col_brass = Color.WHITE if is_flashing else Color(0.85, 0.70, 0.25)
	var col_boiler = Color.WHITE if is_flashing else Color(0.65, 0.25, 0.15)
	var col_steam = Color(0.85, 0.90, 0.95, 0.6)

	var f = float(facing_direction)

	# Heavy Industrial Exoskeleton Legs
	draw_rect(Rect2(-12, -14, 10, 14), col_iron)
	draw_rect(Rect2(2, -14, 10, 14), col_iron)

	# Main Boiler Plating
	draw_rect(Rect2(-14, -38, 28, 24), col_iron)
	draw_rect(Rect2(-10, -34, 20, 16), col_boiler)
	# Rivet studs
	draw_circle(Vector2(-12, -36), 1.5, col_brass)
	draw_circle(Vector2(12, -36), 1.5, col_brass)
	draw_circle(Vector2(-12, -16), 1.5, col_brass)
	draw_circle(Vector2(12, -16), 1.5, col_brass)

	# Head with Top Hat & Monocle
	draw_circle(Vector2(0, -44), 6.0, col_skin)
	# Top hat
	draw_rect(Rect2(-8, -50, 16, 2), Color(0.12, 0.12, 0.15))
	draw_rect(Rect2(-6, -58, 12, 8), Color(0.12, 0.12, 0.15))
	draw_circle(Vector2(f * 2, -44), 2.0, col_brass) # Monocle

	# Steam Exhaust Pipes on shoulders
	draw_rect(Rect2(-f * 12, -48, 5, 12), col_brass)
	draw_circle(Vector2(-f * 12, -52), 4.0, col_steam)

	# Motorized Steam Wrench
	var hand_pos = Vector2(f * 10, -28)
	if current_action == SteinhardtAction.WRENCH_SWEEP:
		var tip = Vector2(f * 40, -28)
		draw_line(hand_pos - Vector2(f * 14, 0), tip, col_iron, 4.0)
		# Wrench jaws
		draw_rect(Rect2(tip.x - 4, tip.y - 8, 10, 16), col_brass)
		draw_arc(Vector2(f * 22, -28), 24.0, -PI * 0.45, PI * 0.45, 10, Color(1.0, 0.45, 0.15, 0.7), 3.0)
	elif current_action == SteinhardtAction.POUND_SLAM:
		draw_line(hand_pos + Vector2(0, -20), hand_pos + Vector2(0, 30), col_iron, 4.0)
		draw_rect(Rect2(hand_pos.x - 6, hand_pos.y + 24, 12, 12), col_brass)
	else:
		draw_line(hand_pos + Vector2(-f * 10, 10), hand_pos + Vector2(f * 20, -18), col_iron, 3.5)
		draw_rect(Rect2(hand_pos.x + f * 16, hand_pos.y - 24, 10, 12), col_brass)

	# Phase 2: Riveted Brass Armor shield ring
	if current_armor > 0:
		draw_arc(Vector2(0, -26), 28.0, 0, TAU, 16, Color(0.9, 0.75, 0.2, 0.7), 2.5)

	# Phase 3: Boiler Meltdown white-hot flame ring
	if current_phase == 3:
		draw_arc(Vector2(0, -26), 34.0, 0, TAU, 16, Color(1.0, 0.4, 0.1, 0.5 + sin(action_timer * 12.0) * 0.25), 3.0)
