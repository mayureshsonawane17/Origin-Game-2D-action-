class_name BossSirGareth
extends BossController

## Medieval Miniboss: Sir Gareth the Ironclad (MED-01).
## Heavy knight boss utilizing tower shield guard, overhead cleaves, and parryable shield bash.

enum GarethAction { IDLE, CLEAVE_TELEGRAPH, CLEAVE_SLASH, BASH_TELEGRAPH, BASH_LUNGE, BASTION_GUARD, RECOVERY }
var current_action: GarethAction = GarethAction.IDLE
var action_timer: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/sir_gareth.tres") as BossData
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
	if player_ref and current_action in [GarethAction.IDLE, GarethAction.CLEAVE_TELEGRAPH, GarethAction.BASH_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		GarethAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if action_timer >= 0.9:
				_choose_next_attack()

		GarethAction.CLEAVE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.45:
				current_action = GarethAction.CLEAVE_SLASH
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 100.0

		GarethAction.CLEAVE_SLASH:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.3:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = GarethAction.RECOVERY
				action_timer = 0.0

		GarethAction.BASH_TELEGRAPH:
			velocity.x = 0.0
			# Golden shield telegraph
			visual_root.modulate = Color(1.3, 1.2, 0.4)
			if action_timer >= 0.4:
				visual_root.modulate = Color.WHITE
				current_action = GarethAction.BASH_LUNGE
				action_timer = 0.0
				hitbox.damage = 1
				hitbox.monitoring = true
				velocity.x = facing_direction * 180.0

		GarethAction.BASH_LUNGE:
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)
			if action_timer >= 0.35:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = GarethAction.RECOVERY
				action_timer = 0.0

		GarethAction.BASTION_GUARD:
			velocity.x = 0.0
			if action_timer >= 1.2:
				current_action = GarethAction.IDLE
				action_timer = 0.0

		GarethAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if action_timer >= 0.5:
				current_action = GarethAction.IDLE
				action_timer = 0.0

	move_and_slide()
	queue_redraw()

func _choose_next_attack() -> void:
	action_timer = 0.0
	var dist = global_position.distance_to(player_ref.global_position) if player_ref else 100.0

	if dist < 50.0:
		# Alternate between Cleave and Bash
		if randf() > 0.5:
			current_action = GarethAction.CLEAVE_TELEGRAPH
			telegraph(0.45, Color(0.4, 0.8, 1.2))
		else:
			current_action = GarethAction.BASH_TELEGRAPH
			telegraph(0.4, Color(1.2, 1.1, 0.3))
	elif dist < 120.0:
		current_action = GarethAction.BASH_TELEGRAPH
		telegraph(0.4, Color(1.2, 1.1, 0.3))
	else:
		# Approach player
		var dir = 1 if player_ref and player_ref.global_position.x > global_position.x else -1
		set_facing(dir)
		velocity.x = dir * data.move_speed
		current_action = GarethAction.IDLE

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# In Bastion Guard, frontal attacks are deflected unless finisher
	var attack_from_front = false
	if attacker:
		var from_right = (attacker.global_position.x > global_position.x)
		attack_from_front = (facing_direction == 1 and from_right) or (facing_direction == -1 and not from_right)

	if current_action == GarethAction.BASTION_GUARD and attack_from_front and not is_finisher and not is_staggered:
		# Guard deflected hit
		flash_white(0.08)
		apply_hitstop(hitstop_frames)
		var spark = HIT_SPARK_SCENE.instantiate()
		spark.global_position = global_position + Vector2(facing_direction * 14.0, -18.0)
		spark.spark_color = Color(0.9, 0.9, 1.0)
		get_parent().add_child(spark)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _draw() -> void:
	# Crisp Procedural Pixel Art: Sir Gareth the Ironclad (Knight Boss)
	var col_steel = Color(0.65, 0.70, 0.75)   # Polished plate
	var col_gold = Color(0.92, 0.82, 0.30)    # Gold trim & lion crest
	var col_cape = Color(0.18, 0.28, 0.60)    # Cobalt blue royal cape

	# Flowing Cape (behind)
	var cape_pts = PackedVector2Array([
		Vector2(-6, -24),
		Vector2(-14, -4),
		Vector2(-4, -4)
	])
	draw_colored_polygon(cape_pts, col_cape)

	# Armored Legs & Sabatons
	draw_rect(Rect2(-8, -10, 6, 10), col_steel.darkened(0.2))
	draw_rect(Rect2(2, -10, 6, 10), col_steel.darkened(0.2))

	# Breastplate & Faulds
	draw_rect(Rect2(-9, -26, 18, 16), col_steel)
	draw_rect(Rect2(-6, -24, 12, 12), col_cape) # Tabard
	draw_line(Vector2(0, -24), Vector2(0, -12), col_gold, 2.0) # Gold stripe

	# Greathelm & Visor
	draw_rect(Rect2(-6, -35, 12, 9), col_steel)
	draw_rect(Rect2(-4, -31, 8, 2), Color(0.1, 0.1, 0.15)) # T-slit visor
	draw_line(Vector2(0, -35), Vector2(-2, -42), col_cape.lightened(0.2), 2.5) # Feathered plume

	# Tower Shield (front)
	if current_action == GarethAction.BASTION_GUARD or current_action == GarethAction.IDLE:
		var shield_pts = PackedVector2Array([
			Vector2(8, -30),
			Vector2(18, -30),
			Vector2(18, -10),
			Vector2(13, -2),
			Vector2(8, -10)
		])
		draw_colored_polygon(shield_pts, col_steel.darkened(0.1))
		draw_line(Vector2(13, -28), Vector2(13, -4), col_gold, 2.0)
	elif is_staggered:
		draw_rect(Rect2(-16, -14, 10, 14), col_steel.darkened(0.2))

	# Heavy Broadsword
	if current_action in [GarethAction.CLEAVE_TELEGRAPH, GarethAction.CLEAVE_SLASH]:
		draw_line(Vector2(4, -26), Vector2(12, -44), col_steel.lightened(0.3), 3.0)
		draw_line(Vector2(1, -28), Vector2(7, -24), col_gold, 2.0) # Crossguard
	else:
		draw_line(Vector2(-4, -20), Vector2(-12, -34), col_steel.lightened(0.2), 2.5)
