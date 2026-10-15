class_name BossOverseerBrant
extends BossController

## Industrial Miniboss: Chief Overseer Brant (IND-01).
## Foundry Master wielding a pneumatic steam hammer, steam dashes, and boiler shockwaves.

const SHOCKWAVE_SCENE = preload("res://scenes/bosses/seismic_shockwave.tscn")

enum BrantAction { IDLE, SLAM_TELEGRAPH, HAMMER_SLAM, DASH_TELEGRAPH, STEAM_DASH, RECOVERY }
var current_action: BrantAction = BrantAction.IDLE
var action_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/overseer_brant.tres") as BossData
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

	# Track player facing
	if player_ref and current_action in [BrantAction.IDLE, BrantAction.SLAM_TELEGRAPH, BrantAction.DASH_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		BrantAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if action_timer >= 0.8:
				_choose_next_action()

		BrantAction.SLAM_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.45:
				current_action = BrantAction.HAMMER_SLAM
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				_trigger_slam_shockwave()

		BrantAction.HAMMER_SLAM:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.35:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = BrantAction.RECOVERY
				action_timer = 0.0

		BrantAction.DASH_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = BrantAction.STEAM_DASH
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 170.0

		BrantAction.STEAM_DASH:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.35:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = BrantAction.RECOVERY
				action_timer = 0.0

		BrantAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			if action_timer >= 0.45:
				current_action = BrantAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = BrantAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > 110.0:
		current_action = BrantAction.DASH_TELEGRAPH
	else:
		current_action = BrantAction.SLAM_TELEGRAPH

func _trigger_slam_shockwave() -> void:
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

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_skin = Color.WHITE if is_flashing else Color(0.85, 0.72, 0.60)
	var col_apron = Color.WHITE if is_flashing else (Color(0.8, 0.25, 0.2) if is_staggered else Color(0.38, 0.26, 0.18))
	var col_iron = Color.WHITE if is_flashing else Color(0.30, 0.32, 0.35)
	var col_brass = Color.WHITE if is_flashing else Color(0.85, 0.70, 0.25)
	var col_steam = Color(0.9, 0.92, 0.98, 0.6)

	var f = float(facing_direction)

	# Heavy boots and trousers
	draw_rect(Rect2(-10, -14, 20, 14), col_iron)
	# Heavy leather foundry apron
	draw_rect(Rect2(-9, -32, 18, 18), col_apron)
	draw_rect(Rect2(-7, -30, 14, 8), col_brass)

	# Head & Welder's Goggles
	draw_circle(Vector2(0, -38), 6.0, col_skin)
	draw_rect(Rect2(-7, -40, 14, 4), col_iron)
	draw_circle(Vector2(f * 2, -38), 2.0, Color(0.4, 0.9, 0.4))

	# Boiler backpack on shoulders
	draw_rect(Rect2(-f * 12, -36, 6, 14), col_brass)
	draw_circle(Vector2(-f * 12, -40), 4.0, col_steam)

	# Pneumatic Sledgehammer
	var hand_pos = Vector2(f * 8, -24)
	if current_action == BrantAction.SLAM_TELEGRAPH:
		# Raised high overhead
		draw_line(hand_pos, hand_pos + Vector2(0, -26), col_iron, 3.0)
		draw_rect(Rect2(hand_pos.x - 7, hand_pos.y - 34, 14, 8), col_iron)
		draw_circle(Vector2(hand_pos.x, hand_pos.y - 30), 2.5, Color(1.0, 0.5, 0.1))
	elif current_action == BrantAction.HAMMER_SLAM:
		# Smashed down to ground
		draw_line(hand_pos, hand_pos + Vector2(f * 18, 14), col_iron, 3.0)
		draw_rect(Rect2(hand_pos.x + f * 12, hand_pos.y + 10, 12, 10), col_iron)
	else:
		# Resting at waist
		draw_line(hand_pos, hand_pos + Vector2(f * 14, -12), col_iron, 3.0)
		draw_rect(Rect2(hand_pos.x + f * 10, hand_pos.y - 18, 10, 8), col_iron)

	if is_staggered:
		draw_circle(Vector2(sin(action_timer * 12.0) * 10.0, -50), 3.0, Color(1.0, 0.85, 0.2))
