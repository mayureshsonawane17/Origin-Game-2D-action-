class_name FortressBackground
extends ParallaxBackground

## Parallax background for Chapter 7: The Fortress of the Gemstone.
## Renders the reality-bending Gemstone fortress, dark crystalline monoliths,
## twisting spacetime vortex, orbiting gemstone shards, and the massive crystal barrier trapping the Hero's wife.

var crystal_pulse: float = 0.0

func _ready() -> void:
	# Layer 1: Spacetime Vortex Sky, Obsidian Monoliths & Reality Fissures
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.06, 0.02)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedFortressVoid.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: The Massive Crystal Barrier Trapping the Hero's Wife & Orbiting Shards
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.20, 0.04)
	var canvas2 = AnimatedCrystalBarrier.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedFortressVoid extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Abyssal purple spacetime vortex sky
		draw_rect(Rect2(0, 0, 480, 140), Color("#030107"))
		draw_rect(Rect2(0, 140, 480, 130), Color("#0f0219"))

		# Twisting spacetime accretion nebula
		var vortex_center = Vector2(240, 110)
		for r in [90.0, 65.0, 40.0]:
			var pulse = (sin(time * 2.5 + r * 0.05) + 1.0) * 0.5
			var v_col = Color(0.7, 0.1, 0.95, 0.12 + pulse * 0.12)
			draw_arc(vortex_center, r + pulse * 6.0, time * 0.5, time * 0.5 + TAU * 0.85, 28, v_col, 3.0)

		# Giant Crystalline Obsidian Monoliths
		var col_monolith = Color("#07030e")
		var col_magenta_laser = Color("#ff00cc")
		var col_cyan_core = Color("#00ffff")

		for mx in [30, 105, 180, 260, 340, 415]:
			var mw = 44.0
			var mh = 220.0
			var my = 50.0
			draw_rect(Rect2(mx, my, mw, mh), col_monolith)

			# Central pulsing energy conduit
			var pulse = (sin(time * 3.2 + mx * 0.1) + 1.0) * 0.5
			var center_x = mx + mw * 0.5
			var stream_col = col_magenta_laser.lerp(col_cyan_core, pulse)
			draw_line(Vector2(center_x, my), Vector2(center_x, my + mh), Color(stream_col.r, stream_col.g, stream_col.b, 0.4 + pulse * 0.4), 2.2)
			draw_line(Vector2(center_x, my), Vector2(center_x, my + mh), Color.WHITE, 0.8)

		# Spacetime reality fracture lines (broken simulation cracks)
		var f_pulse = (sin(time * 3.0) + 1.0) * 0.5
		var f_pts = PackedVector2Array([
			Vector2(80, 15), Vector2(125, 45), Vector2(105, 75), Vector2(150, 110), Vector2(135, 145)
		])
		draw_polyline(f_pts, Color(0.9, 0.1, 1.0, 0.3 + f_pulse * 0.4), 2.5)
		draw_polyline(f_pts, Color.WHITE, 0.8 * f_pulse)

class AnimatedCrystalBarrier extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var barrier_pos = Vector2(240, 135)
		var pulse = (sin(time * 2.8) + 1.0) * 0.5

		# Outer glowing crystal aura
		draw_circle(barrier_pos, 75.0 + pulse * 8.0, Color(0.85, 0.1, 1.0, 0.12 + pulse * 0.08))
		draw_circle(barrier_pos, 55.0 + pulse * 5.0, Color(0.2, 0.9, 1.0, 0.15 + pulse * 0.10))

		# Massive Crystal Barrier Polygon / Facets (trapping the Hero's wife)
		var pts = PackedVector2Array([
			barrier_pos + Vector2(0, -68),
			barrier_pos + Vector2(48, -32),
			barrier_pos + Vector2(48, 48),
			barrier_pos + Vector2(0, 80),
			barrier_pos + Vector2(-48, 48),
			barrier_pos + Vector2(-48, -32)
		])

		# Faceted crystal fill with shifting amethyst/cyan refractions
		var fill_col = Color(0.35, 0.04, 0.5, 0.65).lerp(Color(0.05, 0.3, 0.55, 0.65), pulse * 0.5)
		draw_colored_polygon(pts, fill_col)
		draw_polyline(pts, Color(1.0, 0.75, 1.0, 0.9), 2.5)

		# Internal prismatic refraction lines
		draw_line(pts[0], pts[3], Color(0.9, 0.2, 1.0, 0.7), 2.0)
		draw_line(pts[1], pts[4], Color(0.2, 0.9, 1.0, 0.7), 2.0)
		draw_line(pts[2], pts[5], Color(1.0, 0.4, 0.8, 0.7), 2.0)

		# Trapped Wife Silhouette inside the gemstone core
		var wife_col = Color(0.98, 0.95, 0.90, 0.85)
		draw_circle(barrier_pos + Vector2(0, -8), 7.0, wife_col) # Head
		draw_colored_polygon(PackedVector2Array([ # Dress/cloak
			barrier_pos + Vector2(0, -1),
			barrier_pos + Vector2(10, 24),
			barrier_pos + Vector2(-10, 24)
		]), wife_col)

		# Orbiting Shattered Gemstone Shards
		for i in 4:
			var angle = time * 1.4 + float(i) * (PI * 0.5)
			var orb_radius = 85.0 + sin(time * 2.0 + i) * 8.0
			var shard_pos = barrier_pos + Vector2(cos(angle), sin(angle) * 0.45) * orb_radius
			var shard_pts = PackedVector2Array([
				shard_pos + Vector2(0, -8),
				shard_pos + Vector2(5, 0),
				shard_pos + Vector2(0, 8),
				shard_pos + Vector2(-5, 0)
			])
			draw_colored_polygon(shard_pts, Color(0.0, 0.9, 1.0, 0.8))
			draw_polyline(shard_pts, Color.WHITE, 1.2)
