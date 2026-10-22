class_name PauseMenu
extends Control

## PauseMenu: In-game pause overlay for ORIGIN (Part A).
## Provides Resume, Options, Restart Checkpoint, and Quit to Title.
## Enforces in-game confirmation modals before restarting or quitting.
## Can be disabled during boss title cards via is_pause_disabled.

signal resumed()
signal restarted_checkpoint()
signal quit_to_title()

@onready var resume_btn: Button = $Center/Panel/Margin/VBox/MenuButtons/ResumeButton
@onready var options_btn: Button = $Center/Panel/Margin/VBox/MenuButtons/OptionsButton
@onready var restart_btn: Button = $Center/Panel/Margin/VBox/MenuButtons/RestartButton
@onready var quit_btn: Button = $Center/Panel/Margin/VBox/MenuButtons/QuitButton

# Confirmation Modal
@onready var confirm_modal: Control = $ConfirmModal
@onready var confirm_title_lbl: Label = $ConfirmModal/Center/Panel/Margin/VBox/HeaderLabel
@onready var confirm_msg_lbl: Label = $ConfirmModal/Center/Panel/Margin/VBox/MessageLabel
@onready var confirm_yes_btn: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/YesButton
@onready var confirm_no_btn: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/NoButton

# Embedded Options
@onready var options_menu: OptionsMenu = $OptionsMenu

var is_pause_disabled: bool = false
var pending_action: String = "" # "restart" or "quit"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	confirm_modal.visible = false
	options_menu.visible = false

	resume_btn.pressed.connect(_on_resume_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	confirm_yes_btn.pressed.connect(_on_confirm_yes)
	confirm_no_btn.pressed.connect(_on_confirm_no)
	options_menu.closed.connect(_on_options_closed)

	_update_localized_strings()

func _update_localized_strings() -> void:
	resume_btn.text = Loc.get_str("pause.resume", "RESUME")
	options_btn.text = Loc.get_str("pause.options", "OPTIONS")
	restart_btn.text = Loc.get_str("pause.restart_checkpoint", "RESTART CHECKPOINT")
	quit_btn.text = Loc.get_str("pause.quit_to_menu", "QUIT TO TITLE")

func pause_game() -> void:
	if is_pause_disabled:
		return
	visible = true
	get_tree().paused = true
	confirm_modal.visible = false
	options_menu.visible = false
	resume_btn.grab_focus()
	if SoundManager:
		SoundManager.play_sfx("ui_select")

func resume_game() -> void:
	visible = false
	confirm_modal.visible = false
	options_menu.visible = false
	get_tree().paused = false
	resumed.emit()
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")

func _on_resume_pressed() -> void:
	resume_game()

func _on_options_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	options_menu.visible = true
	var close_btn = options_menu.find_child("CloseButton", true, false) as Button
	if close_btn:
		close_btn.grab_focus()

func _on_options_closed() -> void:
	options_btn.grab_focus()

func _on_restart_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	pending_action = "restart"
	confirm_title_lbl.text = Loc.get_str("pause.restart_confirm_title", "RESTART CHECKPOINT")
	confirm_msg_lbl.text = Loc.get_str(
		"pause.restart_confirm_msg",
		"Restart from the last recorded checkpoint? Unsaved progress will be lost."
	)
	confirm_modal.visible = true
	confirm_no_btn.grab_focus()

func _on_quit_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	pending_action = "quit"
	confirm_title_lbl.text = Loc.get_str("pause.quit_confirm_title", "RETURN TO TITLE")
	confirm_msg_lbl.text = Loc.get_str(
		"pause.quit_confirm_msg",
		"Return to the main title screen? Any unsaved progress will be lost."
	)
	confirm_modal.visible = true
	confirm_no_btn.grab_focus()

func _on_confirm_yes() -> void:
	confirm_modal.visible = false
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")

	if pending_action == "restart":
		get_tree().paused = false
		visible = false
		restarted_checkpoint.emit()
		var scene_path = SaveManager.get_saved_scene_path() if SaveManager else ""
		if scene_path.is_empty():
			scene_path = get_tree().current_scene.scene_file_path
		if UIManager:
			UIManager.transition_to_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	elif pending_action == "quit":
		get_tree().paused = false
		visible = false
		quit_to_title.emit()
		var title_path = "res://scenes/ui/main_menu.tscn"
		if UIManager:
			UIManager.transition_to_scene(title_path)
		else:
			get_tree().change_scene_to_file(title_path)

func _on_confirm_no() -> void:
	confirm_modal.visible = false
	if SoundManager:
		SoundManager.play_sfx("ui_cancel")
	if pending_action == "restart":
		restart_btn.grab_focus()
	else:
		quit_btn.grab_focus()
	pending_action = ""

func _unhandled_input(event: InputEvent) -> void:
	if is_pause_disabled:
		return

	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if not visible:
			pause_game()
			get_viewport().set_input_as_handled()
		else:
			if confirm_modal.visible:
				_on_confirm_no()
				get_viewport().set_input_as_handled()
			elif options_menu.visible:
				options_menu.visible = false
				_on_options_closed()
				get_viewport().set_input_as_handled()
			else:
				resume_game()
				get_viewport().set_input_as_handled()
