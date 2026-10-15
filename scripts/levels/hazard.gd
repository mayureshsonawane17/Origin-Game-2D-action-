class_name HazardArea
extends Area2D

## Hazard area (spikes, pits) that inflicts damage on contact.

@export var damage: int = 1
@export var knockback_force: float = 160.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p = body as Player
		if p.hurtbox:
			var knock_dir = Vector2(0.0, -1.0)
			p.hurtbox.receive_hit(damage, knock_dir * knockback_force, 4, self, true)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		var knock_dir = Vector2(0.0, -1.0)
		(area as Hurtbox).receive_hit(damage, knock_dir * knockback_force, 4, self, true)

func _draw() -> void:
	# Draw crisp pixel spikes
	var col_spike = Color(0.75, 0.72, 0.65)
	var col_blood = Color(0.65, 0.2, 0.2)
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect = (child.shape as RectangleShape2D).size
			var count = int(rect.x / 8.0)
			var start_x = -rect.x / 2.0
			for i in count:
				var x = start_x + (i * 8.0)
				var pts = PackedVector2Array([
					Vector2(x, rect.y / 2.0),
					Vector2(x + 4.0, -rect.y / 2.0),
					Vector2(x + 8.0, rect.y / 2.0)
				])
				draw_colored_polygon(pts, col_spike)
				# Blood tip
				var tip_pts = PackedVector2Array([
					Vector2(x + 2.5, -rect.y / 2.0 + 3.0),
					Vector2(x + 4.0, -rect.y / 2.0),
					Vector2(x + 5.5, -rect.y / 2.0 + 3.0)
				])
				draw_colored_polygon(pts, col_blood)
