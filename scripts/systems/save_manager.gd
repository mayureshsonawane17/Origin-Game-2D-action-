extends Node

## SaveManager: Central persistence pipeline for ORIGIN (Milestone 3 & Part A).
## Serializes and restores skills, equipment, player stats, checkpoints, and loop data.
## Part A: Multi-slot saves (3 slots), standalone settings file, and input rebinding.

signal game_saved()
signal game_loaded()
signal autosave_started()
signal autosave_finished()
signal settings_saved()
signal settings_loaded()

const NUM_SLOTS: int = 3
const SAVE_SLOT_PATTERN: String = "user://save_slot_%d.json"
const LEGACY_SAVE_PATH: String = "user://origin_savegame.json"
const SETTINGS_PATH: String = "user://origin_settings.json"

var active_slot: int = 1
var play_time_seconds: float = 0.0

var skill_tree: SkillTreeManager
var current_save_data: Dictionary = {}
var max_unlocked_chapter: int = 1
var best_boss_rush_time: float = -1.0

# Relic and crafting state
var unlocked_relics: Array[String] = []
var crafted_relic_perks: Array[String] = []
var challenge_return_info: Dictionary = {}

# Settings & Accessibility state (persisted separately in SETTINGS_PATH)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var bgm_volume: float = 0.8
var is_muted: bool = false
var reduce_flashing: bool = false
var screen_shake_intensity: float = 1.0
var screen_shake_enabled: bool = true:
	get:
		return screen_shake_intensity > 0.0
	set(val):
		screen_shake_intensity = 1.0 if val else 0.0
var text_speed: float = 1.0
var high_contrast: bool = false
var skip_intro: bool = false
var touch_controls_enabled: bool = false
var touch_scale: float = 1.0
var touch_opacity: float = 0.8
var fullscreen: bool = false
var integer_scale: int = 0
var custom_keybinds: Dictionary = {}

# Character selection
var selected_character: String = "hero" # "hero" (Naksh) or "riya" (The Radiant Mage)

# In-memory session equipment state
var primary_weapon: EquipmentItem
var secondary_weapon: EquipmentItem
var active_weapon_slot: int = 0 # 0: primary, 1: secondary
var current_armor: EquipmentItem
var inventory: Array[EquipmentItem] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	skill_tree = SkillTreeManager.new()
	add_child(skill_tree)
	_load_initial_default_equipment()
	load_settings()
	if has_save():
		_peek_unlocked_chapter()
	print("[SaveManager] Initialized. 3 Save Slots & Standalone Settings ready.")

func _process(delta: float) -> void:
	# Accumulate play time while playing in an active level
	var player = get_tree().get_first_node_in_group("player")
	if player and not get_tree().paused:
		play_time_seconds += delta

# ----------------------------------------------------
# Multi-Slot File Routing & Queries
# ----------------------------------------------------
func get_slot_path(slot: int) -> String:
	return SAVE_SLOT_PATTERN % clampi(slot, 1, NUM_SLOTS)

func has_save(slot: int = -1) -> bool:
	if slot > 0:
		var p = get_slot_path(slot)
		if FileAccess.file_exists(p):
			return true
		if slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			return true
		return false
	# Check if ANY slot exists or legacy file exists
	for i in range(1, NUM_SLOTS + 1):
		if FileAccess.file_exists(get_slot_path(i)):
			return true
	return FileAccess.file_exists(LEGACY_SAVE_PATH)

func get_slot_meta(slot: int) -> Dictionary:
	var path = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		if slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
		else:
			return {
				"slot": slot,
				"exists": false,
				"is_corrupted": false,
				"era": "",
				"area": "",
				"play_time": 0.0,
				"last_saved": 0,
				"character": "Naksh",
				"chapter": 1
			}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {
			"slot": slot,
			"exists": true,
			"is_corrupted": true,
			"era": "Corrupted",
			"area": "Error reading file",
			"play_time": 0.0,
			"last_saved": 0,
			"character": "Unknown",
			"chapter": 1
		}

	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {
			"slot": slot,
			"exists": true,
			"is_corrupted": true,
			"era": "Corrupted",
			"area": "Invalid JSON format",
			"play_time": 0.0,
			"last_saved": 0,
			"character": "Unknown",
			"chapter": 1
		}

	var ch_num: int = int(parsed.get("unlocked_chapter", 1))
	var era_str: String = _get_era_name(ch_num)
	var area_str: String = _get_area_name(parsed)
	var char_id: String = str(parsed.get("selected_character", "hero"))
	var char_display: String = "Naksh" if char_id == "hero" else "Riya"

	return {
		"slot": slot,
		"exists": true,
		"is_corrupted": false,
		"era": era_str,
		"area": area_str,
		"play_time": float(parsed.get("play_time_seconds", 0.0)),
		"last_saved": int(parsed.get("timestamp", 0)),
		"character": char_display,
		"chapter": ch_num
	}

