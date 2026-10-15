class_name MedievalCastleBackground
extends ParallaxBackground

## Parallax background for Chapter 2: Castle of the Cursed Keep.
## Layers: Stormy twilight sky with blood moon, distant gothic spires, foreground battlements.

func _ready() -> void:
	# Layer 1: Distant Spire silhouettes
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.15, 0.05)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = Node2D.new()
	canvas1.draw.connect(func():
		# Dark twilight sky gradient & blood moon
		canvas1.draw_rect(Rect2(0, 0, 480, 270), Color(0.08, 0.06, 0.12))
		canvas1.draw_circle(Vector2(380, 60), 22.0, Color(0.85, 0.35, 0.35, 0.9)) # Blood Moon
		canvas1.draw_circle(Vector2(380, 60), 18.0, Color(1.0, 0.65, 0.55))
		# Distant mountains and spires
		var pts = PackedVector2Array([
			Vector2(0, 270), Vector2(0, 160), Vector2(70, 130), Vector2(130, 175),
			Vector2(200, 120), Vector2(240, 150), Vector2(310, 110), Vector2(380, 165),
			Vector2(440, 135), Vector2(480, 155), Vector2(480, 270)
		])
		canvas1.draw_colored_polygon(pts, Color(0.12, 0.10, 0.18))
	)
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Midground Gothic Castle Towers & Spires
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.40, 0.10)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = Node2D.new()
	canvas2.draw.connect(func():
		var col_castle = Color(0.18, 0.16, 0.25)
		var col_window = Color(1.0, 0.75, 0.2, 0.6) # Torchlit windows

		# Tower 1
		canvas2.draw_rect(Rect2(40, 90, 50, 180), col_castle)
		canvas2.draw_colored_polygon(PackedVector2Array([Vector2(35, 90), Vector2(65, 40), Vector2(95, 90)]), col_castle.lightened(0.1))
		canvas2.draw_rect(Rect2(58, 120, 14, 24), col_window)

		# Tower 2
		canvas2.draw_rect(Rect2(260, 80, 65, 190), col_castle)
		canvas2.draw_colored_polygon(PackedVector2Array([Vector2(255, 80), Vector2(292, 30), Vector2(330, 80)]), col_castle.lightened(0.1))
		canvas2.draw_rect(Rect2(285, 110, 15, 26), col_window)
		canvas2.draw_rect(Rect2(285, 160, 15, 26), col_window)

		# Curtain Wall
		canvas2.draw_rect(Rect2(90, 150, 170, 120), col_castle.darkened(0.1))
	)
	layer2.add_child(canvas2)
	add_child(layer2)
