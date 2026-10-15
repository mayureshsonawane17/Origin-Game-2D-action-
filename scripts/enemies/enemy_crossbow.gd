class_name EnemyCrossbow
extends CharacterBody2D

## Medieval Crossbow Sniper: Crossbow Marksman (Milestone 5).
## Stations on castle platforms, aims with a red laser telegraph, and fires CrossbowBolt.

signal enemy_died(enemy: EnemyCrossbow)

const CROSSBOW_BOLT_SCENE = preload("res://scenes/combat/crossbow_bolt.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var detection_range: float = 220.0
@export var reload_cooldown: float = 2.4
@export var aim_duration: float = 0.55

enum XBowState { IDLE, AIMING, FIRE, RELOAD, HURT, DIE }
var current_state: XBowState = XBowState.IDLE

var current_health: int = 3
var facing_direction: int = -1
var player_ref: Node2D

var state_timer: float = 0.0
var cooldown_timer: float = 0.0
var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
	current_health = max_health
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

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

	if not is_on_floor():
		velocity.y += 900.0 * delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match current_state:
		XBowState.IDLE:
			_update_idle(delta)
		XBowState.AIMING:
			_update_aiming(delta)
		XBowState.RELOAD:
			_update_reload(delta)
		XBowState.HURT:
			_update_hurt(delta)

	move_and_slide()

func _update_idle(_delta: float) -> void:
	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= detection_range:
			var dir = 1 if player_ref.global_position.x > global_position.x else -1
			set_facing(dir)
			if cooldown_timer <= 0.0:
				current_state = XBowState.AIMING
				state_timer = aim_duration

func _update_aiming(delta: float) -> void:
	state_timer -= delta
	if player_ref:
		var dir = 1 if player_ref.global_position.x > global_position.x else -1
		set_facing(dir)

	# Telegraph aim warning
	var pulse = (sin(state_timer * 25.0) + 1.0) * 0.5
	visual_root.modulate = Color(1.3, 0.7 + pulse * 0.5, 0.4)

	if state_timer <= 0.0:
		visual_root.modulate = Color.WHITE
		_fire_bolt()

func _fire_bolt() -> void:
	var bolt = CROSSBOW_BOLT_SCENE.instantiate() as CrossbowBolt
	bolt.global_position = global_position + Vector2(facing_direction * 14.0, -14.0)
	bolt.direction = Vector2(facing_direction, 0.0)
	bolt.caster = self
	get_parent().add_child(bolt)

	current_state = XBowState.RELOAD
	state_timer = 0.5
	cooldown_timer = reload_cooldown

func _update_reload(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = XBowState.IDLE

func _update_hurt(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	if state_timer <= 0.0:
		current_state = XBowState.IDLE

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
	spark.global_position = global_position + Vector2(0, -14)
	spark.is_heavy = is_finisher
	get_parent().add_child(spark)

	if current_health <= 0:
		_die(knockback)
	else:
		current_state = XBowState.HURT
		state_timer = 0.3
		velocity = knockback * 0.4

func _die(knockback: Vector2) -> void:
	is_dead = true
	current_state = XBowState.DIE
	velocity = knockback * 0.5
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	enemy_died.emit(self)
	visual_root.modulate = Color(0.4, 0.3, 0.3, 0.8)

	await get_tree().create_timer(1.2).timeout
	queue_free()

func _draw() -> void:
	# Crisp Procedural Pixel Art: Crossbow Marksman
	var col_leather = Color(0.42, 0.30, 0.20)
	var col_steel = Color(0.60, 0.64, 0.68)
	var col_tunic = Color(0.20, 0.32, 0.45)

	# Legs
	draw_rect(Rect2(-5, -8, 4, 8), col_leather)
	draw_rect(Rect2(1, -8, 4, 8), col_leather)

	# Body & Brigandine
	draw_rect(Rect2(-6, -20, 12, 12), col_tunic)
	draw_rect(Rect2(-4, -18, 8, 8), col_leather.darkened(0.2))

	# Kettle Hat & Face
	draw_rect(Rect2(-4, -26, 8, 6), Color(0.8, 0.65, 0.5)) # Face
	draw_line(Vector2(-8, -26), Vector2(8, -26), col_steel, 2.0) # Brim
	draw_rect(Rect2(-5, -30, 10, 4), col_steel) # Dome

	# Crossbow & Aim Line
	draw_rect(Rect2(4, -16, 12, 4), Color(0.35, 0.22, 0.12)) # Tiller
	draw_line(Vector2(12, -22), Vector2(12, -10), col_steel, 2.0) # Bow prod

	if current_state == XBowState.AIMING:
		# Laser sight aim telegraph
		draw_line(Vector2(16, -14), Vector2(160, -14), Color(1.0, 0.2, 0.2, 0.6), 1.0)
