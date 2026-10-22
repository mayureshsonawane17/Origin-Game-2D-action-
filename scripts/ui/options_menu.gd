class_name OptionsMenu
extends Control

## OptionsMenu: Full-featured Audio, Controls, Display, Accessibility, and Gameplay settings.
## Conforms to Part A requirements:
## - Audio: Master, SFX, BGM sliders, Mute toggle.
## - Controls: View and rebind keyboard/gamepad actions with conflict detection & reset to defaults.
## - Display: Fullscreen toggle and integer scale options (1x, 2x, 3x, 4x, Auto).
## - Accessibility: Reduce-flashing, Screen shake slider, Text speed slider, High-contrast toggle.
## - Gameplay: Skip-intro toggle, Touch scale & opacity sliders.

signal closed()

# Audio Tab
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var bgm_slider: HSlider = %BGMSlider
@onready var mute_checkbox: CheckBox = %MuteCheckBox

# Display Tab
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox
@onready var integer_scale_opt: OptionButton = %IntegerScaleOption

# Accessibility Tab
@onready var flash_checkbox: CheckBox = %FlashCheckBox
@onready var shake_checkbox: CheckBox = %ShakeCheckBox
@onready var shake_slider: HSlider = %ShakeSlider
@onready var text_speed_slider: HSlider = %TextSpeedSlider
@onready var high_contrast_checkbox: CheckBox = %HighContrastCheckBox

# Gameplay Tab
@onready var skip_intro_checkbox: CheckBox = %SkipIntroCheckBox
@onready var touch_checkbox: CheckBox = %TouchCheckBox
@onready var touch_scale_slider: HSlider = %TouchScaleSlider
@onready var touch_opacity_slider: HSlider = %TouchOpacitySlider

# Controls Tab
@onready var controls_vbox: VBoxContainer = %ControlsVBox
@onready var reset_controls_btn: Button = %ResetControlsButton

# Rebind Modal & Conflict Dialog
@onready var rebind_modal: Control = $RebindModal
@onready var rebind_prompt_label: Label = $RebindModal/Center/Panel/Margin/VBox/PromptLabel
@onready var conflict_modal: Control = $ConflictModal
@onready var conflict_msg_label: Label = $ConflictModal/Center/Panel/Margin/VBox/MessageLabel
@onready var conflict_confirm_btn: Button = $ConflictModal/Center/Panel/Margin/VBox/ButtonHBox/ConfirmButton
@onready var conflict_cancel_btn: Button = $ConflictModal/Center/Panel/Margin/VBox/ButtonHBox/CancelButton

# Main Footer Buttons
@onready var close_button: Button = %CloseButton
@onready var reset_defaults_button: Button = %ResetDefaultsButton
@onready var tab_container: TabContainer = %TabContainer

var is_listening_for_rebind: bool = false
var rebinding_action: String = ""
var pending_rebind_event: InputEvent = null
var pending_conflict_action: String = ""

const REBINDABLE_ACTIONS: Array[Dictionary] = [
	{ "id": "move_left", "label": "Move Left" },
	{ "id": "move_right", "label": "Move Right" },
	{ "id": "jump", "label": "Jump" },
	{ "id": "attack", "label": "Attack" },
	{ "id": "block", "label": "Block / Parry" },
	{ "id": "dodge", "label": "Dodge" },
	{ "id": "magic", "label": "Cast Magic" },
	{ "id": "heal", "label": "Quick Heal" },
	{ "id": "switch_weapon", "label": "Switch Weapon" },
	{ "id": "pause", "label": "Pause Game" }
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rebind_modal.visible = false
	conflict_modal.visible = false

	# Connect Audio
	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)

	# Connect Display
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	integer_scale_opt.item_selected.connect(_on_integer_scale_selected)

	# Connect Accessibility
	flash_checkbox.toggled.connect(_on_flash_toggled)
	shake_checkbox.toggled.connect(_on_shake_toggled)
	shake_slider.value_changed.connect(_on_shake_slider_changed)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	high_contrast_checkbox.toggled.connect(_on_high_contrast_toggled)

	# Connect Gameplay
	skip_intro_checkbox.toggled.connect(_on_skip_intro_toggled)
	touch_checkbox.toggled.connect(_on_touch_toggled)
	touch_scale_slider.value_changed.connect(_on_touch_scale_changed)
	touch_opacity_slider.value_changed.connect(_on_touch_opacity_changed)

	# Connect Controls & Global
	reset_controls_btn.pressed.connect(_on_reset_controls_pressed)
	reset_defaults_button.pressed.connect(_on_reset_all_defaults_pressed)
	close_button.pressed.connect(_on_close_pressed)

	conflict_confirm_btn.pressed.connect(_on_conflict_confirmed)
	conflict_cancel_btn.pressed.connect(_on_conflict_cancelled)

	_setup_integer_scale_items()
	_populate_from_settings()
	_populate_controls_list()

