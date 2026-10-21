class_name StunGrenade
extends Area2D

## Tactical stun grenade lobbed by MOD-02 SWAT Juggernaut Apex.
## Detonates on impact or fuse timeout, producing a blinding concussive flash.

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

var velocity: Vector2 = Vector2.ZERO
var arc_gravity: float = 500.0
var fuse_time: float = 1.6
var damage: int = 2
var has_detonated: bool = false
var anim_timer: float = 0.0

func _ready() -> void:
	collision_layer = 16 # Enemy attack layer
	collision_mask = 9   # Player hurtbox (8) + World (1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if has_detonated:
		return

	anim_timer += delta
	velocity.y += arc_gravity * delta
	global_position += velocity * delta
	rotation += 8.0 * delta

	fuse_time -= delta
	if fuse_time <= 0.0:
		detonate()

	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if has_detonated:
		return
	if area is Hurtbox and area.owner is Player:
		detonate()

func _on_body_entered(body: Node2D) -> void:
	if has_detonated:
		return
	if body is TileMap or body is StaticBody2D:
		detonate()

func detonate() -> void:
	if has_detonated:
		return
	has_detonated = true

	# Concussive shockwave check
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 32.0
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 8 # Player hurtbox
	query.collide_with_areas = true

	var results = space.intersect_shape(query)
	for hit in results:
		var collider = hit.get("collider")
		if collider is Hurtbox and collider.owner is Player:
			var push = (collider.owner.global_position - global_position).normalized()
			collider.receive_hit(damage, push * 160.0, 5, self, false)

	if SoundManager:
		SoundManager.play_sfx("slash_finisher", 1.4)

	# Visual flash burst
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.4, 0.8, 1.0, 1.0)
	get_parent().add_child(spark)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if has_detonated:
		# Expanding flash ring
		draw_circle(Vector2.ZERO, 28.0, Color(0.8, 0.95, 1.0, 0.8))
		draw_circle(Vector2.ZERO, 16.0, Color.WHITE)
		return

	# Tactical canister
	var col_body = Color(0.2, 0.25, 0.28)
	var col_cap = Color(0.1, 0.6, 0.9)
	var col_pin = Color(0.8, 0.8, 0.8)

	draw_rect(Rect2(-4, -6, 8, 12), col_body)
	draw_rect(Rect2(-3, -8, 6, 3), col_cap)
	draw_line(Vector2(2, -7), Vector2(5, -9), col_pin, 1.5)

	# Blinking arming LED
	if fmod(anim_timer * 10.0, 1.0) > 0.5:
		draw_circle(Vector2(0, -2), 1.5, Color.RED)
