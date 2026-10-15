class_name PlayerDodgeState
extends PlayerState

## Dodge state providing burst movement and invulnerability frames.

var dodge_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("dodge")
	player.dodge_cooldown_timer = player.tuning.dodge_cooldown
	player.hurtbox.is_invulnerable = true
	dodge_timer = 0.0
	
	# Horizontal burst
	var move_input = Input.get_axis("move_left", "move_right")
	if abs(move_input) > 0.1:
		player.set_facing(1 if move_input > 0 else -1)
	player.velocity.x = player.facing_direction * player.tuning.dodge_speed
	player.velocity.y = 0.0

	# Translucent dodge visual
	player.visual_root.modulate.a = 0.55

func exit() -> void:
	player.hurtbox.is_invulnerable = false
	player.visual_root.modulate.a = 1.0

func physics_update(delta: float) -> void:
	dodge_timer += delta

	# End i-frames slightly before dodge movement ends
	if dodge_timer >= player.tuning.dodge_invuln_duration:
		player.hurtbox.is_invulnerable = false

	# Decelerate slightly
	player.velocity.x = move_toward(player.velocity.x, 0.0, 150.0 * delta)
	player.move_and_slide()

	if dodge_timer >= player.tuning.dodge_duration:
		if player.is_on_floor():
			var inp = Input.get_axis("move_left", "move_right")
			if abs(inp) > 0.1:
				machine.transition_to("run")
			else:
				machine.transition_to("idle")
		else:
			machine.transition_to("fall")
