class_name FortressBackground
extends ParallaxBackground

## Parallax background for Chapter 7: The Fortress of the Gemstone.
## Renders the reality-bending Gemstone fortress, dark crystalline spires,
## and the massive crystal barrier trapping the Hero's wife.

var crystal_pulse: float = 0.0

func _ready() -> void:
	# Layer 1: The Void Sky & Reality Fracture Spire
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.08, 0.02)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Abyssal purple vortex sky
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.04, 0.02, 0.08))
		canvas1.draw_rect(Rect2(0, 90, 480, 180), Color(0.12, 0.04, 0.18, 0.5))

		# Distant gigantic crystal monoliths
		var col_monolith = Color(0.08, 0.05, 0.12)
		var col_glow = Color(0.85, 0.15, 0.95, 0.35)

		for mx in [40, 120, 200, 280, 360, 440]:
			var mw = 40.0
			var mh = 210.0
			var my = 60.0
			canvas1.draw_rect(Rect2(mx, my, mw, mh), col_monolith)
			canvas1.draw_line(Vector2(mx + mw * 0.5, my), Vector2(mx + mw * 0.5, my + mh), col_glow, 2.0)
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: The Massive Crystal Barrier Trapping the Hero's Wife
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.25, 0.05)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var barrier_pos = Vector2(240, 140)
		var col_barrier = Color(0.9, 0.2, 1.0, 0.65)
		var col_border = Color(1.0, 0.7, 1.0, 0.9)
		var col_wife = Color(0.95, 0.90, 0.85, 0.85)

		# Massive Crystal Barrier Polygon / Facets
		var pts = PackedVector2Array([
			barrier_pos + Vector2(0, -65),
			barrier_pos + Vector2(45, -30),
			barrier_pos + Vector2(45, 45),
			barrier_pos + Vector2(0, 75),
			barrier_pos + Vector2(-45, 45),
			barrier_pos + Vector2(-45, -30)
		])
		canvas2.draw_colored_polygon(pts, Color(0.4, 0.05, 0.55, 0.6))
		canvas2.draw_polyline(pts, col_border, 2.5)

		# Glowing crystalline internal refractions
		canvas2.draw_line(pts[0], pts[3], col_barrier, 2.0)
		canvas2.draw_line(pts[1], pts[4], col_barrier, 2.0)
		canvas2.draw_line(pts[2], pts[5], col_barrier, 2.0)

		# Trapped Wife Silhouette inside the crystal
		var wife_pos = barrier_pos + Vector2(0, 10)
		# Flowing dress
		canvas2.draw_rect(Rect2(wife_pos.x - 7, wife_pos.y - 12, 14, 24), col_wife)
		# Head & long hair
		canvas2.draw_circle(wife_pos + Vector2(0, -18), 5.5, col_wife)
		canvas2.draw_line(wife_pos + Vector2(-4, -18), wife_pos + Vector2(-8, -6), col_wife, 2.0) # Hair strands
		canvas2.draw_line(wife_pos + Vector2(4, -18), wife_pos + Vector2(8, -6), col_wife, 2.0)

		# Floating runic bind rings around barrier
		canvas2.draw_arc(barrier_pos, 75.0, 0, TAU, 16, col_barrier, 1.5)
		canvas2.draw_arc(barrier_pos, 85.0, 0, TAU, 16, Color(0.95, 0.2, 0.8, 0.4), 1.0)
	)
	layer2.add_child(canvas2)
	add_child(layer2)
