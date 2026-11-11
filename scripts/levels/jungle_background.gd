class_name JungleBackground
extends ParallaxBackground

## Layered prehistoric jungle parallax background with Dark Sci-Fi / Cyber Glitch undertones.
## Animated sky, pulsating volcanic caldera, drifting cyber embers, and reality fracture cracks.

func _ready() -> void:
	# Layer 1: Distant Sky, Twinkling Stars, Reality Fissures, and Volcanic Mountain Silhouette
	var sky_layer = ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.08, 0.03)
	sky_layer.motion_mirroring = Vector2(480, 0)
	var sky_canvas = AnimatedSkyCanvas.new()
	sky_layer.add_child(sky_canvas)
	add_child(sky_layer)

	# Layer 2: Midground Primordial Canopy, Bio-luminescent Spores, and Cyber Embers
	var mid_layer = ParallaxLayer.new()
	mid_layer.motion_scale = Vector2(0.28, 0.08)
	mid_layer.motion_mirroring = Vector2(480, 0)
	var mid_canvas = AnimatedMidJungleCanvas.new()
	mid_layer.add_child(mid_canvas)
	add_child(mid_layer)

class AnimatedSkyCanvas extends Node2D:
	var time: float = 0.0
	var stars: Array[Vector3] = [] # x, y, size

	func _ready() -> void:
		var rng = RandomNumberGenerator.new()
		rng.seed = 101
		for i in range(35):
			stars.append(Vector3(rng.randf_range(0, 480), rng.randf_range(0, 160), rng.randf_range(0.8, 2.0)))

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Deep teal-cyan to twilight violet sci-fi sky gradient
		var sky_top = Color("#030d12")
		var sky_mid = Color("#071f24")
		var sky_bottom = Color("#0a3028")

		draw_rect(Rect2(0, 0, 480, 120), sky_top)
		draw_rect(Rect2(0, 120, 480, 80), sky_mid)
		draw_rect(Rect2(0, 200, 480, 70), sky_bottom)

		# Twinkling cyber stars / simulation nodes
		for s in stars:
			var pulse = (sin(time * 3.0 + s.x * 0.1) + 1.0) * 0.5
			var alpha = 0.3 + pulse * 0.7
			var col = Color(0.1, 0.9, 1.0, alpha) if int(s.x) % 2 == 0 else Color(0.2, 1.0, 0.7, alpha)
			draw_circle(Vector2(s.x, s.y), s.z * (0.8 + pulse * 0.4), col)

		# Faint simulation fracture fissure in the sky (the gemstone's cracking reality)
		var fissure_pulse = (sin(time * 2.5) + 1.0) * 0.5
		var fissure_pts = PackedVector2Array([
			Vector2(140, 20), Vector2(175, 45), Vector2(165, 75), Vector2(210, 110), Vector2(195, 140)
		])
		draw_polyline(fissure_pts, Color(0.0, 0.9, 1.0, 0.15 + fissure_pulse * 0.25), 2.0)
		draw_polyline(fissure_pts, Color(1, 1, 1, 0.3 * fissure_pulse), 0.8)

		# Distant ancient volcanic mountain silhouettes with glowing magma veins
		var col_mtn = Color("#041415")
		var col_magma = Color(1.0, 0.4, 0.1, 0.4 + fissure_pulse * 0.4)

		for i in 3:
			var mx = i * 160.0 - 20.0
			var pts = PackedVector2Array([
				Vector2(mx, 270),
				Vector2(mx + 60, 90),
				Vector2(mx + 110, 130),
				Vector2(mx + 160, 270)
			])
			draw_colored_polygon(pts, col_mtn)
			# Peak magma fissure / crater glow
			draw_line(Vector2(mx + 55, 95), Vector2(mx + 65, 95), col_magma, 2.5)
			draw_line(Vector2(mx + 60, 95), Vector2(mx + 68, 118), col_magma, 1.2)

class AnimatedMidJungleCanvas extends Node2D:
	var time: float = 0.0
	var motes: Array[Dictionary] = []

	func _ready() -> void:
		var rng = RandomNumberGenerator.new()
		for i in range(20):
			motes.append({
				"x": rng.randf_range(0, 480),
				"y": rng.randf_range(60, 250),
				"speed": rng.randf_range(12.0, 24.0),
				"phase": rng.randf_range(0, TAU),
				"size": rng.randf_range(1.0, 2.2)
			})

	func _process(delta: float) -> void:
		time += delta
		for m in motes:
			m["y"] -= m["speed"] * delta
			m["x"] += sin(time * 2.0 + m["phase"]) * 0.4
			if m["y"] < 50:
				m["y"] = 260
				m["x"] = randf_range(0, 480)
		queue_redraw()

	func _draw() -> void:
		var col_trees = Color("#0a241b")
		var col_fern = Color("#0f3829")
		var col_bio_glow = Color(0.1, 1.0, 0.8, 0.75)

		# Giant Primordial Tree Trunks & Bioluminescent Canopy
		for i in 6:
			var tx = i * 85.0 - 20.0
			# Trunk
			draw_rect(Rect2(tx + 22, 50, 18, 220), col_trees)
			# Bioluminescent cyber-vine vein running down trunk
			var vine_pulse = (sin(time * 2.2 + i) + 1.0) * 0.5
			var vine_col = Color(col_bio_glow.r, col_bio_glow.g, col_bio_glow.b, 0.3 + vine_pulse * 0.5)
			draw_line(Vector2(tx + 31, 60), Vector2(tx + 31, 230), vine_col, 1.2)

			# Tiered Canopy Umbrellas
			var pts = PackedVector2Array([
				Vector2(tx - 35, 80),
				Vector2(tx + 31, 25),
				Vector2(tx + 95, 80)
			])
			draw_colored_polygon(pts, col_fern)

			# Hanging bioluminescent spores from canopy edges
			var spore_pos1 = Vector2(tx - 15, 88 + sin(time * 3.0 + i) * 3.0)
			var spore_pos2 = Vector2(tx + 75, 86 + cos(time * 3.0 + i) * 3.0)
			draw_circle(spore_pos1, 2.0, vine_col)
			draw_circle(spore_pos2, 2.2, vine_col)

		# Floating glowing spore motes
		for m in motes:
			var alpha = (sin(time * 3.0 + m["phase"]) + 1.0) * 0.4 + 0.2
			draw_circle(Vector2(m["x"], m["y"]), m["size"], Color(0.2, 1.0, 0.85, alpha))
