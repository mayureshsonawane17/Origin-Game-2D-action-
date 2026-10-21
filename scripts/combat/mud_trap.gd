class_name MudTrap
extends Area2D

## Mud Trap hazard spawned by PRE-02 Mud Golem.
## Viscous mud puddle that restricts hero mobility and slows movement speed.

var lifetime: float = 5.0
var anim_timer: float = 0.0
var affected_player: Player = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player body layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	anim_timer += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_dissolve()
		return

	if affected_player and is_instance_valid(affected_player):
		affected_player.velocity.x *= 0.6
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		affected_player = body

func _on_body_exited(body: Node2D) -> void:
	if body == affected_player:
		affected_player = null

func _dissolve() -> void:
	affected_player = null
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var col_mud = Color(0.38, 0.24, 0.14, 0.85)
	var col_clay = Color(0.55, 0.36, 0.20, 0.9)
	var col_bubble = Color(0.70, 0.48, 0.26, 0.8)

	# Outer puddle
	draw_circle(Vector2.ZERO, 20.0, col_mud)
	draw_circle(Vector2(-6, 2), 14.0, col_clay)
	draw_circle(Vector2(8, -1), 12.0, col_clay)

	# Bubbling clay motes
	var b1 = sin(anim_timer * 4.0) * 4.0
	var b2 = cos(anim_timer * 5.0) * 3.0
	draw_circle(Vector2(-5 + b1, -4), 2.5, col_bubble)
	draw_circle(Vector2(6 + b2, 3), 2.0, col_bubble)
