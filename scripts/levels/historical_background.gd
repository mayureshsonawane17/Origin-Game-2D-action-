class_name HistoricalBackground
extends ParallaxBackground

## Parallax background for Chapter 3: Shrine of the Crimson Mist (Historical Era).
## Layers: Crimson twilight mountain sky, breathing blood-sun, drifting spirit sakura motes,
## pagoda silhouettes, and glowing torii lantern flickers.

func _ready() -> void:
	# Layer 1: Distant Misty Mountains & Pulsing Blood Sun
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.10, 0.04)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedShrineSky.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Pagoda, Torii Gate, and Drifting Spirit Sakura Motes
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.32, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = AnimatedBambooGrove.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedShrineSky extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Crimson twilight to violet night gradient
		draw_rect(Rect2(0, 0, 480, 140), Color("#12050e"))
		draw_rect(Rect2(0, 140, 480, 130), Color("#1f0918"))

		# Large Breathing Crimson Sun with chromatic corona
		var sun_center = Vector2(240, 90)
		var pulse = (sin(time * 2.2) + 1.0) * 0.5
		var corona_r = 38.0 + pulse * 6.0
		draw_circle(sun_center, corona_r, Color(0.95, 0.15, 0.25, 0.18 + pulse * 0.12))
		draw_circle(sun_center, 30.0, Color(0.95, 0.25, 0.28, 0.85))
		draw_circle(sun_center, 24.0, Color(1.0, 0.65, 0.45, 0.95))

		# Spacetime fracture cutting across the mountain ridge
		var f_pulse = (sin(time * 3.1) + 1.0) * 0.5
		var f_pts = PackedVector2Array([
			Vector2(110, 30), Vector2(145, 55), Vector2(135, 85), Vector2(180, 115)
		])
		draw_polyline(f_pts, Color(1.0, 0.2, 0.6, 0.25 + f_pulse * 0.3), 2.0)
		draw_polyline(f_pts, Color.WHITE, 0.6 * f_pulse)

		# Distant Mountain Ridges (Fujisan silhouette)
		var col_mtn = Color("#180a15")
		var pts = PackedVector2Array([
			Vector2(0, 270), Vector2(0, 180), Vector2(90, 150),
			Vector2(190, 120), Vector2(240, 80), Vector2(290, 120),
			Vector2(380, 160), Vector2(480, 185), Vector2(480, 270)
		])
		draw_colored_polygon(pts, col_mtn)

class AnimatedBambooGrove extends Node2D:
	var time: float = 0.0
	var petals: Array[Vector3] = [] # x, y, speed

	func _ready() -> void:
		var rng = RandomNumberGenerator.new()
		for i in range(22):
			petals.append(Vector3(rng.randf_range(0, 480), rng.randf_range(40, 250), rng.randf_range(16.0, 32.0)))

	func _process(delta: float) -> void:
		time += delta
		for i in range(petals.size()):
			var p = petals[i]
			p.y += p.z * 0.6 * delta
			p.x += sin(time * 2.0 + i) * 0.8 + 12.0 * delta
			if p.y > 260:
				p.y = 30
				p.x = randf_range(0, 480)
			if p.x > 490:
				p.x = -10
			petals[i] = p
		queue_redraw()

	func _draw() -> void:
		var col_pagoda = Color("#13151b")
		var col_bamboo = Color("#0e1a14")
		var lantern_flicker = 0.8 + sin(time * 7.0) * 0.2
		var col_lantern = Color(1.0, 0.75, 0.25, 0.85 * lantern_flicker)

		# Bamboo Stalks
		for x in [25, 45, 70, 180, 210, 360, 390, 420]:
			draw_line(Vector2(x, 90), Vector2(x, 270), col_bamboo, 4.0)
			for y in [130, 170, 210, 250]:
				draw_line(Vector2(x - 3, y), Vector2(x + 3, y), col_bamboo.lightened(0.2), 1.5)

		# Pagoda Structure
		draw_rect(Rect2(270, 125, 70, 145), col_pagoda)
		# Pagoda Curved Eave Roofs
		var eave1 = PackedVector2Array([
			Vector2(252, 125), Vector2(305, 105), Vector2(358, 125)
		])
		draw_colored_polygon(eave1, Color("#8c1f20"))
		# Glowing Paper Lanterns
		draw_circle(Vector2(305, 142), 4.5, col_lantern)
		draw_circle(Vector2(305, 142), 9.0, Color(1.0, 0.7, 0.2, 0.25 * lantern_flicker))

		# Torii Gate Silhouette
		var col_torii = Color("#591617")
		draw_line(Vector2(110, 140), Vector2(110, 220), col_torii, 3.5)
		draw_line(Vector2(145, 140), Vector2(145, 220), col_torii, 3.5)
		draw_line(Vector2(100, 146), Vector2(155, 146), col_torii, 4.0)
		draw_line(Vector2(105, 158), Vector2(150, 158), col_torii, 2.5)

		# Drifting Glowing Sakura Spirit Petals
		for p in petals:
			var alpha = 0.5 + sin(time * 3.0 + p.x) * 0.3
			var p_col = Color(1.0, 0.45, 0.65, alpha) if int(p.x) % 2 == 0 else Color(0.2, 0.95, 1.0, alpha)
			draw_circle(Vector2(p.x, p.y), 1.8, p_col)
