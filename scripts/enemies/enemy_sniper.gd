class_name EnemySniper
extends CharacterBody2D

## Modern Era Urban Sniper: Tactical SWAT Marksman.
## Stations on skyscraper ledges, targets with a red optical laser line,
## fires high-velocity supersonic SniperTracerBullet, and conducts tactical retreats.

signal enemy_died(enemy: EnemySniper)

const SNIPER_TRACER_SCENE = preload("res://scenes/combat/sniper_tracer_bullet.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var detection_range: float = 250.0
@export var reload_cooldown: float = 2.1
@export var aim_duration: float = 0.48

enum SniperState { IDLE, AIMING, FIRE, RELOAD, RETREAT, HURT, DIE }
var current_state: SniperState = SniperState.IDLE

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

	if not player_ref or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match current_state:
		SniperState.IDLE:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dist = global_position.distance_to(player_ref.global_position)
				if dist <= detection_range and cooldown_timer <= 0.0:
					var dx = player_ref.global_position.x - global_position.x
					set_facing(1 if dx > 0 else -1)
					current_state = SniperState.AIMING
					state_timer = aim_duration
		SniperState.AIMING:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dx = player_ref.global_position.x - global_position.x
				var dist = abs(dx)
				set_facing(1 if dx > 0 else -1)

				if dist < 45.0:
					current_state = SniperState.RETREAT
					state_timer = 0.35
					velocity.x = -facing_direction * 120.0
					return

			state_timer -= delta
			if state_timer <= 0.0:
				current_state = SniperState.FIRE
				_fire_bullet()
				state_timer = 0.22
		SniperState.FIRE:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = SniperState.RELOAD
				cooldown_timer = reload_cooldown
				state_timer = reload_cooldown
		SniperState.RELOAD:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = SniperState.IDLE
		SniperState.RETREAT:
			velocity.x = move_toward(velocity.x, 0, 320.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = SniperState.IDLE
		SniperState.HURT:
			velocity.x = move_toward(velocity.x, 0, 320.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = SniperState.IDLE

	move_and_slide()

func set_facing(dir: int) -> void:
	facing_direction = dir
	queue_redraw()

func _fire_bullet() -> void:
	var bullet = SNIPER_TRACER_SCENE.instantiate() as SniperTracerBullet
	bullet.caster = self
	bullet.direction = Vector2(facing_direction, 0.0)
	bullet.global_position = global_position + Vector2(facing_direction * 18.0, -14.0)
	get_parent().add_child(bullet)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = bullet.global_position
	spark.spark_color = Color(0.2, 0.8, 1.0)
	get_parent().add_child(spark)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	current_health -= dmg
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(1.0, 0.3, 0.3)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		current_state = SniperState.HURT
		state_timer = 0.22
		velocity = knockback * 0.6
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = SniperState.DIE
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
	var col_suit = Color.WHITE if is_flashing else Color(0.15, 0.16, 0.20)
	var col_vest = Color.WHITE if is_flashing else Color(0.10, 0.11, 0.14)
	var col_visor = Color.WHITE if is_flashing else Color(0.2, 0.85, 1.0)
	var col_rifle = Color.WHITE if is_flashing else Color(0.22, 0.24, 0.28)

	var f = float(facing_direction)

	# Tactical fatigues
	draw_rect(Rect2(-6, -14, 12, 14), col_suit)
	draw_rect(Rect2(-6, -22, 12, 9), col_vest)
	# Balaclava Head
	draw_circle(Vector2(0, -26), 4.5, col_suit)
	draw_rect(Rect2(f * 1, -27, 4, 2), col_visor)

	# Long-barreled Sniper Rifle with Scope
	var rifle_y = -14.0
	draw_line(Vector2(-f * 4, rifle_y), Vector2(f * 18, rifle_y), col_rifle, 2.5)
	# Scope on top
	draw_rect(Rect2(f * 2, rifle_y - 4, 8, 3), Color(0.35, 0.38, 0.42))

	# Aiming Laser
	if current_state == SniperState.AIMING:
		var alpha = clampf(1.0 - (state_timer / aim_duration), 0.35, 1.0)
		draw_dashed_line(Vector2(f * 18, rifle_y), Vector2(f * detection_range, rifle_y), Color(1.0, 0.15, 0.15, alpha), 1.0, 4.0)
