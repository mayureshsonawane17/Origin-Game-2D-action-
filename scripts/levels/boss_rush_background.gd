class_name BossRushBackground
extends Node2D

## Dynamic procedural arena background for Boss Rush mode.
## Dynamically re-themes silhouettes, sky gradients, and ambient lighting as eras progress.

var current_era: String = "Prehistoric"
var era_time: float = 0.0

# Era Color Palettes
var sky_top: Color = Color(0.04, 0.10, 0.09)
var sky_bottom: Color = Color(0.08, 0.18, 0.14)
var back_color: Color = Color(0.06, 0.14, 0.12)
var mid_color: Color = Color(0.09, 0.22, 0.16)
var accent_color: Color = Color(0.3, 0.8, 0.5, 0.3)

# Floating ambient motes
var motes: Array[Vector2] = []

func _ready() -> void:
	z_index = -10
	set_era_theme("Prehistoric")
	for i in 20:
		motes.append(Vector2(randf_range(0, 640), randf_range(0, 240)))

func _process(delta: float) -> void:
	era_time += delta
	for i in motes.size():
		motes[i].y -= delta * 12.0
		motes[i].x += sin(era_time + float(i)) * delta * 8.0
		if motes[i].y < -10.0:
			motes[i].y = 260.0
			motes[i].x = randf_range(0, 640)
	queue_redraw()

func set_era_theme(era_name: String) -> void:
	current_era = era_name
	match era_name.to_lower():
		"prehistoric":
			sky_top = Color(0.04, 0.10, 0.09)
			sky_bottom = Color(0.08, 0.18, 0.14)
			back_color = Color(0.06, 0.14, 0.12)
			mid_color = Color(0.09, 0.22, 0.16)
			accent_color = Color(0.3, 0.8, 0.5, 0.3)
		"medieval":
			sky_top = Color(0.05, 0.05, 0.10)
			sky_bottom = Color(0.12, 0.06, 0.10)
			back_color = Color(0.08, 0.07, 0.12)
			mid_color = Color(0.12, 0.10, 0.16)
			accent_color = Color(0.9, 0.4, 0.2, 0.3)
		"historical":
			sky_top = Color(0.06, 0.04, 0.12)
			sky_bottom = Color(0.15, 0.05, 0.12)
			back_color = Color(0.10, 0.05, 0.14)
			mid_color = Color(0.12, 0.06, 0.16)
			accent_color = Color(0.9, 0.3, 0.6, 0.3)
		"industrial":
			sky_top = Color(0.08, 0.06, 0.04)
			sky_bottom = Color(0.18, 0.10, 0.04)
			back_color = Color(0.12, 0.09, 0.06)
			mid_color = Color(0.16, 0.11, 0.07)
			accent_color = Color(1.0, 0.6, 0.2, 0.3)
		"modern":
			sky_top = Color(0.03, 0.05, 0.09)
			sky_bottom = Color(0.07, 0.09, 0.16)
			back_color = Color(0.05, 0.07, 0.12)
			mid_color = Color(0.08, 0.10, 0.16)
			accent_color = Color(0.3, 0.7, 1.0, 0.3)
		"futuristic":
			sky_top = Color(0.04, 0.02, 0.10)
			sky_bottom = Color(0.08, 0.04, 0.18)
			back_color = Color(0.12, 0.05, 0.22)
			mid_color = Color(0.16, 0.08, 0.28)
			accent_color = Color(0.4, 0.8, 1.0, 0.4)
		"the fortress", "fortress":
			sky_top = Color(0.02, 0.01, 0.05)
			sky_bottom = Color(0.08, 0.02, 0.10)
			back_color = Color(0.15, 0.03, 0.20)
			mid_color = Color(0.20, 0.05, 0.28)
			accent_color = Color(0.95, 0.2, 0.85, 0.45)
	queue_redraw()

func _draw() -> void:
	# 1. Sky background
	draw_rect(Rect2(-50, -80, 740, 380), sky_top)
	draw_rect(Rect2(-50, 60, 740, 240), sky_bottom)

	# 2. Era-specific Back Silhouettes
	match current_era.to_lower():
		"prehistoric":
			_draw_volcanic_mountains()
			_draw_primeval_trees()
		"medieval":
			_draw_gothic_spires()
			_draw_battlements()
		"historical":
			_draw_pagoda_silhouettes()
			_draw_bamboo_groves()
		"industrial":
			_draw_factory_smokestacks()
			_draw_iron_trusses()
		"modern":
			_draw_city_skyscrapers()
			_draw_rooftop_structures()
		"futuristic":
			_draw_cyber_spires()
			_draw_quantum_grid()
		_: # Fortress
			_draw_monolith_fissures()
			_draw_gemstone_shards()

	# 3. Floating ambient motes
	for pt in motes:
		draw_circle(pt, 1.5, accent_color)

	# 4. Arena Floor Pedestal Glow
	draw_rect(Rect2(-20, 226, 680, 4), accent_color)

