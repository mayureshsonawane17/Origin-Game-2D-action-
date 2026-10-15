class_name HistoricalShrinePlatform
extends StaticBody2D

## Procedural pixel art Japanese shrine / pagoda wooden platform for Chapter 3 (Historical Era).

@export var platform_size: Vector2 = Vector2(160, 40)
@export var has_torii_trim: bool = true

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
	# Dark polished cedar timber
	var col_wood = Color(0.24, 0.18, 0.14)
	var col_shadow = Color(0.12, 0.08, 0.06)
	var col_vermilion = Color(0.85, 0.22, 0.18)
	var col_gold = Color(0.95, 0.80, 0.25)

	# Main platform body
	draw_rect(Rect2(Vector2.ZERO, platform_size), col_wood)

	# Vermilion lacquered top beam
	draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 4.0)), col_vermilion)

	# Planking vertical seams
	var plank_w = 20.0
	var count = int(ceil(platform_size.x / plank_w))
	for i in range(1, count):
		var x = i * plank_w
		draw_line(Vector2(x, 4.0), Vector2(x, platform_size.y), col_shadow, 1.0)

	# Bottom shadow line
	draw_rect(Rect2(Vector2(0, platform_size.y - 3.0), Vector2(platform_size.x, 3.0)), col_shadow)

	# Gold corner caps / brackets
	draw_rect(Rect2(Vector2(0, 0), Vector2(6.0, 6.0)), col_gold)
	draw_rect(Rect2(Vector2(platform_size.x - 6.0, 0), Vector2(6.0, 6.0)), col_gold)

	# Torii / Pagoda upturned eaves on ends
	if has_torii_trim and platform_size.y >= 25.0:
		# Left eave
		draw_rect(Rect2(Vector2(-4.0, -4.0), Vector2(6.0, 4.0)), col_vermilion)
		# Right eave
		draw_rect(Rect2(Vector2(platform_size.x - 2.0, -4.0), Vector2(6.0, 4.0)), col_vermilion)
