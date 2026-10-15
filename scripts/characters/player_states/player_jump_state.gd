class_name PlayerJumpState
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("jump")
	player.velocity.y = player.tuning.jump_velocity
	player.jump_buffer_timer = 0.0
	player.coyote_timer = 0.0

func physics_update(delta: float) -> void:
	# Variable jump height
	if Input.is_action_just_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.tuning.jump_cut_multiplier

	player.apply_gravity(delta)

	var move_input = Input.get_axis("move_left", "move_right")
	if abs(move_input) > 0.1:
		var dir = 1 if move_input > 0 else -1
		player.set_facing(dir)
		player.velocity.x = move_input * player.tuning.run_speed * player.get_mobility_multiplier()
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.tuning.run_speed * 4.0 * delta)

	player.move_and_slide()

	if Input.is_action_just_pressed("attack"):
		machine.transition_to("attack", {"combo_index": 1, "in_air": true})
		return
	if Input.is_action_just_pressed("dodge") and player.can_dodge():
		machine.transition_to("dodge")
		return
	if Input.is_action_just_pressed("magic") and player.can_cast_magic():
		machine.transition_to("cast")
		return

	if player.velocity.y >= 0.0:
		machine.transition_to("fall")
