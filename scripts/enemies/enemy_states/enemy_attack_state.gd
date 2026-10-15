class_name EnemyAttackState
extends EnemyState

## Telegraphed lunge and bite attack state.

enum Phase { TELEGRAPH, LUNGE, RECOVERY }
var current_phase: Phase = Phase.TELEGRAPH
var timer: float = 0.0

const TELEGRAPH_TIME: float = 0.35
const LUNGE_TIME: float = 0.18
const RECOVERY_TIME: float = 0.40

func enter(_msg: Dictionary = {}) -> void:
	current_phase = Phase.TELEGRAPH
	timer = 0.0
	enemy.velocity.x = 0.0
	enemy.visuals.set_pose("telegraph")
	enemy.hitbox.monitoring = false
	enemy.hitbox.reset_hits()

func exit() -> void:
	enemy.hitbox.monitoring = false
	enemy.hitbox.reset_hits()
	if enemy.has_attack_token:
		AttackTokenManager.release_attack_token()
		enemy.has_attack_token = false

func physics_update(delta: float) -> void:
	timer += delta
	enemy.apply_gravity(delta)

	match current_phase:
		Phase.TELEGRAPH:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)
			if timer >= TELEGRAPH_TIME:
				current_phase = Phase.LUNGE
				timer = 0.0
				enemy.visuals.set_pose("lunge")
				enemy.velocity.x = enemy.facing_direction * enemy.lunge_speed
				enemy.velocity.y = -90.0 # slight hop
				enemy.hitbox.monitoring = true

		Phase.LUNGE:
			if timer >= LUNGE_TIME:
				current_phase = Phase.RECOVERY
				timer = 0.0
				enemy.visuals.set_pose("recovery")
				enemy.hitbox.monitoring = false
				if enemy.has_attack_token:
					AttackTokenManager.release_attack_token()
					enemy.has_attack_token = false

		Phase.RECOVERY:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 250.0 * delta)
			if timer >= RECOVERY_TIME:
				machine.transition_to("chase")

	enemy.move_and_slide()
