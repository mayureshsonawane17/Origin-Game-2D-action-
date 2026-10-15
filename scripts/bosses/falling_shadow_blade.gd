class_name FallingShadowBlade
extends Area2D

## Falling spectral shadow blade hazard summoned during Historical Era Boss Phase 2.

@export var fall_speed: float = 240.0
@export var damage: int = 1

var target_ground_y: float = 230.0
var spin_timer: float = 0.0

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	spin_timer += delta * 14.0
	queue_redraw()

	if position.y >= target_ground_y:
		_impact()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).hurtbox.receive_hit(damage, Vector2(0.0, 50.0), 3, self, false)
		_impact()
	elif body is StaticBody2D:
		_impact()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		(area as Hurtbox).receive_hit(damage, Vector2(0.0, 50.0), 3, self, false)
		_impact()

func _impact() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.9, 0.2, 0.35, 1.0)
	spark.is_heavy = true
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Spectral crimson & shadow blade falling tip-down
	var col_blade = Color(0.95, 0.25, 0.35, 0.9)
	var col_glow = Color(0.6, 0.1, 0.2, 0.5)

	draw_line(Vector2(0, -12), Vector2(0, 10), col_blade, 2.5)
	draw_line(Vector2(-4, -6), Vector2(4, -6), col_blade, 2.0)
	draw_circle(Vector2(0, -12), 2.0, col_glow)
