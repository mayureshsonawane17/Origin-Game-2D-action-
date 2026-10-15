class_name FuturisticSpirePlatform
extends StaticBody2D

## Procedural pixel art digital hardlight & cyber-glass platform for Chapter 6 (Futuristic Era).

@export var platform_size: Vector2 = Vector2(160, 40)
@export var has_hardlight_glow: bool = true
@export var energy_color: Color = Color(0.1, 0.95, 1.0)
@export var circuit_color: Color = Color(0.9, 0.15, 0.95)

var collision_shape: CollisionShape2D

func _ready() -> void:
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

	var rect_shape = RectangleShape2D.new()
	rect_shape.size = platform_size
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(platform_size.x * 0.5, platform_size.y * 0.5)
	queue_redraw()

func _draw() -> void:
	# Deep dark composite chassis
	var col_slab = Color(0.06, 0.08, 0.12)
	var col_top = Color(0.15, 0.20, 0.28)
	var col_shadow = Color(0.03, 0.04, 0.06)

	# Main slab
	draw_rect(Rect2(Vector2.ZERO, platform_size), col_slab)

	# Top edge cyber rail
	draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), col_top)
	draw_rect(Rect2(Vector2(0, platform_size.y - 3.0), Vector2(platform_size.x, 3.0)), col_shadow)

	# Circuit traces across the slab
	var step = 40.0
	var count = int(ceil(platform_size.x / step))
	for i in range(1, count):
		var x = i * step
		draw_line(Vector2(x, 4.0), Vector2(x, platform_size.y - 4.0), circuit_color, 1.0)
		draw_circle(Vector2(x, platform_size.y * 0.5), 2.0, circuit_color)

	# Glowing Hardlight Edge
	if has_hardlight_glow and platform_size.y >= 20.0:
		draw_line(Vector2(2.0, 1.5), Vector2(platform_size.x - 2.0, 1.5), energy_color, 2.0)
		draw_line(Vector2(4.0, platform_size.y - 1.5), Vector2(platform_size.x - 4.0, platform_size.y - 1.5), energy_color, 2.0)
		draw_line(Vector2(6.0, 1.5), Vector2(platform_size.x - 6.0, 1.5), Color.WHITE, 1.0)
