class_name SeismicShockwave
extends Area2D

## Ground shockwave traveling horizontally from boss stomp.

@export var speed: float = 180.0
@export var damage: int = 1
@export var max_distance: float = 300.0

var direction: float = 1.0
var traveled: float = 0.0

func _ready() -> void:
	collision_layer = 16
	collision_mask = 2 # Detects player
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	var move_amt = direction * speed * delta
	position.x += move_amt
	traveled += abs(move_amt)
	if traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).hurtbox.receive_hit(damage, Vector2(direction * 120.0, -80.0), 3, self, false)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		(area as Hurtbox).receive_hit(damage, Vector2(direction * 120.0, -80.0), 3, self, false)
		queue_free()

func _draw() -> void:
	# Jagged earthen rock crest
	var col_rock = Color(0.4, 0.3, 0.22)
	var col_glow = Color(0.95, 0.6, 0.1)
	var pts = PackedVector2Array([
		Vector2(-10, 0),
		Vector2(-4, -14),
		Vector2(4, -18),
		Vector2(10, 0)
	])
	draw_colored_polygon(pts, col_rock)
	# Fiery fissure glow
	draw_rect(Rect2(-2, -12, 4, 12), col_glow)
