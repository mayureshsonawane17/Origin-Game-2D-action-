class_name BossSWATJuggernaut
extends BossController

## Modern Era Regular Boss: SWAT Juggernaut Apex (MOD-02).
## Heavily armored urban demolisher wielding a ballistic riot shield, shock baton, and stun grenades.
## Weakness: Flank Dash (attacks from behind bypass shield) and Magic (pierces visor for 2x damage & stagger).

const STUN_GRENADE_SCENE = preload("res://scenes/bosses/stun_grenade.tscn")

enum JuggernautAction {
	IDLE_STANCE,
	SHIELD_CHARGE_TELEGRAPH,
	SHIELD_CHARGE,
	BATON_TELEGRAPH,
	BATON_SMASH,
	GRENADE_TELEGRAPH,
	GRENADE_TOSS,
	RECOVERY
}

var current_action: JuggernautAction = JuggernautAction.IDLE_STANCE
var action_timer: float = 0.0
var walk_anim_time: float = 0.0
var shield_active: bool = true

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/swat_juggernaut.tres") as BossData
	super._ready()
	hitbox.damage = 2
	hitbox.knockback_force = 180.0
	hitbox.hitstop_frames = 5

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

	# Track player facing when not actively locked into charge or smash
	if player_ref and current_action in [JuggernautAction.IDLE_STANCE, JuggernautAction.SHIELD_CHARGE_TELEGRAPH, JuggernautAction.BATON_TELEGRAPH, JuggernautAction.GRENADE_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		JuggernautAction.IDLE_STANCE:
			shield_active = true
			walk_anim_time += delta * 5.0
			if player_ref:
				var dist = absf(player_ref.global_position.x - global_position.x)
				if dist > 75.0:
					velocity.x = facing_direction * data.move_speed
				elif dist < 40.0:
					velocity.x = -facing_direction * (data.move_speed * 0.6)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

			if action_timer >= 1.1:
				_choose_next_action()

		JuggernautAction.SHIELD_CHARGE_TELEGRAPH:
			velocity.x = 0.0
			shield_active = true
			if action_timer >= 0.50:
				current_action = JuggernautAction.SHIELD_CHARGE
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 220.0
				if SoundManager:
					SoundManager.play_sfx("slash_finisher", 0.9)

		JuggernautAction.SHIELD_CHARGE:
			shield_active = true
			velocity.x = facing_direction * 220.0
			# Stop upon hitting wall or duration
			if is_on_wall() or action_timer >= 0.75:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = JuggernautAction.RECOVERY
				action_timer = 0.0
				velocity.x = 0.0
				if SoundManager:
					SoundManager.play_sfx("block", 0.9)

		JuggernautAction.BATON_TELEGRAPH:
			velocity.x = 0.0
			shield_active = false
			if action_timer >= 0.40:
				current_action = JuggernautAction.BATON_SMASH
				action_timer = 0.0
				hitbox.damage = 2
				hitbox.monitoring = true
				velocity.x = facing_direction * 120.0
				if SoundManager:
					SoundManager.play_sfx("slash_2", 1.1)

		JuggernautAction.BATON_SMASH:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if action_timer >= 0.30:
				hitbox.monitoring = false
				hitbox.reset_hits()
				current_action = JuggernautAction.RECOVERY
				action_timer = 0.0

		JuggernautAction.GRENADE_TELEGRAPH:
			velocity.x = 0.0
			shield_active = false
			if action_timer >= 0.45:
				current_action = JuggernautAction.GRENADE_TOSS
				action_timer = 0.0
				_toss_stun_grenade()

		JuggernautAction.GRENADE_TOSS:
			velocity.x = 0.0
			if action_timer >= 0.28:
				current_action = JuggernautAction.RECOVERY
				action_timer = 0.0

		JuggernautAction.RECOVERY:
			shield_active = true
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)
			if action_timer >= 0.55:
				current_action = JuggernautAction.IDLE_STANCE
				action_timer = 0.0

	move_and_slide()
	queue_redraw()

func _choose_next_action() -> void:
	action_timer = 0.0
	if not player_ref:
		current_action = JuggernautAction.IDLE_STANCE
		return

	var dist = absf(player_ref.global_position.x - global_position.x)
	var roll = randf()

	if dist < 65.0:
		if roll < 0.60:
			current_action = JuggernautAction.BATON_TELEGRAPH
		else:
			current_action = JuggernautAction.SHIELD_CHARGE_TELEGRAPH
	elif dist < 150.0:
		if roll < 0.45:
			current_action = JuggernautAction.SHIELD_CHARGE_TELEGRAPH
		elif roll < 0.80:
			current_action = JuggernautAction.GRENADE_TELEGRAPH
		else:
			current_action = JuggernautAction.BATON_TELEGRAPH
	else:
		if roll < 0.60:
			current_action = JuggernautAction.GRENADE_TELEGRAPH
		else:
			current_action = JuggernautAction.SHIELD_CHARGE_TELEGRAPH

