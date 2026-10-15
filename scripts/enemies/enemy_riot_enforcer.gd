class_name EnemyRiotEnforcer
extends CharacterBody2D

## Modern Era Melee Defender: SWAT Riot Enforcer.
## Frontal ballistic riot shield completely negates frontal attacks (0 damage taken).
## Attacks with telegraphed electric stun baton; parry staggers and drops shield for 2x damage.

signal enemy_died(enemy: EnemyRiotEnforcer)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 4
@export var patrol_speed: float = 35.0
@export var chase_speed: float = 65.0
@export var baton_damage: int = 1
@export var detection_range: float = 130.0
@export var attack_range: float = 34.0
@export var gravity: float = 900.0

enum EnforcerState { PATROL, CHASE, TELEGRAPH, BATON_STRIKE, STAGGER, HURT, DIE }
var current_state: EnforcerState = EnforcerState.PATROL

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
	hitbox.damage = baton_damage
	hitbox.knockback_force = 140.0
	hitbox.hitstop_frames = 3
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * (7.0 if current_state == EnforcerState.CHASE else 4.0)
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
		EnforcerState.PATROL:
			_state_patrol(delta)
		EnforcerState.CHASE:
			_state_chase(delta)
		EnforcerState.TELEGRAPH:
			_state_telegraph(delta)
		EnforcerState.BATON_STRIKE:
			_state_baton_strike(delta)
		EnforcerState.STAGGER:
			_state_stagger(delta)
		EnforcerState.HURT:
			_state_hurt(delta)

	move_and_slide()

func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _state_patrol(_delta: float) -> void:
	velocity.x = facing_direction * patrol_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		set_facing(-facing_direction)

	if player_ref and is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= detection_range:
			current_state = EnforcerState.CHASE

func _state_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = EnforcerState.PATROL
		return

	var dx = player_ref.global_position.x - global_position.x
	var dist = abs(dx)

	if dist > detection_range * 1.5:
		current_state = EnforcerState.PATROL
		return

	var dir_to_p = 1 if dx > 0 else -1
	if dir_to_p != facing_direction:
		set_facing(dir_to_p)

	if dist <= attack_range and attack_cooldown <= 0.0:
		velocity.x = 0
		current_state = EnforcerState.TELEGRAPH
		state_timer = 0.42 # Baton spark charge
		queue_redraw()
		return

	velocity.x = facing_direction * chase_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		velocity.x = 0

func _state_telegraph(delta: float) -> void:
	velocity.x = 0
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = EnforcerState.BATON_STRIKE
		state_timer = 0.22
		velocity.x = facing_direction * 110.0
		hitbox.monitoring = true
		queue_redraw()