func _get_era_name(chapter_num: int) -> String:
	match chapter_num:
		1: return "Era 1: Prehistoric"
		2: return "Era 2: Medieval"
		3: return "Era 3: Historical"
		4: return "Era 4: Industrial"
		5: return "Era 5: Modern"
		6: return "Era 6: Futuristic"
		7: return "Final Era: Fortress"
		_: return "Era %d" % chapter_num

func _get_area_name(data: Dictionary) -> String:
	if data.has("checkpoint"):
		var cp = data["checkpoint"]
		var cp_id = str(cp.get("id", ""))
		if not cp_id.is_empty():
			return "Checkpoint: %s" % cp_id
		var scene_path = str(cp.get("scene_path", ""))
		if not scene_path.is_empty():
			var base = scene_path.get_file().get_basename().replace("_", " ").capitalize()
			return base
	var ch = int(data.get("unlocked_chapter", 1))
	return "Chapter %d Wilderness" % ch

# ----------------------------------------------------
# Save, Load, Delete Operations
# ----------------------------------------------------
func save_game(checkpoint_pos: Vector2 = Vector2.ZERO, scene_path: String = "", cp_id: String = "") -> bool:
	return save_slot(active_slot, checkpoint_pos, scene_path, cp_id)

func save_slot(slot: int, checkpoint_pos: Vector2 = Vector2.ZERO, scene_path: String = "", cp_id: String = "") -> bool:
	autosave_started.emit()
	active_slot = clampi(slot, 1, NUM_SLOTS)
	var player = get_tree().get_first_node_in_group("player") as Player

	var save_dict: Dictionary = {
		"version": "1.0.0",
		"slot": active_slot,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time_seconds": play_time_seconds,
		"reset_count": ResetManager.reset_count if ResetManager else 0,
		"unlocked_chapter": max_unlocked_chapter,
		"best_boss_rush_time": best_boss_rush_time,
		"selected_character": selected_character,
		"relics": unlocked_relics,
		"crafted_perks": crafted_relic_perks,
		"player": {
			"health": player.current_health if player else 5,
			"mana": player.current_mana if player else 50.0,
			"heal_charges": player.heal_charges if player else 3
		},
		"equipment": {
			"primary_id": primary_weapon.id if primary_weapon else "",
			"secondary_id": secondary_weapon.id if secondary_weapon else "",
			"active_slot": active_weapon_slot,
			"armor_id": current_armor.id if current_armor else "",
			"inventory_ids": []
		},
		"skills": skill_tree.serialize(),
		"checkpoint": {
			"id": cp_id,
			"pos_x": checkpoint_pos.x,
			"pos_y": checkpoint_pos.y,
			"scene_path": scene_path
		}
	}

	for item in inventory:
		if item:
			save_dict["equipment"]["inventory_ids"].append(item.id)

	var target_path = get_slot_path(active_slot)
	var file = FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		printerr("[SaveManager] Failed to write slot %d to %s" % [active_slot, target_path])
		autosave_finished.emit()
		return false

	var json_str = JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()

	# Also maintain backward compatible legacy file for slot 1
	if active_slot == 1:
		var legacy_file = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.WRITE)
		if legacy_file:
			legacy_file.store_string(json_str)
			legacy_file.close()

	current_save_data = save_dict
	print("[SaveManager] Saved game to Slot %d: %s" % [active_slot, target_path])
	game_saved.emit()
	autosave_finished.emit()

	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr and ui_mgr.has_method("show_toast"):
		ui_mgr.show_toast(Loc.get_str("toasts.autosave", "CHECKPOINT SAVED"), "💾")

	return true

func load_game() -> bool:
	return load_slot(active_slot)

