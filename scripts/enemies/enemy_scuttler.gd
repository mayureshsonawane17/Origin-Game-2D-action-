class_name TarScuttler
extends CharacterBody2D

## Heavy Armored Prehistoric Brute: Tar Scuttler (Milestone 4).
## Heavily armored carapace brute with frontal deflection, telegraphed ground slam,
## and stagger vulnerability when parried.

signal enemy_died(enemy: TarScuttler)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 6
@export var patrol_speed: float = 28.0
@export var chase_speed: float = 45.0
@export var slam_damage: int = 2
@export var detection_range: float = 120.0
@export var attack_range: float = 38.0
@export var gravity: float = 900.0

enum ScuttlerState { PATROL, CHASE, TELEGRAPH, SLAM, STAGGER, HURT, DIE }
var current_state: ScuttlerState = ScuttlerState.PATROL

var current_health: int = 6
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
	hitbox.damage = slam_damage
	hitbox.knockback_force = 160.0
	hitbox.hitstop_frames = 4
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	walk_cycle += delta * (8.0 if current_state == ScuttlerState.CHASE else 4.0)
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
			player_ref = players[0] as Player

	match current_state:
		ScuttlerState.PATROL:
			_update_patrol(delta)
		ScuttlerState.CHASE:
			_update_chase(delta)
		ScuttlerState.TELEGRAPH:
			_update_telegraph(delta)
		ScuttlerState.SLAM:
			_update_slam(delta)
		ScuttlerState.STAGGER:
			_update_stagger(delta)
		ScuttlerState.HURT:
			_update_hurt(delta)

	move_and_slide()

func _update_patrol(delta: float) -> void:
	velocity.x = facing_direction * patrol_speed

	if wall_ray.is_colliding() or not ledge_ray.is_colliding():
		set_facing(-facing_direction)

	if player_ref and global_position.distance_to(player_ref.global_position) < detection_range:
		current_state = ScuttlerState.CHASE

func _update_chase(delta: float) -> void:
	if not player_ref:
		current_state = ScuttlerState.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > detection_range * 1.5:
		current_state = ScuttlerState.PATROL
		return

	var dir = 1 if player_ref.global_position.x > global_position.x else -1
	set_facing(dir)

	if dist <= attack_range and attack_cooldown <= 0.0:
		current_state = ScuttlerState.TELEGRAPH
		state_timer = 0.45
		velocity.x = 0.0
	else:
		velocity.x = facing_direction * chase_speed

func _update_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity.x = 0.0
	# Warning flash (amber / crimson)
	var flash = (sin(state_timer * 22.0) + 1.0) * 0.5
	visual_root.modulate = Color(1.4, 0.8 + flash * 0.4, 0.3)

	if state_timer <= 0.0:
		visual_root.modulate = Color.WHITE
		current_state = ScuttlerState.SLAM
		state_timer = 0.3
		hitbox.monitoring = true
		velocity.x = facing_direction * 110.0 # Forward lunge slam

func _update_slam(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

	if state_timer <= 0.0:
		hitbox.monitoring = false
		hitbox.reset_hits()
		current_state = ScuttlerState.CHASE
		attack_cooldown = 1.8

func _update_stagger(delta: float) -> void:
	state_timer -= delta
	velocity.x = 0.0
	is_staggered = true
	# Golden stun sparkle
	visual_root.modulate = Color(1.3, 1.2, 0.5)

	if state_timer <= 0.0:
		is_staggered = false
		visual_root.modulate = Color.WHITE
		current_state = ScuttlerState.CHASE
		attack_cooldown = 1.5

func _update_hurt(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	if state_timer <= 0.0:
		current_state = ScuttlerState.CHASE

func stagger(duration: float = 1.6) -> void:
	current_state = ScuttlerState.STAGGER
	state_timer = duration
	is_staggered = true
	hitbox.monitoring = false
	hitbox.reset_hits()
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -12)
	spark.spark_color = Color(1.0, 0.9, 0.2)
	spark.is_heavy = true
	get_parent().add_child(spark)

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)
	wall_ray.target_position.x = 18.0 * float(dir)
	ledge_ray.position.x = 14.0 * float(dir)
	hitbox.position.x = abs(hitbox.position.x) * float(dir)

