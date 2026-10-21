class_name BossOnryoMist
extends BossController

## Historical Regular Boss: Onryo of the Bamboo Mist (HIST-02).
## Vengeful Spirit utilizing mist phase teleportation, spectral clones, and talon dashes.
## Weaknesses: Magic attacks (instantly dispels clones, deals 1.5x dmg) & Perfect Parry stagger.

enum OnryoAction { IDLE_FLOAT, MIST_PHASE, TALON_TELEGRAPH, TALON_DASH, CLONE_SUMMON, RECOVERY }
var current_action: OnryoAction = OnryoAction.IDLE_FLOAT
var action_timer: float = 0.0
var float_time: float = 0.0
var active_clones: Array[Node2D] = []

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/onryo_mist.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 160.0
	hitbox.hitstop_frames = 4

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	float_time += delta * 3.5

	if is_staggered:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [OnryoAction.IDLE_FLOAT, OnryoAction.TALON_TELEGRAPH, OnryoAction.CLONE_SUMMON]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		OnryoAction.IDLE_FLOAT:
			velocity.y = sin(float_time) * 18.0
			if player_ref:
				var dist = absf(player_ref.global_position.x - global_position.x)
				if dist > 90.0:
					velocity.x = facing_direction * (data.move_speed * 0.7)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)

			if action_timer >= 0.85:
				_choose_next_action()

		OnryoAction.MIST_PHASE:
			velocity = Vector2.ZERO
			if action_timer >= 0.5:
				_teleport_behind_player()
				current_action = OnryoAction.TALON_TELEGRAPH
				action_timer = 0.0
				telegraph(0.40, Color(0.9, 0.2, 0.6))

		OnryoAction.TALON_TELEGRAPH:
			velocity = Vector2.ZERO
			if action_timer >= 0.40:
				current_action = OnryoAction.TALON_DASH
				action_timer = 0.0
				hitbox.monitoring = true
				velocity.x = facing_direction * 240.0
				if SoundManager:
					SoundManager.play_sfx("slash_1")

		OnryoAction.TALON_DASH:
			velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)
			if action_timer >= 0.35:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = OnryoAction.RECOVERY
				action_timer = 0.0

		OnryoAction.CLONE_SUMMON:
			velocity = Vector2.ZERO
			if action_timer >= 0.45:
				current_action = OnryoAction.RECOVERY
				action_timer = 0.0

		OnryoAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			velocity.y = sin(float_time) * 12.0
			if action_timer >= 0.6:
				current_action = OnryoAction.IDLE_FLOAT
				action_timer = 0.0

	move_and_slide()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = OnryoAction.IDLE_FLOAT
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var roll = randf()

	if dist > 120.0:
		if roll < 0.6:
			current_action = OnryoAction.MIST_PHASE
			_fade_out()
		else:
			_spawn_shadow_clones()
			current_action = OnryoAction.CLONE_SUMMON
	else:
		if roll < 0.45:
			current_action = OnryoAction.MIST_PHASE
			_fade_out()
		elif roll < 0.8:
			current_action = OnryoAction.TALON_TELEGRAPH
			telegraph(0.40, Color(0.9, 0.2, 0.6))
		else:
			_spawn_shadow_clones()
			current_action = OnryoAction.CLONE_SUMMON

func _fade_out() -> void:
	hurtbox.is_invulnerable = true
	var tween = create_tween()
	tween.tween_property(visual_root, "modulate:a", 0.0, 0.3)
	if SoundManager:
		SoundManager.play_sfx("dodge")

func _teleport_behind_player() -> void:
	if player_ref:
		var target_x = player_ref.global_position.x - (player_ref.facing_direction * 60.0)
		global_position.x = clampf(target_x, 50.0, 590.0)
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	visual_root.modulate.a = 1.0
	hurtbox.is_invulnerable = false
	flash_white(0.15)

func _spawn_shadow_clones() -> void:
	_clear_clones()

	# Spawn left illusion
	var parent_node = get_parent() if get_parent() else self
	var left_clone = OnryoShadowClone.new(Vector2(global_position.x - 70.0, global_position.y), 1)
	parent_node.add_child(left_clone)
	active_clones.append(left_clone)

	# Spawn right illusion
	var right_clone = OnryoShadowClone.new(Vector2(global_position.x + 70.0, global_position.y), -1)
	parent_node.add_child(right_clone)
	active_clones.append(right_clone)

