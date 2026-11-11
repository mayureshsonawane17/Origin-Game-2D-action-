class_name FuturisticSpireBackground
extends ParallaxBackground

## Parallax background for Chapter 6: The Cybernetic Spire (Futuristic Era).
## Layers: Quantum Void sky, animated vertical laser data streams, rotating holographic energy rings,
## pulsing power conduits, and digital glitch distortion.

func _ready() -> void:
	# Layer 1: Quantum Void Sky, Monolithic Data Spires & Laser Streams
	var layer1 = ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.08, 0.03)
	layer1.motion_mirroring = Vector2(480, 0)
	var canvas1 = AnimatedQuantumVoid.new()
	layer1.add_child(canvas1)
	add_child(layer1)

	# Layer 2: Rotating Holographic Rings, Cyber Grid Rail & Conduit Arcs
	var layer2 = ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.30, 0.06)
	layer2.motion_mirroring = Vector2(480, 0)
	var canvas2 = AnimatedHoloConduit.new()
	layer2.add_child(canvas2)
	add_child(layer2)

class AnimatedQuantumVoid extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		# Quantum void abyssal gradient
		draw_rect(Rect2(0, 0, 480, 130), Color("#020308"))
		draw_rect(Rect2(0, 130, 480, 140), Color("#0a0418"))

		# Neon digital nebula haze
		var nebula_poly = PackedVector2Array([
			Vector2(0, 90), Vector2(480, 90), Vector2(480, 200), Vector2(0, 200)
		])
		draw_colored_polygon(nebula_poly, Color(0.12, 0.03, 0.25, 0.35))

		# Monolithic Cybernetic Data Spires
		var col_spire = Color("#070813")
		var col_cyan_stream = Color("#00f0ff")
		var col_pink_stream = Color("#ff00a0")

		for sx in [35, 115, 195, 275, 355, 435]:
			var sw = 42.0
			var sh = 210.0
			var sy = 60.0
			draw_rect(Rect2(sx, sy, sw, sh), col_spire)

			# Central vertical laser data stream with moving packet pulses
			var is_cyan = (sx / 40) % 2 == 0
			var stream_col = col_cyan_stream if is_cyan else col_pink_stream
			var center_x = sx + sw * 0.5

			# Base beam
			draw_line(Vector2(center_x, sy), Vector2(center_x, sy + sh), Color(stream_col.r, stream_col.g, stream_col.b, 0.35), 2.0)
			draw_line(Vector2(center_x, sy), Vector2(center_x, sy + sh), Color(1, 1, 1, 0.6), 0.8)

			# Moving data packets along stream
			var packet_offset = fmod(time * 65.0 + sx * 2.0, sh)
			var packet_y = sy + packet_offset
			draw_circle(Vector2(center_x, packet_y), 3.0, Color.WHITE)
			draw_circle(Vector2(center_x, packet_y), 6.0, Color(stream_col.r, stream_col.g, stream_col.b, 0.5))

class AnimatedHoloConduit extends Node2D:
	var time: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var col_conduit = Color("#111322")
		var holo_cyan = Color("#00f0ff")
		var holo_pink = Color("#ff00a0")

		# Horizontal energy transmission rail with electric pulse
		draw_line(Vector2(0, 135), Vector2(480, 135), col_conduit, 5.0)
		var rail_pulse = (sin(time * 4.0) + 1.0) * 0.5
		draw_line(Vector2(0, 135), Vector2(480, 135), Color(holo_cyan.r, holo_cyan.g, holo_cyan.b, 0.4 + rail_pulse * 0.5), 1.8)

		# Rotating Holographic Energy Rings
		_draw_holo_ring(Vector2(95, 110), 22.0, time * 1.5, holo_cyan)
		_draw_holo_ring(Vector2(245, 105), 26.0, -time * 1.2, holo_pink)
		_draw_holo_ring(Vector2(395, 110), 22.0, time * 1.8, holo_cyan)

		# High-voltage neon energy arcs jumping across nodes
		if int(time * 8.0) % 5 == 0:
			var arc_x = 95.0 + randf_range(-10, 10)
			draw_line(Vector2(arc_x, 110), Vector2(arc_x + randf_range(-15, 15), 135), Color(1, 1, 1, 0.8), 1.2)

	func _draw_holo_ring(pos: Vector2, radius: float, angle: float, col: Color) -> void:
		draw_arc(pos, radius, 0, TAU, 24, Color(col.r, col.g, col.b, 0.65), 1.8)
		draw_arc(pos, radius * 0.65, 0, TAU, 18, Color(1, 1, 1, 0.5), 1.0)
		draw_circle(pos, 2.5, Color.WHITE)

		# Rotating orbital pips
		var pip1 = pos + Vector2(cos(angle), sin(angle)) * radius
		var pip2 = pos + Vector2(cos(angle + PI), sin(angle + PI)) * radius
		draw_circle(pip1, 3.0, Color.WHITE)
		draw_circle(pip2, 3.0, col)
