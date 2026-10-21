class_name MagicProjectile
extends Area2D

## Magic projectile: Moves horizontally, collides with walls/enemies, deals damage.

@export var speed: float = 220.0
@export var damage: int = 2
@export var max_lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var caster: Node2D

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime += delta
	if lifetime >= max_lifetime:
		_explode(false)

func _on_body_entered(body: Node) -> void:
	# Collided with terrain/wall
	if body != caster and not (body is Area2D):
		_explode(false)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		if hurtbox.owner == caster:
			return
		if hurtbox.is_invulnerable:
			return
		var knockback = Vector2(direction.x * 120.0, -30.0)
		hurtbox.receive_hit(damage, knockback, 3, caster, false)
		if caster and caster.has_method("on_hit_landed"):
			caster.on_hit_landed(hurtbox, damage, false)
		_explode(true)

func _explode(hit_enemy: bool) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.4, 0.8, 1.0, 1.0) if not hit_enemy else Color(0.6, 1.0, 0.9, 1.0)
	get_parent().add_child(spark)
	queue_free()

func _draw() -> void:
	# Crisp pixel art magic shard
	# Core: cyan-white, Outer: deep cyan
	var core_color = Color(0.9, 1.0, 1.0, 1.0)
	var glow_color = Color(0.1, 0.7, 1.0, 0.7)
	
	# Glow
	draw_rect(Rect2(-6, -4, 12, 8), glow_color)
	# Core
	draw_rect(Rect2(-4, -2, 8, 4), core_color)
	# Trailing particles
	draw_rect(Rect2(-8, -1, 3, 2), Color(0.2, 0.6, 0.9, 0.5))
