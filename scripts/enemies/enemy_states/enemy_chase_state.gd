class_name EnemyChaseState
extends EnemyState

## Enemy runs toward player, respecting attack tokens and crowd spacing.

func enter(_msg: Dictionary = {}) -> void:
	enemy.visuals.set_pose("run")

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)

	if not enemy.player_ref or enemy.player_ref.is_dead:
		machine.transition_to("patrol")
		return

	var dist = enemy.distance_to_player()
	if dist > enemy.detection_range * 1.6:
		machine.transition_to("patrol")
		return

	var dir_to_player = 1 if enemy.player_ref.global_position.x >= enemy.global_position.x else -1
	enemy.set_facing(dir_to_player)

	if dist <= enemy.attack_range:
		# Attempt to acquire attack token
		if AttackTokenManager.request_attack_token():
			enemy.has_attack_token = true
			machine.transition_to("attack")
			return
		else:
			# Token unavailable: pace or wait shortly
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 150.0 * delta)
	else:
		# Move towards player, avoid walking off cliffs unless leaping
		var at_cliff = enemy.is_on_floor() and not enemy.ledge_ray.is_colliding()
		if at_cliff:
			enemy.velocity.x = 0.0
		else:
			enemy.velocity.x = dir_to_player * enemy.chase_speed

	enemy.move_and_slide()