func load_slot(slot: int) -> bool:
	active_slot = clampi(slot, 1, NUM_SLOTS)
	var path = get_slot_path(active_slot)
	if not FileAccess.file_exists(path):
		if active_slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
		else:
			print("[SaveManager] Slot %d file not found: %s" % [active_slot, path])
			return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		printerr("[SaveManager] Corrupt save file at %s" % path)
		return false

	current_save_data = parsed
	play_time_seconds = float(current_save_data.get("play_time_seconds", 0.0))

	# 1. Restore loop count
	if current_save_data.has("reset_count") and ResetManager:
		ResetManager.reset_count = int(current_save_data["reset_count"])

	# 2. Restore unlocked chapter
	if current_save_data.has("unlocked_chapter"):
		max_unlocked_chapter = clampi(int(current_save_data["unlocked_chapter"]), 1, 7)

	# 3. Restore best boss rush time
	if current_save_data.has("best_boss_rush_time"):
		best_boss_rush_time = float(current_save_data["best_boss_rush_time"])

	# 4. Restore skills
	if current_save_data.has("skills"):
		skill_tree.deserialize(current_save_data["skills"])

	# 5. Restore equipment
	if current_save_data.has("equipment"):
		var eq = current_save_data["equipment"]
		if eq.has("primary_id") and not eq["primary_id"].is_empty():
			var p_path = "res://data/equipment/%s.tres" % eq["primary_id"]
			if ResourceLoader.exists(p_path):
				primary_weapon = load(p_path) as EquipmentItem
		if eq.has("secondary_id") and not eq["secondary_id"].is_empty():
			var s_path = "res://data/equipment/%s.tres" % eq["secondary_id"]
			if ResourceLoader.exists(s_path):
				secondary_weapon = load(s_path) as EquipmentItem
		if eq.has("armor_id") and not eq["armor_id"].is_empty():
			var a_path = "res://data/equipment/%s.tres" % eq["armor_id"]
			if ResourceLoader.exists(a_path):
				current_armor = load(a_path) as EquipmentItem
		if eq.has("active_slot"):
			active_weapon_slot = int(eq["active_slot"])

	# 6. Restore character selection
	if current_save_data.has("selected_character"):
		selected_character = str(current_save_data["selected_character"])

	# 7. Restore relics & crafted perks
	if current_save_data.has("relics"):
		unlocked_relics.clear()
		for r in current_save_data["relics"]:
			unlocked_relics.append(str(r))
	if current_save_data.has("crafted_perks"):
		crafted_relic_perks.clear()
		for p in current_save_data["crafted_perks"]:
			crafted_relic_perks.append(str(p))

	print("[SaveManager] Loaded Slot %d successfully (Max Chapter: %d)" % [active_slot, max_unlocked_chapter])
	game_loaded.emit()
	return true

func delete_slot(slot: int) -> bool:
	var slot_num = clampi(slot, 1, NUM_SLOTS)
	var path = get_slot_path(slot_num)
	var removed = false
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		removed = (err == OK)
	if slot_num == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(LEGACY_SAVE_PATH)
		removed = true

	if active_slot == slot_num:
		current_save_data.clear()
		play_time_seconds = 0.0

	print("[SaveManager] Deleted Slot %d (Success: %s)" % [slot_num, removed])
	return removed

# ----------------------------------------------------
# Standalone Settings Persistence
# ----------------------------------------------------
func save_settings() -> void:
	var st_dict: Dictionary = {
		"version": "1.0.0",
		"audio": {
			"master_volume": master_volume,
			"sfx_volume": sfx_volume,
			"bgm_volume": bgm_volume,
			"is_muted": is_muted
		},
		"display": {
			"fullscreen": fullscreen,
			"integer_scale": integer_scale
		},
		"accessibility": {
			"reduce_flashing": reduce_flashing,
			"screen_shake_intensity": screen_shake_intensity,
			"text_speed": text_speed,
			"high_contrast": high_contrast
		},
		"gameplay": {
			"skip_intro": skip_intro,
			"touch_controls_enabled": touch_controls_enabled,
			"touch_scale": touch_scale,
			"touch_opacity": touch_opacity
		},
		"controls": custom_keybinds
	}

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(st_dict, "\t"))
		file.close()
		settings_saved.emit()
		print("[SaveManager] Settings saved to %s" % SETTINGS_PATH)

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		apply_settings()
		return

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		apply_settings()
		return

	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		apply_settings()
		return

	if parsed.has("audio"):
		var a = parsed["audio"]
		master_volume = float(a.get("master_volume", 1.0))
		sfx_volume = float(a.get("sfx_volume", 1.0))
		bgm_volume = float(a.get("bgm_volume", 0.8))
		is_muted = bool(a.get("is_muted", false))

	if parsed.has("display"):
		var d = parsed["display"]
		fullscreen = bool(d.get("fullscreen", false))
		integer_scale = int(d.get("integer_scale", 0))

	if parsed.has("accessibility"):
		var ac = parsed["accessibility"]
		reduce_flashing = bool(ac.get("reduce_flashing", false))
		screen_shake_intensity = float(ac.get("screen_shake_intensity", 1.0))
		text_speed = float(ac.get("text_speed", 1.0))
		high_contrast = bool(ac.get("high_contrast", false))

	if parsed.has("gameplay"):
		var g = parsed["gameplay"]
		skip_intro = bool(g.get("skip_intro", false))
		touch_controls_enabled = bool(g.get("touch_controls_enabled", false))
		touch_scale = float(g.get("touch_scale", 1.0))
		touch_opacity = float(g.get("touch_opacity", 0.8))

	if parsed.has("controls"):
		custom_keybinds = parsed["controls"]
		_apply_custom_keybinds()

	apply_settings()
	settings_loaded.emit()

