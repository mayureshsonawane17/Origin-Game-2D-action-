class_name HitSpark
extends Node2D

## Procedural pixel hit spark effect on melee/magic impact.

@export var spark_color: Color = Color(1.0, 0.95, 0.4, 1.0)
@export var is_heavy: bool = false

var timer: float = 0.0
var max_time: float = 0.16
var particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = 20
	var count = 8 if is_heavy else 5
	var base_speed = 140.0 if is_heavy else 90.0
	for i in count:
		var angle = randf() * TAU
		var spd = randf_range(base_speed * 0.5, base_speed)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"size": 3.0 if is_heavy and i < 3 else 2.0
		})

func _process(delta: float) -> void:
	timer += delta
	if timer >= max_time:
		queue_free()
		return
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.88 # deceleration
	queue_redraw()

func _draw() -> void:
	var alpha = 1.0 - (timer / max_time)
	var col = Color(spark_color.r, spark_color.g, spark_color.b, alpha)
	for p in particles:
		draw_rect(Rect2(p["pos"], Vector2(p["size"], p["size"])), col)
