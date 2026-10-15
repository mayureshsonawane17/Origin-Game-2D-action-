class_name InventoryMenu
extends CanvasLayer

## Progression, Equipment, and Skill Tree Menu (Milestone 3).
## Allows viewing loadout, swapping weapons, unlocking skills across 6 branches,
## inspecting active stat multipliers, and triggering manual saves.

signal menu_opened()
signal menu_closed()

@onready var panel_container: PanelContainer = $PanelContainer
@onready var loop_label: Label = $PanelContainer/Margin/MainVBox/Header/LoopLabel
@onready var skill_points_label: Label = $PanelContainer/Margin/MainVBox/Header/SkillPointsLabel
@onready var close_btn: Button = $PanelContainer/Margin/MainVBox/Header/CloseButton

# Equipment labels & buttons
@onready var primary_wep_name: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/PrimaryCard/HBox/VBox/WepName
@onready var primary_wep_stats: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/PrimaryCard/HBox/VBox/WepStats
@onready var primary_wep_tag: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/PrimaryCard/HBox/ActiveTag

@onready var secondary_wep_name: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/SecondaryCard/HBox/VBox/WepName
@onready var secondary_wep_stats: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/SecondaryCard/HBox/VBox/WepStats
@onready var secondary_wep_tag: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/SecondaryCard/HBox/ActiveTag

@onready var switch_wep_btn: Button = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/SwitchWepButton
@onready var armor_name: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/ArmorCard/HBox/VBox/ArmorName
@onready var armor_stats: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/ArmorCard/HBox/VBox/ArmorStats

# Aggregated Stats
@onready var stats_summary_label: Label = $PanelContainer/Margin/MainVBox/ContentHBox/EquipVBox/StatsCard/StatsSummary

# Skills container
@onready var skills_grid: GridContainer = $PanelContainer/Margin/MainVBox/ContentHBox/SkillsVBox/SkillsScroll/SkillsGrid
@onready var toast_label: Label = $PanelContainer/Margin/MainVBox/BottomBar/ToastLabel
@onready var save_btn: Button = $PanelContainer/Margin/MainVBox/BottomBar/SaveButton

