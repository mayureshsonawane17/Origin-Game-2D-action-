class_name BossPrimalStalker
extends BossController

## Basic Boss: Primal Stalker (PRE-01).
## High mobility, telegraphed pounces, parryable claw flurry.

enum BossAction { IDLE, POUNCE_TELEGRAPH, POUNCE_LUNGE, POUNCE_RECOVERY, FRENZY_TELEGRAPH, FRENZY_SWIPE, RETREAT }
var current_action: BossAction = BossAction.IDLE
var action_timer: float = 0.0

@onready var visuals: Node2D = $VisualRoot/StalkerVisuals

func _ready() -> void:
	if not data:
		data = load("res://data/bosses/primal_stalker.tres") as BossData
	super._ready()
	hitbox.damage = 1
	hitbox.knockback_force = 140.0
	hitbox.hitstop_frames = 4

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += 900.0 * delta

	if is_staggered:
		move_and_slide()
		return

	action_timer += delta

	# Track player facing
	if player_ref and current_action in [BossAction.IDLE, BossAction.POUNCE_TELEGRAPH, BossAction.FRENZY_TELEGRAPH]:
		var dir = 1 if player_ref.global_position.x >= global_position.x else -1
		set_facing(dir)

	match current_action:
		BossAction.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if action_timer >= 0.8:
				_choose_next_attack()

		BossAction.POUNCE_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.45:
				current_action = BossAction.POUNCE_LUNGE
				action_timer = 0.0
				velocity.x = facing_direction * 220.0
				velocity.y = -120.0
				hitbox.monitoring = true
				visuals.set_pose("lunge")

		BossAction.POUNCE_LUNGE:
			if is_on_floor() or action_timer >= 0.35:
				current_action = BossAction.POUNCE_RECOVERY
				action_timer = 0.0
				hitbox.monitoring = false
				visuals.set_pose("recovery")

		BossAction.POUNCE_RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if action_timer >= 0.4:
				current_action = BossAction.IDLE
				action_timer = 0.0
				visuals.set_pose("idle")

		BossAction.FRENZY_TELEGRAPH:
			velocity.x = 0.0
			if action_timer >= 0.35:
				current_action = BossAction.FRENZY_SWIPE
				action_timer = 0.0
				velocity.x = facing_direction * 120.0
				hitbox.monitoring = true
				visuals.set_pose("swipe")

		BossAction.FRENZY_SWIPE:
			if action_timer >= 0.25:
				current_action = BossAction.POUNCE_RECOVERY
				action_timer = 0.0
				hitbox.monitoring = false
				visuals.set_pose("recovery")

		BossAction.RETREAT:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if action_timer >= 0.4:
				current_action = BossAction.IDLE
				action_timer = 0.0
				visuals.set_pose("idle")

	move_and_slide()

func _choose_next_attack() -> void:
	action_timer = 0.0
	var dist = global_position.distance_to(player_ref.global_position) if player_ref else 100.0

	if dist > 80.0:
		# Pounce
		current_action = BossAction.POUNCE_TELEGRAPH
		telegraph(0.45, Color(1.0, 0.3, 0.1))
		visuals.set_pose("telegraph")
	else:
		# Frenzy or retreat
		if randf() > 0.4:
			current_action = BossAction.FRENZY_TELEGRAPH
			telegraph(0.35, Color(1.0, 0.8, 0.2)) # Warning: parryable!
			visuals.set_pose("telegraph")
		else:
			current_action = BossAction.RETREAT
			velocity = Vector2(-facing_direction * 160.0, -100.0)
			visuals.set_pose("jump")
