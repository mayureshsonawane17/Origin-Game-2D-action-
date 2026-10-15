class_name LevelGoal
extends Area2D

## End of level monolith marker.

signal reached_goal()

var triggered: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body is Player:
		triggered = true
		reached_goal.emit()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_level_complete"):
			hud.show_level_complete()

func _draw() -> void:
	# Monolith pillar (32w x 64h)
	var col_stone = Color(0.3, 0.32, 0.35)
	var col_moss = Color(0.2, 0.45, 0.25)
	var gem_pulse = 0.7 + sin(pulse_time * 5.0) * 0.3
	var col_gem = Color(0.2, 0.85, 0.95, gem_pulse)

	# Base & Stone pillar
	draw_rect(Rect2(-16, -60, 32, 60), col_stone)
	draw_rect(Rect2(-18, -10, 36, 10), col_stone.darkened(0.2))
	# Moss top & carvings
	draw_rect(Rect2(-16, -60, 32, 8), col_moss)
	draw_rect(Rect2(-12, -48, 24, 2), col_stone.darkened(0.3))
	draw_rect(Rect2(-12, -20, 24, 2), col_stone.darkened(0.3))

	# Embedded ancient gemstone
	draw_rect(Rect2(-6, -38, 12, 12), col_stone.darkened(0.4))
	draw_rect(Rect2(-4, -36, 8, 8), col_gem)
