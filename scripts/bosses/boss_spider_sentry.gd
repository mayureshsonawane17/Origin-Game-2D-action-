class_name BossSpiderSentry
extends BossController

## Industrial Era Regular Boss: Clockwork Spider Sentry (IND-02).
## Multi-legged steam-powered arachnid inquisitor equipped with steam vents and cable snares.
## Weakness: Magic / Electricity (overheats boiler, bypasses armor, deals 2x damage and staggers).

const STEAM_VENT_SCENE = preload("res://scenes/bosses/steam_vent_hazard.tscn")
const CABLE_TRAP_SCENE = preload("res://scenes/bosses/cable_trap.tscn")

enum SpiderAction {
	IDLE_SCUTTLE,
	PISTON_TELEGRAPH,
	PISTON_STRIKE,
	STEAM_TELEGRAPH,
	STEAM_VENT,
	CABLE_TELEGRAPH,
	CABLE_TOSS,
	RECOVERY
}

var current_action: SpiderAction = SpiderAction.IDLE_SCUTTLE
var action_timer: float = 0.0
var walk_anim_time: float = 0.0

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/spider_sentry.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 140.0
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
	if player_ref and current_action in [SpiderAction.IDLE_SCUTTLE, SpiderAction.PISTON_TELEGRAPH, SpiderAction.STEAM_TELEGRAPH, SpiderAction.CABLE_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		SpiderAction.IDLE_SCUTTLE:
			walk_anim_time += delta * 12.0
			if player_ref:
				var dist = absf(player_ref.global_position.x - global_position.x)
				if dist > 90.0:
					velocity.x = facing_direction * data.move_speed
				elif dist < 50.0:
					velocity.x = -facing_direction * (data.move_speed * 0.7)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

			if action_timer >= 1.2:
				_choose_next_action()

		SpiderAction.PISTON_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.40:
				current_action = SpiderAction.PISTON_STRIKE
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 150.0
				if SoundManager:
					SoundManager.play_sfx("slash_1", 1.2)

		SpiderAction.PISTON_STRIKE:
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)
			if action_timer >= 0.28:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = SpiderAction.RECOVERY
				action_timer = 0.0

		SpiderAction.STEAM_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.45:
				current_action = SpiderAction.STEAM_VENT
				action_timer = 0.0
				_vent_steam()

		SpiderAction.STEAM_VENT:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = SpiderAction.RECOVERY
				action_timer = 0.0

		SpiderAction.CABLE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.40:
				current_action = SpiderAction.CABLE_TOSS
				action_timer = 0.0
				_launch_cable_trap()

		SpiderAction.CABLE_TOSS:
			velocity.x = 0.0
			if action_timer >= 0.30:
				current_action = SpiderAction.RECOVERY
				action_timer = 0.0

		SpiderAction.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if action_timer >= 0.60:
				current_action = SpiderAction.IDLE_SCUTTLE
				action_timer = 0.0

	move_and_slide()
	queue_redraw()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = SpiderAction.IDLE_SCUTTLE
		return

	var dist = absf(player_ref.global_position.x - global_position.x)
	var roll = randf()

	if dist < 65.0:
		if roll < 0.55:
			current_action = SpiderAction.PISTON_TELEGRAPH
		else:
			current_action = SpiderAction.STEAM_TELEGRAPH
	elif dist < 160.0:
		if roll < 0.45:
			current_action = SpiderAction.PISTON_TELEGRAPH
		elif roll < 0.75:
			current_action = SpiderAction.CABLE_TELEGRAPH
		else:
			current_action = SpiderAction.STEAM_TELEGRAPH
	else:
		if roll < 0.65:
			current_action = SpiderAction.CABLE_TELEGRAPH
		else:
			current_action = SpiderAction.IDLE_SCUTTLE

func _vent_steam() -> void:
	var vent = STEAM_VENT_SCENE.instantiate() as Node2D
	get_parent().add_child(vent)
	vent.global_position = global_position + Vector2(facing_direction * 16, -6)
	if SoundManager:
		SoundManager.play_sfx("whoosh", 1.4)

