class_name EnemyRonin
extends CharacterBody2D

## Historical Era Melee Duelist: Wandering Ronin.
## Executes agile dashes and telegraphed Iaijutsu quickdraw slashes.
## Parryable during iaijutsu dash to trigger 1.5s stagger vulnerability (takes 2x damage).

signal enemy_died(enemy: EnemyRonin)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var patrol_speed: float = 45.0
@export var chase_speed: float = 85.0
@export var slash_damage: int = 1
@export var detection_range: float = 140.0
@export var attack_range: float = 60.0
@export var gravity: float = 900.0

enum RoninState { PATROL, CHASE, TELEGRAPH, IAI_SLASH, STAGGER, HURT, DIE }
var current_state: RoninState = RoninState.PATROL

var current_health: int = 3
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
	hitbox.knockback_force = 140.0
	hitbox.hitstop_frames = 4
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * (8.0 if current_state == RoninState.CHASE else 4.0)
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
		RoninState.PATROL:
			_state_patrol(delta)
		RoninState.CHASE:
			_state_chase(delta)
		RoninState.TELEGRAPH:
			_state_telegraph(delta)
		RoninState.IAI_SLASH:
			_state_iai_slash(delta)
		RoninState.STAGGER:
			_state_stagger(delta)
		RoninState.HURT:
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
			current_state = RoninState.CHASE

func _state_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = RoninState.PATROL
		return

	var dx = player_ref.global_position.x - global_position.x
	var dist = abs(dx)

	if dist > detection_range * 1.5:
		current_state = RoninState.PATROL
		return

	var dir_to_p = 1 if dx > 0 else -1
	if dir_to_p != facing_direction:
		set_facing(dir_to_p)

	if dist <= attack_range and attack_cooldown <= 0.0:
		velocity.x = 0
		current_state = RoninState.TELEGRAPH
		state_timer = 0.40 # Telegraph pause: crouches and readies katana
		queue_redraw()
		return

	velocity.x = facing_direction * chase_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		velocity.x = 0

func _state_telegraph(delta: float) -> void:
	velocity.x = 0
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = RoninState.IAI_SLASH
		state_timer = 0.22 # Rapid dash slash duration
		velocity.x = facing_direction * 220.0
		hitbox.monitoring = true
		queue_redraw()

func _state_iai_slash(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		hitbox.monitoring = false
		attack_cooldown = 1.3
		current_state = RoninState.CHASE
		queue_redraw()

func _state_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 400.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		is_staggered = false
		current_state = RoninState.CHASE
		queue_redraw()

func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 350.0 * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = RoninState.CHASE
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

func stagger(duration: float = 1.5) -> void:
	is_staggered = true
	hitbox.monitoring = false
	current_state = RoninState.STAGGER
	state_timer = duration
	velocity.x = -facing_direction * 60.0
	flash_timer = 0.2
	queue_redraw()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	var final_damage = dmg
	if is_staggered:
		final_damage = dmg * 2 # Takes 2x damage while staggered!

	current_health -= final_damage
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(1.0, 0.3, 0.3, 1.0) if is_staggered else Color(0.95, 0.9, 0.8)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		if not is_staggered:
			current_state = RoninState.HURT
			state_timer = 0.25
			velocity = knockback * 0.7
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = RoninState.DIE
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
	var col_skin = Color.WHITE if is_flashing else Color(0.92, 0.78, 0.65)
	var col_hat = Color.WHITE if is_flashing else Color(0.72, 0.62, 0.42)
	var col_robe = Color.WHITE if is_flashing else (Color(0.8, 0.2, 0.2) if is_staggered else Color(0.20, 0.28, 0.42))
	var col_hakama = Color.WHITE if is_flashing else Color(0.12, 0.15, 0.22)
	var col_blade = Color.WHITE if is_flashing else Color(0.92, 0.95, 1.0)
	var col_sheath = Color.WHITE if is_flashing else Color(0.15, 0.15, 0.18)

	var bob = sin(walk_cycle) * 2.0 if (current_state in [RoninState.PATROL, RoninState.CHASE]) else 0.0
	var f = float(facing_direction)

	# Hakama (pleated trousers/skirt)
	draw_rect(Rect2(-8, -12 + bob, 16, 12), col_hakama)
	# Kimono upper body
	draw_rect(Rect2(-7, -24 + bob, 14, 12), col_robe)
	# Obi (sash)
	draw_rect(Rect2(-7, -14 + bob, 14, 3), Color(0.7, 0.15, 0.15))

	# Head
	draw_circle(Vector2(0, -28 + bob), 5.0, col_skin)
	# Conical Straw Hat (Kasa)
	var hat_pts = PackedVector2Array([
		Vector2(-12, -28 + bob),
		Vector2(0, -36 + bob),
		Vector2(12, -28 + bob)
	])
	draw_colored_polygon(hat_pts, col_hat)

	# Scabbard and Blade
	if current_state == RoninState.TELEGRAPH:
		# Low crouching draw stance with gleam on hilt
		draw_line(Vector2(-f * 8, -12 + bob), Vector2(f * 4, -16 + bob), col_sheath, 2.0)
		draw_circle(Vector2(f * 5, -16 + bob), 2.5, Color(1.0, 1.0, 0.6))
	elif current_state == RoninState.IAI_SLASH:
		# Unsheathed katana blade swept out forward
		var blade_tip = Vector2(f * 26, -18 + bob)
		draw_line(Vector2(f * 4, -18 + bob), blade_tip, col_blade, 2.5)
		# Arc of cutting wind
		draw_arc(Vector2(f * 12, -18 + bob), 14.0, -PI * 0.4, PI * 0.4, 8, Color(0.9, 0.95, 1.0, 0.7), 2.0)
	else:
		# Katana at hip in scabbard
		draw_line(Vector2(-f * 8, -12 + bob), Vector2(f * 2, -18 + bob), col_sheath, 2.0)
		draw_circle(Vector2(f * 3, -19 + bob), 1.5, Color(0.8, 0.7, 0.2))

	# Stagger stars/swirl
	if is_staggered:
		draw_circle(Vector2(sin(walk_cycle * 2.0) * 8.0, -42), 2.0, Color(1.0, 0.8, 0.2))
		draw_circle(Vector2(-sin(walk_cycle * 2.0) * 8.0, -40), 1.5, Color(1.0, 0.4, 0.2))
