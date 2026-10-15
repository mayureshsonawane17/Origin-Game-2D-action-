class_name BossShogunKageyasu
extends BossController

## 3-Phase Historical Era Boss: Shogun Kageyasu (HIST-ERA).
## Phase 1: Naginata Sweeping Cleave & Leaping Ground Slam.
## Phase 2: Spirit Armor (12 HP) + Raining Spectral Shadow Blades.
## Phase 3: Phantom Flame Flurry (+35% speed, glowing crimson crescent strikes, 3 damage).

const SHADOW_BLADE_SCENE = preload("res://scenes/bosses/falling_shadow_blade.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

enum ShogunAction { IDLE, NAGINATA_TELEGRAPH, NAGINATA_SWEEP, LEAP_TELEGRAPH, LEAP_SLAM, PHANTOM_FLURRY, RECOVERY }
var current_action: ShogunAction = ShogunAction.IDLE
var action_timer: float = 0.0
var blade_rain_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/shogun_kageyasu.tres") as BossData
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

	# Phase 2 & 3: Spectral blade rain
	if current_phase >= 2 and not is_staggered:
		blade_rain_timer += delta
		var blade_rate = 1.7 if current_phase == 2 else 1.2
		if blade_rain_timer >= blade_rate:
			blade_rain_timer = 0.0
			_spawn_falling_blade()

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [ShogunAction.IDLE, ShogunAction.NAGINATA_TELEGRAPH, ShogunAction.LEAP_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		ShogunAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			var idle_time = 0.8 if current_phase < 3 else 0.45
			if action_timer >= idle_time:
				_choose_next_attack()

		ShogunAction.NAGINATA_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.42 if current_phase < 3 else 0.28
			if action_timer >= telegraph_time:
				current_action = ShogunAction.NAGINATA_SWEEP
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * (130.0 if current_phase < 3 else 180.0)

		ShogunAction.NAGINATA_SWEEP:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = ShogunAction.RECOVERY
				action_timer = 0.0

		ShogunAction.LEAP_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = ShogunAction.LEAP_SLAM
				action_timer = 0.0
				velocity = Vector2(facing_direction * 160.0, -280.0)

		ShogunAction.LEAP_SLAM:
			if is_on_floor() and action_timer >= 0.25:
				_trigger_slam_shockwave()
				current_action = ShogunAction.RECOVERY
				action_timer = 0.0

		ShogunAction.PHANTOM_FLURRY:
			velocity.x = facing_direction * 220.0
			if action_timer >= 0.45:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = ShogunAction.RECOVERY
				action_timer = 0.0

		ShogunAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			var rec_time = 0.50 if current_phase < 3 else 0.32
			if action_timer >= rec_time:
				current_action = ShogunAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_attack() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = ShogunAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if current_phase == 3 and roll < 0.45:
		current_action = ShogunAction.PHANTOM_FLURRY
		hitbox.damage = 3
		hitbox.monitoring = true
	elif dist > 120.0:
		current_action = ShogunAction.LEAP_TELEGRAPH
	else:
		current_action = ShogunAction.NAGINATA_TELEGRAPH

func _trigger_slam_shockwave() -> void:
	hitbox.monitoring = false
	var left_wave = SHOCKWAVE_SCENE.instantiate()
	left_wave.global_position = global_position + Vector2(-12, 0)
	left_wave.direction = Vector2.LEFT
	left_wave.caster = self
	get_parent().add_child(left_wave)

	var right_wave = SHOCKWAVE_SCENE.instantiate()
	right_wave.global_position = global_position + Vector2(12, 0)
	right_wave.direction = Vector2.RIGHT
	right_wave.caster = self
	get_parent().add_child(right_wave)

func _spawn_falling_blade() -> void:
	var blade = SHADOW_BLADE_SCENE.instantiate() as FallingShadowBlade
	var offset_x = randf_range(-180.0, 180.0)
	var spawn_x = global_position.x + offset_x
	if player_ref and randf() < 0.5:
		spawn_x = player_ref.global_position.x + randf_range(-40.0, 40.0)

	blade.global_position = Vector2(spawn_x, global_position.y - 180.0)
	blade.target_ground_y = global_position.y + 4.0
	get_parent().add_child(blade)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	if phase == 2:
		# Equip Spirit Armor
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		# Enraged Phantom Storm
		current_armor = 0
		hitbox.damage = 3
		hitbox.knockback_force = 220.0
	queue_redraw()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.92, 0.78, 0.65)
	var col_armor = Color.WHITE if is_flashing else (Color(0.85, 0.15, 0.18) if current_phase == 3 else Color(0.18, 0.18, 0.22))
	var col_gold = Color.WHITE if is_flashing else Color(0.95, 0.80, 0.25)
	var col_cape = Color.WHITE if is_flashing else Color(0.70, 0.12, 0.16)
	var col_shaft = Color.WHITE if is_flashing else Color(0.40, 0.25, 0.15)
	var col_blade = Color.WHITE if is_flashing else (Color(1.0, 0.3, 0.4) if current_phase == 3 else Color(0.95, 0.95, 1.0))

	var f = float(facing_direction)

	# Flowing Samurai Cape
	var cape_pts = PackedVector2Array([
		Vector2(-f * 8, -32),
		Vector2(-f * 24, 0),
		Vector2(-f * 10, -8)
	])
	draw_colored_polygon(cape_pts, col_cape)

	# Heavy O-Yoroi Lacquered Plating
	draw_rect(Rect2(-12, -22, 24, 22), col_armor)
	draw_rect(Rect2(-11, -40, 22, 20), col_armor)
	# Gold Trim & Crest
	draw_rect(Rect2(-12, -24, 24, 3), col_gold)
	draw_rect(Rect2(-f * 14, -38, 6, 12), col_gold) # Sode shoulder guard

	# Head & Kabuto Helmet
	draw_circle(Vector2(0, -46), 7.0, col_skin)
	draw_rect(Rect2(-9, -52, 18, 7), col_armor)
	# Golden Crescent Moon Horns (Maedate)
	draw_arc(Vector2(0, -52), 8.0, -PI * 0.8, -PI * 0.2, 8, col_gold, 2.5)

	# Naginata Polearm
	var hand_pos = Vector2(f * 8, -26)
	if current_action == ShogunAction.NAGINATA_SWEEP:
		var tip = Vector2(f * 42, -26)
		draw_line(Vector2(-f * 18, -26), tip, col_shaft, 3.0)
		draw_line(tip, tip + Vector2(f * 12, -10), col_blade, 3.5)
		draw_arc(Vector2(f * 24, -26), 26.0, -PI * 0.45, PI * 0.45, 10, Color(1.0, 0.25, 0.35, 0.7), 3.0)
	elif current_action == ShogunAction.LEAP_SLAM:
		# Overhead vertical plunge
		draw_line(hand_pos + Vector2(0, -24), hand_pos + Vector2(0, 32), col_shaft, 3.0)
		draw_line(hand_pos + Vector2(0, 32), hand_pos + Vector2(f * 6, 42), col_blade, 3.5)
	else:
		# Held diagonally ready
		var tip = hand_pos + Vector2(f * 24, -22)
		draw_line(hand_pos + Vector2(-f * 16, 14), tip, col_shaft, 3.0)
		draw_line(tip, tip + Vector2(f * 8, -8), col_blade, 3.5)

	# Phase 2: Spirit Armor glowing barrier
	if current_armor > 0:
		draw_arc(Vector2(0, -26), 28.0, 0, TAU, 16, Color(0.9, 0.3, 0.4, 0.6), 2.0)

	# Phase 3: Phantom Flame aura
	if current_phase == 3:
		draw_arc(Vector2(0, -26), 32.0, 0, TAU, 16, Color(1.0, 0.2, 0.2, 0.4 + sin(action_timer * 10.0) * 0.2), 2.5)
