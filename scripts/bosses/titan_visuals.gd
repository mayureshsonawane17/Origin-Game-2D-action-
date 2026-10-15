class_name TitanVisuals
extends Node2D

## Procedural pixel art renderer for 3-Phase Era Boss: Titan of the Deep Earth.

var current_pose: String = "idle"
var current_phase: int = 1
var anim_timer: float = 0.0

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func set_pose(pose: String) -> void:
	current_pose = pose
	queue_redraw()

func update_phase(phase: int) -> void:
	current_phase = phase
	queue_redraw()

func _draw() -> void:
	# Origin (0,0) at ground feet
	var col_stone = Color(0.26, 0.28, 0.30)
	var col_moss = Color(0.18, 0.38, 0.22)
	var col_core = Color(0.2, 0.85, 0.95) # Ancient cyan core
	var col_fissure = Color(0.15, 0.16, 0.18)

	if current_phase == 2:
		col_stone = Color(0.32, 0.34, 0.38) # Hardened stone armor
		col_core = Color(0.9, 0.7, 0.2) # Amber resonance
	elif current_phase == 3:
		col_stone = Color(0.20, 0.16, 0.18) # Charred volcanic rock
		col_core = Color(1.0, 0.3, 0.05) # Molten magma heart
		col_fissure = Color(1.0, 0.45, 0.1) # Glowing magma cracks

	var body_y = -32.0
	var arm_offset = 0.0

	if current_pose == "stomp_prep":
		body_y = -36.0
	elif current_pose == "stomp_slam":
		body_y = -28.0
	elif current_pose == "cleave_prep":
		arm_offset = -8.0
	elif current_pose == "cleave":
		arm_offset = 12.0
	elif current_pose == "roar":
		body_y = -36.0

	# 1. Colossal Stone Legs
	draw_rect(Rect2(-20, -18, 14, 18), col_stone.darkened(0.2))
	draw_rect(Rect2(6, -18, 14, 18), col_stone)

	# 2. Heavy Stone Torso (44w x 28h)
	draw_rect(Rect2(-22, body_y, 44, 28), col_stone)
	draw_rect(Rect2(-20, body_y + 2, 40, 6), col_moss)

	# 3. Geo Core / Crystal Heart
	var pulse = 0.8 + sin(anim_timer * (4.0 if current_phase < 3 else 10.0)) * 0.2
	var pulsed_core = Color(col_core.r, col_core.g, col_core.b, pulse)
	draw_rect(Rect2(-8, body_y + 8, 16, 12), col_fissure)
	draw_rect(Rect2(-5, body_y + 10, 10, 8), pulsed_core)

	# 4. Magma / Energy cracks (Phase 2 & 3)
	if current_phase >= 2:
		draw_rect(Rect2(-18, body_y + 14, 8, 2), col_fissure)
		draw_rect(Rect2(10, body_y + 12, 10, 2), col_fissure)
		draw_rect(Rect2(-12, body_y + 22, 24, 2), col_fissure)

	# 5. Stone Head / Brow
	draw_rect(Rect2(-12, body_y - 14, 24, 14), col_stone)
	draw_rect(Rect2(-8, body_y - 12, 16, 4), col_moss)
	# Glowing Golem Eyes
	draw_rect(Rect2(2, body_y - 6, 4, 3), pulsed_core)

	# 6. Colossal Stone Fists / Hammers
	# Back Arm
	draw_rect(Rect2(-28, body_y + 4, 10, 22), col_stone.darkened(0.3))
	# Front Arm & Heavy Fist
	draw_rect(Rect2(18 + arm_offset, body_y + 4, 14, 24), col_stone)
	draw_rect(Rect2(16 + arm_offset, body_y + 20, 18, 12), col_stone.darkened(0.1)) # Hammer fist
