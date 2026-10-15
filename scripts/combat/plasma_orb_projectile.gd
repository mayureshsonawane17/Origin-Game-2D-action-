class_name PlasmaOrbProjectile
extends Area2D

## High-energy plasma orb projectile fired by Futuristic cybernetic units.

@export var speed: float = 240.0
@export var damage: int = 1
@export var max_lifetime: float = 2.4

var direction: Vector2 = Vector2.LEFT
var lifetime: float = 0.0
var caster: Node2D

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16 # Hitbox
	collision_mask = 9   # World (1) and Player Hurtbox (8)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return

	global_position += direction * speed * delta
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D or body is TileMap:
		_impact()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner != caster:
		area.receive_hit(damage, direction * 120.0, 3, caster, false)
		_impact()

func _impact() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.1, 0.95, 1.0, 1.0)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Concentric pulsing cyan and magenta plasma orb
	var pulse = sin(lifetime * 16.0) * 1.5
	draw_circle(Vector2.ZERO, 6.5 + pulse, Color(0.1, 0.85, 1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.5 + pulse * 0.5, Color(0.85, 0.15, 0.95, 0.8))
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
