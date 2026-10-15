class_name EnemyFootman
extends CharacterBody2D

## Medieval Era Melee Soldier: Ironclad Footman (Milestone 5).
## Shields frontal attacks, executes telegraphed sword slash, and staggers on parry.

signal enemy_died(enemy: EnemyFootman)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 4
@export var patrol_speed: float = 35.0
@export var chase_speed: float = 65.0
@export var slash_damage: int = 1
@export var detection_range: float = 120.0
@export var attack_range: float = 32.0
@export var gravity: float = 900.0

enum FootmanState { PATROL, CHASE, TELEGRAPH, SLASH, STAGGER, HURT, DIE }
var current_state: FootmanState = FootmanState.PATROL

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
@onready var visual_root: Node2D = $VisualRoot
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay

func _ready() -> void:
	current_health = max_health
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self
	hitbox.damage = slash_damage
	hitbox.knockback_force = 120.0
	hitbox.hitstop_frames = 3
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * (7.0 if current_state == FootmanState.CHASE else 4.0)
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and visual_root:
			visual_root.modulate = Color.WHITE

	queue_redraw()

func _physics_process(delta: float) -> void:
	if hitstop_timer > 0.0:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		move_and_slide()
		return

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match current_state:
		FootmanState.PATROL:
			_update_patrol(delta)
		FootmanState.CHASE:
			_update_chase(delta)
		FootmanState.TELEGRAPH:
			_update_telegraph(delta)
		FootmanState.SLASH:
			_update_slash(delta)
		FootmanState.STAGGER:
			_update_stagger(delta)
		FootmanState.HURT:
			_update_hurt(delta)

	move_and_slide()

func _update_patrol(delta: float) -> void:
	velocity.x = facing_direction * patrol_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		set_facing(-facing_direction)

	if player_ref and global_position.distance_to(player_ref.global_position) < detection_range:
		current_state = FootmanState.CHASE

func _update_chase(delta: float) -> void:
	if not player_ref:
		current_state = FootmanState.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > detection_range * 1.5:
		current_state = FootmanState.PATROL
		return

	var dir = 1 if player_ref.global_position.x > global_position.x else -1
	set_facing(dir)

	if dist <= attack_range and attack_cooldown <= 0.0:
		current_state = FootmanState.TELEGRAPH
		state_timer = 0.4
		velocity.x = 0.0
	else:
		velocity.x = facing_direction * chase_speed

func _update_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity.x = 0.0
	# Sword raised, golden telegraph flash
	var pulse = (sin(state_timer * 22.0) + 1.0) * 0.5
	visual_root.modulate = Color(1.3, 1.1 + pulse * 0.4, 0.4)

	if state_timer <= 0.0:
		visual_root.modulate = Color.WHITE
		current_state = FootmanState.SLASH
		state_timer = 0.25
		hitbox.monitoring = true
		velocity.x = facing_direction * 90.0

func _update_slash(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)

	if state_timer <= 0.0:
		hitbox.monitoring = false
		hitbox.reset_hits()
		current_state = FootmanState.CHASE
		attack_cooldown = 1.4

func _update_stagger(delta: float) -> void:
	state_timer -= delta
	velocity.x = 0.0
	is_staggered = true
	visual_root.modulate = Color(1.3, 1.2, 0.5)

	if state_timer <= 0.0:
		is_staggered = false
		visual_root.modulate = Color.WHITE
		current_state = FootmanState.CHASE
		attack_cooldown = 1.2

func _update_hurt(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	if state_timer <= 0.0:
		current_state = FootmanState.CHASE

func stagger(duration: float = 1.4) -> void:
	current_state = FootmanState.STAGGER
	state_timer = duration
	is_staggered = true
	hitbox.monitoring = false
	hitbox.reset_hits()
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(1.0, 0.9, 0.2)
	spark.is_heavy = true
	get_parent().add_child(spark)

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)
	wall_ray.target_position.x = 16.0 * float(dir)
	ledge_ray.position.x = 12.0 * float(dir)
	hitbox.position.x = abs(hitbox.position.x) * float(dir)