func _toss_stun_grenade() -> void:
	var grenade = STUN_GRENADE_SCENE.instantiate() as Node2D
	get_parent().add_child(grenade)
	grenade.global_position = global_position + Vector2(facing_direction * 14, -26)

	var target_x = player_ref.global_position.x if player_ref else (global_position.x + facing_direction * 120.0)
	var x_dist = target_x - grenade.global_position.x
	var vx = clampf(x_dist * 1.6, -240.0, 240.0)
	grenade.set("velocity", Vector2(vx, -200.0))
	if SoundManager:
		SoundManager.play_sfx("switch_weapon", 1.2)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	var is_magic = (attacker != null and attacker.is_in_group("magic_projectiles")) or (attacker != null and attacker.name.contains("Magic"))

	# 1. Magic Weakness: Pierces visor and body armor, deals 2x damage, shatters armor, and staggers
	if is_magic:
		current_armor = 0
		boss_armor_changed.emit(0, data.armor_health if data else 6)
		var incoming_dmg = dmg * 2
		super._on_hurtbox_hit_received(incoming_dmg, knockback, hitstop_frames, attacker, is_finisher)
		if not is_dead:
			stagger(1.6)
		if SoundManager:
			SoundManager.play_sfx("parry")
		return

	# 2. Flank Dash Check: Attack landed from BEHIND
	var is_flank = false
	if attacker != null:
		var rel_x = attacker.global_position.x - global_position.x
		# If facing right (1) and attacker is to our left (< 0), it's a flank attack
		# If facing left (-1) and attacker is to our right (> 0), it's a flank attack
		if (facing_direction > 0 and rel_x < -5.0) or (facing_direction < 0 and rel_x > 5.0):
			is_flank = true

	if is_flank:
		# Unprotected from behind! Bypasses shield armor and deals 1.5x damage directly to health
		var saved_armor = current_armor
		current_armor = 0
		var flank_dmg = int(dmg * 1.5)
		super._on_hurtbox_hit_received(flank_dmg, knockback, hitstop_frames, attacker, is_finisher)
		current_armor = saved_armor
		if SoundManager:
			SoundManager.play_sfx("slash_finisher")
		return

	# 3. Frontal Attack during active shield: Shield absorbs hit into armor
	if shield_active and current_armor > 0:
		current_armor = maxi(0, current_armor - dmg)
		boss_armor_changed.emit(current_armor, data.armor_health if data else 6)
		flash_white(0.08)
		if SoundManager:
			SoundManager.play_sfx("block", 1.1)
		if current_armor == 0 and not is_dead:
			stagger(1.5)
		return

	super._on_hurtbox_hit_received(dmg, knockback, hitstop_frames, attacker, is_finisher)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_armor = Color.WHITE if is_flashing else Color(0.12, 0.15, 0.22) # Tactical navy
	var col_rig = Color.WHITE if is_flashing else Color(0.24, 0.28, 0.36)
	var col_visor = Color(0.1, 0.75, 1.0) # Electric blue HUD visor
	var col_shield = Color(0.2, 0.5, 0.7, 0.75) # Ballistic glass
	var col_rim = Color(0.4, 0.45, 0.52) # Titanium frame
	var f = float(facing_direction)

	var bob = sin(walk_anim_time) * 1.5 if current_action == JuggernautAction.IDLE_STANCE else 0.0

	# Heavy tactical combat boots
	draw_rect(Rect2(-12, -12, 10, 12), col_armor)
	draw_rect(Rect2(2, -12, 10, 12), col_armor)

	# Juggernaut Body (Kevlar Exo-Plating)
	draw_rect(Rect2(-16, -34 + bob, 32, 22), col_armor)
	draw_rect(Rect2(-13, -32 + bob, 26, 18), col_rig)

	# Tactical Helmet & Visor
	draw_rect(Rect2(-10 + f * 2, -45 + bob, 20, 13), col_armor)
	draw_rect(Rect2(-6 + f * 4, -41 + bob, 12, 5), col_visor)
	draw_line(Vector2(-5 + f * 4, -39 + bob), Vector2(5 + f * 4, -39 + bob), Color.WHITE, 1.0)

	# Shock Baton
	if current_action == JuggernautAction.BATON_TELEGRAPH:
		# Baton raised overhead
		draw_line(Vector2(-f * 8, -48), Vector2(-f * 4, -62), col_rim, 3.0)
		draw_circle(Vector2(-f * 4, -62), 3.0, col_visor)
	elif current_action == JuggernautAction.BATON_SMASH:
		# Baton smashed down
		draw_line(Vector2(f * 16, -26), Vector2(f * 32, -8), col_rim, 3.5)
		draw_circle(Vector2(f * 32, -8), 4.0, col_visor)
	else:
		# Baton held at side
		draw_line(Vector2(-f * 12, -26 + bob), Vector2(-f * 16, -12 + bob), col_rim, 2.5)

	# Ballistic Riot Shield (Held in front)
	if shield_active:
		var shield_x = f * 12
		var shield_w = 8.0
		var shield_h = 38.0
		# Frame
		draw_rect(Rect2(shield_x - 4, -38, shield_w, shield_h), col_rim)
		# Glass viewport
		draw_rect(Rect2(shield_x - 3, -34, shield_w - 2, shield_h - 8), col_shield)
		# SWAT stencil stripe
		draw_line(Vector2(shield_x, -24), Vector2(shield_x, -14), Color.WHITE, 1.5)
		# Shield flash mount
		draw_circle(Vector2(shield_x + f * 3, -35), 2.0, Color.WHITE)
