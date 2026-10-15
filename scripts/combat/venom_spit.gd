class_name VenomSpitProjectile
extends Area2D

## Acidic venom projectile fired by flying prehistoric pterosaurs.
## Deals damage to player, bursts into acid particles on impact with terrain or player.

@export var speed: float = 140.0
@export var damage: int = 1
@export var max_lifetime: float = 3.0

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
		# Only hit player
		if hurtbox.owner is Player:
			var knockback = Vector2(direction.x * 60.0, -20.0)
			hurtbox.receive_hit(damage, knockback, 3, caster, false)
			_explode(true)

func _explode(hit_target: bool) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.4, 0.95, 0.2, 1.0) if hit_target else Color(0.3, 0.7, 0.15, 0.8)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Acidic toxic venom droplet
	var outer_color = Color(0.2, 0.85, 0.15, 0.85)
	var core_color = Color(0.8, 1.0, 0.4, 1.0)
	draw_circle(Vector2.ZERO, 4.0, outer_color)
	draw_circle(Vector2.ZERO, 2.0, core_color)
	draw_rect(Rect2(-direction.x * 4.0, -1.0, 3.0, 2.0), outer_color.darkened(0.2))