func _setup_integer_scale_items() -> void:
	integer_scale_opt.clear()
	integer_scale_opt.add_item("Auto (Keep Aspect)", 0)
	integer_scale_opt.add_item("1x (480x270)", 1)
	integer_scale_opt.add_item("2x (960x540)", 2)
	integer_scale_opt.add_item("3x (1440x810)", 3)
	integer_scale_opt.add_item("4x (1920x1080)", 4)

func _populate_from_settings() -> void:
	if not SaveManager:
		return

	master_slider.value = SaveManager.master_volume * 100.0
	sfx_slider.value = SaveManager.sfx_volume * 100.0
	bgm_slider.value = SaveManager.bgm_volume * 100.0
	mute_checkbox.button_pressed = SaveManager.is_muted

	fullscreen_checkbox.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	integer_scale_opt.select(SaveManager.integer_scale)

	flash_checkbox.button_pressed = SaveManager.reduce_flashing
	shake_checkbox.button_pressed = SaveManager.screen_shake_enabled
	shake_slider.value = SaveManager.screen_shake_intensity * 100.0
	text_speed_slider.value = SaveManager.text_speed * 100.0
	high_contrast_checkbox.button_pressed = SaveManager.high_contrast

	skip_intro_checkbox.button_pressed = SaveManager.skip_intro
	touch_checkbox.button_pressed = SaveManager.touch_controls_enabled
	touch_scale_slider.value = SaveManager.touch_scale * 100.0
	touch_opacity_slider.value = SaveManager.touch_opacity * 100.0

func _populate_controls_list() -> void:
	for child in controls_vbox.get_children():
		child.queue_free()

	for entry in REBINDABLE_ACTIONS:
		var act_id = entry["id"]
		var act_label = entry["label"]

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var lbl = Label.new()
		lbl.text = act_label
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 8)
		row.add_child(lbl)

		var prompt_btn = Button.new()
		prompt_btn.custom_minimum_size = Vector2(90, 20)
		prompt_btn.add_theme_font_size_override("font_size", 8)
		prompt_btn.text = UIManager.get_action_prompt(act_id) if UIManager else "[KEY]"
		prompt_btn.pressed.connect(func(): _start_rebind(act_id, act_label))
		row.add_child(prompt_btn)

		controls_vbox.add_child(row)

func _start_rebind(action_id: String, action_label: String) -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	rebinding_action = action_id
	is_listening_for_rebind = true
	rebind_prompt_label.text = "%s:\n%s" % [action_label, Loc.get_str("options.press_key_to_bind", "PRESS ANY KEY OR BUTTON...")]
	rebind_modal.visible = true

func _on_master_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.master_volume = val / 100.0
		SaveManager.apply_settings()
		SaveManager.save_settings()

func _on_sfx_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.sfx_volume = val / 100.0
		SaveManager.apply_settings()
		SaveManager.save_settings()
	if SoundManager:
		SoundManager.play_sfx("ui_select")

func _on_bgm_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.bgm_volume = val / 100.0
		SaveManager.apply_settings()
		SaveManager.save_settings()

