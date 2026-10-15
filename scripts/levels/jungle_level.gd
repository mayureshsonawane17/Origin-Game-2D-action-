class_name JungleLevel
extends Node2D

## Jungle Level manager: controls camera bounds, kill-plane, and initialization.

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD

func _ready() -> void:
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 1600
		player.camera.limit_bottom = 280

func _process(_delta: float) -> void:
	if player and is_instance_valid(player) and not player.is_dead:
		# Fall into bottomless pit / kill plane
		if player.global_position.y > 280.0:
			player.is_dead = true
			player.player_died.emit()
			ResetManager.trigger_reset("fall_into_abyss")
