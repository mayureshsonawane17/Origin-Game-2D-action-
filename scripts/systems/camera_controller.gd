class_name CameraController
extends Camera2D

## Camera with screen shake and smooth follow.

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var damp = shake_timer / shake_duration
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity) * damp,
			randf_range(-shake_intensity, shake_intensity) * damp
		)
		if shake_timer <= 0.0:
			offset = Vector2.ZERO

func shake(intensity: float = 3.0, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
