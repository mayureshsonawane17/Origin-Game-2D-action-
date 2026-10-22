class_name DefeatScreen
extends Control

## DefeatScreen: One-button instant restart screen for ORIGIN (Part A).
## Data-driven text from data/strings.json.
## Supports instant restart with no delay via keyboard, gamepad, or touch.

signal restart_requested()

@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var message_label: Label = $Center/Panel/Margin/VBox/MessageLabel
@onready var retry_button: Button = $Center/Panel/Margin/VBox/RetryButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	_refresh_text()

func _refresh_text() -> void:
	title_label.text = Loc.get_str("defeat.title", "DEFEAT")
	var reset_num = (ResetManager.reset_count + 1) if ResetManager else 1
	var def_template = Loc.get_str("defeat.message", "RESET #%d\n\"The loop begins again.\"")
	if "%d" in def_template:
		message_label.text = def_template % reset_num
	else:
		message_label.text = def_template

	retry_button.text = Loc.get_str("defeat.restart_button", "RETRY")

func show_defeat() -> void:
	visible = true
	_refresh_text()
	retry_button.grab_focus()
	if SoundManager:
		SoundManager.play_sfx("ui_cancel")

func _on_retry_pressed() -> void:
	visible = false
	restart_requested.emit()
	if ResetManager:
		ResetManager.trigger_reset("defeat")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		_on_retry_pressed()
		get_viewport().set_input_as_handled()
