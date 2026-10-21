class_name Hitbox
extends Area2D

## Hitbox: Area that inflicts damage, knockback, and hit-stop on Hurtboxes.

signal hit_landed(target: Hurtbox, damage: int, is_finisher: bool)

static var debug_show_hitboxes: bool = false

@export var damage: int = 1
@export var knockback_force: float = 100.0
@export var hitstop_frames: int = 3
@export var is_finisher: bool = false

var attacker_owner: Node2D
var already_hit_targets: Array[Hurtbox] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if not attacker_owner:
		attacker_owner = owner as Node2D
	queue_redraw()

func reset_hits() -> void:
	already_hit_targets.clear()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		if hurtbox.owner == attacker_owner or hurtbox in already_hit_targets:
			return
		if hurtbox.is_invulnerable:
			return
			
		already_hit_targets.append(hurtbox)
		
		# Compute knockback direction
		var dir = 1.0
		if attacker_owner:
			dir = 1.0 if hurtbox.global_position.x >= attacker_owner.global_position.x else -1.0
		var knockback_vec = Vector2(dir * knockback_force, -knockback_force * 0.4 if is_finisher else -20.0)
		
		hurtbox.receive_hit(damage, knockback_vec, hitstop_frames, attacker_owner, is_finisher)
		hit_landed.emit(hurtbox, damage, is_finisher)
		if attacker_owner and attacker_owner.has_method("on_hit_landed"):
			attacker_owner.on_hit_landed(hurtbox, damage, is_finisher)

func _process(_delta: float) -> void:
	if debug_show_hitboxes:
		queue_redraw()

func _draw() -> void:
	if not debug_show_hitboxes or not monitoring:
		return
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is RectangleShape2D:
				var rect_shape = child.shape as RectangleShape2D
				var rect = Rect2(-rect_shape.size / 2.0, rect_shape.size)
				draw_rect(rect, Color(1, 0, 0, 0.45), true)
				draw_rect(rect, Color(1, 0.2, 0.2, 0.9), false, 1.0)
			elif child.shape is CircleShape2D:
				var circle_shape = child.shape as CircleShape2D
				draw_circle(Vector2.ZERO, circle_shape.radius, Color(1, 0, 0, 0.45))
