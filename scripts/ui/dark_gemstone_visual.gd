class_name DarkGemstoneVisual
extends Control

## Visual representation of the ORIGIN logo with a completely dark, cracked gemstone (Beat 14).

func _ready() -> void:
	custom_minimum_size = Vector2(160, 60)
	queue_redraw()

func _draw() -> void:
	var center = Vector2(size.x * 0.5, size.y * 0.5)

	# Completely Dark Gemstone (Black / Deep Charcoal with faint cracks)
	var col_dark_gem = Color(0.08, 0.08, 0.10)
	var col_gem_rim = Color(0.20, 0.20, 0.24)
	var col_crack = Color(0.4, 0.4, 0.45, 0.8)

	var pts = PackedVector2Array([
		center + Vector2(0, -22),
		center + Vector2(18, -10),
		center + Vector2(18, 12),
		center + Vector2(0, 22),
		center + Vector2(-18, 12),
		center + Vector2(-18, -10)
	])

	# Dark inert gemstone body
	draw_colored_polygon(pts, col_dark_gem)
	draw_polyline(pts, col_gem_rim, 2.0)
	draw_line(pts[0], pts[3], col_gem_rim, 1.0)
	draw_line(pts[1], pts[4], col_gem_rim, 1.0)
	draw_line(pts[2], pts[5], col_gem_rim, 1.0)

	# Fractured fracture lines across the dark stone
	draw_line(center + Vector2(-4, -15), center + Vector2(6, 4), col_crack, 1.5)
	draw_line(center + Vector2(6, 4), center + Vector2(-2, 18), col_crack, 1.5)
	draw_line(center + Vector2(6, 4), center + Vector2(14, 8), col_crack, 1.0)
