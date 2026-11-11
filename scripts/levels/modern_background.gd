class_name ModernCityBackground
extends ParallaxBackground

## Parallax background for Chapter 5: Concrete Metropolis & Rooftops (Modern Era).
## Layers: Cyberpunk midnight rain sky, animated sweeping searchlights, blinking beacon towers,
## flickering neon billboards, and holographic communications arrays.

func _ready() -> void:
	# Layer 1: Midnight Rain Sky, Sweeping Searchlights & Skyscraper Silhouettes
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.10, 0.04)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedCitySkyline.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Rooftops, Animated Neon Signs, and Communications Grid
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.32, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = AnimatedCityRooftops.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedCitySkyline extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Dark midnight violet-blue rain haze sky
		draw_rect(Rect2(0, 0, 480, 150), Color("#04060c"))
		draw_rect(Rect2(0, 150, 480, 120), Color("#0a0d18"))

		# Sweeping holographic searchlight beams across the rainy clouds
		var beam_angle1 = sin(time * 0.8) * 0.35 + 0.2
		var beam_angle2 = cos(time * 0.6) * 0.35 - 0.2
		_draw_searchlight(Vector2(120, 240), beam_angle1, Color(0.1, 0.8, 1.0, 0.12))
		_draw_searchlight(Vector2(360, 240), beam_angle2, Color(0.9, 0.2, 0.8, 0.10))

		# Distant Mega-Corporation Skyscraper Towers
		var col_bldg = Color("#070911")
		var col_cyan_win = Color(0.1, 0.85, 1.0, 0.45)
		var col_amber_win = Color(1.0, 0.75, 0.2, 0.40)

		var towers = [
			{"x": 20, "w": 48, "h": 180, "y": 80},
			{"x": 85, "w": 38, "h": 150, "y": 110},
			{"x": 140, "w": 62, "h": 210, "y": 55},
			{"x": 220, "w": 44, "h": 165, "y": 95},
			{"x": 280, "w": 55, "h": 195, "y": 70},
			{"x": 355, "w": 42, "h": 160, "y": 100},
			{"x": 415, "w": 58, "h": 185, "y": 75}
		]

		for t in towers:
			draw_rect(Rect2(t["x"], t["y"], t["w"], t["h"]), col_bldg)

			# Tower top antenna with animated blinking beacon
			var antenna_x = t["x"] + t["w"] * 0.5
			draw_line(Vector2(antenna_x, t["y"]), Vector2(antenna_x, t["y"] - 22), col_bldg, 2.0)
			var beacon_blink = int(time * 3.0 + t["x"]) % 2 == 0
			var col_beacon = Color.RED if beacon_blink else Color(0.3, 0.0, 0.0)
			draw_circle(Vector2(antenna_x, t["y"] - 22), 2.0, col_beacon)

			# Office window matrix
			for wx in range(int(t["x"] + 4), int(t["x"] + t["w"] - 4), 6):
				for wy in range(int(t["y"] + 8), int(t["y"] + t["h"] - 15), 10):
					if (wx * 7 + wy * 13) % 4 == 0:
						var wc = col_cyan_win if (wx + wy) % 2 == 0 else col_amber_win
						draw_rect(Rect2(wx, wy, 3, 4), wc)

	func _draw_searchlight(origin: Vector2, angle: float, col: Color) -> void:
		var dir = Vector2(sin(angle), -cos(angle)).normalized()
		var perp = Vector2(-dir.y, dir.x)
		var end_pt = origin + dir * 320.0
		var beam_poly = PackedVector2Array([
			origin,
			end_pt - perp * 28.0,
			end_pt + perp * 28.0
		])
		draw_colored_polygon(beam_poly, col)

class AnimatedCityRooftops extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var col_roof = Color("#0e121b")
		var col_pipe = Color("#171d2b")
		var neon_cyan = Color("#00f0ff")
		var neon_pink = Color("#ff007f")

		# Rooftop water towers
		draw_rect(Rect2(45, 145, 36, 42), Color("#1b2230"))
		draw_line(Vector2(50, 187), Vector2(50, 225), col_roof, 2.5)
		draw_line(Vector2(75, 187), Vector2(75, 225), col_roof, 2.5)

		# Animated Neon Billboard 1 (CYBERNETIC / ORIGIN sign)
		var sign1_flicker = 0.85 + (sin(time * 14.0) * 0.15) if int(time * 7.0) % 19 != 0 else 0.2
		var neon1_col = Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, sign1_flicker)
		draw_rect(Rect2(150, 125, 68, 28), col_roof)
		draw_rect(Rect2(152, 127, 64, 24), neon1_col, false, 2.0)
		draw_line(Vector2(158, 139), Vector2(210, 139), neon1_col, 1.5)
		draw_line(Vector2(165, 145), Vector2(203, 145), Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, sign1_flicker * 0.5), 1.0)

		# Animated Neon Billboard 2 (Magenta diamond holo-ad)
		var sign2_pulse = (sin(time * 3.5) + 1.0) * 0.5
		var neon2_col = Color(neon_pink.r, neon_pink.g, neon_pink.b, 0.6 + sign2_pulse * 0.4)
		draw_rect(Rect2(310, 135, 52, 32), col_roof)
		draw_rect(Rect2(312, 137, 48, 28), neon2_col, false, 2.0)
		# Holographic diamond inside billboard
		var dia = PackedVector2Array([
			Vector2(336, 141), Vector2(352, 151), Vector2(336, 161), Vector2(320, 151)
		])
		draw_polyline(dia, neon2_col, 1.5)

		# Communications Grid & Power Conduits
		draw_line(Vector2(0, 195), Vector2(480, 195), col_pipe, 3.0)
		draw_line(Vector2(0, 195), Vector2(480, 195), Color(0.1, 0.85, 1.0, 0.4), 1.0)