func _on_mute_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.is_muted = pressed
		SaveManager.apply_settings()
		SaveManager.save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.fullscreen = pressed
		SaveManager.apply_settings()
		SaveManager.save_settings()

func _on_integer_scale_selected(index: int) -> void:
	if SaveManager:
		SaveManager.integer_scale = index
		SaveManager.apply_settings()
		SaveManager.save_settings()

func _on_flash_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.reduce_flashing = pressed
		SaveManager.save_settings()

func _on_shake_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.screen_shake_enabled = pressed
		SaveManager.save_settings()

func _on_shake_slider_changed(val: float) -> void:
	if SaveManager:
		SaveManager.screen_shake_intensity = val / 100.0
		SaveManager.save_settings()

func _on_text_speed_changed(val: float) -> void:
	if SaveManager:
		SaveManager.text_speed = val / 100.0
		SaveManager.save_settings()

func _on_high_contrast_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.high_contrast = pressed
		SaveManager.save_settings()

func _on_skip_intro_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.skip_intro = pressed
		SaveManager.save_settings()

func _on_touch_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.touch_controls_enabled = pressed
		SaveManager.save_settings()
	var touch_node = get_tree().root.find_child("TouchControls", true, false)
	if touch_node and touch_node.has_method("refresh_visibility"):
		touch_node.refresh_visibility()

func _on_touch_scale_changed(val: float) -> void:
	if SaveManager:
		SaveManager.touch_scale = val / 100.0
		SaveManager.save_settings()

func _on_touch_opacity_changed(val: float) -> void:
	if SaveManager:
		SaveManager.touch_opacity = val / 100.0
		SaveManager.save_settings()

func _on_reset_controls_pressed() -> void:
	if SaveManager:
		SaveManager.reset_controls_to_defaults()
		_populate_controls_list()
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")

func _on_reset_all_defaults_pressed() -> void:
	if SaveManager:
		SaveManager.reset_settings_to_defaults()
		_populate_from_settings()
		_populate_controls_list()
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")

func _on_close_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	visible = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if is_listening_for_rebind:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				# Cancel rebind
				is_listening_for_rebind = false
				rebind_modal.visible = false
				get_viewport().set_input_as_handled()
				return
			_process_new_binding(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed:
			_process_new_binding(event)
			get_viewport().set_input_as_handled()

func _process_new_binding(event: InputEvent) -> void:
	is_listening_for_rebind = false
	rebind_modal.visible = false

	var res = SaveManager.rebind_action(rebinding_action, event)
	if res.get("has_conflict", false):
		pending_rebind_event = event
		pending_conflict_action = res.get("conflicting_action", "")
		conflict_msg_label.text = "%s '%s'! %s" % [
			Loc.get_str("options.conflict_detected", "Key already mapped to"),
			pending_conflict_action,
			Loc.get_str("common.warning", "Overwrite?")
		]
		conflict_modal.visible = true
		conflict_cancel_btn.grab_focus()
	else:
		_populate_controls_list()
		if SoundManager:
			SoundManager.play_sfx("ui_confirm")

func _on_conflict_confirmed() -> void:
	conflict_modal.visible = false
	if pending_rebind_event and not rebinding_action.is_empty():
		# Erase conflicting action's event and assign to rebinding_action
		InputMap.action_erase_events(pending_conflict_action)
		InputMap.action_erase_events(rebinding_action)
		InputMap.action_add_event(rebinding_action, pending_rebind_event)
		SaveManager._record_event_in_custom_keybinds(rebinding_action, pending_rebind_event)
		SaveManager.custom_keybinds.erase(pending_conflict_action)
		SaveManager.save_settings()
		_populate_controls_list()
		if SoundManager:
			SoundManager.play_sfx("ui_confirm")
	pending_rebind_event = null
	pending_conflict_action = ""

func _on_conflict_cancelled() -> void:
	conflict_modal.visible = false
	pending_rebind_event = null
	pending_conflict_action = ""
	if SoundManager:
		SoundManager.play_sfx("ui_cancel")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if is_listening_for_rebind or conflict_modal.visible:
		return
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
