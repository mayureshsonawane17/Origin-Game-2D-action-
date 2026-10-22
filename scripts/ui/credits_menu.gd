class_name CreditsMenu
extends Control

## CreditsMenu: Data-driven scrolling credits for ORIGIN.
## Loads credit sections from data/credits.json and scrolls vertically.
## Supports skip (ui_cancel / any key / click) and returns cleanly to title screen.

signal finished()

@export var scroll_speed: float = 38.0 # Pixels per second
@export var fast_speed_multiplier: float = 3.5

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var content_vbox: VBoxContainer = $ScrollContainer/ContentVBox
@onready var skip_prompt_label: Label = $Footer/SkipPromptLabel

var is_scrolling: bool = true
var is_fast_forward: bool = false
var max_scroll_v: float = 0.0
var current_scroll_f: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_credits()
	if UIManager:
		skip_prompt_label.text = "%s %s" % [UIManager.get_action_prompt("ui_cancel"), Loc.get_str("common.close", "SKIP")]

func _populate_credits() -> void:
	for child in content_vbox.get_children():
		child.queue_free()

	# Top spacer so credits start below the screen
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 260)
	content_vbox.add_child(top_spacer)

	var path = "res://data/credits.json"
	var data: Dictionary = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary:
				data = parsed

	var title_text = data.get("title", "ORIGIN")
	var tagline_text = data.get("tagline", "Some loops are meant to be broken")

	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("#ae7e54")) # Gold
	content_vbox.add_child(title_lbl)

	var tag_lbl = Label.new()
	tag_lbl.text = tagline_text
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 8)
	tag_lbl.add_theme_color_override("font_color", Color("#7c5cff")) # Purple
	content_vbox.add_child(tag_lbl)

	# Spacer
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 24)
	content_vbox.add_child(sp1)

	var sections = data.get("sections", [])
	for sec in sections:
		if not (sec is Dictionary):
			continue
		var header_text = sec.get("header", "")
		var header_lbl = Label.new()
		header_lbl.text = header_text
		header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_lbl.add_theme_font_size_override("font_size", 10)
		header_lbl.add_theme_color_override("font_color", Color("#cbefc0")) # Mint green
		content_vbox.add_child(header_lbl)

		var entries = sec.get("entries", [])
		for ent in entries:
			var ent_lbl = Label.new()
			ent_lbl.text = str(ent)
			ent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ent_lbl.add_theme_font_size_override("font_size", 8)
			ent_lbl.add_theme_color_override("font_color", Color("#ebd2bd")) # Off-white
			content_vbox.add_child(ent_lbl)

		var sec_spacer = Control.new()
		sec_spacer.custom_minimum_size = Vector2(0, 18)
		content_vbox.add_child(sec_spacer)

	# Bottom spacer so final entries scroll fully off the screen
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 280)
	content_vbox.add_child(bottom_spacer)

	call_deferred("_calc_max_scroll")

func _calc_max_scroll() -> void:
	await get_tree().process_frame
	var v_bar = scroll_container.get_v_scroll_bar()
	if v_bar:
		max_scroll_v = v_bar.max_value

func _process(delta: float) -> void:
	if not is_scrolling or not visible:
		return

	var speed = scroll_speed * (fast_speed_multiplier if is_fast_forward else 1.0)
	current_scroll_f += speed * delta
	scroll_container.scroll_vertical = int(current_scroll_f)

	var v_bar = scroll_container.get_v_scroll_bar()
	if v_bar and current_scroll_f >= (v_bar.max_value - 10.0) and v_bar.max_value > 0:
		_end_credits()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_end_credits()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		is_fast_forward = true
	elif event.is_action_released("ui_accept") or event.is_action_released("attack") or event.is_action_released("jump"):
		is_fast_forward = false

func _end_credits() -> void:
	is_scrolling = false
	visible = false
	finished.emit()
	var title_path = "res://scenes/ui/main_menu.tscn"
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/ui/credits_menu.tscn":
		if UIManager:
			UIManager.transition_to_scene(title_path)
		else:
			get_tree().change_scene_to_file(title_path)
