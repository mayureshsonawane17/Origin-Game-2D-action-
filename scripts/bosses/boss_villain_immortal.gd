class_name BossVillainImmortal
extends BossController

## The Ultimate Final Boss: The Architect / The Villain ("The Unbeatable One").
## IMMORTAL — NO WEAKNESS DETECTED.
## Conventional combat is 100% ineffective; only deliberate resets destabilize the gemstone.

const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

signal mock_triggered(quote: String)
signal villain_begs_fight()

enum VillainAction { IDLE, VOID_TELEGRAPH, VOID_CLEAVE, WARP_TELEGRAPH, WARP_SHOCKWAVE, MOCK_TAUNT, RECOVERY }
var current_action: VillainAction = VillainAction.IDLE
var action_timer: float = 0.0
var hits_received_count: int = 0
var instability_level: int = 0
var boss_rush_mode: bool = false

func enable_boss_rush(max_hp: int = 16) -> void:
	boss_rush_mode = true
	if data:
		data = data.duplicate()
		data.id = "VIL-FRACTURED"
		data.display_name = "The Architect"
		data.title = "Shattered Core of Twelve Eras"
		data.max_health = max_hp
		data.total_phases = 3
	current_health = max_hp
	boss_health_changed.emit(current_health, max_hp)
	boss_phase_changed.emit(1, 3)

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/villain_immortal.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 190.0
	hitbox.hitstop_frames = 4

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	if not is_on_floor():
		velocity.y += 900.0 * delta

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [VillainAction.IDLE, VillainAction.VOID_TELEGRAPH, VillainAction.WARP_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		VillainAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			var idle_time = 0.85 if instability_level < 2 else 1.2 # Hesitates as world glitches
			if action_timer >= idle_time:
				_choose_next_action()

		VillainAction.VOID_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.40:
				current_action = VillainAction.VOID_CLEAVE
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * 180.0

		VillainAction.VOID_CLEAVE:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = VillainAction.RECOVERY
				action_timer = 0.0

		VillainAction.WARP_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = VillainAction.WARP_SHOCKWAVE
				action_timer = 0.0
				_trigger_warp_shockwave()

		VillainAction.WARP_SHOCKWAVE:
			velocity.x = 0.0
			if action_timer >= 0.30:
				current_action = VillainAction.RECOVERY
				action_timer = 0.0

		VillainAction.MOCK_TAUNT:
			velocity.x = 0.0
			if action_timer >= 0.60:
				current_action = VillainAction.RECOVERY
				action_timer = 0.0

		VillainAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.45:
				current_action = VillainAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = VillainAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 110.0:
		current_action = VillainAction.WARP_TELEGRAPH
	else:
		if roll < 0.6:
			current_action = VillainAction.VOID_TELEGRAPH
		else:
			current_action = VillainAction.MOCK_TAUNT

func _trigger_warp_shockwave() -> void:
	var left_wave = SHOCKWAVE_SCENE.instantiate()
	left_wave.global_position = global_position + Vector2(-16, 0)
	left_wave.direction = -1.0
	left_wave.caster = self
	get_parent().add_child(left_wave)

	var right_wave = SHOCKWAVE_SCENE.instantiate()
	right_wave.global_position = global_position + Vector2(16, 0)
	right_wave.direction = 1.0
	right_wave.caster = self
	get_parent().add_child(right_wave)

func _on_hurtbox_hit_received(_dmg: int, _knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	if boss_rush_mode:
		# In Boss Rush, the hero's accumulated 12-era loop resonance fractures the gemstone barrier!
		super._on_hurtbox_hit_received(_dmg, _knockback, hitstop, _attacker, _is_finisher)
		var max_hp = data.max_health if data else 16
		var progress = 1.0 - (float(current_health) / float(max_hp))
		var new_instability = clampi(int(progress * 3.0), 0, 3)
		if new_instability != instability_level:
			set_instability(new_instability)
		return

	# IMMORTAL: Attacks visibly do NO damage!
	apply_hitstop(hitstop)
	flash_white(0.12)

	hits_received_count += 1
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -22)
	spark.spark_color = Color(0.9, 0.2, 1.0, 1.0) # Gemstone barrier deflection
	get_parent().add_child(spark)

	if hits_received_count % 3 == 0:
		var mocks = [
			"Try again as you always do.",
			"Your determination only makes the gemstone stronger.",
			"You cannot defeat what created this eternity."
		]
		var chosen = mocks[(hits_received_count / 3) % mocks.size()]
		mock_triggered.emit(chosen)

func set_instability(level: int) -> void:
	instability_level = level
	if level == 1:
		# Slight glitch
		flash_timer = 0.3
	elif level == 2:
		# Furious / begging the hero to fight
		villain_begs_fight.emit()
	elif level >= 4:
		# Defeated by gemstone crack
		_die()
	queue_redraw()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_robes = Color.WHITE if is_flashing else Color(0.12, 0.08, 0.18)
	var col_trim = Color.WHITE if is_flashing else Color(0.95, 0.20, 0.85)
	var col_skin = Color.WHITE if is_flashing else Color(0.85, 0.82, 0.90)
	var col_eye = Color.WHITE if is_flashing else Color(1.0, 0.1, 0.3)

	var f = float(facing_direction)

	# Glitch jitter if reality is destabilizing
	var jitter_x = randf_range(-instability_level * 1.5, instability_level * 1.5)
	var jitter_y = randf_range(-instability_level * 1.5, instability_level * 1.5)

	# Robes
	draw_rect(Rect2(-10 + jitter_x, -16 + jitter_y, 20, 16), col_robes)
	draw_rect(Rect2(-12 + jitter_x, -36 + jitter_y, 24, 20), col_robes)
	# Gemstone mantle / trim
	draw_line(Vector2(-10 + jitter_x, -36 + jitter_y), Vector2(0, -20 + jitter_y), col_trim, 2.0)
	draw_line(Vector2(10 + jitter_x, -36 + jitter_y), Vector2(0, -20 + jitter_y), col_trim, 2.0)

	# Head with dark hood
	draw_circle(Vector2(jitter_x, -42 + jitter_y), 7.0, col_robes)
	draw_circle(Vector2(f * 2 + jitter_x, -41 + jitter_y), 5.0, col_skin)
	draw_circle(Vector2(f * 3 + jitter_x, -42 + jitter_y), 2.0, col_eye)

	# Massive Gemstone Ring floating behind villain
	var pulse = sin(action_timer * 6.0) * 2.0
	draw_arc(Vector2(jitter_x, -26 + jitter_y), 32.0 + pulse, 0, TAU, 16, col_trim, 2.5)

	# Barrier glow (Immortal aura)
	draw_arc(Vector2(jitter_x, -26 + jitter_y), 38.0, 0, TAU, 16, Color(0.85, 0.15, 0.95, 0.4), 1.5)
