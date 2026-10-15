class_name BossCyberUnit73
extends BossController

## Futuristic Miniboss: Unit 73 Infiltrator (FUT-01).
## High-speed cybernetic assassin with hardlight blade flurries, teleport phase-dashes, and plasma volleys.

const PLASMA_ORB_SCENE = preload("res://scenes/combat/plasma_orb_projectile.tscn")

enum Unit73Action { IDLE, BLADE_TELEGRAPH, BLADE_FLURRY, TELEPORT_TELEGRAPH, TELEPORT_DASH, PLASMA_VOLLEY, RECOVERY }
var current_action: Unit73Action = Unit73Action.IDLE
var action_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/cyber_unit73.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 170.0
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
	if player_ref and current_action in [Unit73Action.IDLE, Unit73Action.BLADE_TELEGRAPH, Unit73Action.TELEPORT_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		Unit73Action.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.70:
				_choose_next_action()

		Unit73Action.BLADE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = Unit73Action.BLADE_FLURRY
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 200.0

		Unit73Action.BLADE_FLURRY:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.30:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = Unit73Action.RECOVERY
				action_timer = 0.0

		Unit73Action.TELEPORT_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.25:
				current_action = Unit73Action.TELEPORT_DASH
				action_timer = 0.0
				# Teleport behind or towards player
				if player_ref:
					var target_x = player_ref.global_position.x - (facing_direction * 35.0)
					global_position.x = target_x
					set_facing(-facing_direction)
				flash_white(0.15)

		Unit73Action.TELEPORT_DASH:
			velocity.x = 0.0
			if action_timer >= 0.20:
				current_action = Unit73Action.BLADE_TELEGRAPH
				action_timer = 0.0

		Unit73Action.PLASMA_VOLLEY:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = Unit73Action.RECOVERY
				action_timer = 0.0

		Unit73Action.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			if action_timer >= 0.38:
				current_action = Unit73Action.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = Unit73Action.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 110.0:
		if roll < 0.5:
			current_action = Unit73Action.TELEPORT_TELEGRAPH
		else:
			current_action = Unit73Action.PLASMA_VOLLEY
			_fire_plasma_volley()
	else:
		current_action = Unit73Action.BLADE_TELEGRAPH

func _fire_plasma_volley() -> void:
	for i in range(2):
		var orb = PLASMA_ORB_SCENE.instantiate() as PlasmaOrbProjectile
		orb.caster = self
		orb.direction = Vector2(facing_direction, 0.0)
		orb.global_position = global_position + Vector2(facing_direction * 16.0, -18.0 + (i * 5.0))
		get_parent().add_child(orb)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_chassis = Color.WHITE if is_flashing else Color(0.10, 0.12, 0.16)
	var col_armor = Color.WHITE if is_flashing else (Color(1.0, 0.2, 0.3) if is_staggered else Color(0.18, 0.22, 0.30))
	var col_blade = Color.WHITE if is_flashing else Color(0.1, 0.95, 1.0)
	var col_magenta = Color.WHITE if is_flashing else Color(0.9, 0.15, 0.95)

	var f = float(facing_direction)

	# Sleek cyber chassis legs
	draw_rect(Rect2(-8, -14, 7, 14), col_chassis)
	draw_rect(Rect2(1, -14, 7, 14), col_chassis)
	draw_line(Vector2(-5, -14), Vector2(-5, 0), col_blade, 1.5)
	draw_line(Vector2(4, -14), Vector2(4, 0), col_blade, 1.5)

	# Armored carbon-fiber torso & glowing core
	draw_rect(Rect2(-9, -32, 18, 18), col_armor)
	draw_circle(Vector2(0, -23), 3.5, col_magenta)

	# Head visor & optics
	draw_circle(Vector2(0, -38), 6.0, col_chassis)
	draw_rect(Rect2(f * 1, -39, 6, 2.5), col_blade)

	# Twin Hardlight energy blades
	var hand_pos = Vector2(f * 8, -22)
	if current_action == Unit73Action.BLADE_FLURRY:
		var tip = hand_pos + Vector2(f * 26, -4)
		draw_line(hand_pos, tip, col_blade, 3.0)
		draw_arc(Vector2(f * 18, -22), 20.0, -PI * 0.45, PI * 0.45, 8, Color(0.1, 0.95, 1.0, 0.7), 2.5)
	else:
		draw_line(hand_pos, hand_pos + Vector2(-f * 4, 12), col_blade, 2.0)

	if is_staggered:
		draw_arc(Vector2(0, -38), 12.0, 0, TAU, 8, Color(1.0, 0.2, 0.3), 2.0)
