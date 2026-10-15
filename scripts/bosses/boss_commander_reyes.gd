class_name BossCommanderReyes
extends BossController

## Modern Miniboss: Commander Reyes (MOD-01).
## Black Ops Infiltrator using flashbang dashes, tactical knife flurries, and burst pistol fire.

const TRACER_SCENE = preload("res://scenes/combat/sniper_tracer_bullet.tscn")

enum ReyesAction { IDLE, KNIFE_TELEGRAPH, KNIFE_FLURRY, DASH_TELEGRAPH, FLASH_DASH, BURST_FIRE, RECOVERY }
var current_action: ReyesAction = ReyesAction.IDLE
var action_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/commander_reyes.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 160.0
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

	# Track player facing during neutral & telegraphs
	if player_ref and current_action in [ReyesAction.IDLE, ReyesAction.KNIFE_TELEGRAPH, ReyesAction.DASH_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		ReyesAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.75:
				_choose_next_action()

		ReyesAction.KNIFE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.38:
				current_action = ReyesAction.KNIFE_FLURRY
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 180.0

		ReyesAction.KNIFE_FLURRY:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = ReyesAction.RECOVERY
				action_timer = 0.0

		ReyesAction.DASH_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.28:
				current_action = ReyesAction.FLASH_DASH
				action_timer = 0.0
				velocity.x = facing_direction * 260.0
				flash_white(0.15)

		ReyesAction.FLASH_DASH:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if action_timer >= 0.25:
				current_action = ReyesAction.KNIFE_TELEGRAPH
				action_timer = 0.0

		ReyesAction.BURST_FIRE:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = ReyesAction.RECOVERY
				action_timer = 0.0

		ReyesAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			if action_timer >= 0.40:
				current_action = ReyesAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = ReyesAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 120.0:
		if roll < 0.5:
			current_action = ReyesAction.DASH_TELEGRAPH
		else:
			current_action = ReyesAction.BURST_FIRE
			_fire_burst_pistol()
	else:
		current_action = ReyesAction.KNIFE_TELEGRAPH

func _fire_burst_pistol() -> void:
	for i in range(2):
		var bullet = TRACER_SCENE.instantiate() as SniperTracerBullet
		bullet.caster = self
		bullet.direction = Vector2(facing_direction, 0.0)
		bullet.global_position = global_position + Vector2(facing_direction * 16.0, -18.0 + (i * 4.0))
		get_parent().add_child(bullet)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.85, 0.72, 0.60)
	var col_gear = Color.WHITE if is_flashing else (Color(0.8, 0.2, 0.2) if is_staggered else Color(0.14, 0.16, 0.20))
	var col_vest = Color.WHITE if is_flashing else Color(0.08, 0.10, 0.12)
	var col_blade = Color.WHITE if is_flashing else Color(0.25, 0.85, 1.0)
	var col_beret = Color.WHITE if is_flashing else Color(0.18, 0.22, 0.28)

	var f = float(facing_direction)

	# Tactical fatigues & combat boots
	draw_rect(Rect2(-8, -14, 16, 14), col_gear)
	# Heavy tactical vest with mag pouches
	draw_rect(Rect2(-8, -32, 16, 18), col_vest)
	draw_rect(Rect2(-6, -26, 12, 6), Color(0.20, 0.24, 0.30))

	# Head with tactical earpiece & beret
	draw_circle(Vector2(0, -38), 6.0, col_skin)
	draw_rect(Rect2(-7, -45, 14, 4), col_beret) # Beret
	draw_circle(Vector2(f * 2, -37), 1.5, Color(0.2, 0.8, 1.0)) # Eye / optics

	# Combat knife
	var hand_pos = Vector2(f * 8, -22)
	if current_action == ReyesAction.KNIFE_FLURRY:
		var tip = hand_pos + Vector2(f * 26, -4)
		draw_line(hand_pos, tip, col_blade, 2.5)
		draw_arc(Vector2(f * 18, -22), 18.0, -PI * 0.45, PI * 0.45, 8, Color(0.2, 0.85, 1.0, 0.7), 2.5)
	elif current_action == ReyesAction.BURST_FIRE:
		# Pistol pointed forward
		draw_line(hand_pos, hand_pos + Vector2(f * 16, 0), Color(0.2, 0.22, 0.25), 3.0)
		draw_circle(hand_pos + Vector2(f * 16, 0), 2.5, Color(1.0, 0.9, 0.3))
	else:
		# Knife held in reverse tactical grip
		draw_line(hand_pos, hand_pos + Vector2(-f * 4, 12), col_blade, 2.0)

	if is_staggered:
		draw_circle(Vector2(sin(action_timer * 12.0) * 10.0, -50), 3.0, Color(0.2, 0.8, 1.0))
