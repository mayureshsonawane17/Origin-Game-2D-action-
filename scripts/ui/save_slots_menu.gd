class_name SaveSlotsMenu
extends Control

## SaveSlotsMenu: 3-slot save management screen for ORIGIN (Part A).
## Displays era, area, play time, and last saved timestamp.
## Supports New Game, Continue/Load, and in-game Delete confirmation modal.

signal closed()
signal slot_selected(slot_num: int)

enum Mode { NEW_GAME, LOAD }
var current_mode: Mode = Mode.LOAD

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/TitleLabel
@onready var slots_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/SlotsVBox
@onready var back_button: Button = $CenterContainer/Panel/Margin/VBox/BottomHBox/BackButton

# Delete confirmation modal
@onready var confirm_modal: Control = $ConfirmModal
@onready var confirm_msg_label: Label = $ConfirmModal/Center/Panel/Margin/VBox/MessageLabel
@onready var confirm_yes_button: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/YesButton
@onready var confirm_no_button: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/NoButton

var pending_delete_slot: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	confirm_modal.visible = false
	back_button.pressed.connect(_on_back_pressed)
	confirm_yes_button.pressed.connect(_on_confirm_delete_yes)
	confirm_no_button.pressed.connect(_on_confirm_delete_no)

	refresh_slots()

func open(mode: Mode = Mode.LOAD) -> void:
	current_mode = mode
	visible = true
	title_label.text = Loc.get_str("save_slots.title", "SELECT SAVE SLOT")
	refresh_slots()

	# Focus first slot's action button
	if slots_container.get_child_count() > 0:
		var first_slot = slots_container.get_child(0)
		var btn = first_slot.find_child("ActionButton", true, false) as Button
		if btn:
			btn.grab_focus()

func refresh_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	for slot_idx in range(1, SaveManager.NUM_SLOTS + 1):
		var meta = SaveManager.get_slot_meta(slot_idx)
		var card = _create_slot_card(slot_idx, meta)
		slots_container.add_child(card)

func _create_slot_card(slot_idx: int, meta: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 48)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Slot number header
	var slot_lbl = Label.new()
	slot_lbl.custom_minimum_size = Vector2(50, 0)
	slot_lbl.text = "SLOT %d" % slot_idx
	slot_lbl.add_theme_color_override("font_color", Color("#ae7e54")) # Gold
	slot_lbl.add_theme_font_size_override("font_size", 9)
	hbox.add_child(slot_lbl)

	# Slot details
	var details_vbox = VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 2)

	if not meta["exists"]:
		var empty_lbl = Label.new()
		empty_lbl.text = Loc.get_str("save_slots.slot_empty", "[ EMPTY SLOT ]")
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		empty_lbl.add_theme_font_size_override("font_size", 8)
		details_vbox.add_child(empty_lbl)
	elif meta["is_corrupted"]:
		var corrupt_lbl = Label.new()
		corrupt_lbl.text = Loc.get_str("save_slots.corrupt_slot", "[ CORRUPTED SAVE - SELECT TO RESET ]")
		corrupt_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		corrupt_lbl.add_theme_font_size_override("font_size", 8)
		details_vbox.add_child(corrupt_lbl)
	else:
		var line1 = Label.new()
		line1.text = "%s  •  %s  (%s)" % [meta["era"], meta["area"], meta["character"]]
		line1.add_theme_color_override("font_color", Color("#ebd2bd"))
		line1.add_theme_font_size_override("font_size", 8)

		var time_str = SaveManager.format_time(meta["play_time"])
		var date_str = Time.get_datetime_string_from_unix_time(meta["last_saved"]).replace("T", " ")
		var line2 = Label.new()
		line2.text = "%s: %s  |  %s: %s" % [
			Loc.get_str("save_slots.playtime", "TIME"), time_str,
			Loc.get_str("save_slots.last_saved", "SAVED"), date_str
		]
		line2.add_theme_color_override("font_color", Color(0.65, 0.72, 0.78))
		line2.add_theme_font_size_override("font_size", 7)

		details_vbox.add_child(line1)
		details_vbox.add_child(line2)

	hbox.add_child(details_vbox)

	# Action buttons (Start/Load + Delete)
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)

	var action_btn = Button.new()
	action_btn.name = "ActionButton"
	action_btn.custom_minimum_size = Vector2(65, 24)
	action_btn.add_theme_font_size_override("font_size", 8)

	if current_mode == Mode.NEW_GAME:
		action_btn.text = "SELECT" if not meta["exists"] else "OVERWRITE"
		action_btn.pressed.connect(func(): _on_slot_action(slot_idx, true))
	else:
		action_btn.text = "LOAD"
		action_btn.disabled = not meta["exists"] or meta["is_corrupted"]
		action_btn.pressed.connect(func(): _on_slot_action(slot_idx, false))

	btn_hbox.add_child(action_btn)

	var del_btn = Button.new()
	del_btn.name = "DeleteButton"
	del_btn.text = Loc.get_str("common.delete", "DELETE")
	del_btn.custom_minimum_size = Vector2(50, 24)
	del_btn.add_theme_font_size_override("font_size", 7)
	del_btn.disabled = not meta["exists"]
	del_btn.pressed.connect(func(): _on_slot_delete_clicked(slot_idx))
	btn_hbox.add_child(del_btn)

	hbox.add_child(btn_hbox)
	margin.add_child(hbox)
	panel.add_child(margin)
	return panel

func _on_slot_action(slot_idx: int, is_new: bool) -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	SaveManager.active_slot = slot_idx

	if is_new:
		SaveManager.reset_for_new_game()
		var ch1 = "res://scenes/levels/chapter1_prehistoric.tscn"
		if ResourceLoader.exists(ch1):
			if UIManager:
				UIManager.transition_to_scene(ch1)
			else:
				get_tree().change_scene_to_file(ch1)
	else:
		var loaded = SaveManager.load_slot(slot_idx)
		if loaded:
			var target_scene = SaveManager.get_saved_scene_path()
			if target_scene.is_empty() or not ResourceLoader.exists(target_scene):
				target_scene = "res://scenes/levels/chapter1_prehistoric.tscn"
			if UIManager:
				UIManager.transition_to_scene(target_scene)
			else:
				get_tree().change_scene_to_file(target_scene)

func _on_slot_delete_clicked(slot_idx: int) -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	pending_delete_slot = slot_idx
	confirm_msg_label.text = Loc.get_str(
		"save_slots.delete_confirm",
		"Are you sure you want to permanently delete this save slot? This cannot be undone."
	)
	confirm_modal.visible = true
	confirm_no_button.grab_focus()

func _on_confirm_delete_yes() -> void:
	confirm_modal.visible = false
	if pending_delete_slot > 0:
		SaveManager.delete_slot(pending_delete_slot)
		if SoundManager:
			SoundManager.play_sfx("ui_confirm")
		pending_delete_slot = -1
		refresh_slots()
		# Return focus to back button
		back_button.grab_focus()

func _on_confirm_delete_no() -> void:
	confirm_modal.visible = false
	pending_delete_slot = -1
	if SoundManager:
		SoundManager.play_sfx("ui_cancel")

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_cancel")
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if confirm_modal.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_on_confirm_delete_no()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
