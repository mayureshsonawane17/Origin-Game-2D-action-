class_name FallingSiegeEmber
extends Area2D

## Falling flaming trebuchet ember hazard during Medieval Era Boss Phase 2.

@export var fall_speed: float = 220.0
@export var damage: int = 1

var target_ground_y: float = 230.0
var flicker_timer: float = 0.0

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	flicker_timer += delta * 12.0
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
	# Flaming catapult burning pitch ball
	var col_fire = Color(1.0, 0.35 + sin(flicker_timer) * 0.15, 0.1)
	var col_core = Color(1.0, 0.9, 0.4)
	draw_circle(Vector2.ZERO, 5.0, col_fire)
	draw_circle(Vector2.ZERO, 2.5, col_core)
	draw_rect(Rect2(-2, -8, 4, 4), col_fire.darkened(0.2)) # Trailing flame
