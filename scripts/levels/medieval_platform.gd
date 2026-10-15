class_name MedievalCastlePlatform
extends StaticBody2D

## Procedural pixel art stone castle masonry platform for Chapter 2 (Medieval Era).

@export var platform_size: Vector2 = Vector2(160, 40)
@export var has_crenellations: bool = true

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
	# Heavy ashlar grey stone blocks with darker mortar joints
	var col_stone = Color(0.32, 0.35, 0.40)
	var col_mortar = Color(0.18, 0.20, 0.24)
	var col_top = Color(0.45, 0.50, 0.56)

	draw_rect(Rect2(Vector2.ZERO, platform_size), col_stone)
	# Top flagstone edge
	draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), col_top)
	# Bottom shadow edge
	draw_rect(Rect2(Vector2(0, platform_size.y - 2.0), Vector2(platform_size.x, 2.0)), col_mortar)

	# Mortar brick grid
	var brick_w = 24.0
	var brick_h = 10.0
	var rows = int(ceil(platform_size.y / brick_h))
	var cols = int(ceil(platform_size.x / brick_w))

	for r in range(rows):
		var y = r * brick_h
		draw_line(Vector2(0, y), Vector2(platform_size.x, y), col_mortar, 1.0)
		var x_offset = (r % 2) * (brick_w * 0.5)
		for c in range(cols + 1):
			var x = c * brick_w + x_offset
			if x > 0 and x < platform_size.x:
				draw_line(Vector2(x, y), Vector2(x, min(y + brick_h, platform_size.y)), col_mortar, 1.0)

	# Castle Crenellations on top
	if has_crenellations and platform_size.y >= 30:
		var cren_w = 12.0
		var cren_gap = 12.0
		var pos_x = 4.0
		while pos_x + cren_w < platform_size.x:
			draw_rect(Rect2(Vector2(pos_x, -5.0), Vector2(cren_w, 5.0)), col_top)
			pos_x += (cren_w + cren_gap)