func apply_settings() -> void:
	# Audio buses
	if SoundManager:
		var effective_master = 0.0 if is_muted else master_volume
		SoundManager.set_sfx_volume(sfx_volume * effective_master)
		SoundManager.set_bgm_volume(bgm_volume * effective_master)

	# Display fullscreen
	var target_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)

	# Integer Scale
	if not fullscreen and integer_scale > 0:
		var base_w = 480
		var base_h = 270
		DisplayServer.window_set_size(Vector2i(base_w * integer_scale, base_h * integer_scale))

func reset_settings_to_defaults() -> void:
	master_volume = 1.0
	sfx_volume = 1.0
	bgm_volume = 0.8
	is_muted = false
	reduce_flashing = false
	screen_shake_intensity = 1.0
	text_speed = 1.0
	high_contrast = false
	skip_intro = false
	touch_controls_enabled = false
	touch_scale = 1.0
	touch_opacity = 0.8
	fullscreen = false
	integer_scale = 0
	custom_keybinds.clear()
	reset_controls_to_defaults()
	save_settings()
	apply_settings()

# ----------------------------------------------------
# Rebindable Input System
# ----------------------------------------------------
func rebind_action(action: String, new_event: InputEvent) -> Dictionary:
	var conflict_action = find_action_with_event(new_event, action)
	if not conflict_action.is_empty():
		return {
			"has_conflict": true,
			"conflicting_action": conflict_action
		}

	# Clear and bind new event
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	_record_event_in_custom_keybinds(action, new_event)
	save_settings()
	return { "has_conflict": false, "conflicting_action": "" }

func find_action_with_event(target_event: InputEvent, exclude_action: String = "") -> String:
	for action in InputMap.get_actions():
		if action == exclude_action or action.begins_with("ui_"):
			continue
		for ev in InputMap.action_get_events(action):
			if _are_events_equal(ev, target_event):
				return action
	return ""

func _are_events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode or a.keycode == b.keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	return false

func _record_event_in_custom_keybinds(action: String, ev: InputEvent) -> void:
	if ev is InputEventKey:
		var code = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		custom_keybinds[action] = { "type": "key", "code": code }
	elif ev is InputEventJoypadButton:
		custom_keybinds[action] = { "type": "button", "index": ev.button_index }

func _apply_custom_keybinds() -> void:
	for action in custom_keybinds.keys():
		if not InputMap.has_action(action):
			continue
		var data = custom_keybinds[action]
		if data is Dictionary:
			if data.get("type") == "key":
				var key_ev = InputEventKey.new()
				key_ev.physical_keycode = int(data.get("code", 0))
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, key_ev)
			elif data.get("type") == "button":
				var joy_ev = InputEventJoypadButton.new()
				joy_ev.button_index = int(data.get("index", 0))
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, joy_ev)

func reset_controls_to_defaults() -> void:
	InputMap.load_from_project_settings()
	custom_keybinds.clear()
	save_settings()

# ----------------------------------------------------
# Backward Compatibility & Equipment Pipelines
# ----------------------------------------------------
func _load_initial_default_equipment() -> void:
	if ResourceLoader.exists("res://data/equipment/primordial_blade.tres"):
		primary_weapon = load("res://data/equipment/primordial_blade.tres") as EquipmentItem
	if ResourceLoader.exists("res://data/equipment/heavy_obsidian_cleaver.tres"):
		secondary_weapon = load("res://data/equipment/heavy_obsidian_cleaver.tres") as EquipmentItem
	if ResourceLoader.exists("res://data/equipment/stalker_leather_armor.tres"):
		current_armor = load("res://data/equipment/stalker_leather_armor.tres") as EquipmentItem

