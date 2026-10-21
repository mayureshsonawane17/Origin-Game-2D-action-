class_name BossMudGolem
extends BossController

## Prehistoric Regular Boss: Mud Golem (PRE-02).
## Earth Spirit utilizing mud traps, clay boulder throws, and heavy swamp smashes.
## Weakness: Ranged / Magic (takes 2x damage and stagger from magic projectiles).

const CLAY_BOULDER_SCENE = preload("res://scenes/bosses/clay_boulder.tscn")
const MUD_TRAP_SCENE = preload("res://scenes/bosses/mud_trap.tscn")

enum GolemAction { IDLE, SWIPE_TELEGRAPH, SWIPE_ATTACK, BOULDER_TELEGRAPH, BOULDER_TOSS, SLAM_TELEGRAPH, SLAM_ATTACK, RECOVERY }
var current_action: GolemAction = GolemAction.IDLE
var action_timer: float = 0.0
var walk_anim_time: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/mud_golem.tres") as BossData
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

	# Track player facing
	if player_ref and current_action in [GolemAction.IDLE, GolemAction.SWIPE_TELEGRAPH, GolemAction.BOULDER_TELEGRAPH, GolemAction.SLAM_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		GolemAction.IDLE:
			walk_anim_time += delta * 4.0
			if player_ref:
				var dist = absf(player_ref.global_position.x - global_position.x)
				if dist > 80.0:
					velocity.x = facing_direction * data.move_speed
				else:
					velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

			if action_timer >= 1.0:
				_choose_next_action()

		GolemAction.SWIPE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.45:
				current_action = GolemAction.SWIPE_ATTACK
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 110.0
				if SoundManager:
					SoundManager.play_sfx("slash_finisher")

		GolemAction.SWIPE_ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			if action_timer >= 0.32:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = GolemAction.RECOVERY
				action_timer = 0.0

		GolemAction.BOULDER_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.40:
				current_action = GolemAction.BOULDER_TOSS
				action_timer = 0.0
				_throw_clay_boulder()

		GolemAction.BOULDER_TOSS:
			velocity.x = 0.0
			if action_timer >= 0.30:
				current_action = GolemAction.RECOVERY
				action_timer = 0.0

		GolemAction.SLAM_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.50:
				current_action = GolemAction.SLAM_ATTACK
				action_timer = 0.0
				_execute_mud_slam()

		GolemAction.SLAM_ATTACK:
			velocity.x = 0.0
			if action_timer >= 0.40:
				current_action = GolemAction.RECOVERY
				action_timer = 0.0

		GolemAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.55:
				current_action = GolemAction.IDLE
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = GolemAction.IDLE
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 140.0:
		if roll < 0.6:
			current_action = GolemAction.BOULDER_TELEGRAPH
			telegraph(0.40, Color(0.9, 0.6, 0.2))
		else:
			current_action = GolemAction.SLAM_TELEGRAPH
			telegraph(0.50, Color(0.7, 0.4, 0.2))
	elif dist > 70.0:
		if roll < 0.4:
			current_action = GolemAction.SWIPE_TELEGRAPH
			telegraph(0.45, Color(1.0, 0.3, 0.1))
		elif roll < 0.7:
			current_action = GolemAction.SLAM_TELEGRAPH
			telegraph(0.50, Color(0.7, 0.4, 0.2))
		else:
			current_action = GolemAction.BOULDER_TELEGRAPH
			telegraph(0.40, Color(0.9, 0.6, 0.2))
	else:
		current_action = GolemAction.SWIPE_TELEGRAPH
		telegraph(0.45, Color(1.0, 0.3, 0.1))

func _throw_clay_boulder() -> void:
	var boulder = CLAY_BOULDER_SCENE.instantiate()
	boulder.global_position = global_position + Vector2(facing_direction * 16, -26)
	var target_x = player_ref.global_position.x if player_ref else global_position.x + facing_direction * 140.0
	var dx = target_x - boulder.global_position.x
	var vx = clampf(dx * 1.5, -220.0, 220.0)
	boulder.velocity = Vector2(vx, -180.0)
	get_parent().add_child(boulder)
	if SoundManager:
		SoundManager.play_sfx("slash_2")

func _execute_mud_slam() -> void:
	if SoundManager:
		SoundManager.play_sfx("enemy_hit")

	# Spawn mud traps on both sides
	var trap_left = MUD_TRAP_SCENE.instantiate()
	trap_left.global_position = Vector2(global_position.x - 45.0, global_position.y)
	get_parent().add_child(trap_left)

	var trap_right = MUD_TRAP_SCENE.instantiate()
	trap_right.global_position = Vector2(global_position.x + 45.0, global_position.y)
	get_parent().add_child(trap_right)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# Ranged / Magic Weakness check!
	var is_magic = (attacker is MagicProjectile) or (attacker != null and (attacker.get_script() == preload("res://scripts/combat/magic_projectile.gd") or attacker.name.to_lower().contains("magic")))
	var incoming_dmg = dmg
	if is_magic:
		incoming_dmg *= 2 # 2x Damage weakness
		if SoundManager:
			SoundManager.play_sfx("parry")

	super._on_hurtbox_hit_received(incoming_dmg, knockback, hitstop_frames, attacker, is_finisher)

	if is_magic and not is_dead:
		stagger(1.2) # Stagger after taking the hit

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_dark = Color.WHITE if is_flashing else Color(0.32, 0.20, 0.12)
	var col_mid = Color.WHITE if is_flashing else Color(0.50, 0.32, 0.18)
	var col_light = Color.WHITE if is_flashing else Color(0.68, 0.44, 0.24)
	var col_core = Color(1.0, 0.75, 0.2, 0.9) # Glowing Amber Heart
	var col_moss = Color(0.24, 0.42, 0.18)

	var f = float(facing_direction)
	var bob = sin(walk_anim_time) * 2.0 if current_action == GolemAction.IDLE else 0.0

	# Heavy legs
	draw_rect(Rect2(-14, -14, 11, 14), col_dark)
	draw_rect(Rect2(3, -14, 11, 14), col_dark)

	# Bulky earthen torso
	draw_rect(Rect2(-18, -38 + bob, 36, 26), col_mid)
	draw_rect(Rect2(-14, -34 + bob, 28, 18), col_light)

	# Moss patches
	draw_rect(Rect2(-16, -37 + bob, 8, 4), col_moss)
	draw_rect(Rect2(6, -26 + bob, 7, 5), col_moss)

	# Glowing Molten Core
	draw_circle(Vector2(f * 2, -26 + bob), 4.5, col_core)
	draw_circle(Vector2(f * 2, -26 + bob), 2.0, Color.WHITE)

	# Golem Head (Sunken earthen dome)
	draw_rect(Rect2(-11 + f * 2, -48 + bob, 22, 12), col_dark)
	draw_rect(Rect2(-8 + f * 2, -46 + bob, 16, 9), col_mid)
	# Glowing yellow eyes
	draw_circle(Vector2(f * 3 - 2, -42 + bob), 1.5, Color(1, 0.9, 0.2))
	draw_circle(Vector2(f * 3 + 4, -42 + bob), 1.5, Color(1, 0.9, 0.2))

	# Heavy clay fists / arms
	if current_action == GolemAction.SWIPE_TELEGRAPH:
		# Fist cocked back high
		draw_rect(Rect2(-f * 20 - 6, -42, 14, 14), col_dark)
	elif current_action == GolemAction.SWIPE_ATTACK:
		# Fist lunged forward
		draw_rect(Rect2(f * 20 - 6, -26, 16, 14), col_light)
	elif current_action == GolemAction.SLAM_TELEGRAPH:
		# Both fists raised
		draw_rect(Rect2(-18, -52, 12, 12), col_dark)
		draw_rect(Rect2(6, -52, 12, 12), col_dark)
	else:
		draw_rect(Rect2(-24, -32 + bob, 10, 20), col_dark)
		draw_rect(Rect2(14, -32 + bob, 10, 20), col_dark)
