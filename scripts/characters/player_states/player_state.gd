class_name PlayerState
extends State

## Base state for all Player states with typed player access.

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
