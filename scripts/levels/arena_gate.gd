class_name ArenaGate
extends StaticBody2D

## Arena barrier gate that blocks passage during boss encounters.

@export var is_closed: bool = false
@export var gate_color: Color = Color(0.35, 0.28, 0.25) # Ancient thorn/stone

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var target_height: float = 64.0
var current_height: float = 0.0

func _ready() -> void:
	current_height = target_height if is_closed else 0.0
	collision_shape.disabled = not is_closed
	queue_redraw()

func close_gate() -> void:
	is_closed = true
	collision_shape.set_deferred("disabled", false)
	var tween = create_tween()
	tween.tween_property(self, "current_height", target_height, 0.4).set_trans(Tween.TRANS_BOUNCE)
	tween.step_finished.connect(func(_step): queue_redraw())

func open_gate() -> void:
	is_closed = false
	var tween = create_tween()
	tween.tween_property(self, "current_height", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func():
		collision_shape.set_deferred("disabled", true)
		queue_redraw()
	)

func _process(_delta: float) -> void:
	if is_closed and current_height < target_height:
		queue_redraw()

func _draw() -> void:
	if current_height <= 0.0:
		return
	# Ancient carved bone and jagged stone spikes rising from floor
	var w = 14.0
	var h = current_height
	draw_rect(Rect2(-w * 0.5, -h, w, h), gate_color)
	draw_line(Vector2(-w * 0.5, -h), Vector2(0, -h - 8.0), gate_color.lightened(0.2), 2.0)
	draw_line(Vector2(w * 0.5, -h), Vector2(0, -h - 8.0), gate_color.darkened(0.2), 2.0)
