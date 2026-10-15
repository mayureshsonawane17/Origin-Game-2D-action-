class_name FallingAirstrikeMissile
extends Area2D

## Guided airstrike rocket hazard called down during Modern Era Boss Phase 2.

@export var fall_speed: float = 260.0
@export var damage: int = 1

var target_ground_y: float = 230.0
var exhaust_timer: float = 0.0

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	exhaust_timer += delta * 16.0
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
	spark.spark_color = Color(1.0, 0.45, 0.1, 1.0)
	spark.is_heavy = true
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Military cruise missile
	var col_missile = Color(0.20, 0.22, 0.25)
	var col_tip = Color(0.9, 0.2, 0.2)
	var col_flame = Color(1.0, 0.6, 0.1, 0.8)

	draw_rect(Rect2(-3, -12, 6, 18), col_missile)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, 6), Vector2(0, 12), Vector2(3, 6)]), col_tip)
	# Tail fins
	draw_line(Vector2(-5, -10), Vector2(-3, -6), col_missile, 2.0)
	draw_line(Vector2(5, -10), Vector2(3, -6), col_missile, 2.0)
	# Exhaust fire
	draw_circle(Vector2(0, -14), 2.5 + sin(exhaust_timer) * 0.8, col_flame)
