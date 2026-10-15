class_name GlitchOverlay
extends CanvasLayer

## Fullscreen glitch and chromatic reality destabilization overlay for Chapter 7.
## Escalates as deliberate resets destabilize the gemstone prison.

var glitch_level: int = 0
var glitch_intensity: float = 0.0
var glitch_timer: float = 0.0

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func set_glitch_level(level: int) -> void:
	glitch_level = level
	glitch_intensity = float(level) * 0.25
	visible = level > 0

func _process(delta: float) -> void:
	if glitch_level <= 0:
		return

	glitch_timer += delta
	if int(glitch_timer * 15.0) % 2 == 0:
		# Rapid jittering scanlines
		color_rect.color = Color(randf_range(0.1, 0.4), randf_range(0.0, 0.2), randf_range(0.2, 0.6), glitch_intensity * 0.35)
		color_rect.position.x = randf_range(-glitch_intensity * 8.0, glitch_intensity * 8.0)
	else:
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.position.x = 0
