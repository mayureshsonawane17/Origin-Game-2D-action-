class_name FallingStalactite
extends Area2D

## Falling rock stalactite hazard during Era Boss Phase 2.

@export var fall_speed: float = 240.0
@export var damage: int = 1

var target_ground_y: float = 230.0

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3 # Player and terrain
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y >= target_ground_y:
		# Shatter on ground impact
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).hurtbox.receive_hit(damage, Vector2(0.0, 60.0), 3, self, false)
		queue_free()
	elif body.name.begins_with("Ground") or body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		(area as Hurtbox).receive_hit(damage, Vector2(0.0, 60.0), 3, self, false)
		queue_free()

func _draw() -> void:
	var col_rock = Color(0.35, 0.32, 0.28)
	var col_tip = Color(0.25, 0.22, 0.18)
	var pts = PackedVector2Array([
		Vector2(-6, -16),
		Vector2(6, -16),
		Vector2(0, 8)
	])
	draw_colored_polygon(pts, col_rock)
	# Sharp point
	draw_rect(Rect2(-1, 4, 2, 4), col_tip)
