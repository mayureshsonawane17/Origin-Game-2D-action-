class_name EnemyGunner
extends CharacterBody2D

## Historical Era Matchlock Rifleman: Tanegashima Gunner.
## Stations on platforms, aims with a fiery match cord telegraph, fires high-speed MatchlockBullet,
## and performs tactical retreat back-dashes if player gets within close melee range.

signal enemy_died(enemy: EnemyGunner)

const MATCHLOCK_BULLET_SCENE = preload("res://scenes/combat/matchlock_bullet.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var max_health: int = 3
@export var detection_range: float = 240.0
@export var reload_cooldown: float = 2.2
@export var aim_duration: float = 0.50

enum GunnerState { IDLE, AIMING, FIRE, RELOAD, RETREAT, HURT, DIE }
var current_state: GunnerState = GunnerState.IDLE

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
		GunnerState.IDLE:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dist = global_position.distance_to(player_ref.global_position)
				if dist <= detection_range and cooldown_timer <= 0.0:
					var dx = player_ref.global_position.x - global_position.x
					set_facing(1 if dx > 0 else -1)
					current_state = GunnerState.AIMING
					state_timer = aim_duration
		GunnerState.AIMING:
			velocity.x = 0
			if player_ref and is_instance_valid(player_ref):
				var dx = player_ref.global_position.x - global_position.x
				var dist = abs(dx)
				set_facing(1 if dx > 0 else -1)

				# Close range panic retreat
				if dist < 45.0:
					current_state = GunnerState.RETREAT
					state_timer = 0.35
					velocity.x = -facing_direction * 110.0
					return

			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GunnerState.FIRE
				_fire_bullet()
				state_timer = 0.25
		GunnerState.FIRE:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GunnerState.RELOAD
				cooldown_timer = reload_cooldown
				state_timer = reload_cooldown
		GunnerState.RELOAD:
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GunnerState.IDLE
		GunnerState.RETREAT:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GunnerState.IDLE
		GunnerState.HURT:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = GunnerState.IDLE

	move_and_slide()

func set_facing(dir: int) -> void:
	facing_direction = dir
	queue_redraw()

func _fire_bullet() -> void:
	var bullet = MATCHLOCK_BULLET_SCENE.instantiate() as MatchlockBullet
	bullet.caster = self
	bullet.direction = Vector2(facing_direction, 0.0)
	bullet.global_position = global_position + Vector2(facing_direction * 18.0, -14.0)
	get_parent().add_child(bullet)

	# Gunpowder flash & smoke
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = bullet.global_position
	spark.spark_color = Color(1.0, 0.8, 0.3)
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
		current_state = GunnerState.HURT
		state_timer = 0.25
		velocity = knockback * 0.6
	queue_redraw()

func _die() -> void:
	is_dead = true
	current_state = GunnerState.DIE
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
	var col_skin = Color.WHITE if is_flashing else Color(0.92, 0.78, 0.65)
	var col_armor = Color.WHITE if is_flashing else Color(0.35, 0.15, 0.15)
	var col_robe = Color.WHITE if is_flashing else Color(0.20, 0.22, 0.25)
	var col_hat = Color.WHITE if is_flashing else Color(0.18, 0.18, 0.20)
	var col_gun = Color.WHITE if is_flashing else Color(0.45, 0.30, 0.18)
	var col_barrel = Color.WHITE if is_flashing else Color(0.75, 0.65, 0.30)

	var f = float(facing_direction)

	# Robe & hakama trousers
	draw_rect(Rect2(-6, -14, 12, 14), col_robe)
	# Lacquered chest cuirass (do)
	draw_rect(Rect2(-6, -22, 12, 9), col_armor)
	# Head
	draw_circle(Vector2(0, -25), 4.5, col_skin)
	# Jingasa conical war hat
	var hat_pts = PackedVector2Array([
		Vector2(-10, -27),
		Vector2(0, -32),
		Vector2(10, -27)
	])
	draw_colored_polygon(hat_pts, col_hat)

	# Tanegashima Matchlock Rifle
	var gun_y = -14.0
	# Wooden stock
	draw_line(Vector2(-f * 4, gun_y), Vector2(f * 12, gun_y), col_gun, 2.5)
	# Brass long barrel
	draw_line(Vector2(f * 6, gun_y), Vector2(f * 18, gun_y), col_barrel, 1.8)

	# Aiming telegraph laser line & match cord spark
	if current_state == GunnerState.AIMING:
		# Glowing red match cord
		draw_circle(Vector2(f * 2, gun_y - 2), 2.0, Color(1.0, 0.4, 0.1, 0.9))
		# Aiming red trajectory line
		var alpha = clampf(1.0 - (state_timer / aim_duration), 0.3, 1.0)
		var aim_color = Color(1.0, 0.2, 0.2, alpha)
		draw_dashed_line(Vector2(f * 18, gun_y), Vector2(f * detection_range, gun_y), aim_color, 1.0, 4.0)
