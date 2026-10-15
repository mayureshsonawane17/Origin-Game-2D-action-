class_name ModernCityPlatform
extends StaticBody2D

## Procedural pixel art reinforced concrete & neon rooftop platform for Chapter 5 (Modern Era).

@export var platform_size: Vector2 = Vector2(160, 40)
@export var has_neon_edge: bool = true
@export var neon_color: Color = Color(0.20, 0.75, 1.0)

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
	# Dark reinforced skyscraper concrete slab
	var col_concrete = Color(0.20, 0.22, 0.25)
	var col_top_edge = Color(0.35, 0.38, 0.42)
	var col_shadow = Color(0.10, 0.11, 0.13)

	# Main slab
	draw_rect(Rect2(Vector2.ZERO, platform_size), col_concrete)

	# Top edge asphalt / metal lip
	draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), col_top_edge)
	# Bottom shadow line
	draw_rect(Rect2(Vector2(0, platform_size.y - 3.0), Vector2(platform_size.x, 3.0)), col_shadow)

	# Concrete panel expansion seams
	var panel_w = 32.0
	var count = int(ceil(platform_size.x / panel_w))
	for i in range(1, count):
		var x = i * panel_w
		draw_line(Vector2(x, 3.0), Vector2(x, platform_size.y - 3.0), col_shadow, 1.0)

	# Glowing Neon Under-lip or Edge Light
	if has_neon_edge and platform_size.y >= 20.0:
		# Glowing neon tube line
		draw_line(Vector2(4.0, platform_size.y - 1.5), Vector2(platform_size.x - 4.0, platform_size.y - 1.5), neon_color, 2.0)
		draw_line(Vector2(6.0, platform_size.y - 1.5), Vector2(platform_size.x - 6.0, platform_size.y - 1.5), Color.WHITE, 1.0)
