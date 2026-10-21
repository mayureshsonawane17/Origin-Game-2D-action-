class_name BossSentinelSwarm
extends BossController

## Futuristic Era Regular Boss: Sentinel Swarm-Mind (FUT-02).
## Sub-orbital drone hive nexus with orbiting support drones, homing plasma, and EMP web.
## Weakness: Magic / Piercing (collapses shield matrix, deals 2x damage and disables swarm).

const PLASMA_ORB_SCENE = preload("res://scenes/bosses/plasma_orb.tscn")

enum SwarmAction {
	HOVER_ORBIT,
	PLASMA_TELEGRAPH,
	PLASMA_FIRE,
	EMP_TELEGRAPH,
	EMP_BURST,
	DIVE_TELEGRAPH,
	SWARM_DIVE,
	RECOVERY
}

var current_action: SwarmAction = SwarmAction.HOVER_ORBIT
var action_timer: float = 0.0
var flight_time: float = 0.0
var orbit_angle: float = 0.0
var base_hover_y: float = 0.0
var dive_target_pos: Vector2 = Vector2.ZERO

# Sub-drone offsets relative to core
var drone_a_pos: Vector2 = Vector2.ZERO
var drone_b_pos: Vector2 = Vector2.ZERO
var emp_active: bool = false

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/sentinel_swarm.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 160.0
	hitbox.hitstop_frames = 4
	base_hover_y = global_position.y - 20.0

