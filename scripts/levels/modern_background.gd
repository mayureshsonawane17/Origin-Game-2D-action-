class_name ModernCityBackground
extends ParallaxBackground

## Parallax background for Chapter 5: Concrete Metropolis & Rooftops (Modern Era).
## Layers: Midnight city sky, distant glowing skyscrapers, neon billboards, and communications towers.

func _ready() -> void:
	# Layer 1: Midnight Rain Sky & Distant Skyscraper Skyline
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.12, 0.05)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Dark rainy midnight sky
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.06, 0.08, 0.12))
		# Glowing urban haze
		canvas1.draw_rect(Rect2(0, 140, 480, 130), Color(0.10, 0.14, 0.22, 0.5))

		# Distant Skyscraper Towers
		var col_bldg = Color(0.08, 0.10, 0.15)
		var col_win = Color(0.9, 0.95, 0.6, 0.5) # Window glow
		var col_cyan_win = Color(0.2, 0.8, 1.0, 0.4)

		for bx in [20, 80, 150, 210, 280, 360, 430]:
			var bw = 45.0
			var bh = 180.0
			var by = 90.0
			canvas1.draw_rect(Rect2(bx, by, bw, bh), col_bldg)

			# Tower antenna / red beacon
			canvas1.draw_line(Vector2(bx + bw * 0.5, by), Vector2(bx + bw * 0.5, by - 20), col_bldg, 2.0)
			canvas1.draw_circle(Vector2(bx + bw * 0.5, by - 20), 1.5, Color.RED)

			# Window grid dots
			for wx in range(int(bx + 4), int(bx + bw - 4), 6):
				for wy in range(int(by + 10), int(by + bh - 20), 12):
					var c = col_win if (wx + wy) % 5 == 0 else col_cyan_win
					canvas1.draw_rect(Rect2(wx, wy, 3, 4), c)
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Rooftops, Neon Billboards & Communications Antennas
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.35, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var col_roof = Color(0.12, 0.14, 0.18)
		var col_neon_pink = Color(1.0, 0.2, 0.6, 0.85)
		var col_neon_cyan = Color(0.2, 0.8, 1.0, 0.85)

		# Rooftop water tower
		canvas2.draw_rect(Rect2(50, 150, 35, 45), Color(0.22, 0.24, 0.26))
		canvas2.draw_line(Vector2(55, 195), Vector2(55, 230), col_roof, 2.5)
		canvas2.draw_line(Vector2(80, 195), Vector2(80, 230), col_roof, 2.5)

		# Neon Billboard 1 (Cyan)
		canvas2.draw_rect(Rect2(160, 130, 60, 25), col_roof)
		canvas2.draw_rect(Rect2(162, 132, 56, 21), col_neon_cyan, false, 2.0)
		canvas2.draw_line(Vector2(170, 142), Vector2(210, 142), Color.WHITE, 1.5)

		# Neon Billboard 2 (Magenta)
		canvas2.draw_rect(Rect2(340, 120, 50, 30), col_roof)
		canvas2.draw_rect(Rect2(342, 122, 46, 26), col_neon_pink, false, 2.0)
		canvas2.draw_line(Vector2(350, 135), Vector2(380, 135), Color.WHITE, 1.5)

		# Air Conditioning HVAC Vents on roof
		canvas2.draw_rect(Rect2(250, 175, 25, 16), col_roof)
		canvas2.draw_circle(Vector2(262, 183), 4.0, Color(0.2, 0.22, 0.25))
	)
	layer2.add_child(canvas2)
	add_child(layer2)
