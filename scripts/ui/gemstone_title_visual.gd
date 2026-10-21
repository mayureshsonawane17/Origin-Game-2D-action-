class_name GemstoneTitleVisual
extends Control

## Visual representation of the glowing, reality-bending Gemstone for the Title Screen.
## Displays an ornate multifaceted crystalline gem with pulsing aura and drifting time motes.

@export var pulse_speed: float = 2.2
@export var base_gem_color: Color = Color(0.2, 0.85, 1.0) # Cyan/Amethyst energy
@export var is_cracked: bool = false

var time_elapsed: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(90, 80)
	queue_redraw()

func _process(delta: float) -> void:
	time_elapsed += delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2(size.x * 0.5, size.y * 0.5)
	var pulse = (sin(time_elapsed * pulse_speed) + 1.0) * 0.5 # 0.0 to 1.0

	# 1. Outer energy aura
	var aura_radius = 28.0 + pulse * 6.0
	var aura_color = Color(base_gem_color.r, base_gem_color.g, base_gem_color.b, 0.12 + pulse * 0.10)
	draw_circle(center, aura_radius, aura_color)

	var inner_aura_radius = 20.0 + pulse * 3.0
	var inner_aura_color = Color(0.9, 0.4, 1.0, 0.20 + pulse * 0.15)
	draw_circle(center, inner_aura_radius, inner_aura_color)

	# 2. Gemstone Vertices (faceted hexagon with apex points)
	var outer_pts = PackedVector2Array([
		center + Vector2(0, -22),
		center + Vector2(18, -10),
		center + Vector2(18, 11),
		center + Vector2(0, 23),
		center + Vector2(-18, 11),
		center + Vector2(-18, -10)
	])

	var inner_pts = PackedVector2Array([
		center + Vector2(0, -11),
		center + Vector2(9, -5),
		center + Vector2(9, 6),
		center + Vector2(0, 12),
		center + Vector2(-9, 6),
		center + Vector2(-9, -5)
	])

	# 3. Draw outer facet triangles
	for i in range(6):
		var next_i = (i + 1) % 6
		var facet_col = base_gem_color.lerp(Color(0.8, 0.2, 0.9), float(i) / 6.0)
		facet_col.a = 0.75 + pulse * 0.15
		if i % 2 == 0:
			facet_col = facet_col.lightened(0.2)
		else:
			facet_col = facet_col.darkened(0.25)

		var tri = PackedVector2Array([outer_pts[i], outer_pts[next_i], inner_pts[next_i], inner_pts[i]])
		draw_colored_polygon(tri, facet_col)

	# 4. Draw central core polygon
	var core_color = Color(0.95, 0.98, 1.0, 0.90 + pulse * 0.10)
	draw_colored_polygon(inner_pts, core_color)

	# 5. Crystalline rim and facet lines
	var rim_color = Color(1.0, 1.0, 1.0, 0.9)
	draw_polyline(outer_pts, rim_color, 1.5)
	draw_line(outer_pts[5], outer_pts[0], rim_color, 1.5)

	var inner_rim = Color(0.8, 0.9, 1.0, 0.7)
	draw_polyline(inner_pts, inner_rim, 1.0)
	draw_line(inner_pts[5], inner_pts[0], inner_rim, 1.0)

	for i in range(6):
		draw_line(outer_pts[i], inner_pts[i], inner_rim, 1.0)

	# 6. Fracture cracks if loop destabilization is high
	if is_cracked or (ResetManager and ResetManager.reset_count > 0):
		var crack_col = Color(1.0, 0.3, 0.4, 0.85)
		draw_line(center + Vector2(-5, -14), center + Vector2(4, 2), crack_col, 1.2)
		draw_line(center + Vector2(4, 2), center + Vector2(-3, 14), crack_col, 1.2)
		draw_line(center + Vector2(4, 2), center + Vector2(12, 5), crack_col, 1.0)
