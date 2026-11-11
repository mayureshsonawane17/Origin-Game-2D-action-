class_name TitleBackground
extends Control

## TitleBackground: Cyberpunk / Dark Sci-Fi Glitch animated background for ORIGIN.
## Features:
## 1. Deep space cosmic nebula with pulsating cyber stars
## 2. Animated neon synthwave perspective grid (forward scrolling velocity)
## 3. Floating crystalline gemstone shards & reality fracture fissures
## 4. Digital glitch slices, holographic scanlines, and rising neon motes
## 5. Smooth mouse-parallax tracking for depth

@export var grid_speed: float = 48.0
@export var star_count: int = 45
@export var shard_count: int = 8
@export var ember_count: int = 35

var time_elapsed: float = 0.0
var mouse_offset: Vector2 = Vector2.ZERO
var target_mouse_offset: Vector2 = Vector2.ZERO

# Starfield data: [x, y, size, pulse_speed, pulse_phase, base_color]
var stars: Array[Dictionary] = []

# Gemstone shards: [pos, vel, rot, rot_speed, scale, points, colors]
var shards: Array[Dictionary] = []

# Rising cyber embers: [pos, vel, size, alpha, max_life, life, color]
var embers: Array[Dictionary] = []

# Glitch state
var glitch_timer: float = 0.0
var glitch_active: bool = false
var glitch_slices: Array[Rect2] = []
var glitch_offsets: Array[float] = []

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_IGNORE
	_init_stars()
	_init_shards()
	_init_embers()

func _init_stars() -> void:
	stars.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(star_count):
		stars.append({
			"pos": Vector2(rng.randf_range(0, 480), rng.randf_range(0, 180)),
			"size": rng.randf_range(0.8, 2.2),
			"speed": rng.randf_range(1.5, 4.0),
			"phase": rng.randf_range(0, TAU),
			"color": Color("#00f0ff") if rng.randf() > 0.4 else Color("#ff0077")
		})

func _init_shards() -> void:
	shards.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(shard_count):
		var base_size = rng.randf_range(10.0, 26.0)
		# Build a diamond / faceted crystal polygon
		var pts = PackedVector2Array([
			Vector2(0, -base_size),
			Vector2(base_size * 0.65, -base_size * 0.2),
			Vector2(base_size * 0.5, base_size * 0.7),
			Vector2(0, base_size),
			Vector2(-base_size * 0.5, base_size * 0.7),
			Vector2(-base_size * 0.65, -base_size * 0.2)
		])
		shards.append({
			"pos": Vector2(rng.randf_range(30, 450), rng.randf_range(20, 160)),
			"vel": Vector2(rng.randf_range(-4, 4), rng.randf_range(-2, 3)),
			"rot": rng.randf_range(0, TAU),
			"rot_speed": rng.randf_range(-0.4, 0.4),
			"pts": pts,
			"scale": rng.randf_range(0.6, 1.2),
			"depth": rng.randf_range(0.2, 0.9)
		})

func _init_embers() -> void:
	embers.clear()
	var rng = RandomNumberGenerator.new()
	for i in range(ember_count):
		_spawn_ember(rng, true)

func _spawn_ember(rng: RandomNumberGenerator, random_y: bool = false) -> void:
	var y_pos = rng.randf_range(0, 270) if random_y else rng.randf_range(250, 275)
	var col = Color("#00ffff") if rng.randf() > 0.45 else Color("#ff00aa")
	if rng.randf() > 0.85:
		col = Color("#ffe600")
	embers.append({
		"pos": Vector2(rng.randf_range(0, 480), y_pos),
		"vel": Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-18.0, -42.0)),
		"size": rng.randf_range(1.0, 2.8),
		"life": rng.randf_range(0.0, 4.0) if random_y else 0.0,
		"max_life": rng.randf_range(3.0, 6.0),
		"color": col
	})

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var center = get_viewport_rect().size * 0.5
		if center.x > 0 and center.y > 0:
			target_mouse_offset = (event.position - center) / center # -1.0 to 1.0

