class_name OptionsMenu
extends Control

## OptionsMenu: Comprehensive audio, accessibility, and display settings.
## Supports Master/SFX/BGM volumes, flash reduction, screen shake, touch toggle, and fullscreen.

signal closed()

@onready var master_slider: HSlider = $CenterContainer/Panel/VBox/AudioGrid/MasterSlider
@onready var sfx_slider: HSlider = $CenterContainer/Panel/VBox/AudioGrid/SFXSlider
@onready var bgm_slider: HSlider = $CenterContainer/Panel/VBox/AudioGrid/BGMSlider

@onready var flash_checkbox: CheckBox = $CenterContainer/Panel/VBox/AccessGrid/FlashCheckBox
@onready var shake_checkbox: CheckBox = $CenterContainer/Panel/VBox/AccessGrid/ShakeCheckBox
@onready var touch_checkbox: CheckBox = $CenterContainer/Panel/VBox/AccessGrid/TouchCheckBox
@onready var fullscreen_checkbox: CheckBox = $CenterContainer/Panel/VBox/AccessGrid/FullscreenCheckBox

@onready var close_button: Button = $CenterContainer/Panel/VBox/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_from_settings()

	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)

	flash_checkbox.toggled.connect(_on_flash_toggled)
	shake_checkbox.toggled.connect(_on_shake_toggled)
	touch_checkbox.toggled.connect(_on_touch_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	close_button.pressed.connect(_on_close_pressed)

func _populate_from_settings() -> void:
	if not SaveManager:
		return

	master_slider.value = SaveManager.master_volume * 100.0
	sfx_slider.value = SaveManager.sfx_volume * 100.0
	bgm_slider.value = SaveManager.bgm_volume * 100.0

	flash_checkbox.button_pressed = SaveManager.reduce_flashing
	shake_checkbox.button_pressed = SaveManager.screen_shake_enabled
	touch_checkbox.button_pressed = SaveManager.touch_controls_enabled

	var is_fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fs

func _on_master_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.master_volume = val / 100.0
		SaveManager.apply_settings()

func _on_sfx_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.sfx_volume = val / 100.0
		SaveManager.apply_settings()
	if SoundManager:
		SoundManager.play_sfx("ui_select")

func _on_bgm_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.bgm_volume = val / 100.0
		SaveManager.apply_settings()

func _on_flash_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.reduce_flashing = pressed

func _on_shake_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.screen_shake_enabled = pressed

func _on_touch_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.touch_controls_enabled = pressed
	# Notify any active touch controls widget
	var touch_node = get_tree().root.find_child("TouchControls", true, false)
	if touch_node and touch_node.has_method("refresh_visibility"):
		touch_node.refresh_visibility()

func _on_fullscreen_toggled(pressed: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_close_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
