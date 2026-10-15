class_name PlayerDieState
extends PlayerState

## Player death state, halts movement and emits defeat signal.

func enter(_msg: Dictionary = {}) -> void:
	player.animation_player.play("die")
	player.velocity = Vector2.ZERO
	player.hurtbox.is_invulnerable = true
	player.hurtbox.monitoring = false
	player.hitbox.monitoring = false

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, 200.0 * delta)
	player.move_and_slide()