func _on_hurtbox_hit_received(damage: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	var final_damage = damage
	var hit_from_front = false
	if attacker:
		var attack_from_right = (attacker.global_position.x > global_position.x)
		hit_from_front = (facing_direction == 1 and attack_from_right) or (facing_direction == -1 and not attack_from_right)

	# Shield guard: Frontal light hits are blocked completely or reduced to 0
	if hit_from_front and not is_staggered and not is_finisher and current_state != FootmanState.SLASH:
		final_damage = 0
		var clank = HIT_SPARK_SCENE.instantiate()
		clank.global_position = global_position + Vector2(facing_direction * 10, -12)
		clank.spark_color = Color(0.9, 0.9, 1.0)
		get_parent().add_child(clank)
	elif is_staggered:
		final_damage = damage * 2

	current_health -= final_damage
	hitstop_timer = float(hitstop_frames) / 60.0
	flash_timer = 0.1
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.is_heavy = is_finisher or is_staggered
	spark.spark_color = Color(0.9, 0.2, 0.2) if final_damage > 0 else Color(0.7, 0.7, 0.8)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die(knockback)
	else:
		if not is_staggered:
			current_state = FootmanState.HURT
			state_timer = 0.2
			velocity = knockback * 0.4

func _die(knockback: Vector2) -> void:
	is_dead = true
	current_state = FootmanState.DIE
	velocity = knockback * 0.5
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	hitbox.set_deferred("monitoring", false)
	enemy_died.emit(self)
	visual_root.modulate = Color(0.4, 0.4, 0.4, 0.8)

	await get_tree().create_timer(1.2).timeout
	queue_free()

func _draw() -> void:
	# Crisp Procedural Pixel Art: Ironclad Footman
	var col_armor = Color(0.55, 0.58, 0.62)    # Steel plate & chainmail
	var col_cloth = Color(0.25, 0.35, 0.60)    # Blue royal tunic
	var col_shield = Color(0.35, 0.22, 0.15)   # Wood & iron trim
	var col_gold = Color(0.9, 0.8, 0.3)        # Gold lion emblem

	var leg_bob = sin(walk_cycle) * 3.0 if not is_dead and not is_staggered else 0.0

	# Legs (greaves)
	draw_rect(Rect2(-6, -8 + leg_bob, 4, 8), col_armor.darkened(0.2))
	draw_rect(Rect2(2, -8 - leg_bob, 4, 8), col_armor.darkened(0.2))

	# Torso & Tunic
	draw_rect(Rect2(-7, -22, 14, 14), col_cloth)
	draw_rect(Rect2(-5, -20, 10, 10), col_armor) # Breastplate

	# Head & Sallet Helmet
	draw_rect(Rect2(-5, -29, 10, 8), col_armor)
	draw_rect(Rect2(-3, -26, 6, 2), Color(0.1, 0.1, 0.15)) # Visor slit

	# Kite Shield (front)
	if not is_staggered:
		var shield_pts = PackedVector2Array([
			Vector2(5, -24),
			Vector2(14, -24),
			Vector2(14, -10),
			Vector2(9, -2),
			Vector2(5, -10)
		])
		draw_colored_polygon(shield_pts, col_shield)
		draw_line(Vector2(9, -22), Vector2(9, -4), col_gold, 1.5) # Shield cross
	else:
		# Shield dropped behind
		draw_rect(Rect2(-14, -10, 8, 12), col_shield)

	# Sword
	if current_state == FootmanState.TELEGRAPH:
		# Raised overhead
		draw_line(Vector2(2, -22), Vector2(4, -36), col_armor.lightened(0.3), 2.0)
	elif current_state == FootmanState.SLASH:
		# Thrust forward
		draw_line(Vector2(6, -16), Vector2(22, -14), col_armor.lightened(0.3), 2.5)
