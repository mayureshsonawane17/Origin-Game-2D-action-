class_name EnemyCyberDrone
extends CharacterBody2D

## Futuristic Era Aerial Unit: Hovering Cyber Drone.
## Floats using anti-grav repulsors, locks on with cyan targeting reticle,
## fires PlasmaOrbProjectile, and crashes to ground in EMP overload when parried (2x damage).

signal enemy_died(enemy: EnemyCyberDrone)

const PLASMA_ORB_SCENE = preload("res://scenes/combat/plasma_orb_projectile.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var hover_speed: float = 55.0
@export var detection_range: float = 240.0
@export var attack_range: float = 160.0
@export var fire_cooldown: float = 2.0

enum DroneState { HOVER, AIMING, FIRE, EMP_STAGGER, HURT, DIE }
var current_state: DroneState = DroneState.HOVER

var current_health: int = 3
var facing_direction: int = -1
var player_ref: Node2D

var hover_timer: float = 0.0
var state_timer: float = 0.0
var cooldown_timer: float = 0.0
var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false
var is_staggered: bool = false
var base_altitude_y: float = 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	current_health = max_health
	base_altitude_y = global_position.y
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self
	hitbox.damage = 1
	hitbox.monitoring = false
	set_facing(facing_direction)
	queue_redraw()

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	hover_timer += delta * 4.0
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			queue_redraw()

	queue_redraw()

func _physics_process(delta: float) -> void:
	if hitstop_timer > 0.0 or is_dead:
		if is_dead:
			velocity.y += 600.0 * delta
			move_and_slide()
		return

	if not player_ref or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match current_state:
		DroneState.HOVER:
			# Anti-grav undulating hover
			var target_y = base_altitude_y + sin(hover_timer) * 8.0
			velocity.y = (target_y - global_position.y) * 4.0

			if player_ref and is_instance_valid(player_ref):
				var dist = global_position.distance_to(player_ref.global_position)
				var dx = player_ref.global_position.x - global_position.x
				set_facing(1 if dx > 0 else -1)

				if dist <= attack_range and cooldown_timer <= 0.0:
					velocity.x = 0
					current_state = DroneState.AIMING
					state_timer = 0.50 # Targeting laser charge
				elif dist <= detection_range:
					velocity.x = facing_direction * hover_speed
				else:
					velocity.x = 0
			else:
				velocity.x = 0

		DroneState.AIMING:
			velocity = Vector2.ZERO
			if player_ref and is_instance_valid(player_ref):
				var dx = player_ref.global_position.x - global_position.x
				set_facing(1 if dx > 0 else -1)

			state_timer -= delta
			if state_timer <= 0.0:
				current_state = DroneState.FIRE
				_fire_plasma_orb()
				state_timer = 0.20

		DroneState.FIRE:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0:
				cooldown_timer = fire_cooldown
				current_state = DroneState.HOVER

		DroneState.EMP_STAGGER:
			# Crashed to ground by EMP shock
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			velocity.y += 800.0 * delta
			state_timer -= delta
			if state_timer <= 0.0:
				is_staggered = false
				current_state = DroneState.HOVER
				base_altitude_y = global_position.y - 40.0

		DroneState.HURT:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = DroneState.HOVER

	move_and_slide()

func set_facing(dir: int) -> void:
	facing_direction = dir
	queue_redraw()

func _fire_plasma_orb() -> void:
	var orb = PLASMA_ORB_SCENE.instantiate() as PlasmaOrbProjectile
	orb.caster = self
	orb.direction = Vector2(facing_direction, 0.0)
	orb.global_position = global_position + Vector2(facing_direction * 14.0, 0.0)
	get_parent().add_child(orb)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = orb.global_position
	spark.spark_color = Color(0.1, 0.9, 1.0)
	get_parent().add_child(spark)

func stagger(duration: float = 1.5) -> void:
	is_staggered = true
	current_state = DroneState.EMP_STAGGER
	state_timer = duration
	flash_timer = 0.2
	queue_redraw()

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop: int, _attacker: Node, _is_finisher: bool) -> void:
	if is_dead:
		return

	var final_dmg = dmg * 2 if is_staggered else dmg
	current_health -= final_dmg
	hitstop_timer = float(hitstop) * (1.0 / 60.0)
	flash_timer = 0.15

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.1, 0.9, 1.0) if not is_staggered else Color(1.0, 0.2, 0.3)
	get_parent().add_child(spark)

	if current_health <= 0:
		_die()
	else:
		if not is_staggered:
			current_state = DroneState.HURT
			state_timer = 0.20
			velocity = knockback * 0.5
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = DroneState.DIE
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
	var col_chassis = Color.WHITE if is_flashing else Color(0.12, 0.14, 0.18)
	var col_trim = Color.WHITE if is_flashing else Color(0.25, 0.28, 0.35)
	var col_eye = Color.WHITE if is_flashing else (Color(1.0, 0.2, 0.3) if is_staggered else Color(0.1, 0.95, 1.0))
	var col_energy = Color(0.1, 0.85, 1.0, 0.6)

	var f = float(facing_direction)

	# Main aerodynamic chassis
	draw_circle(Vector2.ZERO, 9.0, col_chassis)
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 16, col_trim, 1.5)

	# Optical eye sensor
	draw_circle(Vector2(f * 4, 0), 3.5, col_eye)

	# Twin anti-grav thruster wings
	draw_line(Vector2(0, -9), Vector2(-f * 8, -14), col_trim, 2.5)
	draw_line(Vector2(0, 9), Vector2(-f * 8, 14), col_trim, 2.5)

	# Thruster plasma exhaust glows
	if not is_staggered:
		draw_circle(Vector2(-f * 8, -14), 2.5, col_energy)
		draw_circle(Vector2(-f * 8, 14), 2.5, col_energy)

	# Targeting Laser
	if current_state == DroneState.AIMING:
		var alpha = clampf(1.0 - (state_timer / 0.50), 0.3, 1.0)
		draw_dashed_line(Vector2(f * 8, 0), Vector2(f * attack_range, 0), Color(0.1, 0.9, 1.0, alpha), 1.0, 4.0)

	if is_staggered:
		# EMP electric spark arcs
		draw_arc(Vector2.ZERO, 14.0, 0, TAU, 8, Color(0.1, 0.9, 1.0, 0.8), 2.0)
