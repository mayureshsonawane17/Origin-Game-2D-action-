class_name ProwlerVisuals
extends Node2D

## Procedural pixel art renderer for the Prehistoric Crested Prowler.

var current_pose: String = "walk"
var anim_timer: float = 0.0

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func set_pose(pose: String) -> void:
	current_pose = pose
	queue_redraw()

func _draw() -> void:
	# Origin (0,0) is at ground level between feet
	var col_skin = Color(0.18, 0.32, 0.22)
	var col_belly = Color(0.55, 0.52, 0.38)
	var col_crest = Color(0.85, 0.22, 0.18)
	var col_eye = Color(1.0, 0.85, 0.1)
	var col_teeth = Color(0.95, 0.95, 0.9)

	var body_y = -10.0
	var head_x = 8.0
	var head_y = -14.0
	var leg_front_offset = 0.0
	var leg_back_offset = 0.0

	if current_pose == "walk":
		body_y += sin(anim_timer * 6.0) * 1.0
		leg_front_offset = sin(anim_timer * 6.0) * 3.0
		leg_back_offset = -leg_front_offset
	elif current_pose == "run":
		body_y += abs(sin(anim_timer * 12.0)) * -2.0
		leg_front_offset = sin(anim_timer * 12.0) * 5.0
		leg_back_offset = -leg_front_offset
	elif current_pose == "telegraph":
		# Crouch down, crest flaring
		body_y = -7.0
		head_x = 5.0
		head_y = -10.0
		col_crest = Color(1.0, 0.45, 0.05) # Bright orange flare
	elif current_pose == "lunge":
		body_y = -12.0
		head_x = 12.0
		head_y = -15.0
	elif current_pose == "hurt":
		body_y = -8.0
		head_x = 4.0
		head_y = -12.0
		col_eye = col_skin # Eyes closed

	# 1. Tail (curved back)
	draw_rect(Rect2(-18, body_y - 4, 6, 4), col_skin)
	draw_rect(Rect2(-22, body_y - 7, 5, 3), col_skin)

	# 2. Back Legs
	draw_rect(Rect2(-12 + leg_back_offset, body_y + 4, 4, 7), col_skin.darkened(0.2))
	draw_rect(Rect2(-13 + leg_back_offset, body_y + 9, 5, 2), col_skin.darkened(0.3))

	# 3. Main Torso
	draw_rect(Rect2(-14, body_y - 6, 22, 12), col_skin)
	# Belly underside
	draw_rect(Rect2(-10, body_y + 2, 16, 4), col_belly)

	# 4. Spiked Crest along spine
	var crest_h = 5 if current_pose != "telegraph" else 7
	draw_rect(Rect2(-12, body_y - 6 - crest_h, 3, crest_h), col_crest)
	draw_rect(Rect2(-7, body_y - 6 - (crest_h + 1), 3, crest_h + 1), col_crest)
	draw_rect(Rect2(-2, body_y - 6 - crest_h, 3, crest_h), col_crest)
	draw_rect(Rect2(3, body_y - 6 - (crest_h - 1), 3, crest_h - 1), col_crest)

	# 5. Front Legs
	draw_rect(Rect2(4 + leg_front_offset, body_y + 4, 4, 7), col_skin)
	draw_rect(Rect2(4 + leg_front_offset, body_y + 9, 5, 2), col_skin.darkened(0.2))

	# 6. Head & Snout
	draw_rect(Rect2(head_x, head_y, 10, 8), col_skin)
	draw_rect(Rect2(head_x + 6, head_y + 2, 6, 6), col_skin) # Snout
	# Jaw / Teeth
	draw_rect(Rect2(head_x + 7, head_y + 6, 4, 2), col_teeth)
	# Eye
	draw_rect(Rect2(head_x + 4, head_y + 2, 2, 2), col_eye)

	# Telegraph alert icon if alert pose
	if current_pose == "alert":
		draw_rect(Rect2(head_x + 2, head_y - 10, 3, 6), Color(1.0, 0.2, 0.2))
		draw_rect(Rect2(head_x + 2, head_y - 2, 3, 2), Color(1.0, 0.2, 0.2))
