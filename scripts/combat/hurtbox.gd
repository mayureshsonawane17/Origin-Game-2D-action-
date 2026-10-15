class_name Hurtbox
extends Area2D

## Hurtbox: Area that receives damage from Hitboxes and signals owner.

signal hit_received(damage: int, knockback_vector: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool)

@export var is_invulnerable: bool = false

func _ready() -> void:
	queue_redraw()

func receive_hit(damage: int, knockback_vector: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool = false) -> void:
	if is_invulnerable:
		return
	hit_received.emit(damage, knockback_vector, hitstop_frames, attacker, is_finisher)

func _process(_delta: float) -> void:
	if Hitbox.debug_show_hitboxes:
		queue_redraw()

func _draw() -> void:
	if not Hitbox.debug_show_hitboxes:
		return
	var col = Color(0, 0.8, 0.2, 0.35) if not is_invulnerable else Color(0.2, 0.5, 1.0, 0.45)
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is RectangleShape2D:
				var rect_shape = child.shape as RectangleShape2D
				var rect = Rect2(-rect_shape.size / 2.0, rect_shape.size)
				draw_rect(rect, col, true)
				draw_rect(rect, Color(0, 1, 0.3, 0.8), false, 1.0)
			elif child.shape is CircleShape2D:
				var circle_shape = child.shape as CircleShape2D
				draw_circle(Vector2.ZERO, circle_shape.radius, col)
