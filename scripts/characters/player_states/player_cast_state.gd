class_name PlayerCastState
extends PlayerState

## Magic casting state: fires MagicProjectile with brief recovery.

var cast_timer: float = 0.0
var cast_duration: float = 0.22
var has_fired: bool = false

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("cast")
	cast_timer = 0.0
	has_fired = false
	player.velocity.x = 0.0

func physics_update(delta: float) -> void:
	cast_timer += delta

	# Apply gravity if cast in air
	player.apply_gravity(delta)
	player.move_and_slide()

	if cast_timer >= 0.06 and not has_fired:
		has_fired = true
		player.cast_magic()

	if cast_timer >= cast_duration:
		if player.is_on_floor():
			var inp = Input.get_axis("move_left", "move_right")
			if abs(inp) > 0.1:
				machine.transition_to("run")
			else:
				machine.transition_to("idle")
		else:
			machine.transition_to("fall")