func _state_baton_strike(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		hitbox.monitoring = false
		attack_cooldown = 1.3
		current_state = EnforcerState.CHASE
		queue_redraw()

func _state_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		is_staggered = false
		current_state = EnforcerState.CHASE
		queue_redraw()

func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = EnforcerState.CHASE
		queue_redraw()

func set_facing(dir: int) -> void:
	facing_direction = dir
	if wall_ray:
		wall_ray.target_position.x = 18.0 * dir
	if ledge_ray:
		ledge_ray.position.x = 12.0 * dir
	if hitbox:
		hitbox.position.x = 18.0 * dir
	queue_redraw()

func stagger(duration: float = 1.4) -> void:
	is_staggered = true
	hitbox.monitoring = false
	current_state = EnforcerState.STAGGER
	state_timer = duration
	velocity.x = -facing_direction * 60.0
	flash_timer = 0.2
	queue_redraw()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, attacker: Node, is_finisher: bool) -> void:
	if is_dead:
		return

	# Frontal block check
	if not is_staggered and attacker:
		var attacker_pos = (attacker as Node2D).global_position
		var hit_from_front = (facing_direction == 1 and attacker_pos.x > global_position.x) or (facing_direction == -1 and attacker_pos.x < global_position.x)

		if hit_from_front and not is_finisher:
			# Ballistic riot shield blocks completely!
			hitstop_timer = 0.1
			flash_timer = 0.1
			var clank_spark = HIT_SPARK_SCENE.instantiate()
			clank_spark.global_position = global_position + Vector2(facing_direction * 12.0, -14.0)
			clank_spark.spark_color = Color(0.3, 0.8, 1.0, 1.0)
			get_parent().add_child(clank_spark)
			return

	var final_damage = dmg
	if is_staggered:
		final_damage = dmg * 2 # Double damage while staggered!

	current_health -= final_damage
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(1.0, 0.3, 0.3, 1.0) if is_staggered else Color(0.9, 0.9, 0.9)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		if not is_staggered:
			current_state = EnforcerState.HURT
			state_timer = 0.22
			velocity = knockback * 0.5
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = EnforcerState.DIE
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
	var col_uniform = Color.WHITE if is_flashing else Color(0.18, 0.20, 0.24)
	var col_vest = Color.WHITE if is_flashing else (Color(0.8, 0.2, 0.2) if is_staggered else Color(0.12, 0.14, 0.18))
	var col_shield = Color(0.35, 0.75, 0.95, 0.6)
	var col_shield_rim = Color(0.70, 0.72, 0.78)
	var col_baton = Color(0.15, 0.15, 0.18)
	var col_spark = Color(0.3, 0.85, 1.0)

	var bob = sin(walk_cycle) * 2.0 if (current_state in [EnforcerState.PATROL, EnforcerState.CHASE]) else 0.0
	var f = float(facing_direction)

	# Tactical trousers & boots
	draw_rect(Rect2(-7, -12 + bob, 14, 12), col_uniform)
	# Tactical Body Armor (Tactical Vest)
	draw_rect(Rect2(-8, -26 + bob, 16, 14), col_vest)
	# SWAT text plate
	draw_rect(Rect2(-5, -23 + bob, 10, 4), Color(0.9, 0.9, 0.95))

	# Helmet & Visor
	draw_circle(Vector2(0, -30 + bob), 5.5, col_vest)
	draw_rect(Rect2(f * 1, -31 + bob, 5, 3), Color(0.2, 0.8, 1.0, 0.9))

	# Electric Stun Baton
	if current_state == EnforcerState.TELEGRAPH:
		# Raised baton sparking with electricity
		draw_line(Vector2(-f * 4, -22 + bob), Vector2(-f * 8, -34 + bob), col_baton, 2.5)
		draw_circle(Vector2(-f * 8, -34 + bob), 3.0, col_spark)
	elif current_state == EnforcerState.BATON_STRIKE:
		# Thrust forward
		draw_line(Vector2(f * 4, -20 + bob), Vector2(f * 22, -20 + bob), col_baton, 3.0)
		draw_circle(Vector2(f * 22, -20 + bob), 3.5, col_spark)
	else:
		# Baton at hip
		draw_line(Vector2(-f * 6, -14 + bob), Vector2(-f * 2, -22 + bob), col_baton, 2.0)

	# Ballistic Riot Shield in front
	if not is_staggered:
		var shield_x = f * 8
		draw_rect(Rect2(shield_x - 3, -32 + bob, 6, 30), col_shield)
		draw_rect(Rect2(shield_x - 3, -32 + bob, 6, 30), col_shield_rim, false, 1.5)
		# Viewport slot in shield
		draw_rect(Rect2(shield_x - 2, -28 + bob, 4, 6), Color(0.85, 0.95, 1.0, 0.8))
	else:
		# Shield dropped to ground
		draw_rect(Rect2(-6, -4, 12, 4), col_shield_rim)
		draw_circle(Vector2(sin(walk_cycle * 2.0) * 8.0, -42), 2.5, Color(0.3, 0.85, 1.0))
