class_name EnemyDetectState
extends EnemyState

## Brief telegraph/reaction state when player is first spotted.

var detect_timer: float = 0.0
var detect_duration: float = 0.25

func enter(_msg: Dictionary = {}) -> void:
	detect_timer = 0.0
	enemy.velocity.x = 0.0
	enemy.visuals.set_pose("alert")
	# Face player
	if enemy.player_ref:
		var dir = 1 if enemy.player_ref.global_position.x >= enemy.global_position.x else -1
		enemy.set_facing(dir)

func physics_update(delta: float) -> void:
	detect_timer += delta
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	if detect_timer >= detect_duration:
		machine.transition_to("chase")
