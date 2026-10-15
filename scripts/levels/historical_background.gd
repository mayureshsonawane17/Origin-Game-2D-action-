class_name HistoricalBackground
extends ParallaxBackground

## Parallax background for Chapter 3: Shrine of the Crimson Mist (Historical Era).
## Layers: Crimson twilight mountain sky with rising sun, distant pagoda roofs, and bamboo silhouettes.

func _ready() -> void:
	# Layer 1: Distant Misty Mountains & Rising Sun
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.12, 0.05)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Sky gradient
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.18, 0.08, 0.14))
		# Large crimson morning sun
		canvas1.draw_circle(Vector2(240, 95), 32.0, Color(0.95, 0.28, 0.28, 0.85))
		canvas1.draw_circle(Vector2(240, 95), 26.0, Color(1.0, 0.65, 0.45, 0.95))

		# Distant Mountain Ridges (Fujisan silhouette)
		var pts = PackedVector2Array([
			Vector2(0, 270), Vector2(0, 180), Vector2(90, 150),
			Vector2(190, 120), Vector2(240, 80), Vector2(290, 120),
			Vector2(380, 160), Vector2(480, 185), Vector2(480, 270)
		])
		canvas1.draw_colored_polygon(pts, Color(0.25, 0.12, 0.20))
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Bamboo Grove & Pagoda Roofs
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.35, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var col_pagoda = Color(0.15, 0.16, 0.20)
		var col_bamboo = Color(0.12, 0.18, 0.14)
		var col_lantern = Color(1.0, 0.8, 0.3, 0.7)

		# Bamboo Stalks
		for x in [25, 45, 70, 180, 210, 360, 390, 420]:
			canvas2.draw_line(Vector2(x, 90), Vector2(x, 270), col_bamboo, 4.0)
			# Bamboo segments
			for y in [130, 170, 210, 250]:
				canvas2.draw_line(Vector2(x - 3, y), Vector2(x + 3, y), col_bamboo.lightened(0.2), 1.5)

		# Pagoda Tier 1
		canvas2.draw_rect(Rect2(270, 130, 70, 140), col_pagoda)
		# Pagoda Curved Eave
		var eave1 = PackedVector2Array([
			Vector2(255, 130), Vector2(305, 110), Vector2(355, 130)
		])
		canvas2.draw_colored_polygon(eave1, Color(0.85, 0.22, 0.18))
		# Lantern
		canvas2.draw_circle(Vector2(305, 150), 4.0, col_lantern)

		# Torii Gate Silhouette in distance
		var col_torii = Color(0.55, 0.14, 0.12)
		canvas2.draw_line(Vector2(110, 140), Vector2(110, 220), col_torii, 3.5)
		canvas2.draw_line(Vector2(145, 140), Vector2(145, 220), col_torii, 3.5)
		canvas2.draw_line(Vector2(100, 146), Vector2(155, 146), col_torii, 4.0)
		canvas2.draw_line(Vector2(105, 158), Vector2(150, 158), col_torii, 2.5)
	)
	layer2.add_child(canvas2)
	add_child(layer2)