func _peek_unlocked_chapter() -> void:
	var meta = get_slot_meta(active_slot)
	if meta["exists"] and not meta["is_corrupted"]:
		max_unlocked_chapter = meta["chapter"]

func get_active_weapon() -> EquipmentItem:
	return secondary_weapon if active_weapon_slot == 1 and secondary_weapon else primary_weapon

func switch_weapon() -> EquipmentItem:
	if secondary_weapon:
		active_weapon_slot = 1 if active_weapon_slot == 0 else 0
		print("[SaveManager] Switched active weapon to slot %d: %s" % [active_weapon_slot, get_active_weapon().display_name if get_active_weapon() else "None"])
	return get_active_weapon()

func set_selected_character(char_id: String) -> void:
	if char_id in ["hero", "elysia", "riya"]:
		selected_character = char_id
		print("[SaveManager] Selected Character: %s" % selected_character)

func get_selected_character() -> String:
	return selected_character

func record_boss_rush_time(time_seconds: float) -> bool:
	if time_seconds <= 0.0:
		return false
	var is_new_record: bool = false
	if best_boss_rush_time < 0.0 or time_seconds < best_boss_rush_time:
		best_boss_rush_time = time_seconds
		is_new_record = true
	return is_new_record

func get_best_boss_rush_time() -> float:
	return best_boss_rush_time

static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--.--"
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	var centis: int = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, centis]

func unlock_chapter(chapter_num: int) -> void:
	if chapter_num > max_unlocked_chapter:
		max_unlocked_chapter = clampi(chapter_num, 1, 7)
		print("[SaveManager] Unlocked Chapter %d" % max_unlocked_chapter)

func get_unlocked_chapter() -> int:
	return max_unlocked_chapter

func get_saved_scene_path() -> String:
	if current_save_data.has("checkpoint"):
		return str(current_save_data["checkpoint"].get("scene_path", ""))
	return ""

func reset_for_new_game() -> void:
	current_save_data.clear()
	play_time_seconds = 0.0
	_load_initial_default_equipment()
	active_weapon_slot = 0
	if skill_tree:
		skill_tree.unlocked_skill_ids.clear()
		skill_tree.available_skill_points = 0
		skill_tree.skill_points_changed.emit(0)

func apply_to_player(player: Player) -> void:
	if not player or current_save_data.is_empty():
		return

	if current_save_data.has("player"):
		var p_data = current_save_data["player"]
		player.current_health = int(p_data.get("health", player.current_health))
		player.current_mana = float(p_data.get("mana", player.current_mana))
		player.heal_charges = int(p_data.get("heal_charges", player.heal_charges))
		player.health_changed.emit(player.current_health, player.tuning.max_health)
		player.mana_changed.emit(player.current_mana, float(player.tuning.max_mana))
		player.heal_charges_changed.emit(player.heal_charges, player.tuning.max_heal_charges)

	if current_save_data.has("checkpoint"):
		var cp = current_save_data["checkpoint"]
		var px = float(cp.get("pos_x", 0.0))
		var py = float(cp.get("pos_y", 0.0))
		if px != 0.0 or py != 0.0:
			player.global_position = Vector2(px, py)

func add_relic(relic_id: String) -> void:
	if not unlocked_relics.has(relic_id):
		unlocked_relics.append(relic_id)
		print("[SaveManager] Acquired Relic: %s" % relic_id)
		var ui_mgr = get_node_or_null("/root/UIManager")
		if ui_mgr and ui_mgr.has_method("show_toast"):
			ui_mgr.show_toast(Loc.get_str("toasts.relic_unlocked", "NEW BOSS RELIC DISCOVERED"), "✦")

func has_relic(relic_id: String) -> bool:
	return unlocked_relics.has(relic_id)

func craft_relic_perk(relic_id: String) -> bool:
	if has_relic(relic_id) and not has_relic_perk(relic_id):
		crafted_relic_perks.append(relic_id)
		print("[SaveManager] Crafted Relic Perk for: %s" % relic_id)
		return true
	return false

func has_relic_perk(relic_id: String) -> bool:
	return crafted_relic_perks.has(relic_id)

func set_challenge_return(scene_path: String, pos: Vector2) -> void:
	challenge_return_info = {
		"scene_path": scene_path,
		"pos_x": pos.x,
		"pos_y": pos.y
	}

func has_challenge_return() -> bool:
	return not challenge_return_info.is_empty() and str(challenge_return_info.get("scene_path", "")).length() > 0

func get_challenge_return() -> Dictionary:
	return challenge_return_info

func clear_challenge_return() -> void:
	challenge_return_info.clear()
