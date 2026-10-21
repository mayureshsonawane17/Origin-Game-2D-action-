class_name ClayBoulder
extends Area2D

## Heavy ballistic clay boulder hurled by PRE-02 Mud Golem.
## Arcs through the air and shatters on impact.

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

var velocity: Vector2 = Vector2.ZERO
var arc_gravity: float = 480.0
var damage: int = 2
var lifetime: float = 4.0
var rotation_speed: float = 4.0

func _ready() -> void:
	collision_layer = 16 # Enemy attack layer
	collision_mask = 9  # Player hurtbox (8) + environment (1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y += arc_gravity * delta
	global_position += velocity * delta
	rotation += rotation_speed * delta

	lifetime -= delta
	if lifetime <= 0.0:
		_shatter()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox = area as Hurtbox
		if hurtbox.owner is Player:
			hurtbox.receive_hit(damage, velocity.normalized() * 120.0, 4, self, false)
			_shatter()

func _on_body_entered(body: Node2D) -> void:
	if body is TileMap or body is StaticBody2D:
		_shatter()

func _shatter() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.68, 0.44, 0.22, 1.0) # Clay dust
	get_parent().add_child(spark)
	if SoundManager:
		SoundManager.play_sfx("block")
	queue_free()

func _draw() -> void:
	var col_dark = Color(0.42, 0.28, 0.16)
	var col_mid = Color(0.62, 0.42, 0.24)
	var col_light = Color(0.78, 0.54, 0.32)

	draw_circle(Vector2.ZERO, 9.0, col_dark)
	draw_circle(Vector2(-2, -2), 7.0, col_mid)
	draw_circle(Vector2(-3, -3), 4.0, col_light)
	# Clay fissures
	draw_line(Vector2(-4, 2), Vector2(4, 5), col_dark, 1.5)
