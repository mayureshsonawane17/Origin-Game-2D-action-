class_name CableTrap
extends Area2D

## High-tensile steel cable trap deployed by IND-02 Clockwork Spider Sentry.
## Deploys a tripwire snare on impact that entangles the player and restricts movement.

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

var velocity: Vector2 = Vector2.ZERO
var arc_gravity: float = 400.0
var is_deployed: bool = false
var lifetime: float = 5.0
var anim_timer: float = 0.0
var affected_player: Player = null

func _ready() -> void:
	collision_layer = 16 # Enemy attack layer
	collision_mask = 9   # Player hurtbox (8) + World (1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	anim_timer += delta

	if not is_deployed:
		velocity.y += arc_gravity * delta
		global_position += velocity * delta
	else:
		lifetime -= delta
		if lifetime <= 0.0:
			_dissolve()
			return

		if affected_player and is_instance_valid(affected_player):
			affected_player.velocity.x *= 0.5

	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		affected_player = area.owner as Player
		if not is_deployed:
			area.receive_hit(1, velocity.normalized() * 80.0, 3, self, false)
			_deploy()

func _on_body_entered(body: Node2D) -> void:
	if not is_deployed and (body is TileMap or body is StaticBody2D):
		_deploy()

func _deploy() -> void:
	is_deployed = true
	velocity = Vector2.ZERO
	if SoundManager:
		SoundManager.play_sfx("block", 1.2)
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.9, 0.7, 0.2, 1.0)
	get_parent().add_child(spark)

func _dissolve() -> void:
	affected_player = null
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var col_wire = Color(0.75, 0.75, 0.8)
	var col_brass = Color(0.85, 0.6, 0.2)
	var col_spark = Color(1.0, 0.9, 0.3)

	if not is_deployed:
		# Coiled canister spinning through air
		draw_circle(Vector2.ZERO, 6.0, col_brass)
		draw_line(Vector2(-6, 0), Vector2(6, 0), col_wire, 2.0)
	else:
		# Anchored tripwire web
		var alpha = clampf(lifetime, 0.0, 1.0)
		col_wire.a = alpha
		draw_rect(Rect2(-16, -4, 32, 4), col_brass)
		# Taut steel cables with electric spark
		draw_line(Vector2(-16, -2), Vector2(16, -2), col_wire, 2.0)
		draw_line(Vector2(-12, -8), Vector2(12, 0), col_wire, 1.5)
		draw_line(Vector2(-12, 0), Vector2(12, -8), col_wire, 1.5)

		if fmod(anim_timer * 8.0, 1.0) > 0.5:
			draw_circle(Vector2(sin(anim_timer * 10.0) * 10.0, -3), 2.0, col_spark)