func _physics_process(delta: float) -> void:
	# Note: BossSentinelSwarm levitates, so we don't apply ground gravity in standard state
	if is_dead:
		return

	flight_time += delta
	orbit_angle += delta * (8.0 if current_action == SwarmAction.PLASMA_TELEGRAPH else 3.0)

	# Update orbiting sub-drone positions
	var orbit_radius = 28.0
	drone_a_pos = Vector2(cos(orbit_angle), sin(orbit_angle) * 0.6) * orbit_radius
	drone_b_pos = Vector2(cos(orbit_angle + PI), sin(orbit_angle + PI) * 0.6) * orbit_radius

	if is_staggered:
		# Falls toward floor during stagger
		velocity.y += 600.0 * delta
		move_and_slide()
		queue_redraw()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [SwarmAction.HOVER_ORBIT, SwarmAction.PLASMA_TELEGRAPH, SwarmAction.EMP_TELEGRAPH, SwarmAction.DIVE_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		SwarmAction.HOVER_ORBIT:
			emp_active = false
			# Smooth floating hover
			var target_y = base_hover_y + sin(flight_time * 2.5) * 12.0
			velocity.y = move_toward(velocity.y, (target_y - global_position.y) * 4.0, 300.0 * delta)

			if player_ref:
				var dist = absf(player_ref.global_position.x - global_position.x)
				if dist > 100.0:
					velocity.x = facing_direction * data.move_speed
				elif dist < 50.0:
					velocity.x = -facing_direction * (data.move_speed * 0.7)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

			if action_timer >= 1.2:
				_choose_next_action()

		SwarmAction.PLASMA_TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if action_timer >= 0.45:
				current_action = SwarmAction.PLASMA_FIRE
				action_timer = 0.0
				_fire_plasma_salvo()

		SwarmAction.PLASMA_FIRE:
			velocity = Vector2.ZERO
			if action_timer >= 0.35:
				current_action = SwarmAction.RECOVERY
				action_timer = 0.0

		SwarmAction.EMP_TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if action_timer >= 0.40:
				current_action = SwarmAction.EMP_BURST
				action_timer = 0.0
				emp_active = true
				hitbox.damage = 1
				hitbox.monitoring = true
				if SoundManager:
					SoundManager.play_sfx("magic_laser", 1.2)

		SwarmAction.EMP_BURST:
			velocity = Vector2.ZERO
			emp_active = true
			if action_timer >= 1.0:
				emp_active = false
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = SwarmAction.RECOVERY
				action_timer = 0.0

		SwarmAction.DIVE_TELEGRAPH:
			velocity = Vector2.ZERO
			if action_timer >= 0.45:
				current_action = SwarmAction.SWARM_DIVE
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				var target_x = player_ref.global_position.x if player_ref else (global_position.x + facing_direction * 120.0)
				var target_dir = Vector2(facing_direction, 0.7).normalized()
				velocity = target_dir * 240.0
				if SoundManager:
					SoundManager.play_sfx("slash_finisher", 1.3)

		SwarmAction.SWARM_DIVE:
			# Swooping arc
			if global_position.y >= base_hover_y + 25.0:
				velocity.y = -160.0 # Pull back up
			if action_timer >= 0.65:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = SwarmAction.RECOVERY
				action_timer = 0.0

		SwarmAction.RECOVERY:
			emp_active = false
			var target_y = base_hover_y
			velocity.y = move_toward(velocity.y, (target_y - global_position.y) * 4.0, 350.0 * delta)
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.60:
				current_action = SwarmAction.HOVER_ORBIT
				action_timer = 0.0

	move_and_slide()
	queue_redraw()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = SwarmAction.HOVER_ORBIT
		return

	var dist = absf(player_ref.global_position.x - global_position.x)
	var roll = randf()

	if dist < 70.0:
		if roll < 0.55:
			current_action = SwarmAction.EMP_TELEGRAPH
		else:
			current_action = SwarmAction.DIVE_TELEGRAPH
	elif dist < 160.0:
		if roll < 0.50:
			current_action = SwarmAction.PLASMA_TELEGRAPH
		elif roll < 0.75:
			current_action = SwarmAction.DIVE_TELEGRAPH
		else:
			current_action = SwarmAction.EMP_TELEGRAPH
	else:
		if roll < 0.65:
			current_action = SwarmAction.PLASMA_TELEGRAPH
		else:
			current_action = SwarmAction.HOVER_ORBIT

func _fire_plasma_salvo() -> void:
	# Launch 2 seeking orbs (from drone A and drone B)
	var spawn_points = [global_position + drone_a_pos, global_position + drone_b_pos]
	for sp in spawn_points:
		var orb = PLASMA_ORB_SCENE.instantiate() as Node2D
		get_parent().add_child(orb)
		orb.global_position = sp
		orb.set("target", player_ref)
		var launch_dir = (sp - global_position).normalized()
		orb.set("velocity", launch_dir * 140.0)

	if SoundManager:
		SoundManager.play_sfx("magic_cast", 1.2)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	var is_magic = (attacker != null and attacker.is_in_group("magic_projectiles")) or (attacker != null and attacker.name.contains("Magic"))

	if is_magic:
		# Magic shatters the energy matrix, deals 2x damage, drops armor, and causes overload stagger
		current_armor = 0
		boss_armor_changed.emit(current_armor, data.armor_health if data else 4)
		var incoming_dmg = dmg * 2
		super._on_hurtbox_hit_received(incoming_dmg, knockback, hitstop_frames, attacker, is_finisher)
		if not is_dead:
			stagger(1.8)
		if SoundManager:
			SoundManager.play_sfx("parry")
		return

	# Standard hits reduce armor matrix first
	if current_armor > 0:
		current_armor = maxi(0, current_armor - dmg)
		boss_armor_changed.emit(current_armor, data.armor_health if data else 4)
		flash_white(0.08)
		if SoundManager:
			SoundManager.play_sfx("block")
		if current_armor == 0 and not is_dead:
			stagger(1.2)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_hull = Color.WHITE if is_flashing else Color(0.18, 0.22, 0.28) # Futuristic composite
	var col_glow = Color(0.1, 0.9, 0.8) # Neon cyan ion glow
	var col_shield = Color(0.1, 0.8, 1.0, 0.3)
	var col_core = Color(0.9, 0.2, 0.7) if current_action == SwarmAction.EMP_BURST else Color(0.15, 0.95, 0.85)

	# EMP Web Laser Beams between Core and Drones
	if emp_active or current_action == SwarmAction.EMP_TELEGRAPH:
		var beam_col = Color(0.2, 0.9, 1.0, 0.85 if emp_active else 0.4)
		var beam_width = 3.0 if emp_active else 1.5
		draw_line(Vector2.ZERO, drone_a_pos, beam_col, beam_width)
		draw_line(Vector2.ZERO, drone_b_pos, beam_col, beam_width)
		draw_line(drone_a_pos, drone_b_pos, beam_col, beam_width)

	# Central Hive Core (Floating Octahedron)
	var core_points = PackedVector2Array([
		Vector2(0, -18),
		Vector2(14, -4),
		Vector2(0, 10),
		Vector2(-14, -4)
	])
	draw_colored_polygon(core_points, col_hull)
	draw_polyline(core_points, col_glow, 1.5)

	# Inner Central Energy Eye
	draw_circle(Vector2(0, -4), 5.0, col_core)
	draw_circle(Vector2(0, -4), 2.5, Color.WHITE)

	# Thruster Glow
	draw_circle(Vector2(0, 11), 3.0, col_glow)

	# Orbiting Sentinel Sub-Drones
	_draw_drone(drone_a_pos, col_hull, col_glow)
	_draw_drone(drone_b_pos, col_hull, col_glow)

	# Shield Ring if Armor is intact
	if current_armor > 0:
		var ring_pulse = sin(flight_time * 6.0) * 2.0
		draw_arc(Vector2(0, -4), 22.0 + ring_pulse, 0, TAU, 16, col_shield, 2.0)

func _draw_drone(pos: Vector2, hull_col: Color, glow_col: Color) -> void:
	var drone_pts = PackedVector2Array([
		pos + Vector2(0, -7),
		pos + Vector2(7, 3),
		pos + Vector2(0, 1),
		pos + Vector2(-7, 3)
	])
	draw_colored_polygon(drone_pts, hull_col)
	draw_polyline(drone_pts, glow_col, 1.0)
	draw_circle(pos + Vector2(0, -2), 2.0, glow_col)
