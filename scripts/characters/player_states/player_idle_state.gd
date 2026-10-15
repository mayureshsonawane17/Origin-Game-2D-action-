class_name PlayerIdleState
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("idle")
	player.velocity.x = 0.0

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		machine.transition_to("fall")
		return

	# Transitions
	if Input.is_action_just_pressed("attack"):
		machine.transition_to("attack", {"combo_index": 1})
		return
	if Input.is_action_pressed("block"):
		machine.transition_to("block")
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

	var move_input = Input.get_axis("move_left", "move_right")
	if abs(move_input) > 0.1:
		machine.transition_to("run")
