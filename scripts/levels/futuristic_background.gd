class_name FuturisticSpireBackground
extends ParallaxBackground

## Parallax background for Chapter 6: The Cybernetic Spire (Futuristic Era).
## Layers: Quantum Void sky, vertical laser data streams, floating holographic rings, and spire conduits.

func _ready() -> void:
	# Layer 1: Quantum Void & Spire Mega-Structure Silhouettes
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.10, 0.04)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Deep space void
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.03, 0.04, 0.08))
		# Neon nebula haze
		canvas1.draw_rect(Rect2(0, 100, 480, 170), Color(0.08, 0.05, 0.15, 0.6))

		# Distant monolithic spire pillars
		var col_spire = Color(0.05, 0.07, 0.12)
		var col_cyan_stream = Color(0.1, 0.9, 1.0, 0.4)
		var col_magenta_stream = Color(0.9, 0.15, 0.95, 0.4)

		for sx in [30, 110, 190, 270, 350, 430]:
			var sw = 38.0
			var sh = 200.0
			var sy = 70.0
			canvas1.draw_rect(Rect2(sx, sy, sw, sh), col_spire)

			# Central vertical laser data stream
			var stream_col = col_cyan_stream if (sx / 40) % 2 == 0 else col_magenta_stream
			canvas1.draw_line(Vector2(sx + sw * 0.5, sy), Vector2(sx + sw * 0.5, sy + sh), stream_col, 2.0)
			canvas1.draw_line(Vector2(sx + sw * 0.5, sy), Vector2(sx + sw * 0.5, sy + sh), Color.WHITE, 0.8)

			# Floating data hex dots
			for hy in range(int(sy + 20), int(sy + sh - 20), 25):
				canvas1.draw_circle(Vector2(sx + sw * 0.5, hy), 2.0, stream_col)
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Holographic Energy Rings, Floating Servitors, and Power Conduits
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.32, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var col_conduit = Color(0.08, 0.10, 0.16)
		var col_holo_cyan = Color(0.1, 0.95, 1.0, 0.7)
		var col_holo_pink = Color(0.95, 0.15, 0.85, 0.7)

		# Horizontal energy transmission rail
		canvas2.draw_line(Vector2(0, 130), Vector2(480, 130), col_conduit, 4.0)
		canvas2.draw_line(Vector2(0, 130), Vector2(480, 130), col_holo_cyan, 1.5)

		# Floating holographic rings
		canvas2.draw_arc(Vector2(90, 110), 22.0, 0, TAU, 16, col_holo_cyan, 2.0)
		canvas2.draw_arc(Vector2(90, 110), 16.0, 0, TAU, 12, col_holo_pink, 1.0)
		canvas2.draw_circle(Vector2(90, 110), 3.0, Color.WHITE)

		canvas2.draw_arc(Vector2(290, 95), 26.0, 0, TAU, 16, col_holo_pink, 2.0)
		canvas2.draw_arc(Vector2(290, 95), 18.0, 0, TAU, 12, col_holo_cyan, 1.0)
		canvas2.draw_circle(Vector2(290, 95), 4.0, Color.WHITE)

		# Sub-station transformer node
		canvas2.draw_rect(Rect2(400, 140, 36, 40), col_conduit)
		canvas2.draw_line(Vector2(400, 145), Vector2(436, 145), col_holo_cyan, 2.0)
		canvas2.draw_line(Vector2(400, 165), Vector2(436, 165), col_holo_pink, 2.0)
	)
	layer2.add_child(canvas2)
	add_child(layer2)
