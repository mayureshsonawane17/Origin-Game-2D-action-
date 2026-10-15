class_name BossLordMalakor
extends BossController

## 3-Phase Medieval Era Boss: Lord Malakor of the Iron Bastion (MED-ERA).
## Phase 1: Spiked Morningstar Cleave & Shield Slam.
## Phase 2: Bastion Iron Armor (10 HP) + Raining Trebuchet Ember Barrage.
## Phase 3: Phantom Flame Frenzy (+40% speed, glowing cursed flame swings, 3 damage).

const EMBER_SCENE = preload("res://scenes/bosses/falling_siege_ember.tscn")
const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

enum MalakorAction { IDLE, CLEAVE_TELEGRAPH, CLEAVE_SWING, SLAM_TELEGRAPH, SLAM_SHOCKWAVE, FRENZY_SWEEP, RECOVERY }
var current_action: MalakorAction = MalakorAction.IDLE
var action_timer: float = 0.0
var ember_rain_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/lord_malakor.tres") as BossData
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

	# Phase 2 & 3: Ember rain
	if current_phase >= 2 and not is_staggered:
		ember_rain_timer += delta
		var ember_rate = 1.6 if current_phase == 2 else 1.2
		if ember_rain_timer >= ember_rate:
			ember_rain_timer = 0.0
			_spawn_falling_ember()

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [MalakorAction.IDLE, MalakorAction.CLEAVE_TELEGRAPH, MalakorAction.SLAM_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		MalakorAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			var idle_time = 0.8 if current_phase < 3 else 0.45
			if action_timer >= idle_time:
				_choose_next_attack()

		MalakorAction.CLEAVE_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.45 if current_phase < 3 else 0.3
			if action_timer >= telegraph_time:
				current_action = MalakorAction.CLEAVE_SWING
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * (120.0 if current_phase < 3 else 160.0)

		MalakorAction.CLEAVE_SWING:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.3:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = MalakorAction.RECOVERY
				action_timer = 0.0

		MalakorAction.SLAM_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.5:
				current_action = MalakorAction.SLAM_SHOCKWAVE
				action_timer = 0.0
				_trigger_shield_shockwave()

		MalakorAction.SLAM_SHOCKWAVE:
			if action_timer >= 0.4:
				current_action = MalakorAction.RECOVERY
				action_timer = 0.0

		MalakorAction.FRENZY_SWEEP:
			# Phase 3 rapid forward rush
			velocity.x = facing_direction * 200.0
			if action_timer >= 0.4:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = MalakorAction.RECOVERY
				action_timer = 0.0

		MalakorAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
			var recovery_time = 0.5 if current_phase < 3 else 0.25
			if action_timer >= recovery_time:
				current_action = MalakorAction.IDLE
				action_timer = 0.0

	move_and_slide()
	queue_redraw()

func _choose_next_attack() -> void:
	action_timer = 0.0
	var dist = global_position.distance_to(player_ref.global_position) if player_ref else 100.0

	if current_phase == 3:
		# Rapid aggressive alternation
		if randf() > 0.4:
			current_action = MalakorAction.FRENZY_SWEEP
			hitbox.damage = 3
			hitbox.monitoring = true
			telegraph(0.25, Color(1.5, 0.4, 0.2))
		else:
			current_action = MalakorAction.CLEAVE_TELEGRAPH
			telegraph(0.3, Color(1.3, 0.3, 0.2))
	elif dist < 60.0:
		current_action = MalakorAction.CLEAVE_TELEGRAPH
		telegraph(0.45, Color(1.0, 0.3, 0.3))
	else:
		if randf() > 0.4:
			current_action = MalakorAction.SLAM_TELEGRAPH
			telegraph(0.5, Color(0.9, 0.5, 0.2))
		else:
			# Advance
			var dir = 1 if player_ref and player_ref.global_position.x > global_position.x else -1
			set_facing(dir)
			velocity.x = dir * data.move_speed
			current_action = MalakorAction.IDLE

func _trigger_shield_shockwave() -> void:
	# Spawns travelling shockwave
	var wave = SHOCKWAVE_SCENE.instantiate() as SeismicShockwave
	wave.global_position = global_position + Vector2(facing_direction * 16.0, 0.0)
	wave.direction = facing_direction
	get_parent().add_child(wave)

func _spawn_falling_ember() -> void:
	if not player_ref:
		return
	var ember = EMBER_SCENE.instantiate() as FallingSiegeEmber
	# Spawn above player's general vicinity
	var spawn_x = player_ref.global_position.x + randf_range(-60.0, 60.0)
	ember.global_position = Vector2(spawn_x, global_position.y - 140.0)
	ember.target_ground_y = global_position.y
	get_parent().add_child(ember)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	if phase == 2:
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		hitbox.damage = 3
		data.move_speed = 80.0

func _draw() -> void:
	# Crisp Procedural Pixel Art: Lord Malakor of the Iron Bastion
	var col_armor = Color(0.22, 0.20, 0.24)   # Blackened iron
	var col_red = Color(0.85, 0.20, 0.22)     # Crimson heraldry / glowing veins
	var col_gold = Color(0.85, 0.70, 0.25)    # Imperial gold trim

	if current_phase == 3:
		# Fiery phantom glow
		visual_root.modulate = Color(1.4, 0.6, 0.4)

	# Cape
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -30), Vector2(-18, -4), Vector2(-4, -4)]), col_red.darkened(0.3))

	# Heavy Sabatons & Greaves
	draw_rect(Rect2(-10, -12, 8, 12), col_armor.darkened(0.2))
	draw_rect(Rect2(2, -12, 8, 12), col_armor.darkened(0.2))

	# Massive Bulwark Cuirass
	draw_rect(Rect2(-12, -32, 24, 20), col_armor)
	draw_line(Vector2(-12, -22), Vector2(12, -22), col_gold, 2.0)
	draw_rect(Rect2(-4, -30, 8, 14), col_red) # Center blood sash

	# Horned Iron Greathelm
	draw_rect(Rect2(-8, -44, 16, 12), col_armor)
	draw_rect(Rect2(-5, -38, 10, 2), Color(1.0, 0.2, 0.2)) # Glowing red eye slit
	# Upward sweeping horns
	draw_line(Vector2(-8, -42), Vector2(-16, -52), col_gold, 3.0)
	draw_line(Vector2(8, -42), Vector2(16, -52), col_gold, 3.0)

	# Spiked Morningstar
	if current_action in [MalakorAction.CLEAVE_TELEGRAPH, MalakorAction.CLEAVE_SWING, MalakorAction.FRENZY_SWEEP]:
		draw_line(Vector2(8, -26), Vector2(24, -46), Color(0.4, 0.4, 0.45), 2.5) # Shaft
		draw_circle(Vector2(24, -46), 7.0, col_armor.darkened(0.3)) # Heavy spiked ball
		draw_circle(Vector2(24, -46), 4.0, col_red if current_phase == 3 else col_gold)
	else:
		draw_line(Vector2(6, -20), Vector2(16, -10), Color(0.4, 0.4, 0.45), 2.0)
		draw_circle(Vector2(16, -10), 6.0, col_armor.darkened(0.3))

	# Phase 2 Bastion Armor Shell Indicator
	if current_armor > 0:
		draw_rect(Rect2(-14, -34, 28, 24), Color(0.4, 0.45, 0.5, 0.35))
		draw_line(Vector2(-14, -34), Vector2(14, -34), Color(0.7, 0.8, 0.9), 2.0)
