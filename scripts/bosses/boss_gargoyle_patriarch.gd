class_name BossGargoylePatriarch
extends BossController

## Medieval Regular Boss: Gargoyle Patriarch (MED-02).
## Cathedral Beast featuring battlement dive attacks, stone armor hardening, and talon sweeps.
## Weaknesses: Ranged/Magic (pierces stone armor) & Aerial parry counter.

enum GargoyleAction { IDLE_PERCH, TAKEOFF, HOVER_TELEGRAPH, BATTLEMENT_DIVE, STONE_HARDEN, TALON_SWEEP, RECOVERY }
var current_action: GargoyleAction = GargoyleAction.IDLE_PERCH
var action_timer: float = 0.0
var wing_anim_time: float = 0.0
var dive_target: Vector2 = Vector2.ZERO
var ground_y: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/gargoyle_patriarch.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 170.0
	hitbox.hitstop_frames = 5
	ground_y = global_position.y

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	# Only apply ground gravity when not flying/hovering
	if current_action in [GargoyleAction.IDLE_PERCH, GargoyleAction.STONE_HARDEN, GargoyleAction.TALON_SWEEP, GargoyleAction.RECOVERY]:
		if not is_on_floor():
			velocity.y += 900.0 * delta
	else:
		wing_anim_time += delta * 12.0

	if is_staggered:
		if not is_on_floor():
			velocity.y += 900.0 * delta
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [GargoyleAction.IDLE_PERCH, GargoyleAction.HOVER_TELEGRAPH, GargoyleAction.STONE_HARDEN]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		GargoyleAction.IDLE_PERCH:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			if action_timer >= 0.9:
				_choose_next_action()

		GargoyleAction.TAKEOFF:
			# Fly upward into hover position
			velocity.y = -180.0
			velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)
			if action_timer >= 0.6:
				current_action = GargoyleAction.HOVER_TELEGRAPH
				action_timer = 0.0
				velocity = Vector2.ZERO
				telegraph(0.45, Color(1.0, 0.4, 0.1))

		GargoyleAction.HOVER_TELEGRAPH:
			velocity = Vector2.ZERO
			if action_timer >= 0.45:
				current_action = GargoyleAction.BATTLEMENT_DIVE
				action_timer = 0.0
				hitbox.damage = 3
				hitbox.monitoring = true
				var target_pos = player_ref.global_position if player_ref else global_position + Vector2(facing_direction * 100, 80)
				var dir_vec = (target_pos - global_position).normalized()
				velocity = dir_vec * 260.0
				if SoundManager:
					SoundManager.play_sfx("dodge")

		GargoyleAction.BATTLEMENT_DIVE:
			# Dive diagonally until landing on floor or timer
			if is_on_floor() or action_timer >= 0.7:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = GargoyleAction.RECOVERY
				action_timer = 0.0
				velocity = Vector2.ZERO
				if SoundManager:
					SoundManager.play_sfx("block")

		GargoyleAction.STONE_HARDEN:
			velocity = Vector2.ZERO
			if action_timer >= 1.6:
				current_action = GargoyleAction.RECOVERY
				action_timer = 0.0

		GargoyleAction.TALON_SWEEP:
			velocity.x = move_toward(velocity.x, 0.0, 280.0 * delta)
			if action_timer >= 0.35:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = GargoyleAction.RECOVERY
				action_timer = 0.0

		GargoyleAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
			if action_timer >= 0.6:
				current_action = GargoyleAction.IDLE_PERCH
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = GargoyleAction.IDLE_PERCH
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	# If armor broken and low, chance to harden
	if current_armor <= 1 and roll < 0.35:
		current_action = GargoyleAction.STONE_HARDEN
		current_armor = mini(data.armor_health, current_armor + 4)
		boss_armor_changed.emit(current_armor, data.armor_health)
		flash_white(0.2)
		if SoundManager:
			SoundManager.play_sfx("block")
		return

	if dist > 110.0:
		if roll < 0.65:
			current_action = GargoyleAction.TAKEOFF
		else:
			current_action = GargoyleAction.STONE_HARDEN
	else:
		if roll < 0.5:
			current_action = GargoyleAction.TALON_SWEEP
			hitbox.damage = 2
			hitbox.monitoring = true
			velocity.x = facing_direction * 90.0
			telegraph(0.35, Color(0.9, 0.3, 0.2))
		else:
			current_action = GargoyleAction.TAKEOFF

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# Weakness: Ranged / Magic bypasses stone armor!
	var is_magic = (attacker is MagicProjectile) or (attacker != null and attacker.name.contains("Magic"))
	if is_magic:
		if current_armor > 0:
			current_armor = 0
			boss_armor_changed.emit(0, data.armor_health)
			stagger(1.5) # Magic shatters stone stance
			if SoundManager:
				SoundManager.play_sfx("parry")
		super._on_hurtbox_hit_received(int(round(dmg * 1.5)), knockback, hitstop_frames, attacker, is_finisher)
		return

	# If hit while diving: crash down and stagger!
	if current_action == GargoyleAction.BATTLEMENT_DIVE:
		current_armor = 0
		boss_armor_changed.emit(0, data.armor_health)
		stagger(2.0)
		hitbox.monitoring = false
		hitbox.reset_hits()
		super._on_hurtbox_hit_received(dmg * 2, knockback, hitstop_frames, attacker, is_finisher)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_stone_dark = Color.WHITE if is_flashing else Color(0.32, 0.36, 0.42)
	var col_stone_mid = Color.WHITE if is_flashing else Color(0.50, 0.56, 0.64)
	var col_stone_light = Color.WHITE if is_flashing else Color(0.68, 0.74, 0.82)
	var col_wing = Color.WHITE if is_flashing else Color(0.24, 0.28, 0.34)
	var col_eye = Color(1.0, 0.85, 0.2)

	var f = float(facing_direction)
	var is_flying = current_action in [GargoyleAction.TAKEOFF, GargoyleAction.HOVER_TELEGRAPH, GargoyleAction.BATTLEMENT_DIVE]
	var wing_flap = sin(wing_anim_time) * 12.0 if is_flying else 0.0

	# Bat Wings
	if current_action == GargoyleAction.STONE_HARDEN:
		# Curled wings enveloping the body
		draw_rect(Rect2(-16, -34, 32, 28), col_wing)
		draw_rect(Rect2(-12, -30, 24, 22), col_stone_mid)
		draw_line(Vector2(-12, -30), Vector2(12, -8), col_stone_dark, 2.0)
		draw_line(Vector2(12, -30), Vector2(-12, -8), col_stone_dark, 2.0)
	else:
		# Spread wings behind body
		var w_pts_left = PackedVector2Array([
			Vector2(-6, -24),
			Vector2(-26, -42 + wing_flap),
			Vector2(-32, -26 + wing_flap),
			Vector2(-10, -16)
		])
		draw_colored_polygon(w_pts_left, col_wing)

		var w_pts_right = PackedVector2Array([
			Vector2(6, -24),
			Vector2(26, -42 + wing_flap),
			Vector2(32, -26 + wing_flap),
			Vector2(10, -16)
		])
		draw_colored_polygon(w_pts_right, col_wing)

	# Stone Torso
	draw_rect(Rect2(-10, -28, 20, 20), col_stone_mid)
	draw_rect(Rect2(-7, -26, 14, 14), col_stone_light)

	# Claws / Feet
	draw_rect(Rect2(-9, -8, 7, 8), col_stone_dark)
	draw_rect(Rect2(2, -8, 7, 8), col_stone_dark)

	# Horned Demonic Head
	draw_circle(Vector2(f * 2, -34), 8.0, col_stone_mid)
	# Curved Horns
	draw_line(Vector2(f * 2 - 4, -38), Vector2(f * 2 - 8, -48), col_stone_dark, 2.5)
	draw_line(Vector2(f * 2 + 4, -38), Vector2(f * 2 + 8, -48), col_stone_dark, 2.5)

	# Glowing Predator Eyes
	draw_circle(Vector2(f * 3 - 2, -34), 1.5, col_eye)
	draw_circle(Vector2(f * 3 + 3, -34), 1.5, col_eye)

	# Aiming line during hover telegraph
	if current_action == GargoyleAction.HOVER_TELEGRAPH and player_ref:
		var target_pos = to_local(player_ref.global_position)
		draw_line(Vector2.ZERO, target_pos, Color(1.0, 0.3, 0.1, 0.45), 1.5)