func _process(delta: float) -> void:
	time_elapsed += delta
	# Smooth parallax damping
	mouse_offset = mouse_offset.lerp(target_mouse_offset, delta * 3.0)

	# Update shards
	for shard in shards:
		shard["rot"] += shard["rot_speed"] * delta
		shard["pos"] += shard["vel"] * delta
		# Wrap around screen edges
		if shard["pos"].x < -40: shard["pos"].x = 520
		elif shard["pos"].x > 520: shard["pos"].x = -40
		if shard["pos"].y < -40: shard["pos"].y = 200
		elif shard["pos"].y > 200: shard["pos"].y = -40

	# Update embers
	var rng = RandomNumberGenerator.new()
	for i in range(embers.size() - 1, -1, -1):
		var e = embers[i]
		e["life"] += delta
		e["pos"] += e["vel"] * delta
		# Slight horizontal sway
		e["pos"].x += sin(time_elapsed * 3.0 + i) * 0.35
		if e["life"] >= e["max_life"] or e["pos"].y < -10:
			embers.remove_at(i)
			_spawn_ember(rng, false)

	# Glitch triggers (periodic reality de-sync pulse)
	glitch_timer += delta
	if glitch_timer >= 3.6:
		glitch_timer = 0.0
		glitch_active = true
		_generate_glitch_slices(rng)
	elif glitch_timer >= 0.18 and glitch_active:
		glitch_active = false
		glitch_slices.clear()

	queue_redraw()

func _generate_glitch_slices(rng: RandomNumberGenerator) -> void:
	glitch_slices.clear()
	glitch_offsets.clear()
	var slice_count = rng.randi_range(3, 7)
	for i in range(slice_count):
		var sy = rng.randf_range(10, 250)
		var sh = rng.randf_range(4, 18)
		glitch_slices.append(Rect2(0, sy, 480, sh))
		glitch_offsets.append(rng.randf_range(-12.0, 12.0))

