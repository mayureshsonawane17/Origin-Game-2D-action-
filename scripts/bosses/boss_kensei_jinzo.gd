class_name BossKenseiJinzo
extends BossController

## Historical Miniboss: Kensei Jinzo (HIST-01).
## Wandering Swordmaster featuring dual-strike combos, elusive wind steps, and counter stances.

enum JinzoAction { IDLE, SLASH_TELEGRAPH, DUAL_SLASH, WIND_STEP, COUNTER_STANCE, RECOVERY }
var current_action: JinzoAction = JinzoAction.IDLE
var action_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/kensei_jinzo.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 150.0
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

	# Track player facing during neutral/telegraphs
	if player_ref and current_action in [JinzoAction.IDLE, JinzoAction.SLASH_TELEGRAPH, JinzoAction.COUNTER_STANCE]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		JinzoAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			if action_timer >= 0.75:
				_choose_next_action()

		JinzoAction.SLASH_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.38:
				current_action = JinzoAction.DUAL_SLASH
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 180.0

		JinzoAction.DUAL_SLASH:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = JinzoAction.RECOVERY
				action_timer = 0.0

		JinzoAction.WIND_STEP:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if action_timer >= 0.30:
				current_action = JinzoAction.SLASH_TELEGRAPH
				action_timer = 0.0

		JinzoAction.COUNTER_STANCE:
			velocity.x = 0.0
			if action_timer >= 0.85:
				current_action = JinzoAction.RECOVERY
				action_timer = 0.0

		JinzoAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
			if action_timer >= 0.45:
				current_action = JinzoAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = JinzoAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 110.0:
		# Wind step dash towards player
		current_action = JinzoAction.WIND_STEP
		velocity.x = facing_direction * 240.0
	elif roll < 0.55:
		current_action = JinzoAction.SLASH_TELEGRAPH
	elif roll < 0.85:
		current_action = JinzoAction.COUNTER_STANCE
	else:
		current_action = JinzoAction.WIND_STEP
		velocity.x = -facing_direction * 200.0 # Retreat step

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, attacker: Node, is_finisher: bool) -> void:
	if current_action == JinzoAction.COUNTER_STANCE and not is_finisher:
		# Counter-strike back at attacker
		hitbox.damage = 2
		hitbox.monitoring = true
		velocity.x = facing_direction * 120.0
		current_action = JinzoAction.DUAL_SLASH
		action_timer = 0.0
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop, attacker, is_finisher)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.92, 0.78, 0.65)
	var col_robe = Color.WHITE if is_flashing else (Color(0.8, 0.2, 0.2) if is_staggered else Color(0.18, 0.22, 0.32))
	var col_sash = Color.WHITE if is_flashing else Color(0.9, 0.2, 0.3)
	var col_blade = Color.WHITE if is_flashing else Color(0.95, 0.96, 1.0)
	var col_hair = Color.WHITE if is_flashing else Color(0.9, 0.9, 0.95)

	var f = float(facing_direction)

	# Samurai Hakama & Kimono
	draw_rect(Rect2(-10, -18, 20, 18), col_robe)
	draw_rect(Rect2(-9, -34, 18, 16), col_robe)
	# Red Cherry Blossom Sash (Obi)
	draw_rect(Rect2(-10, -20, 20, 4), col_sash)

	# Head & Topknot
	draw_circle(Vector2(0, -40), 6.0, col_skin)
	draw_circle(Vector2(-f * 3, -46), 3.0, col_hair)

	# Dual Katanas
	if current_action == JinzoAction.COUNTER_STANCE:
		# Crossed blades in defensive guard
		draw_line(Vector2(f * 4, -20), Vector2(f * 14, -38), col_blade, 2.5)
		draw_line(Vector2(f * 14, -20), Vector2(f * 4, -38), col_blade, 2.5)
		draw_circle(Vector2(f * 9, -29), 3.0, Color(1.0, 0.9, 0.3, 0.8))
	elif current_action == JinzoAction.DUAL_SLASH:
		# Twin extended sweeping slashes
		draw_line(Vector2(0, -28), Vector2(f * 28, -24), col_blade, 3.0)
		draw_line(Vector2(0, -22), Vector2(f * 32, -32), col_blade, 2.5)
		draw_arc(Vector2(f * 14, -26), 18.0, -PI * 0.45, PI * 0.45, 10, Color(0.95, 0.3, 0.4, 0.7), 2.5)
	elif current_action == JinzoAction.SLASH_TELEGRAPH:
		# Crouched draw stance with flash
		draw_line(Vector2(-f * 8, -18), Vector2(f * 6, -24), col_blade, 2.0)
		draw_circle(Vector2(f * 8, -25), 3.5, Color(1.0, 1.0, 0.4))
	else:
		# Twin sheathed katanas at waist
		draw_line(Vector2(-f * 10, -16), Vector2(f * 4, -22), col_blade, 2.0)
		draw_line(Vector2(-f * 8, -14), Vector2(f * 6, -20), col_blade, 2.0)

	# Stagger indicator
	if is_staggered:
		draw_circle(Vector2(sin(action_timer * 12.0) * 10.0, -52), 3.0, Color(1.0, 0.85, 0.2))
