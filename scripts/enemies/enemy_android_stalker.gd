class_name EnemyAndroidStalker
extends CharacterBody2D

## Futuristic Era Melee Striker: Cybernetic Android Stalker.
## Uses holographic phase dashes, twin high-frequency plasma daggers,
## and optical sensor overloading when parried (takes 2x double damage).

signal enemy_died(enemy: EnemyAndroidStalker)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 4
@export var patrol_speed: float = 40.0
@export var chase_speed: float = 85.0
@export var dagger_damage: int = 1
@export var detection_range: float = 150.0
@export var attack_range: float = 42.0
@export var gravity: float = 900.0

enum StalkerState { PATROL, CHASE, PHASE_TELEGRAPH, BLADE_DASH, STAGGER, HURT, DIE }
var current_state: StalkerState = StalkerState.PATROL

var current_health: int = 4
var facing_direction: int = -1
var player_ref: Node2D

var walk_cycle: float = 0.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false
var is_staggered: bool = false

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay

func _ready() -> void:
	current_health = max_health
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self
	hitbox.damage = dagger_damage
	hitbox.knockback_force = 150.0
	hitbox.hitstop_frames = 3
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * (8.0 if current_state == StalkerState.CHASE else 4.0)
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead or hitstop_timer > 0.0:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	_find_player()

	match current_state:
		StalkerState.PATROL:
			velocity.x = facing_direction * patrol_speed
			if wall_ray.is_colliding() or not ledge_ray.is_colliding():
				set_facing(-facing_direction)

			if player_ref and is_instance_valid(player_ref):
				var dist = global_position.distance_to(player_ref.global_position)
				if dist <= detection_range:
					current_state = StalkerState.CHASE

		StalkerState.CHASE:
			if not player_ref or not is_instance_valid(player_ref):
				current_state = StalkerState.PATROL
				return

			var dx = player_ref.global_position.x - global_position.x
			var dist = abs(dx)

			if dist > detection_range * 1.5:
				current_state = StalkerState.PATROL
				return

			var dir_to_p = 1 if dx > 0 else -1
			if dir_to_p != facing_direction:
				set_facing(dir_to_p)

			if dist <= attack_range and attack_cooldown <= 0.0:
				velocity.x = 0
				current_state = StalkerState.PHASE_TELEGRAPH
				state_timer = 0.35 # Holographic shimmer charge
				queue_redraw()
				return

			velocity.x = facing_direction * chase_speed
			if wall_ray.is_colliding() or not ledge_ray.is_colliding():
				velocity.x = 0

		StalkerState.PHASE_TELEGRAPH:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = StalkerState.BLADE_DASH
				state_timer = 0.24
				velocity.x = facing_direction * 220.0
				hitbox.monitoring = true
				queue_redraw()

		StalkerState.BLADE_DASH:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				hitbox.monitoring = false
				attack_cooldown = 1.2
				current_state = StalkerState.CHASE
				queue_redraw()

		StalkerState.STAGGER:
			velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				is_staggered = false
				current_state = StalkerState.CHASE
				queue_redraw()

		StalkerState.HURT:
			velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = StalkerState.CHASE
				queue_redraw()

	move_and_slide()

func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func set_facing(dir: int) -> void:
	facing_direction = dir
	if wall_ray:
		wall_ray.target_position.x = 18.0 * dir
	if ledge_ray:
		ledge_ray.position.x = 12.0 * dir
	if hitbox:
		hitbox.position.x = 16.0 * dir
	queue_redraw()

func stagger(duration: float = 1.4) -> void:
	is_staggered = true
	hitbox.monitoring = false
	current_state = StalkerState.STAGGER
	state_timer = duration
	velocity.x = -facing_direction * 70.0
	flash_timer = 0.2
	queue_redraw()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	var final_dmg = dmg * 2 if is_staggered else dmg
	current_health -= final_dmg
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(0.1, 0.95, 1.0) if not is_staggered else Color(1.0, 0.2, 0.3)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		if not is_staggered:
			current_state = StalkerState.HURT
			state_timer = 0.20
			velocity = knockback * 0.5
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = StalkerState.DIE
	hitbox.monitoring = false
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	enemy_died.emit(self)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_frame = Color.WHITE if is_flashing else Color(0.12, 0.14, 0.18)
	var col_synth = Color.WHITE if is_flashing else (Color(1.0, 0.2, 0.3) if is_staggered else Color(0.20, 0.25, 0.32))
	var col_blade = Color(0.1, 0.95, 1.0)
	var col_glow = Color(0.85, 0.15, 0.95)

	var bob = sin(walk_cycle) * 2.0 if (current_state in [StalkerState.PATROL, StalkerState.CHASE]) else 0.0
	var f = float(facing_direction)

	# Sleek cybernetic limbs
	draw_rect(Rect2(-6, -14 + bob, 5, 14), col_frame)
	draw_rect(Rect2(1, -14 + bob, 5, 14), col_frame)

	# Synthetic carbon fiber torso & glowing spine line
	draw_rect(Rect2(-7, -28 + bob, 14, 14), col_synth)
	draw_line(Vector2(-f * 2, -28 + bob), Vector2(-f * 2, -14 + bob), col_glow, 1.5)

	# Android visor head
	draw_circle(Vector2(0, -32 + bob), 5.0, col_frame)
	draw_rect(Rect2(f * 1, -33 + bob, 5, 2.5), col_blade)

	# Twin High-Frequency Plasma Daggers
	var hand_pos = Vector2(f * 6, -20 + bob)
	if current_state == StalkerState.BLADE_DASH:
		# Cross-slash forward
		draw_line(hand_pos, hand_pos + Vector2(f * 22, -6), col_blade, 2.5)
		draw_line(hand_pos, hand_pos + Vector2(f * 22, 6), col_blade, 2.5)
		draw_arc(hand_pos + Vector2(f * 12, 0), 16.0, -PI * 0.4, PI * 0.4, 8, Color(0.1, 0.95, 1.0, 0.7), 2.0)
	elif current_state == StalkerState.PHASE_TELEGRAPH:
		# Holographic phase shimmer
		draw_line(hand_pos, hand_pos + Vector2(-f * 6, -14), col_blade, 2.0)
		draw_arc(Vector2.ZERO, 16.0, 0, TAU, 8, Color(0.1, 0.95, 1.0, 0.6), 1.5)
	else:
		# Daggers primed
		draw_line(hand_pos, hand_pos + Vector2(f * 10, 4), col_blade, 2.0)

	if is_staggered:
		# Optical desync ring
		draw_arc(Vector2(0, -32 + bob), 10.0, 0, TAU, 8, Color(1.0, 0.2, 0.3), 1.5)