func _draw() -> void:
	var screen_w = size.x if size.x > 0 else 480.0
	var screen_h = size.y if size.y > 0 else 270.0
	var horizon_y = 152.0 + mouse_offset.y * 6.0
	var vp_x = screen_w * 0.5 + mouse_offset.x * 24.0

	# 1. Base Cosmic Sci-Fi Gradient Background
	# Dark void top to glowing cyberpunk horizon
	draw_rect(Rect2(0, 0, screen_w, screen_h), Color("#030408"))
	
	# Atmospheric upper nebula glow
	var nebula_h = horizon_y
	var steps = 12
	for i in range(steps):
		var t = float(i) / float(steps)
		var y1 = t * nebula_h
		var y2 = ((float(i) + 1.0) / float(steps)) * nebula_h
		var col = Color("#04050d").lerp(Color("#140727"), t * 0.8)
		col = col.lerp(Color("#081c2e"), t * t * 0.5)
		draw_rect(Rect2(0, y1, screen_w, y2 - y1 + 1.0), col)

	# 2. Distant Twinkling Cyber Stars
	for star in stars:
		var pulse = (sin(time_elapsed * star["speed"] + star["phase"]) + 1.0) * 0.5
		var star_pos = star["pos"] + mouse_offset * (star["size"] * 4.0)
		var alpha = 0.35 + pulse * 0.65
		var star_col = Color(star["color"].r, star["color"].g, star["color"].b, alpha)
		draw_circle(star_pos, star["size"] * (0.8 + pulse * 0.3), star_col)
		# Cross flare on brightest stars
		if star["size"] > 1.8 and pulse > 0.7:
			var flare_len = 4.0 + pulse * 3.0
			draw_line(star_pos - Vector2(flare_len, 0), star_pos + Vector2(flare_len, 0), Color(1, 1, 1, 0.5), 1.0)
			draw_line(star_pos - Vector2(0, flare_len), star_pos + Vector2(0, flare_len), Color(1, 1, 1, 0.5), 1.0)

	# 3. Floating Reality Fracture Fissures (Gemstone cracks in spacetime)
	_draw_fracture_fissures(horizon_y)

	# 4. Floating Crystalline Gemstone Shards (Deep parallax)
	for shard in shards:
		_draw_crystal_shard(shard)

	# 5. Neon Perspective Cyber Grid (Lower Screen)
	_draw_cyber_grid(screen_w, screen_h, horizon_y, vp_x)

	# 6. Horizon Neon Bloom Strip
	var horizon_col_cyan = Color("#00f0ff")
	var horizon_col_pink = Color("#ff007f")
	# Soft gradient glow around horizon
	draw_line(Vector2(0, horizon_y), Vector2(screen_w, horizon_y), Color(0.2, 0.9, 1.0, 0.85), 2.0)
	draw_line(Vector2(0, horizon_y - 1), Vector2(screen_w, horizon_y - 1), Color(1.0, 0.1, 0.7, 0.45), 1.0)
	draw_line(Vector2(0, horizon_y + 1), Vector2(screen_w, horizon_y + 1), Color(0.0, 1.0, 0.9, 0.45), 1.0)

	# Horizon soft haze
	var haze_poly = PackedVector2Array([
		Vector2(0, horizon_y - 24),
		Vector2(screen_w, horizon_y - 24),
		Vector2(screen_w, horizon_y + 18),
		Vector2(0, horizon_y + 18)
	])
	var haze_col = Color(0.12, 0.05, 0.28, 0.28)
	draw_colored_polygon(haze_poly, haze_col)

	# 7. Rising Cyber Embers & Data Sparks
	for e in embers:
		var life_ratio = e["life"] / e["max_life"]
		var alpha = sin(life_ratio * PI) * 0.9
		var ember_col = Color(e["color"].r, e["color"].g, e["color"].b, alpha)
		var p = e["pos"] + mouse_offset * 6.0
		draw_circle(p, e["size"], ember_col)
		# Halo
		draw_circle(p, e["size"] * 2.2, Color(ember_col.r, ember_col.g, ember_col.b, alpha * 0.3))

	# 8. Cyber Glitch Slices (Simulating the broken reality prison loop)
	if glitch_active:
		for s_idx in range(glitch_slices.size()):
			var rect = glitch_slices[s_idx]
			var offset_x = glitch_offsets[s_idx]
			# Cyan chromatic slice
			draw_rect(Rect2(rect.position.x + offset_x, rect.position.y, rect.size.x, rect.size.y), Color(0.0, 0.9, 1.0, 0.16))
			# Magenta chromatic fringe
			draw_rect(Rect2(rect.position.x - offset_x * 0.5, rect.position.y, rect.size.x, 1.0), Color(1.0, 0.0, 0.6, 0.45))
			draw_line(Vector2(0, rect.position.y), Vector2(screen_w, rect.position.y), Color(1.0, 1.0, 1.0, 0.3), 1.0)

	# 9. Subtle CRT / Hologram Scanlines
	var scanline_col = Color(0.0, 0.0, 0.0, 0.12)
	for y in range(0, int(screen_h), 3):
		draw_line(Vector2(0, y), Vector2(screen_w, y), scanline_col, 1.0)

