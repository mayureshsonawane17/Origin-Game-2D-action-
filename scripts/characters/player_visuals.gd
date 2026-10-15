class_name PlayerVisuals
extends Node2D

## Procedural pixel art character renderer for the Player.
## Designed to match the 32x48 bounding box and pixel art requirements (5b).

@export var anim_pose: String = "idle"
@export var weapon_swing_angle: float = 0.0
@export var show_slash_arc: bool = false
@export var slash_tier: int = 1 # 1: light, 2: medium, 3: finisher

var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	# Origin (0,0) is at character's feet
	
	# Determine procedural offsets based on anim_pose
	var body_y_offset = 0.0
	var leg_left_x = -4.0
	var leg_right_x = 2.0
	var leg_left_y = -10.0
	var leg_right_y = -10.0
	var arm_rot = weapon_swing_angle
	
	if anim_pose == "idle":
		body_y_offset = sin(anim_time * 4.0) * 1.0
	elif anim_pose == "run":
		body_y_offset = abs(sin(anim_time * 12.0)) * -2.0
		leg_left_x = -4.0 + sin(anim_time * 12.0) * 4.0
		leg_right_x = 2.0 - sin(anim_time * 12.0) * 4.0
	elif anim_pose == "jump":
		body_y_offset = -2.0
		leg_left_y = -12.0
		leg_right_y = -14.0
	elif anim_pose == "fall":
		body_y_offset = 0.0
		leg_left_y = -8.0
		leg_right_y = -9.0
	elif anim_pose == "hurt":
		body_y_offset = 1.0
	elif anim_pose == "die":
		# Collapsed on ground
		_draw_collapsed_pose()
		return

	# Color Palette (Prehistoric/Adventurer Palette)
	var col_skin = Color(0.92, 0.72, 0.58)
	var col_hair = Color(0.18, 0.14, 0.16)
	var col_headband = Color(0.2, 0.55, 0.95)
	var col_tunic = Color(0.28, 0.32, 0.38)
	var col_belt = Color(0.48, 0.30, 0.18)
	var col_gem = Color(0.2, 0.9, 0.85)
	var col_pants = Color(0.18, 0.20, 0.24)
	var col_boots = Color(0.35, 0.22, 0.14)
	var col_blade = Color(0.85, 0.88, 0.95)
	var col_hilt = Color(0.85, 0.65, 0.2)

	# 1. Back Arm / Shoulder
	draw_rect(Rect2(-8, -26 + body_y_offset, 4, 8), col_tunic.darkened(0.2))

	# 2. Legs & Boots
	# Left Leg
	draw_rect(Rect2(leg_left_x, leg_left_y, 4, 6), col_pants)
	draw_rect(Rect2(leg_left_x - 1, leg_left_y + 6, 5, 4), col_boots)
	# Right Leg
	draw_rect(Rect2(leg_right_x, leg_right_y, 4, 6), col_pants)
	draw_rect(Rect2(leg_right_x, leg_right_y + 6, 5, 4), col_boots)

	# 3. Torso & Tunic
	draw_rect(Rect2(-6, -26 + body_y_offset, 12, 14), col_tunic)
	# Gemstone pendant (narrative hook)
	draw_rect(Rect2(-1, -22 + body_y_offset, 3, 3), col_gem)
	# Belt
	draw_rect(Rect2(-6, -14 + body_y_offset, 12, 3), col_belt)
	draw_rect(Rect2(-1, -14 + body_y_offset, 3, 3), col_hilt)

	# 4. Head & Face
	draw_rect(Rect2(-5, -36 + body_y_offset, 10, 10), col_skin)
	# Hair
	draw_rect(Rect2(-6, -38 + body_y_offset, 12, 4), col_hair)
	draw_rect(Rect2(-7, -36 + body_y_offset, 3, 6), col_hair)
	# Headband & trailing ribbon
	draw_rect(Rect2(-6, -35 + body_y_offset, 12, 2), col_headband)
	draw_rect(Rect2(-9, -34 + body_y_offset, 4, 2), col_headband)
	# Eyes
	draw_rect(Rect2(2, -32 + body_y_offset, 2, 2), col_hair)

	# 5. Front Arm & Weapon
	draw_set_transform(Vector2(2, -22 + body_y_offset), arm_rot, Vector2.ONE)
	# Arm
	draw_rect(Rect2(-2, -2, 4, 8), col_skin)
	# Sword Hilt
	draw_rect(Rect2(-2, 6, 6, 2), col_hilt)
	# Sword Blade
	draw_rect(Rect2(4, 5, 16, 4), col_blade)
	draw_rect(Rect2(20, 6, 2, 2), col_blade)
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 6. Slash Arc FX (when active)
	if show_slash_arc:
		_draw_slash_arc()

func _draw_collapsed_pose() -> void:
	var col_pants = Color(0.18, 0.20, 0.24)
	var col_tunic = Color(0.28, 0.32, 0.38)
	var col_skin = Color(0.92, 0.72, 0.58)
	var col_hair = Color(0.18, 0.14, 0.16)
	draw_rect(Rect2(-16, -6, 14, 6), col_pants)
	draw_rect(Rect2(-4, -8, 12, 8), col_tunic)
	draw_rect(Rect2(8, -8, 8, 8), col_skin)
	draw_rect(Rect2(12, -10, 6, 6), col_hair)

func _draw_slash_arc() -> void:
	var col = Color(1.0, 1.0, 1.0, 0.85)
	if slash_tier == 2:
		col = Color(0.4, 0.9, 1.0, 0.9)
	elif slash_tier == 3: # Finisher
		col = Color(1.0, 0.85, 0.2, 0.95)

	# Draw crescent slash swoosh in front of character
	var pts = PackedVector2Array([
		Vector2(10, -32),
		Vector2(26, -26),
		Vector2(32, -14),
		Vector2(26, 2),
		Vector2(12, 8),
		Vector2(18, -4),
		Vector2(22, -14),
		Vector2(18, -24)
	])
	draw_colored_polygon(pts, col)
