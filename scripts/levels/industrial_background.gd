class_name IndustrialBackground
extends ParallaxBackground

## Parallax background for Chapter 4: Smog Docks & Foundry (Industrial Era).
## Layers: Smog-choked amber sky, smoking chimneys, iron cranes, and molten factory silhouettes.

func _ready() -> void:
	# Layer 1: Smoggy Amber Sky & Distant Chimneys
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.12, 0.05)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Heavily polluted smog sky
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.16, 0.12, 0.10))
		# Murky chemical sun
		canvas1.draw_circle(Vector2(200, 75), 24.0, Color(0.85, 0.55, 0.20, 0.6))
		canvas1.draw_circle(Vector2(200, 75), 18.0, Color(1.0, 0.8, 0.4, 0.8))

		# Distant Factory Skyline
		var col_skyline = Color(0.10, 0.09, 0.08)
		# Chimneys & Smoke Plumes
		for cx in [50, 110, 220, 310, 410]:
			canvas1.draw_rect(Rect2(cx - 6, 90, 12, 180), col_skyline)
			canvas1.draw_circle(Vector2(cx, 80), 8.0, Color(0.20, 0.18, 0.16, 0.7))
			canvas1.draw_circle(Vector2(cx + 8, 70), 12.0, Color(0.25, 0.22, 0.20, 0.6))
			canvas1.draw_circle(Vector2(cx + 20, 60), 16.0, Color(0.30, 0.26, 0.22, 0.4))
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Iron Cranes, Foundry Furnaces & Pipe Networks
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.35, 0.08)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var col_crane = Color(0.14, 0.15, 0.18)
		var col_pipe = Color(0.22, 0.20, 0.22)
		var col_furnace = Color(1.0, 0.45, 0.15, 0.8)

		# Dock Crane 1
		canvas2.draw_line(Vector2(80, 270), Vector2(80, 100), col_crane, 5.0)
		canvas2.draw_line(Vector2(80, 110), Vector2(170, 70), col_crane, 4.0)
		canvas2.draw_line(Vector2(140, 85), Vector2(140, 140), col_crane, 2.0) # Cable

		# Foundry Building
		canvas2.draw_rect(Rect2(250, 110, 90, 160), col_crane)
		# Molten furnace window
		canvas2.draw_rect(Rect2(275, 150, 30, 20), col_furnace)
		canvas2.draw_rect(Rect2(280, 155, 20, 10), Color(1.0, 0.9, 0.5))

		# Overhead Steam Pipes
		canvas2.draw_line(Vector2(0, 170), Vector2(480, 170), col_pipe, 3.5)
		canvas2.draw_circle(Vector2(190, 170), 5.0, col_pipe.lightened(0.2)) # Valve wheel
		canvas2.draw_circle(Vector2(380, 170), 5.0, col_pipe.lightened(0.2))
	)
	layer2.add_child(canvas2)
	add_child(layer2)
