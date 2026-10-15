class_name EnemyPterosaur
extends CharacterBody2D

## Flying Prehistoric Predator: Venom Pterosaur (Milestone 4).
## Glides horizontally with sinusoidal wing flaps, maintains an elevated perch,
## telegraphs an acidic spit attack, and fires VenomSpitProjectile at the player.

signal enemy_died(enemy: EnemyPterosaur)

const VENOM_SPIT_SCENE = preload("res://scenes/combat/venom_spit.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 4
@export var flight_speed: float = 65.0
@export var detection_range: float = 190.0
@export var preferred_altitude: float = -65.0
@export var preferred_distance: float = 110.0
@export var spit_cooldown: float = 2.4

enum PteroState { PATROL, CHASE_HOVER, TELEGRAPH, SPIT, RECOVER, HURT, DIE }
var current_state: PteroState = PteroState.PATROL

var current_health: int = 4
var facing_direction: int = -1
var player_ref: Node2D

var hover_timer: float = 0.0
var state_timer: float = 0.0
var cooldown_timer: float = 0.0
var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false
var spawn_pos: Vector2 = Vector2.ZERO

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
	current_health = max_health
	spawn_pos = global_position
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	hover_timer += delta
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and visual_root:
			visual_root.modulate = Color.WHITE

	queue_redraw()

func _physics_process(delta: float) -> void:
	if hitstop_timer > 0.0 or is_dead:
		if is_dead:
			velocity.y += 600.0 * delta
			move_and_slide()
		return

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0] as Player

	match current_state:
		PteroState.PATROL:
			_update_patrol(delta)
		PteroState.CHASE_HOVER:
			_update_chase_hover(delta)
		PteroState.TELEGRAPH:
			_update_telegraph(delta)
		PteroState.SPIT:
			_update_spit(delta)
		PteroState.RECOVER:
			_update_recover(delta)
		PteroState.HURT:
			_update_hurt(delta)

	move_and_slide()

func _update_patrol(delta: float) -> void:
	# Gentle hover loop around spawn
	var target_x = spawn_pos.x + sin(hover_timer * 1.5) * 50.0
	var target_y = spawn_pos.y + sin(hover_timer * 3.0) * 10.0
	velocity.x = (target_x - global_position.x) * 2.0
	velocity.y = (target_y - global_position.y) * 2.0

	set_facing(1 if velocity.x >= 0 else -1)

	if player_ref and global_position.distance_to(player_ref.global_position) < detection_range:
		current_state = PteroState.CHASE_HOVER

func _update_chase_hover(delta: float) -> void:
	if not player_ref:
		current_state = PteroState.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > detection_range * 1.4:
		current_state = PteroState.PATROL
		return

	# Position above and to side of player
	var p_pos = player_ref.global_position
	var side = 1 if global_position.x > p_pos.x else -1
	var target_pos = Vector2(p_pos.x + side * preferred_distance, p_pos.y + preferred_altitude)
	var dir_to_target = (target_pos - global_position).normalized()
	velocity = dir_to_target * flight_speed
	velocity.y += sin(hover_timer * 4.0) * 15.0

	set_facing(-1 if global_position.x > p_pos.x else 1)

	# Ready to spit?
	if cooldown_timer <= 0.0 and abs(global_position.x - p_pos.x) < 140.0:
		current_state = PteroState.TELEGRAPH
		state_timer = 0.45
		velocity = Vector2.ZERO

func _update_telegraph(delta: float) -> void:
	state_timer -= delta
	# Telegraph glow: pulsating acid green
	var pulse = (sin(state_timer * 20.0) + 1.0) * 0.5
	visual_root.modulate = Color(1.0 + pulse * 0.8, 1.2 + pulse * 1.0, 0.4)

	if state_timer <= 0.0:
		visual_root.modulate = Color.WHITE
		current_state = PteroState.SPIT

func _update_spit(delta: float) -> void:
	if player_ref:
		var spit = VENOM_SPIT_SCENE.instantiate() as VenomSpitProjectile
		spit.global_position = global_position + Vector2(facing_direction * 12.0, -2.0)
		var aim_dir = (player_ref.global_position + Vector2(0, -14.0) - spit.global_position).normalized()
		spit.direction = aim_dir
		spit.caster = self
		get_parent().add_child(spit)

	cooldown_timer = spit_cooldown
	current_state = PteroState.RECOVER
	state_timer = 0.6
	velocity = Vector2(-facing_direction * 40.0, -30.0) # Recoil hop

func _update_recover(delta: float) -> void:
	state_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 120.0 * delta)
	if state_timer <= 0.0:
		current_state = PteroState.CHASE_HOVER

func _update_hurt(delta: float) -> void:
	state_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
	if state_timer <= 0.0:
		current_state = PteroState.CHASE_HOVER

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)

func _on_hurtbox_hit_received(damage: int, knockback: Vector2, hitstop_frames: int, _attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	current_health -= damage
	hitstop_timer = float(hitstop_frames) / 60.0
	flash_timer = 0.12
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.is_heavy = is_finisher
	spark.spark_color = Color(0.4, 0.9, 0.2, 1.0) # Acid green blood
	get_parent().add_child(spark)

	if current_health <= 0:
		_die(knockback)
	else:
		current_state = PteroState.HURT
		state_timer = 0.35
		velocity = knockback * 0.7

func _die(knockback: Vector2) -> void:
	is_dead = true
	current_state = PteroState.DIE
	velocity = knockback
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	enemy_died.emit(self)
	visual_root.modulate = Color(0.6, 0.2, 0.2, 0.8)

	await get_tree().create_timer(1.2).timeout
	queue_free()

func _draw() -> void:
	# Crisp Procedural Pixel Art: Venom Pterosaur
	# Scaled for 480x270 viewport
	var flap = sin(hover_timer * 9.0) * 8.0 if not is_dead else 0.0
	var col_skin = Color(0.32, 0.44, 0.35) # Prehistoric olive-green
	var col_wing = Color(0.24, 0.35, 0.26) # Darker wing membrane
	var col_throat = Color(0.45, 0.85, 0.25) if current_state == PteroState.TELEGRAPH else Color(0.38, 0.55, 0.3)
	var col_beak = Color(0.75, 0.65, 0.40) # Bone beak

	# Wings (Two separate simple triangles for flawless triangulation)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -4), Vector2(-22, -14 + flap), Vector2(-8, 0)]), col_wing)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -4), Vector2(18, -14 + flap), Vector2(6, 0)]), col_wing)

	# Torso & Tail
	draw_rect(Rect2(-6, -6, 12, 10), col_skin)
	draw_line(Vector2(-6, 0), Vector2(-16, 2), col_skin, 2.0) # Tail

	# Throat sac (glowing acid)
	draw_circle(Vector2(5, 2), 4.0, col_throat)

	# Head & Crest
	draw_rect(Rect2(4, -8, 8, 7), col_skin)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -8), Vector2(-4, -14), Vector2(6, -6)]), col_beak.darkened(0.2)) # Backward crest
	# Beak
	draw_colored_polygon(PackedVector2Array([Vector2(12, -7), Vector2(20, -3), Vector2(12, -1)]), col_beak)
	# Eye
	draw_rect(Rect2(8, -7, 2, 2), Color(1.0, 0.9, 0.2))
