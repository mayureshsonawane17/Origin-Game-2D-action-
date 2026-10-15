class_name JungleBackground
extends ParallaxBackground

## Layered prehistoric jungle parallax background (Section 5b).

func _ready() -> void:
	# Add ParallaxLayers with procedural pixel canvas items
	var sky_layer = ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.1, 0.05)
	add_child(sky_layer)

	var sky_canvas = SkyCanvas.new()
	sky_layer.add_child(sky_canvas)

	var mid_layer = ParallaxLayer.new()
	mid_layer.motion_scale = Vector2(0.3, 0.1)
	add_child(mid_layer)

	var mid_canvas = MidJungleCanvas.new()
	mid_layer.add_child(mid_canvas)

class SkyCanvas extends Node2D:
	func _draw() -> void:
		# Draw deep prehistoric teal sky gradient
		var sky_top = Color(0.05, 0.12, 0.14)
		var sky_bottom = Color(0.10, 0.22, 0.18)
		draw_rect(Rect2(-200, -100, 2400, 600), sky_top)
		
		# Distant ancient volcanic mountain silhouettes
		var col_mtn = Color(0.07, 0.16, 0.14)
		for i in 6:
			var mx = i * 360.0 - 100.0
			var pts = PackedVector2Array([
				Vector2(mx, 260),
				Vector2(mx + 120, 60),
				Vector2(mx + 220, 110),
				Vector2(mx + 360, 260)
			])
			draw_colored_polygon(pts, col_mtn)

class MidJungleCanvas extends Node2D:
	func _draw() -> void:
		# Mid-distance giant tree trunks and fern canopies
		var col_trees = Color(0.12, 0.26, 0.18)
		var col_fern = Color(0.14, 0.32, 0.20)
		for i in 12:
			var tx = i * 160.0 - 50.0
			# Trunk
			draw_rect(Rect2(tx + 20, 60, 18, 220), col_trees)
			# Canopy umbrella
			var pts = PackedVector2Array([
				Vector2(tx - 30, 90),
				Vector2(tx + 29, 30),
				Vector2(tx + 88, 90)
			])
			draw_colored_polygon(pts, col_fern)
