class_name EscapeCollapse
extends Node2D

## Collapsing Reality Escape Run (docs/STORY.md Beat 10).
## The hero races across fragmented platforms of all six eras as reality disintegrates,
## reaches his wife at the shattered crystal barrier, and leaps with her through the final opening.

const EPILOGUE_SCENE_PATH = "res://scenes/levels/epilogue_real_world.tscn"

@onready var player: Player = $Player
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var glitch_overlay = $GlitchOverlay
@onready var wife_area: Area2D = $WifeArea
@onready var escape_portal: Area2D = $EscapeOpening

var reached_wife: bool = false
var escape_completed: bool = false

func _ready() -> void:
	glitch_overlay.set_glitch_level(2)

	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 1400
		player.camera.limit_bottom = 290

	wife_area.body_entered.connect(_on_wife_reached)
	escape_portal.body_entered.connect(_on_escape_portal_entered)

	await get_tree().create_timer(0.4).timeout
	var lines: Array[Dictionary] = [
		{"speaker": "Hero", "text": "The gemstone has cracked! The entire reality is collapsing!"},
		{"speaker": "Hero", "text": "I have to reach her before the prison dissolves forever!"}
	]
	dialogue_box.start_dialogue(lines)

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return

	# Bottomless void check
	if player.global_position.y > 290.0:
		player.is_dead = true
		player.player_died.emit()
		ResetManager.trigger_reset("fall_into_collapsing_void")

func _on_wife_reached(body: Node) -> void:
	if body is Player and not reached_wife:
		reached_wife = true
		var lines: Array[Dictionary] = [
			{"speaker": "Wife", "text": "You broke through the crystal... You remembered me!"},
			{"speaker": "Hero", "text": "Always. Take my hand — the exit is right ahead!"}
		]
		dialogue_box.start_dialogue(lines)

func _on_escape_portal_entered(body: Node) -> void:
	if body is Player and reached_wife and not escape_completed:
		escape_completed = true
		_transition_to_epilogue()

func _transition_to_epilogue() -> void:
	glitch_overlay.set_glitch_level(4)
	await get_tree().create_timer(0.8).timeout
	if ResourceLoader.exists(EPILOGUE_SCENE_PATH):
		get_tree().change_scene_to_file(EPILOGUE_SCENE_PATH)
	else:
		print("[Escape] Escaped with wife into real world")
