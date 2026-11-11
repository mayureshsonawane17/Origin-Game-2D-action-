class_name MedievalCastleBackground
extends ParallaxBackground

## Parallax background for Chapter 2: Castle of the Cursed Keep.
## Layers: Blood Moon with pulsating crimson corona, gothic spire silhouettes, torchlit windows, and drifting cursed embers.

func _ready() -> void:
	# Layer 1: Sky, Blood Moon, Distant Mountains & Spires
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.12, 0.04)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedCastleSky.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Gothic Towers, Stained Glass Windows, and Cursed Embers
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.35, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = AnimatedGothicKeep.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedCastleSky extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Dark crimson-indigo stormy twilight sky
		draw_rect(Rect2(0, 0, 480, 140), Color("#07050e"))
		draw_rect(Rect2(0, 140, 480, 130), Color("#13081a"))

		# Blood Moon with pulsing neon corona & chromatic aura
		var moon_center = Vector2(370, 65)
		var pulse = (sin(time * 2.0) + 1.0) * 0.5
		var corona_radius = 28.0 + pulse * 6.0
		# Outer chromatic halo
		draw_circle(moon_center, corona_radius, Color(0.9, 0.1, 0.3, 0.15 + pulse * 0.10))
		draw_circle(moon_center, 22.0, Color(0.85, 0.22, 0.25, 0.85))
		draw_circle(moon_center, 18.0, Color(1.0, 0.55, 0.45, 0.95))
		# Lunar glitch ring
		draw_arc(moon_center, 25.0 + sin(time * 3.5) * 2.0, 0, TAU, 24, Color(1.0, 0.2, 0.5, 0.4), 1.2)

		# Spacetime fracture fissure cutting through the clouds
		var fissure_pulse = (sin(time * 2.8 + 1.0) + 1.0) * 0.5
		var fissure_pts = PackedVector2Array([
			Vector2(50, 20), Vector2(85, 45), Vector2(75, 75), Vector2(110, 105), Vector2(95, 135)
		])
		draw_polyline(fissure_pts, Color(0.8, 0.1, 0.9, 0.2 + fissure_pulse * 0.3), 2.2)
		draw_polyline(fissure_pts, Color(1, 0.8, 0.9, 0.4 * fissure_pulse), 0.8)

		# Distant jagged mountain & spire silhouettes
		var col_mtn = Color("#0e0817")
		var pts = PackedVector2Array([
			Vector2(0, 270), Vector2(0, 170), Vector2(60, 135), Vector2(120, 170),
			Vector2(190, 120), Vector2(230, 150), Vector2(300, 105), Vector2(370, 160),
			Vector2(430, 130), Vector2(480, 155), Vector2(480, 270)
		])
		draw_colored_polygon(pts, col_mtn)

class AnimatedGothicKeep extends Node2D:
	var time: float = 0.0
	var embers: Array[Vector3] = [] # x, y, speed

	func _ready() -> void:
		var rng = RandomNumberGenerator.new()
		for i in range(18):
			embers.append(Vector3(rng.randf_range(0, 480), rng.randf_range(80, 260), rng.randf_range(15.0, 32.0)))

	func _process(delta: float) -> void:
		time += delta
		for i in range(embers.size()):
			var e = embers[i]
			e.y -= e.z * delta
			e.x += sin(time * 2.5 + i) * 0.4
			if e.y < 60:
				e.y = 260
				e.x = randf_range(0, 480)
			embers[i] = e
		queue_redraw()

	func _draw() -> void:
		var col_castle = Color("#171124")
		var col_roof = Color("#221834")
		var torch_flicker = (sin(time * 6.5) * 0.5 + sin(time * 11.2) * 0.3) * 0.2 + 0.8
		var col_torch = Color(1.0, 0.65, 0.2, 0.75 * torch_flicker)
		var col_crimson_sigil = Color(0.9, 0.15, 0.4, 0.5 + sin(time * 2.0) * 0.3)

		# Tower 1 (Left)
		draw_rect(Rect2(35, 90, 52, 180), col_castle)
		draw_colored_polygon(PackedVector2Array([Vector2(30, 90), Vector2(61, 35), Vector2(92, 90)]), col_roof)
		# Gothic Arched Torchlit Windows
		draw_rect(Rect2(55, 115, 12, 22), col_torch)
		draw_rect(Rect2(55, 155, 12, 22), col_torch)

		# Tower 2 (Right)
		draw_rect(Rect2(250, 75, 68, 195), col_castle)
		draw_colored_polygon(PackedVector2Array([Vector2(245, 75), Vector2(284, 25), Vector2(323, 75)]), col_roof)
		# Windows with glowing gothic sigils
		draw_rect(Rect2(276, 105, 16, 26), col_torch)
		draw_rect(Rect2(276, 150, 16, 26), col_crimson_sigil)

		# Castle Curtain Wall & Crenellations
		draw_rect(Rect2(87, 145, 163, 125), col_castle.darkened(0.12))
		# Crenellations
		for cx in range(88, 245, 20):
			draw_rect(Rect2(cx, 137, 12, 10), col_castle.darkened(0.12))

		# Drifting cursed embers
		for e in embers:
			var alpha = 0.4 + sin(time * 4.0 + e.x) * 0.4
			draw_circle(Vector2(e.x, e.y), 1.6, Color(1.0, 0.3, 0.2, alpha))
