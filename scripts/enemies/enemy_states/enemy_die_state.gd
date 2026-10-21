class_name EnemyDieState
extends EnemyState

## Enemy defeat and death dissolution state.

var timer: float = 0.0
var death_duration: float = 0.45

func enter(msg: Dictionary = {}) -> void:
	timer = 0.0
	enemy.is_dead = true
	enemy.visuals.set_pose("die")
	enemy.hurtbox.is_invulnerable = true
	enemy.hurtbox.monitoring = false
	enemy.hitbox.monitoring = false
	if SoundManager:
		SoundManager.play_sfx("enemy_die")

	if enemy.has_attack_token:
		AttackTokenManager.release_attack_token()
		enemy.has_attack_token = false

	# Slight knockback lift on death
	var knockback = msg.get("knockback", Vector2.ZERO)
	enemy.velocity = Vector2(knockback.x * 0.5, min(knockback.y * 0.5, -60.0))

func physics_update(delta: float) -> void:
	timer += delta
	enemy.apply_gravity(delta)
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 200.0 * delta)
	enemy.move_and_slide()

	# Fade out visual
	var alpha = 1.0 - (timer / death_duration)
	enemy.visual_root.modulate.a = max(0.0, alpha)

	if timer >= death_duration:
		enemy.queue_free()
