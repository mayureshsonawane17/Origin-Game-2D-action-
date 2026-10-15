class_name EnemyPatrolState
extends EnemyState

## Enemy patrols back and forth, turning on ledges or walls.

var turn_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	enemy.visuals.set_pose("walk")
	turn_timer = 0.0

func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)

	# Check player detection
	if enemy.can_see_player():
		machine.transition_to("detect")
		return

	# Check wall or cliff
	var hit_wall = enemy.wall_ray.is_colliding()
	var at_cliff = enemy.is_on_floor() and not enemy.ledge_ray.is_colliding()

	turn_timer += delta
	if (hit_wall or at_cliff) and turn_timer > 0.4:
		enemy.set_facing(-enemy.facing_direction)
		turn_timer = 0.0

	enemy.velocity.x = enemy.facing_direction * enemy.patrol_speed
	enemy.move_and_slide()
