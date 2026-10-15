class_name FortressObsidianPlatform
extends StaticBody2D

## Procedural pixel art crystalline obsidian platform for Chapter 7: The Fortress of the Gemstone.

@export var platform_size: Vector2 = Vector2(160, 40)
@export var crystal_vein_color: Color = Color(0.85, 0.15, 0.95)

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
	# Deep dark obsidian slab
	var col_obsidian = Color(0.06, 0.04, 0.10)
	var col_facet = Color(0.14, 0.10, 0.22)
	var col_edge = Color(0.24, 0.16, 0.35)

	# Main slab
	draw_rect(Rect2(Vector2.ZERO, platform_size), col_obsidian)

	# Crystalline faceted facets
	var step = 32.0
	var count = int(ceil(platform_size.x / step))
	for i in range(count):
		var x = i * step
		draw_line(Vector2(x, 2.0), Vector2(x + step * 0.5, platform_size.y - 2.0), col_facet, 1.0)
		draw_line(Vector2(x + step * 0.5, platform_size.y - 2.0), Vector2(x + step, 2.0), col_facet, 1.0)

	# Glowing crystal veins
	draw_line(Vector2(2.0, 1.5), Vector2(platform_size.x - 2.0, 1.5), crystal_vein_color, 2.0)
	draw_line(Vector2(6.0, 1.5), Vector2(platform_size.x - 6.0, 1.5), Color.WHITE, 1.0)
	draw_line(Vector2(4.0, platform_size.y - 1.5), Vector2(platform_size.x - 4.0, platform_size.y - 1.5), crystal_vein_color, 1.5)
