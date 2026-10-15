class_name OrbitalLaserStrike
extends Area2D

## Targeted vertical orbital laser strike called down during Futuristic Era Boss Phase 2.

@export var damage: int = 1
@export var telegraph_duration: float = 0.42
@export var beam_duration: float = 0.28

var timer: float = 0.0
var is_active_beam: bool = false
var caster: Node2D

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 2 # Player Hurtbox
	monitoring = false
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _process(delta: float) -> void:
	timer += delta
	if not is_active_beam:
		if timer >= telegraph_duration:
			is_active_beam = true
			monitoring = true
			timer = 0.0
			_spawn_impact_sparks()
	else:
		if timer >= beam_duration:
			queue_free()
			return
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if is_active_beam and area is Hurtbox and area.owner != caster:
		area.receive_hit(damage, Vector2.ZERO, 4, caster, false)

func _spawn_impact_sparks() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position
	spark.spark_color = Color(0.1, 0.9, 1.0, 1.0)
	get_parent().add_child(spark)

func _draw() -> void:
	var beam_height = 300.0
	var top_y = -beam_height

	if not is_active_beam:
		# Telegraph target reticle & thin tracking line
		var alpha = clampf(timer / telegraph_duration, 0.2, 0.85)
		draw_line(Vector2(0, top_y), Vector2.ZERO, Color(0.1, 0.85, 1.0, alpha), 1.0)
		draw_arc(Vector2.ZERO, 14.0, 0, TAU, 16, Color(1.0, 0.2, 0.8, alpha), 1.5)
		draw_circle(Vector2.ZERO, 2.5, Color(0.1, 0.9, 1.0, alpha))
	else:
		# Full orbital beam column
		var beam_width = 24.0
		# Outer glow
		draw_rect(Rect2(-beam_width * 0.5, top_y, beam_width, beam_height), Color(0.1, 0.85, 1.0, 0.45))
		# Core laser
		draw_rect(Rect2(-beam_width * 0.25, top_y, beam_width * 0.5, beam_height), Color(0.85, 0.2, 0.95, 0.8))
		# White-hot center
		draw_rect(Rect2(-2, top_y, 4, beam_height), Color.WHITE)
		# Ground impact shock ring
		draw_circle(Vector2.ZERO, 16.0, Color(0.2, 0.9, 1.0, 0.7))
