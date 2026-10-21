class_name EnemyHurtState
extends EnemyState

## Enemy hurt state with knockback and juggle handling.

var timer: float = 0.0
var hurt_duration: float = 0.25

func enter(msg: Dictionary = {}) -> void:
	timer = 0.0
	enemy.visuals.set_pose("hurt")
	enemy.hitbox.monitoring = false
	if SoundManager:
		SoundManager.play_sfx("enemy_hit")

	var knockback = msg.get("knockback", Vector2.ZERO)
	enemy.velocity = knockback

func physics_update(delta: float) -> void:
	timer += delta
	enemy.apply_gravity(delta)
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 200.0 * delta)
	enemy.move_and_slide()

	if enemy.is_on_floor():
		enemy.air_juggle_count = 0

	if timer >= hurt_duration and enemy.is_on_floor():
		machine.transition_to("chase")