func _draw_cyber_grid(screen_w: float, screen_h: float, horizon_y: float, vp_x: float) -> void:
	var grid_color_cyan = Color(0.0, 0.85, 1.0, 0.35)
	var grid_color_magenta = Color(0.9, 0.1, 0.7, 0.28)
	var grid_bottom_h = screen_h - horizon_y

	# Dynamic forward movement offset (0.0 to 1.0)
	var move_progress = fmod(time_elapsed * (grid_speed / 40.0), 1.0)

	# Horizontal perspective lines (geometric distribution)
	var num_horiz_lines = 14
	for i in range(num_horiz_lines):
		# Non-linear spacing for realistic 3D perspective
		var norm = (float(i) + move_progress) / float(num_horiz_lines)
		if norm <= 0.0 or norm > 1.0:
			continue
		var y = horizon_y + (norm * norm) * grid_bottom_h
		var alpha = norm * 0.55
		var line_col = grid_color_cyan.lerp(grid_color_magenta, norm * 0.7)
		line_col.a = alpha
		var line_w = 1.0 + norm * 1.5
		draw_line(Vector2(0, y), Vector2(screen_w, y), line_col, line_w)

	# Perspective vertical lines converging at horizon (vp_x, horizon_y)
	var num_vert_lines = 22
	var spread_bottom = screen_w * 2.2
	var start_x = vp_x - spread_bottom * 0.5
	var step_x = spread_bottom / float(num_vert_lines)

	for i in range(num_vert_lines + 1):
		var bx = start_x + float(i) * step_x
		# Calculate line from horizon point to bottom
		var line_col = grid_color_cyan
		line_col.a = 0.30
		draw_line(Vector2(vp_x, horizon_y), Vector2(bx, screen_h), line_col, 1.2)

func _draw_fracture_fissures(horizon_y: float) -> void:
	# Spacetime fissure cracks across the sky
	var pulse = (sin(time_elapsed * 2.8) + 1.0) * 0.5
	var fissure_col = Color(0.3, 0.9, 1.0, 0.25 + pulse * 0.35)
	var neon_glow = Color(0.85, 0.2, 1.0, 0.18 + pulse * 0.20)

	# Main lightning-like spacetime fracture 1 (left side)
	var f1 = PackedVector2Array([
		Vector2(70 + mouse_offset.x * 12, 15),
		Vector2(110 + mouse_offset.x * 10, 42),
		Vector2(95 + mouse_offset.x * 8, 68),
		Vector2(140 + mouse_offset.x * 6, 95),
		Vector2(125 + mouse_offset.x * 5, 125),
		Vector2(160 + mouse_offset.x * 3, horizon_y)
	])
	draw_polyline(f1, neon_glow, 3.5)
	draw_polyline(f1, fissure_col, 1.5)
	draw_polyline(f1, Color(1, 1, 1, 0.6 * pulse), 0.8)

	# Minor spacetime fracture 2 (right side)
	var f2 = PackedVector2Array([
		Vector2(410 + mouse_offset.x * 10, 25),
		Vector2(375 + mouse_offset.x * 8, 55),
		Vector2(395 + mouse_offset.x * 6, 80),
		Vector2(360 + mouse_offset.x * 4, 115)
	])
	draw_polyline(f2, neon_glow, 2.8)
	draw_polyline(f2, fissure_col, 1.2)

func _draw_crystal_shard(shard: Dictionary) -> void:
	var pos = shard["pos"] + mouse_offset * (shard["depth"] * 18.0)
	var rot = shard["rot"]
	var s = shard["scale"]
	var depth = shard["depth"]

	# Transform polygon points by rotation and scale
	var transformed_pts = PackedVector2Array()
	for pt in shard["pts"]:
		var rotated = pt.rotated(rot) * s
		transformed_pts.append(pos + rotated)

	# Color styling based on depth
	var base_col = Color("#00d9ff").lerp(Color("#bd00ff"), sin(rot) * 0.5 + 0.5)
	base_col.a = 0.35 + depth * 0.40

	# Fill shard polygon
	draw_colored_polygon(transformed_pts, base_col)

	# Facet outline with neon edge glint
	var border_col = Color(1.0, 1.0, 1.0, 0.5 + depth * 0.4)
	for i in range(transformed_pts.size()):
		var p1 = transformed_pts[i]
		var p2 = transformed_pts[(i + 1) % transformed_pts.size()]
		draw_line(p1, p2, border_col, 1.2)

	# Inner crystal facet ridge line
	if transformed_pts.size() >= 4:
		draw_line(transformed_pts[0], transformed_pts[3], Color(0.8, 0.95, 1.0, 0.6), 1.0)
