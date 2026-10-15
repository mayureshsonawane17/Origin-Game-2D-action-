class_name DialogueBox
extends CanvasLayer

## Cinematic Dialogue & Story Presentation System (Milestone 4).
## Displays typewriter dialogue with speaker nameplates, pausing the scene tree
## and allowing instant advance or full skip on player input.

signal line_started(speaker: String, text: String)
signal dialogue_finished()

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $PanelContainer/Margin/VBox/TextLabel
@onready var prompt_label: Label = $PanelContainer/Margin/VBox/PromptLabel

@export var characters_per_second: float = 40.0

var dialogue_lines: Array[Dictionary] = [] # [{"speaker": "Hero", "text": "..."}]
var current_line_index: int = 0
var displayed_char_count: float = 0.0
var full_current_text: String = ""
var is_typing: bool = false
var is_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_active = false

func _process(delta: float) -> void:
	if not is_active or not is_typing:
		return

	displayed_char_count += characters_per_second * delta
	var visible_chars = int(displayed_char_count)

	if visible_chars >= full_current_text.length():
		text_label.text = full_current_text
		is_typing = false
		prompt_label.visible = true
	else:
		text_label.text = full_current_text.substr(0, visible_chars)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()

func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return

	dialogue_lines = lines
	current_line_index = 0
	is_active = true
	visible = true
	get_tree().paused = true
	_show_current_line()

func advance() -> void:
	if not is_active:
		return

	if is_typing:
		# Fast-forward to end of line
		is_typing = false
		text_label.text = full_current_text
		prompt_label.visible = true
	else:
		# Advance to next line or finish
		current_line_index += 1
		if current_line_index < dialogue_lines.size():
			_show_current_line()
		else:
			finish_dialogue()

func finish_dialogue() -> void:
	is_active = false
	visible = false
	get_tree().paused = false
	dialogue_finished.emit()

func _show_current_line() -> void:
	var line_data = dialogue_lines[current_line_index]
	var speaker = line_data.get("speaker", "???")
	full_current_text = line_data.get("text", "")

	speaker_label.text = speaker.to_upper()
	if speaker == "Hero":
		speaker_label.modulate = Color(0.4, 0.85, 1.0)
	elif speaker == "The Gemstone" or speaker == "Echoing Voice":
		speaker_label.modulate = Color(1.0, 0.35, 0.6)
	else:
		speaker_label.modulate = Color(1.0, 0.85, 0.3)

	displayed_char_count = 0.0
	text_label.text = ""
	is_typing = true
	prompt_label.visible = false
	line_started.emit(speaker, full_current_text)
