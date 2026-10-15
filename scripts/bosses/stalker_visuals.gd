class_name StalkerVisuals
extends Node2D

## Procedural pixel art renderer for Boss: Primal Stalker.

var current_pose: String = "idle"
var anim_timer: float = 0.0

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func set_pose(pose: String) -> void:
	current_pose = pose
	queue_redraw()

func _draw() -> void:
	# Origin (0,0) at ground feet
	var col_body = Color(0.24, 0.22, 0.20)
	var col_belly = Color(0.48, 0.42, 0.35)
	var col_crest = Color(0.95, 0.35, 0.15)
	var col_eye = Color(1.0, 0.85, 0.2)
	var col_fang = Color(0.95, 0.95, 0.9)

	var body_y = -14.0
	var head_x = 12.0
	var head_y = -20.0
	var crest_h = 7.0

	if current_pose == "telegraph":
		body_y = -10.0
		head_x = 8.0
		head_y = -15.0
		col_crest = Color(1.0, 0.9, 0.2) # High warning glow
		crest_h = 10.0
	elif current_pose == "lunge" or current_pose == "swipe":
		body_y = -16.0
		head_x = 16.0
		head_y = -22.0
	elif current_pose == "recovery":
		body_y = -10.0
		head_x = 6.0
		head_y = -14.0

	# 1. Spiked Tail
	draw_rect(Rect2(-26, body_y - 2, 10, 5), col_body)
	draw_rect(Rect2(-32, body_y - 6, 8, 4), col_body)
	draw_rect(Rect2(-30, body_y - 10, 4, 4), col_crest) # Tail spike

	# 2. Back Legs
	draw_rect(Rect2(-16, body_y + 4, 6, 10), col_body.darkened(0.2))
	draw_rect(Rect2(-18, body_y + 12, 8, 3), col_body.darkened(0.3))

	# 3. Main Torso (34w x 16h)
	draw_rect(Rect2(-18, body_y - 8, 32, 16), col_body)
	# Armored underbelly
	draw_rect(Rect2(-14, body_y + 2, 24, 5), col_belly)

	# 4. Flaming Spines along spine
	for i in 4:
		var sx = -14.0 + (i * 7.0)
		draw_rect(Rect2(sx, body_y - 8 - crest_h, 4, crest_h), col_crest)

	# 5. Front Legs / Claws
	draw_rect(Rect2(6, body_y + 4, 6, 10), col_body)
	draw_rect(Rect2(6, body_y + 12, 9, 3), col_body.darkened(0.2))

	# 6. Head & Sabre Fangs
	draw_rect(Rect2(head_x, head_y, 14, 12), col_body)
	draw_rect(Rect2(head_x + 8, head_y + 4, 8, 8), col_body)
	# Eye
	draw_rect(Rect2(head_x + 6, head_y + 3, 3, 3), col_eye)
	# Giant Sabre Fangs
	draw_rect(Rect2(head_x + 12, head_y + 10, 3, 6), col_fang)
	draw_rect(Rect2(head_x + 8, head_y + 10, 2, 4), col_fang)
