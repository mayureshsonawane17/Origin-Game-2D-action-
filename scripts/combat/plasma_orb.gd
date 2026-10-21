class_name PlasmaOrb
extends Area2D

## Seeking plasma projectile fired by FUT-02 Sentinel Swarm-Mind.
## Curves toward player position before detonating in a burst of ion energy.

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null
var speed: float = 140.0
var turn_rate: float = 3.5
var lifetime: float = 4.0
var damage: int = 2
var anim_timer: float = 0.0

func _ready() -> void:
	collision_layer = 16 # Enemy attack layer
	collision_mask = 9   # Player hurtbox (8) + World (1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	anim_timer += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_detonate()
		return

	if target and is_instance_valid(target):
		var target_pos = target.global_position + Vector2(0, -12)
		var desired_dir = (target_pos - global_position).normalized()
		var current_dir = velocity.normalized() if velocity.length_squared() > 1.0 else desired_dir
		var new_dir = current_dir.slerp(desired_dir, turn_rate * delta)
		velocity = new_dir * speed
	elif velocity.length_squared() < 1.0:
		velocity = Vector2(-1, 0) * speed

	global_position += velocity * delta
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		area.receive_hit(damage, velocity.normalized() * 100.0, 4, self, false)
		_detonate()

func _on_body_entered(body: Node2D) -> void:
	if body is TileMap or body is StaticBody2D:
		_detonate()

func _detonate() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.1, 0.9, 0.8, 1.0) # Ion cyan
	get_parent().add_child(spark)
	if SoundManager:
		SoundManager.play_sfx("magic_cast", 1.4)
	queue_free()

func _draw() -> void:
	var pulse = sin(anim_timer * 14.0) * 2.0
	var col_glow = Color(0.1, 0.8, 1.0, 0.4)
	var col_core = Color(0.2, 0.95, 0.85)

	# Plasma aura
	draw_circle(Vector2.ZERO, 9.0 + pulse, col_glow)
	draw_circle(Vector2.ZERO, 5.0, col_core)
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)

	# Trailing ionization motes
	var trail_dir = -velocity.normalized()
	draw_circle(trail_dir * 6.0, 2.0, col_glow)
	draw_circle(trail_dir * 11.0, 1.0, col_glow)
