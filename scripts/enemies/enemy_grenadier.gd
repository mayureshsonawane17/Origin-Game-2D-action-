class_name EnemyGrenadier
extends CharacterBody2D

## Industrial Era Ranged Bombadier: Gas Mask Trench Grenadier.
## Lobs toxic canisters in ballistic arcs, covers area in poisonous fumes,
## and conducts tactical back-dash retreats when player gets within close melee range.

signal enemy_died(enemy: EnemyGrenadier)

const TOXIC_GRENADE_SCENE = preload("res://scenes/combat/toxic_grenade.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var detection_range: float = 230.0
@export var throw_cooldown: float = 2.3
@export var aim_duration: float = 0.50

enum GrenadierState { IDLE, AIMING, THROW, RELOAD, RETREAT, HURT, DIE }
var current_state: GrenadierState = GrenadierState.IDLE

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
		GrenadierState.IDLE:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dist = global_position.distance_to(player_ref.global_position)
				if dist <= detection_range and cooldown_timer <= 0.0:
					var dx = player_ref.global_position.x - global_position.x
					set_facing(1 if dx > 0 else -1)
					current_state = GrenadierState.AIMING
					state_timer = aim_duration
		GrenadierState.AIMING:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dx = player_ref.global_position.x - global_position.x
				var dist = abs(dx)
				set_facing(1 if dx > 0 else -1)

				if dist < 45.0:
					current_state = GrenadierState.RETREAT
					state_timer = 0.35
					velocity.x = -facing_direction * 115.0
					return

			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GrenadierState.THROW
				_throw_grenade()
				state_timer = 0.25
		GrenadierState.THROW:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GrenadierState.RELOAD
				cooldown_timer = throw_cooldown
				state_timer = throw_cooldown
		GrenadierState.RELOAD:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GrenadierState.IDLE
		GrenadierState.RETREAT:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GrenadierState.IDLE
		GrenadierState.HURT:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GrenadierState.IDLE

	move_and_slide()

func set_facing(dir: int) -> void:
	facing_direction = dir
	queue_redraw()

func _throw_grenade() -> void:
	var grenade = TOXIC_GRENADE_SCENE.instantiate() as ToxicGrenade
	grenade.caster = self
	var launch_vx = facing_direction * 150.0
	if player_ref and is_instance_valid(player_ref):
		var dx = player_ref.global_position.x - global_position.x
		launch_vx = clampf(dx * 1.6, -240.0, 240.0)

	grenade.velocity = Vector2(launch_vx, -230.0)
	grenade.global_position = global_position + Vector2(facing_direction * 12.0, -18.0)
	get_parent().add_child(grenade)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	current_health -= dmg
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -14)
	spark.spark_color = Color(0.4, 0.9, 0.4)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		current_state = GrenadierState.HURT
		state_timer = 0.25
		velocity = knockback * 0.6
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = GrenadierState.DIE
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
	var col_coat = Color.WHITE if is_flashing else Color(0.35, 0.32, 0.28)
	var col_mask = Color.WHITE if is_flashing else Color(0.20, 0.22, 0.24)
	var col_goggles = Color.WHITE if is_flashing else Color(0.35, 0.95, 0.45)
	var col_canister = Color.WHITE if is_flashing else Color(0.70, 0.65, 0.25)

	var f = float(facing_direction)

	# Heavy trenchcoat & boots
	draw_rect(Rect2(-7, -14, 14, 14), col_coat)
	draw_rect(Rect2(-6, -24, 12, 10), col_coat)
	# Bandolier with mini canisters
	draw_line(Vector2(-f * 5, -24), Vector2(f * 5, -14), col_canister, 2.0)

	# Gas mask snout and head
	draw_circle(Vector2(0, -28), 5.0, col_mask)
	draw_rect(Rect2(f * 2, -29, 4, 4), col_mask) # Filter canister snout
	# Glowing green goggle lens
	draw_circle(Vector2(f * 2, -29), 2.0, col_goggles)

	# Arm holding canister
	if current_state == GrenadierState.AIMING:
		# Cocked throwing arm
		draw_line(Vector2(-f * 4, -22), Vector2(-f * 10, -28), col_coat, 2.5)
		draw_circle(Vector2(-f * 10, -28), 3.0, Color(0.4, 0.9, 0.4))
	elif current_state == GrenadierState.THROW:
		# Extended throw forward
		draw_line(Vector2(0, -22), Vector2(f * 12, -26), col_coat, 2.5)
	else:
		# Idle arm
		draw_line(Vector2(f * 2, -22), Vector2(f * 6, -16), col_coat, 2.0)
