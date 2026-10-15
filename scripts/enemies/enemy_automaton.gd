class_name EnemyAutomaton
extends CharacterBody2D

## Industrial Era Melee Heavy: Clockwork Steam Automaton.
## Heavy iron chassis, telegraphed high-pressure piston punch, and boiler overload stagger on parry.

signal enemy_died(enemy: EnemyAutomaton)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 4
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 55.0
@export var punch_damage: int = 1
@export var detection_range: float = 130.0
@export var attack_range: float = 38.0
@export var gravity: float = 900.0

enum AutomatonState { PATROL, CHASE, TELEGRAPH, PUNCH, STAGGER, HURT, DIE }
var current_state: AutomatonState = AutomatonState.PATROL

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
	hitbox.damage = punch_damage
	hitbox.knockback_force = 150.0
	hitbox.hitstop_frames = 4
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * 6.0
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
		AutomatonState.PATROL:
			_state_patrol(delta)
		AutomatonState.CHASE:
			_state_chase(delta)
		AutomatonState.TELEGRAPH:
			_state_telegraph(delta)
		AutomatonState.PUNCH:
			_state_punch(delta)
		AutomatonState.STAGGER:
			_state_stagger(delta)
		AutomatonState.HURT:
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
			current_state = AutomatonState.CHASE

func _state_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = AutomatonState.PATROL
		return

	var dx = player_ref.global_position.x - global_position.x
	var dist = abs(dx)

	if dist > detection_range * 1.5:
		current_state = AutomatonState.PATROL
		return

	var dir_to_p = 1 if dx > 0 else -1
	if dir_to_p != facing_direction:
		set_facing(dir_to_p)

	if dist <= attack_range and attack_cooldown <= 0.0:
		velocity.x = 0
		current_state = AutomatonState.TELEGRAPH
		state_timer = 0.45 # Steam pressure buildup
		queue_redraw()
		return

	velocity.x = facing_direction * chase_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		velocity.x = 0

func _state_telegraph(delta: float) -> void:
	velocity.x = 0
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = AutomatonState.PUNCH
		state_timer = 0.25 # Piston strike duration
		velocity.x = facing_direction * 130.0
		hitbox.monitoring = true
		queue_redraw()

func _state_punch(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		hitbox.monitoring = false
		attack_cooldown = 1.4
		current_state = AutomatonState.CHASE
		queue_redraw()

func _state_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		is_staggered = false
		current_state = AutomatonState.CHASE
		queue_redraw()

func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = AutomatonState.CHASE
		queue_redraw()

func set_facing(dir: int) -> void:
	facing_direction = dir
	if wall_ray:
		wall_ray.target_position.x = 18.0 * dir
	if ledge_ray:
		ledge_ray.position.x = 14.0 * dir
	if hitbox:
		hitbox.position.x = 18.0 * dir
	queue_redraw()

func stagger(duration: float = 1.5) -> void:
	is_staggered = true
	hitbox.monitoring = false
	current_state = AutomatonState.STAGGER
	state_timer = duration
	velocity.x = -facing_direction * 50.0
	flash_timer = 0.2
	queue_redraw()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	var final_damage = dmg
	if is_staggered:
		final_damage = dmg * 2 # Double damage during boiler overload!

	current_health -= final_damage
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -16)
	spark.spark_color = Color(1.0, 0.4, 0.1) if is_staggered else Color(0.9, 0.8, 0.4)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		if not is_staggered:
			current_state = AutomatonState.HURT
			state_timer = 0.22
			velocity = knockback * 0.5
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = AutomatonState.DIE
	hitbox.monitoring = false
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	enemy_died.emit(self)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if is_dead:
		return

	var is_flashing = flash_timer > 0.0
	var col_iron = Color.WHITE if is_flashing else (Color(0.85, 0.3, 0.2) if is_staggered else Color(0.32, 0.34, 0.38))
	var col_brass = Color.WHITE if is_flashing else Color(0.85, 0.70, 0.25)
	var col_core = Color.WHITE if is_flashing else Color(1.0, 0.5, 0.1)
	var col_steam = Color(0.85, 0.90, 0.95, 0.6)

	var f = float(facing_direction)

	# Heavy robotic legs
	draw_rect(Rect2(-8, -10, 6, 10), col_iron)
	draw_rect(Rect2(2, -10, 6, 10), col_iron)

	# Main Boiler Torso
	draw_rect(Rect2(-10, -28, 20, 18), col_iron)
	# Rivets
	draw_circle(Vector2(-8, -26), 1.0, col_brass)
	draw_circle(Vector2(8, -26), 1.0, col_brass)
	draw_circle(Vector2(-8, -12), 1.0, col_brass)
	draw_circle(Vector2(8, -12), 1.0, col_brass)

	# Glowing Furnace Grate
	draw_rect(Rect2(-5, -20, 10, 6), col_core)

	# Head with Optical Sensor
	draw_rect(Rect2(-6, -34, 12, 6), col_iron)
	draw_circle(Vector2(f * 3, -31), 2.0, col_core)

	# Steam Chimney on back
	draw_rect(Rect2(-f * 8, -38, 4, 10), col_brass)
	# Steam puff
	draw_circle(Vector2(-f * 8, -42), 3.5, col_steam)

	# Piston Punch Arm
	if current_state == AutomatonState.TELEGRAPH:
		# Cocked back arm glowing orange
		draw_rect(Rect2(-f * 12, -22, 6, 6), col_brass)
		draw_circle(Vector2(f * 2, -22), 3.0, Color(1.0, 0.3, 0.1, 0.8))
	elif current_state == AutomatonState.PUNCH:
		# Extended pneumatic iron piston
		draw_line(Vector2(f * 6, -20), Vector2(f * 24, -20), col_brass, 4.0)
		draw_rect(Rect2(f * 20, -24, 8, 8), col_iron)
	else:
		# Idle resting arm
		draw_rect(Rect2(f * 6, -22, 6, 10), col_iron)

	# Overload steam venting
	if is_staggered:
		draw_circle(Vector2(-f * 10, -45), 5.0, col_steam)
		draw_circle(Vector2(-f * 6, -50), 6.0, col_steam)
