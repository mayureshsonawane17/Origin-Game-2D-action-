class_name IndustrialBackground
extends ParallaxBackground

## Parallax background for Chapter 4: Smog Docks & Foundry (Industrial Era).
## Layers: Smog-choked amber sky, animated molten furnace glow, smoking chimneys with rising sparks,
## iron cranes, and overhead steam pipe networks.

func _ready() -> void:
	# Layer 1: Smoggy Amber Sky, Murky Sun, and Chimney Plumes
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.10, 0.04)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedFoundrySky.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Iron Cranes, Molten Furnaces, Steam Pipes, and Sparks
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.32, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = AnimatedFoundryWorks.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedFoundrySky extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Smoggy industrial amber-obsidian gradient
		draw_rect(Rect2(0, 0, 480, 140), Color("#120d09"))
		draw_rect(Rect2(0, 140, 480, 130), Color("#21140a"))

		# Murky chemical sun with pulsating amber aura
		var sun_center = Vector2(210, 75)
		var pulse = (sin(time * 2.0) + 1.0) * 0.5
		draw_circle(sun_center, 28.0 + pulse * 4.0, Color(0.9, 0.45, 0.1, 0.2 + pulse * 0.15))
		draw_circle(sun_center, 20.0, Color(0.95, 0.55, 0.15, 0.75))
		draw_circle(sun_center, 15.0, Color(1.0, 0.85, 0.4, 0.9))

		# Distant Factory Skyline & Chimney Smoke Plumes
		var col_skyline = Color("#0d0b09")
		for cx in [50, 115, 230, 320, 420]:
			draw_rect(Rect2(cx - 7, 85, 14, 185), col_skyline)
			# Animated drifting smoke puff
			var smoke_drift = fmod(time * 20.0 + cx, 50.0)
			var s_alpha = 1.0 - (smoke_drift / 50.0)
			draw_circle(Vector2(cx + sin(time + cx) * 5.0, 80 - smoke_drift * 0.6), 8.0 + smoke_drift * 0.2, Color(0.18, 0.15, 0.12, 0.4 * s_alpha))

class AnimatedFoundryWorks extends Node2D:
	var time: float = 0.0
	var sparks: Array[Vector3] = [] # x, y, speed

	func _ready() -> void:
		var rng = RandomNumberGenerator.new()
		for i in range(20):
			sparks.append(Vector3(rng.randf_range(0, 480), rng.randf_range(90, 260), rng.randf_range(18.0, 38.0)))

	func _process(delta: float) -> void:
		time += delta
		for i in range(sparks.size()):
			var s = sparks[i]
			s.y -= s.z * delta
			s.x += sin(time * 3.0 + i) * 0.5
			if s.y < 80:
				s.y = 260
				s.x = randf_range(0, 480)
			sparks[i] = s
		queue_redraw()

	func _draw() -> void:
		var col_crane = Color("#111317")
		var col_pipe = Color("#1d1c21")
		var molten_pulse = (sin(time * 4.5) + 1.0) * 0.5
		var col_furnace = Color(1.0, 0.45, 0.1, 0.75 + molten_pulse * 0.25)

		# Dock Crane 1
		draw_line(Vector2(80, 270), Vector2(80, 95), col_crane, 5.0)
		draw_line(Vector2(80, 105), Vector2(175, 65), col_crane, 4.0)
		draw_line(Vector2(145, 80), Vector2(145, 145), col_crane, 2.0)

		# Foundry Building
		draw_rect(Rect2(245, 105, 95, 165), col_crane)
		# Molten furnace core window with intense heat glow
		draw_rect(Rect2(270, 145, 36, 24), col_furnace)
		draw_rect(Rect2(275, 150, 26, 14), Color(1.0, 0.95, 0.6, 0.95))
		draw_circle(Vector2(288, 157), 24.0, Color(1.0, 0.4, 0.05, 0.2 + molten_pulse * 0.15))

		# Overhead Steam Pipes with periodic steam vents
		draw_line(Vector2(0, 165), Vector2(480, 165), col_pipe, 4.0)
		draw_circle(Vector2(190, 165), 5.5, col_pipe.lightened(0.2))
		draw_circle(Vector2(380, 165), 5.5, col_pipe.lightened(0.2))

		# Rising molten sparks / foundry embers
		for s in sparks:
			var alpha = 0.5 + sin(time * 5.0 + s.x) * 0.5
			draw_circle(Vector2(s.x, s.y), 1.5, Color(1.0, 0.6, 0.15, alpha))
