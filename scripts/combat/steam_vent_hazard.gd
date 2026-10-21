class_name SteamVentHazard
extends Area2D

## Scalding steam vent hazard deployed by IND-02 Clockwork Spider Sentry.
## Deals continuous periodic damage and knocks back player while active.

var lifetime: float = 2.5
var damage_interval: float = 0.5
var damage_timer: float = 0.0
var anim_timer: float = 0.0
var affected_player: Player = null

func _ready() -> void:
	collision_layer = 16 # Enemy attack layer
	collision_mask = 8   # Player hurtbox layer
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if SoundManager:
		SoundManager.play_sfx("whoosh", 1.3)

func _process(delta: float) -> void:
	anim_timer += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_dissipate()
		return

	damage_timer -= delta
	if damage_timer <= 0.0 and affected_player and is_instance_valid(affected_player):
		damage_timer = damage_interval
		if affected_player.hurtbox:
			var push_dir = Vector2(1 if affected_player.global_position.x > global_position.x else -1, -0.5).normalized()
			affected_player.hurtbox.receive_hit(1, push_dir * 100.0, 3, self, false)

	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.owner is Player:
		affected_player = area.owner as Player

func _on_area_exited(area: Area2D) -> void:
	if area is Hurtbox and area.owner == affected_player:
		affected_player = null

func _dissipate() -> void:
	affected_player = null
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var alpha = clampf(lifetime, 0.0, 1.0)
	var col_outer = Color(0.85, 0.88, 0.95, 0.35 * alpha)
	var col_mid = Color(0.9, 0.7, 0.4, 0.45 * alpha)
	var col_dense = Color(1.0, 1.0, 1.0, 0.65 * alpha)

	var pulse = sin(anim_timer * 12.0) * 3.0
	draw_circle(Vector2(0, -10), 22.0 + pulse, col_outer)
	draw_circle(Vector2(-4, -14), 15.0 + pulse * 0.7, col_mid)
	draw_circle(Vector2(5, -8), 12.0 - pulse * 0.5, col_dense)
	draw_circle(Vector2(0, -4), 8.0, Color(1.0, 0.6, 0.2, 0.7 * alpha))
