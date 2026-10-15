class_name CrossbowBolt
extends Area2D

## High-speed piercing bolt fired by medieval crossbow marksmen.

@export var speed: float = 260.0
@export var damage: int = 1
@export var max_lifetime: float = 2.5

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
			var knockback = Vector2(direction.x * 80.0, -20.0)
			hurtbox.receive_hit(damage, knockback, 3, caster, false)
			_explode(true)

func _explode(hit_target: bool) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.9, 0.85, 0.7, 1.0) if not hit_target else Color(0.9, 0.2, 0.2, 1.0)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Steel-tipped feathered crossbow bolt
	var col_shaft = Color(0.55, 0.38, 0.22)
	var col_tip = Color(0.85, 0.88, 0.95)
	var col_fletch = Color(0.9, 0.2, 0.2)
	
	draw_line(Vector2(-6 * direction.x, 0), Vector2(6 * direction.x, 0), col_shaft, 1.5)
	draw_line(Vector2(6 * direction.x, 0), Vector2(9 * direction.x, 0), col_tip, 2.0)
	draw_line(Vector2(-6 * direction.x, -2), Vector2(-6 * direction.x, 2), col_fletch, 1.5)
