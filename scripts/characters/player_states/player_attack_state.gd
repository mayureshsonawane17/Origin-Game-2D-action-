class_name PlayerAttackState
extends PlayerState

## Dan-the-Man style 3-hit combo attack state.
## Frame data (startup, active, recovery) is driven by CombatTuning.

var combo_index: int = 1
var in_air: bool = false
var phase_timer: float = 0.0

enum AttackPhase { STARTUP, ACTIVE, RECOVERY }
var current_phase: AttackPhase = AttackPhase.STARTUP
var buffered_next_attack: bool = false

func enter(msg: Dictionary = {}) -> void:
	combo_index = msg.get("combo_index", 1)
	in_air = msg.get("in_air", false)
	buffered_next_attack = false
	current_phase = AttackPhase.STARTUP
	phase_timer = 0.0

	# Setup hitbox parameters from tuning
	var startup: float = 0.05
	var dmg: int = 1
	var knockback: float = 80.0
	var hitstop: int = 3
	var is_finisher: bool = false

	match combo_index:
		1:
			player.animation_player.play("attack1")
			startup = player.tuning.attack1_startup
			dmg = player.tuning.attack1_damage
			knockback = player.tuning.attack1_knockback
			hitstop = player.tuning.attack1_hitstop_frames
		2:
			player.animation_player.play("attack2")
			startup = player.tuning.attack2_startup
			dmg = player.tuning.attack2_damage
			knockback = player.tuning.attack2_knockback
			hitstop = player.tuning.attack2_hitstop_frames
		3:
			player.animation_player.play("attack3")
			startup = player.tuning.attack3_startup
			dmg = player.tuning.attack3_damage
			knockback = player.tuning.attack3_knockback
			hitstop = player.tuning.attack3_hitstop_frames
			is_finisher = true

	player.hitbox.damage = dmg
	player.hitbox.knockback_force = knockback
	player.hitbox.hitstop_frames = hitstop
	player.hitbox.is_finisher = is_finisher
	player.hitbox.reset_hits()
	player.hitbox.monitoring = false

	# Slight forward step for arcade melee feel
	if not in_air:
		player.velocity.x = player.facing_direction * (35.0 if not is_finisher else 60.0)

func exit() -> void:
	player.hitbox.monitoring = false
	player.hitbox.reset_hits()

func physics_update(delta: float) -> void:
	phase_timer += delta

	# Apply gravity if in air
	if in_air:
		player.apply_gravity(delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 300.0 * delta)

	player.move_and_slide()

	# Buffer next attack if pressed
	if Input.is_action_just_pressed("attack") and combo_index < 3:
		buffered_next_attack = true

	# Phase progression
	match current_phase:
		AttackPhase.STARTUP:
			var startup_duration = _get_startup_duration()
			if phase_timer >= startup_duration:
				current_phase = AttackPhase.ACTIVE
				phase_timer = 0.0
				player.hitbox.monitoring = true

		AttackPhase.ACTIVE:
			var active_duration = _get_active_duration()
			if phase_timer >= active_duration:
				current_phase = AttackPhase.RECOVERY
				phase_timer = 0.0
				player.hitbox.monitoring = false

		AttackPhase.RECOVERY:
			# Can cancel into dodge or jump after active window!
			if Input.is_action_just_pressed("dodge") and player.can_dodge():
				machine.transition_to("dodge")
				return
			if Input.is_action_just_pressed("jump") and player.is_on_floor():
				machine.transition_to("jump")
				return

			var recovery_duration = _get_recovery_duration()
			if phase_timer >= recovery_duration:
				if buffered_next_attack and combo_index < 3 and not in_air:
					machine.transition_to("attack", {"combo_index": combo_index + 1})
					return
				else:
					if player.is_on_floor():
						var inp = Input.get_axis("move_left", "move_right")
						if abs(inp) > 0.1:
							machine.transition_to("run")
						else:
							machine.transition_to("idle")
					else:
						machine.transition_to("fall")

func _get_startup_duration() -> float:
	match combo_index:
		1: return player.tuning.attack1_startup
		2: return player.tuning.attack2_startup
		3: return player.tuning.attack3_startup
	return 0.05

func _get_active_duration() -> float:
	match combo_index:
		1: return player.tuning.attack1_active
		2: return player.tuning.attack2_active
		3: return player.tuning.attack3_active
	return 0.12

func _get_recovery_duration() -> float:
	match combo_index:
		1: return player.tuning.attack1_recovery
		2: return player.tuning.attack2_recovery
		3: return player.tuning.attack3_recovery
	return 0.12
