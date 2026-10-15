class_name PlayerRunState
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("run")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	var move_input = Input.get_axis("move_left", "move_right")
	if abs(move_input) > 0.1:
		var dir = 1 if move_input > 0 else -1
		player.set_facing(dir)
		player.velocity.x = move_input * player.tuning.run_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.tuning.run_speed * 10.0 * delta)
		if is_zero_approx(player.velocity.x):
			machine.transition_to("idle")
			return

	player.move_and_slide()

	if not player.is_on_floor():
		machine.transition_to("fall")
		return

	if Input.is_action_just_pressed("attack"):
		machine.transition_to("attack", {"combo_index": 1})
		return
	if Input.is_action_just_pressed("dodge") and player.can_dodge():
		machine.transition_to("dodge")
		return
	if Input.is_action_just_pressed("magic") and player.can_cast_magic():
		machine.transition_to("cast")
		return
	if Input.is_action_just_pressed("heal") and player.can_heal():
		player.perform_heal()
		return
	if player.jump_buffer_timer > 0.0:
		machine.transition_to("jump")
		return