var is_open: bool = false
var toast_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false
	
	close_btn.pressed.connect(close)
	if switch_wep_btn:
		switch_wep_btn.pressed.connect(_on_switch_weapon_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
		
	if SaveManager:
		SaveManager.game_saved.connect(_on_game_saved)
		if SaveManager.skill_tree:
			SaveManager.skill_tree.skill_points_changed.connect(func(_pts): _refresh_ui())
			SaveManager.skill_tree.skill_unlocked.connect(func(_sk): _refresh_ui())

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and toast_label:
			toast_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open:
		if event.is_action_pressed("pause") or event.is_action_pressed("dodge"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("switch_weapon"):
			_on_switch_weapon_pressed()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh_ui()
	close_btn.grab_focus()
	menu_opened.emit()

func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	menu_closed.emit()

func _refresh_ui() -> void:
	if not SaveManager:
		return

	# Loop & Points
	if loop_label and ResetManager:
		loop_label.text = "LOOP #%d" % ResetManager.reset_count
	if skill_points_label and SaveManager.skill_tree:
		skill_points_label.text = "SKILL POINTS: %d" % SaveManager.skill_tree.available_skill_points

	# Weapons
	var p_wep = SaveManager.primary_weapon
	if primary_wep_name and p_wep:
		primary_wep_name.text = p_wep.display_name
		primary_wep_stats.text = "DMG: %d | MOBILITY: %.0f%%" % [p_wep.base_damage, p_wep.mobility_multiplier * 100.0]
		primary_wep_tag.visible = (SaveManager.active_weapon_slot == 0)
	elif primary_wep_name:
		primary_wep_name.text = "None"
		primary_wep_stats.text = "-"
		primary_wep_tag.visible = false

	var s_wep = SaveManager.secondary_weapon
	if secondary_wep_name and s_wep:
		secondary_wep_name.text = s_wep.display_name
		secondary_wep_stats.text = "DMG: %d | MOBILITY: %.0f%%" % [s_wep.base_damage, s_wep.mobility_multiplier * 100.0]
		secondary_wep_tag.visible = (SaveManager.active_weapon_slot == 1)
	elif secondary_wep_name:
		secondary_wep_name.text = "None"
		secondary_wep_stats.text = "-"
		secondary_wep_tag.visible = false

	# Armor
	var armor = SaveManager.current_armor
	if armor_name and armor:
		armor_name.text = armor.display_name
		armor_stats.text = "DEF: %.0f%% DMG | MOBILITY: %.0f%%" % [armor.defense_multiplier * 100.0, armor.mobility_multiplier * 100.0]
	elif armor_name:
		armor_name.text = "None"
		armor_stats.text = "-"

	# Overall Stats calculation
	var player = get_tree().get_first_node_in_group("player") as Player
	if stats_summary_label:
		var mob = player.get_mobility_multiplier() if player else 1.0
		var def = player.get_defense_multiplier() if player else 1.0
		var wep = SaveManager.get_active_weapon()
		var dmg = wep.base_damage if wep else 1
		if SaveManager.skill_tree:
			var mods = SaveManager.skill_tree.get_total_stat_modifiers()
			dmg += int(mods.get("bonus_damage", 0))
		stats_summary_label.text = "ACTIVE ATK DMG: %d  |  DMG TAKEN: %.0f%%  |  SPEED: %.0f%%" % [
			dmg,
			def * 100.0,
			mob * 100.0
		]

	# Build Skills Grid
	_build_skills_grid()

func _build_skills_grid() -> void:
	if not skills_grid or not SaveManager or not SaveManager.skill_tree:
		return

	for child in skills_grid.get_children():
		child.queue_free()

	var st = SaveManager.skill_tree
	for skill_id in st.all_skills.keys():
		var skill: SkillData = st.all_skills[skill_id]
		var is_unlocked = st.is_skill_unlocked(skill_id)
		var can_unlock = st.can_unlock_skill(skill_id)

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 48)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		card.add_child(vbox)

		# Branch & Name
		var title_lbl = Label.new()
		title_lbl.text = "[%s] %s" % [skill.branch.substr(0, 3).to_upper(), skill.display_name]
		title_lbl.add_theme_font_size_override("font_size", 7)
		if is_unlocked:
			title_lbl.modulate = Color(0.3, 1.0, 0.4)
		elif can_unlock:
			title_lbl.modulate = Color(1.0, 0.85, 0.2)
		else:
			title_lbl.modulate = Color(0.6, 0.6, 0.6)
		vbox.add_child(title_lbl)

		# Description snippet
		var desc_lbl = Label.new()
		desc_lbl.text = skill.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 6)
		desc_lbl.modulate = Color(0.8, 0.85, 0.9)
		vbox.add_child(desc_lbl)

		# Button / Status
		if is_unlocked:
			var status_lbl = Label.new()
			status_lbl.text = "✓ UNLOCKED"
			status_lbl.add_theme_font_size_override("font_size", 7)
			status_lbl.modulate = Color(0.3, 1.0, 0.4)
			vbox.add_child(status_lbl)
		else:
			var unlock_btn = Button.new()
			unlock_btn.text = "LEARN (%d SP)" % skill.cost
			unlock_btn.add_theme_font_size_override("font_size", 7)
			unlock_btn.disabled = not can_unlock
			unlock_btn.pressed.connect(func(): _on_unlock_skill_pressed(skill_id))
			vbox.add_child(unlock_btn)

		skills_grid.add_child(card)

func _on_unlock_skill_pressed(skill_id: String) -> void:
	if SaveManager and SaveManager.skill_tree:
		if SaveManager.skill_tree.unlock_skill(skill_id):
			_show_toast("Unlocked skill!")
			# Auto-save changes
			SaveManager.save_game()
			_refresh_ui()

func _on_switch_weapon_pressed() -> void:
	if SaveManager:
		var wep = SaveManager.switch_weapon()
		var player = get_tree().get_first_node_in_group("player") as Player
		if player and wep:
			var spark = player.HIT_SPARK_SCENE.instantiate()
			spark.global_position = player.global_position + Vector2(player.facing_direction * 12.0, -18.0)
			spark.spark_color = wep.weapon_accent_color
			player.get_parent().add_child(spark)
		_refresh_ui()

func _on_save_pressed() -> void:
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
		var player = get_tree().get_first_node_in_group("player") as Player
		var p_pos = player.global_position if player else Vector2.ZERO
		if SaveManager.save_game(p_pos, scene_path, "manual_save"):
			_show_toast("Progress Saved!")

func _on_game_saved() -> void:
	_show_toast("Game Saved!")

func _show_toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg
		toast_timer = 2.0
