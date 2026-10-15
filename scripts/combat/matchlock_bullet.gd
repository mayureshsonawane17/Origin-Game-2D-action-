class_name MatchlockBullet
extends Area2D

## High-speed lead ball fired by Historical Tanegashima gunners.

@export var speed: float = 320.0
@export var damage: int = 1
@export var max_lifetime: float = 2.0

var direction: Vector2 = Vector2.LEFT
var lifetime: float = 0.0
var caster: Node2D

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16 # Hitbox
	collision_mask = 9   # World (1) and Player Hurtbox (8)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime += delta
	if lifetime >= max_lifetime:
		_explode(false)

func _on_body_entered(body: Node) -> void:
	if body != caster and not (body is Area2D):
		_explode(false)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		if hurtbox.owner == caster:
			return
		if hurtbox.is_invulnerable:
			return
		if hurtbox.owner is Player:
			var knockback = Vector2(direction.x * 90.0, -30.0)
			hurtbox.receive_hit(damage, knockback, 4, caster, false)
			_explode(true)

func _explode(hit_target: bool) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(1.0, 0.6, 0.1, 1.0) if hit_target else Color(0.7, 0.7, 0.7, 0.8)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Lead bullet sphere with glowing gunpowder trail
	var col_lead = Color(0.25, 0.25, 0.28)
	var col_spark = Color(1.0, 0.75, 0.2, 0.8)
	var col_smoke = Color(0.65, 0.65, 0.68, 0.5)

	# Smoke puff trail behind
	draw_circle(Vector2(-6 * direction.x, 0), 2.5, col_smoke)
	draw_circle(Vector2(-3 * direction.x, 0), 2.0, col_spark)
	# Dense spherical lead pellet
	draw_circle(Vector2.ZERO, 3.0, col_lead)
	draw_circle(Vector2(direction.x * 1.0, -1.0), 1.0, Color.WHITE)
