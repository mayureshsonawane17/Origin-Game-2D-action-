class_name IndustrialFactoryPlatform
extends StaticBody2D

## Procedural pixel art riveted iron girder & steel factory platform for Chapter 4 (Industrial Era).

@export var platform_size: Vector2 = Vector2(160, 40)
@export var has_hazard_stripes: bool = true

var collision_shape: CollisionShape2D

func _ready() -> void:
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

	var rect_shape = RectangleShape2D.new()
	rect_shape.size = platform_size
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(platform_size.x * 0.5, platform_size.y * 0.5)
	queue_redraw()

func _draw() -> void:
	# Heavy riveted dark industrial iron girder
	var col_steel = Color(0.24, 0.26, 0.30)
	var col_shadow = Color(0.12, 0.14, 0.16)
	var col_rivet = Color(0.65, 0.68, 0.75)
	var col_caution_yellow = Color(0.92, 0.75, 0.15)
	var col_caution_black = Color(0.12, 0.12, 0.14)

	# Main platform body
	draw_rect(Rect2(Vector2.ZERO, platform_size), col_steel)

	# Top edge hazard stripes or steel catwalk plate
	if has_hazard_stripes and platform_size.y >= 20.0:
		var stripe_w = 12.0
		var count = int(ceil(platform_size.x / stripe_w))
		for i in range(count):
			var x = i * stripe_w
			var col = col_caution_yellow if (i % 2 == 0) else col_caution_black
			draw_rect(Rect2(Vector2(x, 0), Vector2(min(stripe_w, platform_size.x - x), 4.0)), col)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), col_rivet)

	# Bottom shadow line
	draw_rect(Rect2(Vector2(0, platform_size.y - 3.0), Vector2(platform_size.x, 3.0)), col_shadow)

	# Girder diagonal cross-braces
	var segment_w = 40.0
	var segments = int(ceil(platform_size.x / segment_w))
	for s in range(segments):
		var x1 = s * segment_w
		var x2 = min(x1 + segment_w, platform_size.x)
		if x2 - x1 >= 20.0 and platform_size.y >= 25.0:
			draw_line(Vector2(x1, 5.0), Vector2(x2, platform_size.y - 4.0), col_shadow, 1.5)
			draw_line(Vector2(x1, platform_size.y - 4.0), Vector2(x2, 5.0), col_shadow, 1.5)

	# Rivet bolts along edges
	var bolt_spacing = 16.0
	var bolt_count = int(floor(platform_size.x / bolt_spacing))
	for b in range(1, bolt_count):
		var bx = b * bolt_spacing
		draw_circle(Vector2(bx, 8.0), 1.2, col_rivet)
		draw_circle(Vector2(bx, platform_size.y - 6.0), 1.2, col_rivet)
