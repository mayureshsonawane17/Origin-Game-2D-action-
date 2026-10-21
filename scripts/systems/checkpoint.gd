class_name Checkpoint
extends Area2D

## Checkpoint beacon restoring player vitals and persisting progress.

signal checkpoint_activated(checkpoint: Checkpoint)

@export var checkpoint_id: String = "checkpoint_01"

var is_activated: bool = false
var pulse_timer: float = 0.0

func _ready() -> void:
	collision_layer = 64
	collision_mask = 2 # Detects player
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	pulse_timer += delta
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		var p = body as Player
		if not is_activated:
			is_activated = true
			checkpoint_activated.emit(self)
			if SoundManager:
				SoundManager.play_sfx("checkpoint")
			# Restore vitals
			p.current_health = p.tuning.max_health
			p.heal_charges = p.tuning.max_heal_charges
			p.health_changed.emit(p.current_health, p.tuning.max_health)
			p.heal_charges_changed.emit(p.heal_charges, p.tuning.max_heal_charges)
			p._spawn_heal_fx()
			# Trigger Save
			if SaveManager:
				SaveManager.save_game(global_position, get_tree().current_scene.scene_file_path, checkpoint_id)

func _draw() -> void:
	# Ancient Stone Pillar with Carved Crystal
	var col_stone = Color(0.28, 0.30, 0.32)
	var col_crystal = Color(0.2, 0.9, 0.85) if is_activated else Color(0.3, 0.45, 0.5)
	var glow = 0.8 + sin(pulse_timer * 4.0) * 0.2 if is_activated else 0.5
	var pulsed_crystal = Color(col_crystal.r, col_crystal.g, col_crystal.b, glow)

	# Pillar Base & Shaft
	draw_rect(Rect2(-12, -40, 24, 40), col_stone)
	draw_rect(Rect2(-14, -8, 28, 8), col_stone.darkened(0.2))
	# Floating Crystal Shard
	var cy = -54.0 + sin(pulse_timer * 3.0) * 3.0 if is_activated else -50.0
	var pts = PackedVector2Array([
		Vector2(0, cy - 8),
		Vector2(6, cy),
		Vector2(0, cy + 8),
		Vector2(-6, cy)
	])
	draw_colored_polygon(pts, pulsed_crystal)
