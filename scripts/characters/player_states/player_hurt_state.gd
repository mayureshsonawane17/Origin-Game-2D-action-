class_name PlayerHurtState
extends PlayerState

## Player hurt/stagger state when receiving damage.

var hurt_timer: float = 0.0
var hurt_duration: float = 0.2

func enter(msg: Dictionary = {}) -> void:
	player.animation_player.play("hurt")
	hurt_timer = 0.0
	player.hurtbox.is_invulnerable = true

	var knockback = msg.get("knockback", Vector2.ZERO)
	player.velocity = knockback

func exit() -> void:
	player.hurtbox.is_invulnerable = false

func physics_update(delta: float) -> void:
	hurt_timer += delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, 300.0 * delta)
	player.move_and_slide()

	if hurt_timer >= hurt_duration:
		if player.is_on_floor():
			machine.transition_to("idle")
		else:
			machine.transition_to("fall")
