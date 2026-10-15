class_name BossTitanDeepEarth
extends BossController

## 3-Phase Era Boss: Titan of the Deep Earth (PRE-ERA).
## Multi-phase Geo-Cataclysm: Seismic shockwaves, Geo-Armor, Stalactite rain, Magma frenzy.

const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")
const STALACTITE_SCENE = preload("res://scenes/bosses/falling_stalactite.tscn")

enum TitanState { IDLE, STOMP_TELEGRAPH, STOMP_SLAM, CLEAVE_TELEGRAPH, CLEAVE_STRIKE, RECOVERY, ROAR }
var current_state: TitanState = TitanState.IDLE
var state_timer: float = 0.0

@onready var visuals: Node2D = $VisualRoot/TitanVisuals

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/titan_deep_earth.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 180.0
	hitbox.hitstop_frames = 5

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += 900.0 * delta

	if is_staggered:
		move_and_slide()
		return

	state_timer += delta

	# Track player facing
	if player_ref and current_state in [TitanState.IDLE, TitanState.STOMP_TELEGRAPH, TitanState.CLEAVE_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_state:
		TitanState.IDLE:
			var idle_time = 1.0 if current_phase == 1 else (0.7 if current_phase == 2 else 0.45)
			velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)
			if state_timer >= idle_time:
				_pick_next_attack()

		TitanState.STOMP_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.5 if current_phase < 3 else 0.35
			if state_timer >= telegraph_time:
				current_state = TitanState.STOMP_SLAM
				state_timer = 0.0
				_execute_seismic_stomp()

		TitanState.STOMP_SLAM:
			if state_timer >= 0.2:
				current_state = TitanState.RECOVERY
				state_timer = 0.0

		TitanState.CLEAVE_TELEGRAPH:
			velocity.x = 0.0
			var telegraph_time = 0.45 if current_phase < 3 else 0.3
			if state_timer >= telegraph_time:
				current_state = TitanState.CLEAVE_STRIKE
				state_timer = 0.0
				velocity.x = facing_direction * (data.move_speed if current_phase < 3 else data.move_speed * 1.5)
				hitbox.monitoring = true
				visuals.set_pose("cleave")

		TitanState.CLEAVE_STRIKE:
			if state_timer >= 0.25:
				current_state = TitanState.RECOVERY
				state_timer = 0.0
				hitbox.monitoring = false
				visuals.set_pose("idle")

		TitanState.RECOVERY:
			var recovery_time = 0.5 if current_phase == 1 else (0.35 if current_phase == 2 else 0.2)
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if state_timer >= recovery_time:
				current_state = TitanState.IDLE
				state_timer = 0.0
				visuals.set_pose("idle")

		TitanState.ROAR:
			velocity.x = 0.0
			if state_timer >= 1.2:
				current_state = TitanState.IDLE
				state_timer = 0.0
				visuals.set_pose("idle")

	move_and_slide()

func _pick_next_attack() -> void:
	state_timer = 0.0

	# Phase 2 stalactite hazard chance
	if current_phase == 2 and randf() > 0.4:
		_spawn_stalactite_rain()

	# Choose between Seismic Stomp and Earth Cleave
	if randf() > 0.45:
		current_state = TitanState.STOMP_TELEGRAPH
		telegraph(0.5 if current_phase < 3 else 0.35, Color(1.0, 0.5, 0.1))
		visuals.set_pose("stomp_prep")
	else:
		current_state = TitanState.CLEAVE_TELEGRAPH
		telegraph(0.45 if current_phase < 3 else 0.3, Color(1.0, 0.8, 0.2)) # Warning: parryable!
		visuals.set_pose("cleave_prep")

func _execute_seismic_stomp() -> void:
	visuals.set_pose("stomp_slam")
	# Camera heavy shake
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(6.0, 0.3)

	# Spawn shockwave traveling towards player
	var wave = SHOCKWAVE_SCENE.instantiate() as SeismicShockwave
	wave.global_position = global_position + Vector2(facing_direction * 20.0, 0.0)
	wave.direction = float(facing_direction)
	wave.damage = 1 if current_phase < 3 else 2
	get_parent().add_child(wave)

	# If phase 3, also shoot a secondary reverse wave
	if current_phase == 3:
		var back_wave = SHOCKWAVE_SCENE.instantiate() as SeismicShockwave
		back_wave.global_position = global_position + Vector2(-facing_direction * 20.0, 0.0)
		back_wave.direction = -float(facing_direction)
		back_wave.damage = 1
		get_parent().add_child(back_wave)

func _spawn_stalactite_rain() -> void:
	for i in 2:
		var rock = STALACTITE_SCENE.instantiate() as FallingStalactite
		var offset_x = randf_range(-140.0, 140.0)
		rock.global_position = Vector2(global_position.x + offset_x, global_position.y - 180.0)
		get_parent().add_child(rock)

func _on_phase_entered(phase: int) -> void:
	super._on_phase_entered(phase)
	current_state = TitanState.ROAR
	state_timer = 0.0
	visuals.set_pose("roar")
	visuals.update_phase(phase)

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(8.0, 0.6)

	if phase == 2:
		current_armor = data.armor_health
		boss_armor_changed.emit(current_armor, data.armor_health)
	elif phase == 3:
		# Magma frenzy boost
		hitbox.damage = 3
