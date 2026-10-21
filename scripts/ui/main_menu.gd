class_name MainMenu
extends Control

## Main Title Menu for ORIGIN.
## Provides New Game, Continue, Era Select, Controls Guide, and Quit functionality.
## Connects all 7 chapters into a seamless campaign with persistent progression.

signal menu_started()

const CHAPTER_SCENES: Array[Dictionary] = [
	{
		"chapter": 1,
		"title": "Era 1: Prehistoric Wilderness",
		"boss": "Titan of the Deep Earth",
		"scene": "res://scenes/levels/chapter1_prehistoric.tscn"
	},
	{
		"chapter": 2,
		"title": "Era 2: Medieval Cursed Keep",
		"boss": "Lord Malakor",
		"scene": "res://scenes/levels/chapter2_medieval.tscn"
	},
	{
		"chapter": 3,
		"title": "Era 3: Historical Crimson Mist",
		"boss": "Shogun Kageyasu",
		"scene": "res://scenes/levels/chapter3_historical.tscn"
	},
	{
		"chapter": 4,
		"title": "Era 4: Industrial Smog Docks",
		"boss": "Baron Von Steinhardt",
		"scene": "res://scenes/levels/chapter4_industrial.tscn"
	},
	{
		"chapter": 5,
		"title": "Era 5: Modern Metropolis",
		"boss": "General Vance",
		"scene": "res://scenes/levels/chapter5_modern.tscn"
	},
	{
		"chapter": 6,
		"title": "Era 6: Futuristic Cyber Spire",
		"boss": "Unit 00-NEXUS",
		"scene": "res://scenes/levels/chapter6_futuristic.tscn"
	},
	{
		"chapter": 7,
		"title": "Final Act: Fortress of the Gemstone",
		"boss": "The Immortal Villain",
		"scene": "res://scenes/levels/chapter7_fortress.tscn"
	}
]

# UI Nodes
@onready var loop_badge: Label = $MainLayout/Header/LoopBadge
@onready var new_game_btn: Button = $MainLayout/MenuVBox/NewGameButton
@onready var continue_btn: Button = $MainLayout/MenuVBox/ContinueButton
@onready var chapter_select_btn: Button = $MainLayout/MenuVBox/ChapterSelectButton
@onready var boss_rush_btn: Button = $MainLayout/MenuVBox/BossRushButton
@onready var controls_btn: Button = $MainLayout/MenuVBox/ControlsButton
@onready var quit_btn: Button = $MainLayout/MenuVBox/QuitButton

# Modal Overlays
@onready var chapter_modal: Control = $ChapterSelectModal
@onready var chapter_list_container: VBoxContainer = $ChapterSelectModal/Center/Panel/Margin/VBox/Scroll/ChapterList
@onready var chapter_close_btn: Button = $ChapterSelectModal/Center/Panel/Margin/VBox/CloseButton

@onready var controls_modal: Control = $ControlsModal
@onready var controls_close_btn: Button = $ControlsModal/Center/Panel/Margin/VBox/CloseButton

@onready var confirm_modal: Control = $ConfirmModal
@onready var confirm_yes_btn: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/YesButton
@onready var confirm_no_btn: Button = $ConfirmModal/Center/Panel/Margin/VBox/ButtonHBox/NoButton

func _ready() -> void:
	chapter_modal.visible = false
	controls_modal.visible = false
	confirm_modal.visible = false

	# Connect main buttons
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	chapter_select_btn.pressed.connect(_on_chapter_select_pressed)
	boss_rush_btn.pressed.connect(_on_boss_rush_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Connect modal buttons
	chapter_close_btn.pressed.connect(func(): chapter_modal.visible = false)
	controls_close_btn.pressed.connect(func(): controls_modal.visible = false)
	confirm_yes_btn.pressed.connect(_start_fresh_new_game)
	confirm_no_btn.pressed.connect(func(): confirm_modal.visible = false)

	_refresh_menu_state()
	if SoundManager:
		SoundManager.play_bgm("title")
	menu_started.emit()

func _refresh_menu_state() -> void:
	var reset_count = ResetManager.reset_count if ResetManager else 0
	loop_badge.text = "ACTIVE LOOP: #%d" % reset_count

	var has_save_file = SaveManager.has_save() if SaveManager else false
	continue_btn.disabled = not has_save_file
	if has_save_file:
		continue_btn.text = "CONTINUE [Loop #%d]" % reset_count
	else:
		continue_btn.text = "CONTINUE [No Save]"

	var best_rush_time = SaveManager.get_best_boss_rush_time() if SaveManager else -1.0
	if best_rush_time > 0.0:
		boss_rush_btn.text = "BOSS RUSH [Best: %s]" % SaveManager.format_time(best_rush_time)
	else:
		boss_rush_btn.text = "BOSS RUSH [13 Boss Gauntlet]"

	# Focus first available button
	if has_save_file:
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()

func _on_new_game_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	if SaveManager and SaveManager.has_save():
		confirm_modal.visible = true
		confirm_yes_btn.grab_focus()
	else:
		_start_fresh_new_game()

func _start_fresh_new_game() -> void:
	confirm_modal.visible = false
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	if SaveManager:
		SaveManager.reset_for_new_game()
	if ResetManager:
		ResetManager.reset_count += 1
		ResetManager.save_loop_count()

	var ch1_path = CHAPTER_SCENES[0]["scene"]
	if ResourceLoader.exists(ch1_path):
		get_tree().change_scene_to_file(ch1_path)

func _on_continue_pressed() -> void:
	if not SaveManager or not SaveManager.has_save():
		return
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")

	var loaded = SaveManager.load_game()
	if not loaded:
		printerr("[MainMenu] Failed to load save file.")
		return

	var saved_scene = SaveManager.get_saved_scene_path()
	if not saved_scene.is_empty() and ResourceLoader.exists(saved_scene):
		get_tree().change_scene_to_file(saved_scene)
		return

	# Fallback: jump to highest unlocked chapter
	var max_unlocked = SaveManager.get_unlocked_chapter()
	var target_index = clampi(max_unlocked - 1, 0, CHAPTER_SCENES.size() - 1)
	var fallback_scene = CHAPTER_SCENES[target_index]["scene"]
	get_tree().change_scene_to_file(fallback_scene)

func _on_chapter_select_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	_populate_chapter_list()
	chapter_modal.visible = true
	chapter_close_btn.grab_focus()

func _populate_chapter_list() -> void:
	for child in chapter_list_container.get_children():
		child.queue_free()

	var max_unlocked = SaveManager.get_unlocked_chapter() if SaveManager else 1

	for entry in CHAPTER_SCENES:
		var ch_num = int(entry["chapter"])
		var is_unlocked = (ch_num <= max_unlocked)

		var item_btn = Button.new()
		item_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_btn.add_theme_font_size_override("font_size", 8)

		if is_unlocked:
			item_btn.text = "▶ %s  [%s]" % [entry["title"], entry["boss"]]
			item_btn.disabled = false
			item_btn.pressed.connect(func(): _launch_chapter(entry["scene"]))
		else:
			item_btn.text = "🔒 %s  (Complete Era %d)" % [entry["title"], ch_num - 1]
			item_btn.disabled = true

		chapter_list_container.add_child(item_btn)

func _launch_chapter(scene_path: String) -> void:
	chapter_modal.visible = false
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	if SaveManager and SaveManager.has_save():
		SaveManager.load_game()
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)

func _on_boss_rush_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file("res://scenes/levels/boss_rush.tscn")

func _on_controls_pressed() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	controls_modal.visible = true
	controls_close_btn.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
