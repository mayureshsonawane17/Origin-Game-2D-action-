class_name ToxicGrenade
extends Area2D

## Ballistic lobbed toxic canister thrown by Industrial grenadiers.

@export var damage: int = 1
@export var arc_gravity: float = 750.0

var velocity: Vector2 = Vector2.ZERO
var caster: Node2D
var lifetime: float = 0.0

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	collision_layer = 16 # Hitbox
	collision_mask = 9   # World (1) and Player Hurtbox (8)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	velocity.y += arc_gravity * delta
	position += velocity * delta
	lifetime += delta

	queue_redraw()

	if lifetime >= 3.0:
		_detonate(false)

func _on_body_entered(body: Node) -> void:
	if body != caster and not (body is Area2D):
		_detonate(false)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		if hurtbox.owner == caster:
			return
		if hurtbox.is_invulnerable:
			return
		if hurtbox.owner is Player:
			var knockback = Vector2(sign(velocity.x) * 80.0, -40.0)
			hurtbox.receive_hit(damage, knockback, 3, caster, false)
			_detonate(true)

func _detonate(hit_player: bool) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.3, 0.95, 0.35, 1.0) if hit_player else Color(0.4, 0.8, 0.4, 0.8)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Heavy cast-iron cylindrical canister with glowing green vents
	var col_iron = Color(0.28, 0.30, 0.32)
	var col_gas = Color(0.35, 0.95, 0.40, 0.9)
	var col_brass = Color(0.85, 0.70, 0.25)

	draw_rect(Rect2(-4, -5, 8, 10), col_iron)
	draw_rect(Rect2(-3, -2, 6, 4), col_gas)
	draw_rect(Rect2(-2, -7, 4, 2), col_brass)