func _launch_cable_trap() -> void:
	var trap = CABLE_TRAP_SCENE.instantiate() as Node2D
	get_parent().add_child(trap)
	trap.global_position = global_position + Vector2(facing_direction * 12, -14)

	var target_x = player_ref.global_position.x if player_ref else (global_position.x + facing_direction * 140.0)
	var x_dist = target_x - trap.global_position.x
	var vx = clampf(x_dist * 1.8, -260.0, 260.0)
	trap.set("velocity", Vector2(vx, -180.0))
	if SoundManager:
		SoundManager.play_sfx("switch_weapon", 1.3)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	var is_magic = (attacker != null and attacker.is_in_group("magic_projectiles")) or (attacker != null and attacker.name.contains("Magic"))

	if is_magic:
		# Magic/Electricity instantly bypasses & overloads brass boiler armor
		current_armor = 0
		boss_armor_changed.emit(current_armor, data.armor_health if data else 4)
		var incoming_dmg = dmg * 2 # 2x damage weakness
		super._on_hurtbox_hit_received(incoming_dmg, knockback, hitstop_frames, attacker, is_finisher)
		if not is_dead:
			stagger(1.8)
		if SoundManager:
			SoundManager.play_sfx("parry")
		return

	# Normal hits strike armor first if intact
	if current_armor > 0:
		current_armor = maxi(0, current_armor - dmg)
		boss_armor_changed.emit(current_armor, data.armor_health if data else 4)
		if SoundManager:
			SoundManager.play_sfx("block")
		flash_white(0.08)
		if current_armor == 0 and not is_dead:
			stagger(1.2)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_brass = Color.WHITE if is_flashing else Color(0.85, 0.58, 0.22)
	var col_dark_iron = Color.WHITE if is_flashing else Color(0.28, 0.26, 0.28)
	var col_rivet = Color(0.95, 0.85, 0.5)
	var col_eye = Color(1.0, 0.2, 0.1) if current_action == SpiderAction.PISTON_TELEGRAPH else Color(0.2, 0.9, 1.0)
	var f = float(facing_direction)

	# 8 Mechanical Spider Legs (4 pairs)
	var leg_anim = sin(walk_anim_time) if current_action == SpiderAction.IDLE_SCUTTLE else 0.0
	var leg_offsets = [-18.0, -8.0, 6.0, 16.0]

	for i in range(leg_offsets.size()):
		var base_x = leg_offsets[i]
		var phase = leg_anim * (1.0 if i % 2 == 0 else -1.0) * 4.0
		var knee_x = base_x + (f * 6.0)
		var knee_y = -22.0 + phase
		var foot_x = base_x * 1.5 + (f * 10.0)
		var foot_y = 0.0

		# Upper leg segment
		draw_line(Vector2(base_x, -10), Vector2(knee_x, knee_y), col_brass, 2.5)
		# Lower leg piston
		draw_line(Vector2(knee_x, knee_y), Vector2(foot_x, foot_y), col_dark_iron, 2.0)
		# Joint bolt
		draw_circle(Vector2(knee_x, knee_y), 2.0, col_rivet)

	# Main Boiler Body
	draw_rect(Rect2(-16, -20, 32, 16), col_brass)
	draw_rect(Rect2(-12, -17, 24, 10), col_dark_iron)

	# Twin Exhaust Smokestacks
	draw_rect(Rect2(-12, -26, 6, 8), col_dark_iron)
	draw_rect(Rect2(6, -26, 6, 8), col_dark_iron)
	# Steam wisps
	if current_action in [SpiderAction.STEAM_TELEGRAPH, SpiderAction.STEAM_VENT]:
		draw_circle(Vector2(-9, -29), 3.5, Color(1, 1, 1, 0.7))
		draw_circle(Vector2(9, -29), 3.5, Color(1, 1, 1, 0.7))

	# Central Monocle Sensor Lens
	draw_circle(Vector2(f * 8, -12), 4.0, Color.BLACK)
	draw_circle(Vector2(f * 8, -12), 2.5, col_eye)

	# Pressure Gauge
	draw_circle(Vector2(-f * 6, -12), 3.0, Color(0.9, 0.9, 0.9))
	draw_line(Vector2(-f * 6, -12), Vector2(-f * 6 + 1.5, -14), Color.RED, 1.0)

	# Front Piston Blades
	if current_action == SpiderAction.PISTON_STRIKE:
		draw_line(Vector2(f * 14, -12), Vector2(f * 32, -10), col_brass, 3.0)
		draw_line(Vector2(f * 14, -6), Vector2(f * 30, -4), col_brass, 3.0)
