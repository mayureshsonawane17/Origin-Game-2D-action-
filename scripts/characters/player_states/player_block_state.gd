class_name PlayerBlockState
extends PlayerState

## Block & Timed Parry state.
## Holding block reduces damage; timing block within the parry window negates damage and counters.

var parry_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	player.is_blocking = true
	player.is_parrying = true
	parry_timer = player.tuning.parry_window
	player.velocity.x = 0.0
	player.animation_player.play("idle")
	# Guard visual tint (deep azure/golden during parry window)
	player.visual_root.modulate = Color(1.2, 1.1, 0.5, 1.0)

func exit() -> void:
	player.is_blocking = false
	player.is_parrying = false
	player.visual_root.modulate = Color.WHITE

func physics_update(delta: float) -> void:
	if parry_timer > 0.0:
		parry_timer -= delta
		if parry_timer <= 0.0:
			player.is_parrying = false
			player.visual_root.modulate = Color(0.7, 0.85, 1.0, 1.0) # Normal block tint

	player.apply_gravity(delta)
	player.move_and_slide()

	# Release block or switch
	if not Input.is_action_pressed("block"):
		machine.transition_to("idle")
		return
	if Input.is_action_just_pressed("dodge") and player.can_dodge():
		machine.transition_to("dodge")
		return
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		machine.transition_to("jump")
		return