func _draw_volcanic_mountains() -> void:
	for i in 4:
		var mx = i * 200.0 - 50.0
		var pts = PackedVector2Array([
			Vector2(mx, 230),
			Vector2(mx + 80, 50),
			Vector2(mx + 140, 90),
			Vector2(mx + 220, 230)
		])
		draw_colored_polygon(pts, back_color)

func _draw_primeval_trees() -> void:
	for i in 6:
		var tx = i * 120.0 + 20.0
		draw_rect(Rect2(tx, 90, 14, 140), mid_color)
		var canopy = PackedVector2Array([
			Vector2(tx - 35, 110),
			Vector2(tx + 7, 65),
			Vector2(tx + 49, 110)
		])
		draw_colored_polygon(canopy, mid_color)

func _draw_gothic_spires() -> void:
	for i in 5:
		var sx = i * 140.0 + 10.0
		draw_rect(Rect2(sx, 70, 36, 160), back_color)
		var spire = PackedVector2Array([
			Vector2(sx, 70),
			Vector2(sx + 18, 20),
			Vector2(sx + 36, 70)
		])
		draw_colored_polygon(spire, back_color)

func _draw_battlements() -> void:
	for i in 8:
		var bx = i * 85.0
		draw_rect(Rect2(bx, 130, 40, 100), mid_color)
		# Crenellations
		draw_rect(Rect2(bx + 4, 118, 10, 12), mid_color)
		draw_rect(Rect2(bx + 26, 118, 10, 12), mid_color)

func _draw_pagoda_silhouettes() -> void:
	# Giant Torii gate in back center
	draw_rect(Rect2(280, 50, 16, 180), back_color)
	draw_rect(Rect2(360, 50, 16, 180), back_color)
	draw_rect(Rect2(260, 55, 136, 14), back_color)
	draw_rect(Rect2(270, 80, 116, 10), back_color)

func _draw_bamboo_groves() -> void:
	for i in 14:
		var bx = i * 50.0 + 10.0
		draw_rect(Rect2(bx, 70, 6, 160), mid_color)
		draw_line(Vector2(bx - 12, 100), Vector2(bx, 115), mid_color, 2.0)
		draw_line(Vector2(bx + 6, 130), Vector2(bx + 18, 145), mid_color, 2.0)

func _draw_factory_smokestacks() -> void:
	for i in 5:
		var fx = i * 135.0 + 20.0
		draw_rect(Rect2(fx, 40, 22, 190), back_color)
		draw_rect(Rect2(fx - 4, 34, 30, 8), back_color)

func _draw_iron_trusses() -> void:
	for i in 6:
		var tx = i * 110.0 + 10.0
		draw_rect(Rect2(tx, 110, 65, 120), mid_color)
		draw_line(Vector2(tx, 110), Vector2(tx + 65, 230), back_color, 3.0)
		draw_line(Vector2(tx + 65, 110), Vector2(tx, 230), back_color, 3.0)

func _draw_city_skyscrapers() -> void:
	for i in 8:
		var kx = i * 85.0
		var h = 90.0 + sin(float(i) * 2.1) * 45.0
		draw_rect(Rect2(kx, 230 - h, 60, h), back_color)
		# Windows grid
		for wy in range(int(240 - h) + 8, 220, 12):
			draw_circle(Vector2(kx + 16, wy), 1.5, Color(1, 0.9, 0.4, 0.4))
			draw_circle(Vector2(kx + 44, wy), 1.5, Color(1, 0.9, 0.4, 0.4))

func _draw_rooftop_structures() -> void:
	for i in 5:
		var rx = i * 130.0 + 30.0
		draw_rect(Rect2(rx, 140, 70, 90), mid_color)
		draw_line(Vector2(rx + 35, 95), Vector2(rx + 35, 140), mid_color, 2.0)

func _draw_cyber_spires() -> void:
	for i in 6:
		var cx = i * 110.0 + 15.0
		draw_rect(Rect2(cx, 40, 26, 190), back_color)
		draw_line(Vector2(cx + 13, 10), Vector2(cx + 13, 40), accent_color, 2.0)

func _draw_quantum_grid() -> void:
	for i in 9:
		var gx = i * 75.0
		draw_line(Vector2(gx, 230), Vector2(320 + (gx - 320) * 0.4, 120), mid_color, 1.5)

func _draw_monolith_fissures() -> void:
	for i in 5:
		var fx = i * 130.0 + 40.0
		var pts = PackedVector2Array([
			Vector2(fx, 230),
			Vector2(fx + 12, 60),
			Vector2(fx + 34, 40),
			Vector2(fx + 46, 230)
		])
		draw_colored_polygon(pts, back_color)

func _draw_gemstone_shards() -> void:
	# Floating fractured reality crystal shards
	for i in 7:
		var sx = i * 90.0 + 30.0
		var sy = 90.0 + sin(era_time * 2.0 + float(i)) * 14.0
		var shard = PackedVector2Array([
			Vector2(sx, sy - 14),
			Vector2(sx + 10, sy),
			Vector2(sx, sy + 14),
			Vector2(sx - 10, sy)
		])
		draw_colored_polygon(shard, Color(0.95, 0.2, 0.85, 0.7))