func _clear_clones() -> void:
	for clone in active_clones:
		if is_instance_valid(clone):
			clone.dispel()
	active_clones.clear()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# Magic Weakness: dispels all clones and deals 1.5x damage!
	var is_magic = (attacker is MagicProjectile) or (attacker != null and (attacker.get_script() == preload("res://scripts/combat/magic_projectile.gd") or attacker.name.to_lower().contains("magic")))
	if is_magic:
		_clear_clones()
		stagger(1.4)
		if SoundManager:
			SoundManager.play_sfx("parry")
		super._on_hurtbox_hit_received(int(round(dmg * 1.5)), knockback, hitstop_frames, attacker, is_finisher)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _die() -> void:
	_clear_clones()
	super._die()

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_robe = Color.WHITE if is_flashing else Color(0.92, 0.94, 0.98, 0.88)
	var col_hair = Color.WHITE if is_flashing else Color(0.08, 0.06, 0.12)
	var col_ribbon = Color(0.95, 0.15, 0.35) # Glowing Crimson Silk Ribbon
	var col_skin = Color.WHITE if is_flashing else Color(0.88, 0.86, 0.92)
	var col_eye = Color(0.9, 0.1, 0.25)
	var col_wisp = Color(0.3, 0.8, 1.0, 0.5)

	var f = float(facing_direction)
	var bob = sin(float_time) * 3.0

	# Flowing ethereal kimono robes
	var robe_pts = PackedVector2Array([
		Vector2(-8, -26 + bob),
		Vector2(8, -26 + bob),
		Vector2(14, -4 + bob),
		Vector2(4, 2 + bob),
		Vector2(-4, -2 + bob),
		Vector2(-14, -4 + bob)
	])
	draw_colored_polygon(robe_pts, col_robe)

	# Long flowing black hair
	draw_rect(Rect2(-7, -40 + bob, 14, 20), col_hair)
	draw_line(Vector2(-f * 4, -36 + bob), Vector2(-f * 14, -18 + bob), col_hair, 4.0)

	# Glowing Crimson Hair Ribbon
	draw_circle(Vector2(-f * 4, -37 + bob), 3.0, col_ribbon)
	draw_line(Vector2(-f * 4, -37 + bob), Vector2(-f * 10, -32 + bob), col_ribbon, 2.0)

	# Spectral Pale Head
	draw_circle(Vector2(f * 2, -36 + bob), 6.5, col_skin)
	# Glowing red eyes
	draw_circle(Vector2(f * 4 - 1, -36 + bob), 1.5, col_eye)
	draw_circle(Vector2(f * 4 + 3, -36 + bob), 1.5, col_eye)

	# Ghostly Hands / Talons
	if current_action == OnryoAction.TALON_DASH:
		# Extended spectral slash claws
		draw_line(Vector2(f * 8, -22 + bob), Vector2(f * 24, -22 + bob), col_ribbon, 3.0)
		draw_line(Vector2(f * 8, -18 + bob), Vector2(f * 22, -14 + bob), col_ribbon, 2.0)
	else:
		draw_line(Vector2(f * 4, -20 + bob), Vector2(f * 10, -14 + bob), col_skin, 2.0)

	# Ambient spirit wisps
	var w1 = sin(float_time * 2.0) * 16.0
	var w2 = cos(float_time * 2.5) * 14.0
	draw_circle(Vector2(w1, -28 + w2 * 0.5), 2.0, col_wisp)

## Inner class for illusory shadow clone
class OnryoShadowClone extends Area2D:
	var dir: int = 1
	var timer: float = 0.0

	func _init(pos: Vector2, initial_dir: int) -> void:
		global_position = pos
		dir = initial_dir
		collision_layer = 4
		collision_mask = 32 # Player attack hurtbox
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 36)
		shape.shape = rect
		shape.position.y = -18
		add_child(shape)

	func _ready() -> void:
		area_entered.connect(_on_hit)

	func _process(delta: float) -> void:
		timer += delta
		global_position.x += dir * 80.0 * delta
		if timer >= 2.5:
			dispel()
		queue_redraw()

	func _on_hit(_area: Area2D) -> void:
		dispel()

	func dispel() -> void:
		queue_free()

	func _draw() -> void:
		# Semi-transparent shadow silhouette (without the crimson ribbon)
		var col_shadow = Color(0.2, 0.15, 0.35, 0.45)
		draw_rect(Rect2(-8, -36, 16, 36), col_shadow)
		draw_circle(Vector2(0, -36), 6.0, col_shadow)
