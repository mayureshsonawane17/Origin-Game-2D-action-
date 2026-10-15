class_name JunglePlatform
extends StaticBody2D

## Modular pixel art platform for the Prehistoric Jungle level.

@export var platform_size: Vector2 = Vector2(160, 32)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	
	# Ensure shape matches size
	var col = get_node_or_null("CollisionShape2D")
	if not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect = RectangleShape2D.new()
		rect.size = platform_size
		col.shape = rect
		col.position = platform_size / 2.0
		add_child(col)
	elif col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = platform_size
		col.position = platform_size / 2.0
		
	queue_redraw()

func _draw() -> void:
	var w = platform_size.x
	var h = platform_size.y

	# Prehistoric jungle loamy earth palette
	var col_grass_top = Color(0.40, 0.68, 0.26)
	var col_grass = Color(0.22, 0.46, 0.20)
	var col_dirt = Color(0.30, 0.22, 0.16)
	var col_rock = Color(0.22, 0.16, 0.12)
	var col_detail = Color(0.18, 0.12, 0.09)

	# 1. Main Dirt Body
	draw_rect(Rect2(0, 0, w, h), col_dirt)

	# 2. Rock layers
	var num_rocks = int(w / 32.0)
	for i in num_rocks:
		var rx = i * 32.0 + 6.0
		draw_rect(Rect2(rx, 10, 18, h - 14), col_rock)
		draw_rect(Rect2(rx + 2, 12, 14, 4), col_detail)

	# 3. Grass Top Layer (4px thick)
	draw_rect(Rect2(0, 0, w, 5), col_grass)
	draw_rect(Rect2(0, 0, w, 2), col_grass_top)

	# Grass blades / tufts
	var tufts = int(w / 8.0)
	for t in tufts:
		var tx = t * 8.0
		if (t % 2) == 0:
			draw_rect(Rect2(tx + 2, -2, 2, 2), col_grass_top)
			draw_rect(Rect2(tx + 1, 5, 2, 3), col_grass)

	# Hanging moss/roots on bottom
	var roots = int(w / 16.0)
	for r in roots:
		var rx = r * 16.0 + 4.0
		if (r % 3) == 0:
			draw_rect(Rect2(rx, h, 2, 5), col_grass.darkened(0.2))
			draw_rect(Rect2(rx + 1, h + 5, 1, 3), col_grass.darkened(0.3))