func _on_hurtbox_hit_received(damage: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	var final_damage = damage
	var hit_from_front = false
	if attacker:
		var attack_from_right = (attacker.global_position.x > global_position.x)
		hit_from_front = (facing_direction == 1 and attack_from_right) or (facing_direction == -1 and not attack_from_right)

	# Carapace logic: Frontal light hits are deflected unless staggered or finisher
	if hit_from_front and not is_staggered and not is_finisher:
		final_damage = 1
		# Clank spark
		var clank = HIT_SPARK_SCENE.instantiate()
		clank.global_position = global_position + Vector2(facing_direction * 10, -10)
		clank.spark_color = Color(0.9, 0.9, 0.95)
		get_parent().add_child(clank)
	elif is_staggered:
		# Double damage while overturned!
		final_damage = damage * 2

	current_health -= final_damage
	hitstop_timer = float(hitstop_frames) / 60.0
	flash_timer = 0.12
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -10)
	spark.is_heavy = is_finisher or is_staggered
	spark.spark_color = Color(1.0, 0.5, 0.1) if not hit_from_front else Color(0.8, 0.8, 0.8)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die(knockback)
	else:
		if not is_staggered:
			current_state = ScuttlerState.HURT
			state_timer = 0.25
			velocity = knockback * 0.4

func _die(knockback: Vector2) -> void:
	is_dead = true
	current_state = ScuttlerState.DIE
	velocity = knockback * 0.6
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	hitbox.set_deferred("monitoring", false)
	enemy_died.emit(self)
	visual_root.modulate = Color(0.4, 0.3, 0.3, 0.8)

	await get_tree().create_timer(1.2).timeout
	queue_free()

func _draw() -> void:
	# Crisp Procedural Pixel Art: Tar Scuttler (Chitin Carapace Tank)
	var col_shell = Color(0.18, 0.20, 0.22)   # Heavy tar-rock carapace
	var col_under = Color(0.65, 0.35, 0.15)   # Amber underside
	var col_vein = Color(0.90, 0.55, 0.15)    # Glowing magma/amber cracks
	var col_eye = Color(1.0, 0.2, 0.1)

	var leg_offset = sin(walk_cycle) * 4.0 if not is_dead and not is_staggered else 0.0

	# Skittering Legs
	draw_line(Vector2(-10, -2), Vector2(-16, 0 + leg_offset), col_shell, 2.0)
	draw_line(Vector2(-2, -2), Vector2(-4, 0 - leg_offset), col_shell, 2.0)
	draw_line(Vector2(6, -2), Vector2(12, 0 + leg_offset), col_shell, 2.0)

	# Main Body & Carapace
	if is_staggered:
		# Turned upside down
		draw_rect(Rect2(-12, -14, 24, 12), col_under)
		draw_line(Vector2(-10, -8), Vector2(10, -8), Color(1.0, 0.8, 0.3), 2.0) # Exposed glowing belly
	else:
		# Arched shell
		var shell_pts = PackedVector2Array([
			Vector2(-14, -2),
			Vector2(-10, -18),
			Vector2(8, -18),
			Vector2(14, -6),
			Vector2(12, -2)
		])
		draw_colored_polygon(shell_pts, col_shell)
		# Carapace ridges
		draw_line(Vector2(-6, -18), Vector2(-8, -4), col_vein, 1.5)
		draw_line(Vector2(2, -18), Vector2(2, -4), col_vein, 1.5)
		# Heavy front pincer
		draw_colored_polygon(PackedVector2Array([Vector2(12, -8), Vector2(18, -12), Vector2(16, -4)]), col_shell.lightened(0.15))
		# Eye slit
		draw_rect(Rect2(10, -14, 2, 2), col_eye)
