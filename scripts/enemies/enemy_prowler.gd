class_name EnemyProwler
extends CharacterBody2D

## Original Prehistoric Beast: Crested Prowler.
## Patrols, detects player, coordinates attacks, receives knockback/juggle, and dies.

signal enemy_died(enemy: EnemyProwler)

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var patrol_speed: float = 40.0
@export var chase_speed: float = 80.0
@export var lunge_speed: float = 140.0
@export var detection_range: float = 120.0
@export var attack_range: float = 30.0
@export var gravity: float = 900.0

@onready var state_machine: StateMachine = $StateMachine
@onready var visual_root: Node2D = $VisualRoot
@onready var visuals: Node2D = $VisualRoot/ProwlerVisuals
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay

var current_health: int = 3
var facing_direction: int = -1
var player_ref: Player
var has_attack_token: bool = false
var air_juggle_count: int = 0
const MAX_AIR_JUGGLES: int = 3

var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self
	hitbox.damage = 1
	hitbox.knockback_force = 120.0
	hitbox.hitstop_frames = 3
	set_facing(facing_direction)

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			visual_root.modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if hitstop_timer > 0.0:
		return

	# Locate player if needed
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Player

func set_facing(dir: int) -> void:
	if dir == 0:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)
	wall_ray.target_position.x = 16.0 * float(dir)
	ledge_ray.position.x = 12.0 * float(dir)
	hitbox.position.x = abs(hitbox.position.x) * float(dir)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func distance_to_player() -> float:
	if not player_ref or not is_instance_valid(player_ref):
		return 9999.0
	return global_position.distance_to(player_ref.global_position)

func can_see_player() -> bool:
	if not player_ref or not is_instance_valid(player_ref) or player_ref.is_dead:
		return false
	var dist = distance_to_player()
	if dist > detection_range:
		return false
	# Check horizontal facing alignment (don't detect if player is completely behind while patrol)
	var dir_to_player = 1 if player_ref.global_position.x >= global_position.x else -1
	return dir_to_player == facing_direction or dist < 40.0

func apply_hitstop(frames: int) -> void:
	hitstop_timer = float(frames) / 60.0

func flash_white(duration: float = 0.08) -> void:
	flash_timer = duration
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	current_health = max(0, current_health - dmg)
	apply_hitstop(hitstop_frames)
	flash_white(0.1)

	# Spawn hit spark
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -10)
	spark.is_heavy = is_finisher
	get_parent().add_child(spark)

	# Air juggle handling (Section 5a)
	if not is_on_floor():
		air_juggle_count += 1
		if air_juggle_count > MAX_AIR_JUGGLES:
			# Prevent infinite juggling: knock down to ground faster
			knockback.y = max(knockback.y, 100.0)

	if has_attack_token:
		AttackTokenManager.release_attack_token()
		has_attack_token = false

	if current_health <= 0:
		is_dead = true
		enemy_died.emit(self)
		state_machine.transition_to("die", {"knockback": knockback})
	else:
		state_machine.transition_to("hurt", {"knockback": knockback})
