extends Node

## SaveManager: Central persistence pipeline for ORIGIN (Milestone 3).
## Serializes and restores skills, equipment, player stats, checkpoints, and loop data.

signal game_saved()
signal game_loaded()

const SAVE_PATH: String = "user://origin_savegame.json"

var skill_tree: SkillTreeManager
var current_save_data: Dictionary = {}
var max_unlocked_chapter: int = 1
var best_boss_rush_time: float = -1.0

# Relic and crafting state
var unlocked_relics: Array[String] = []
var crafted_relic_perks: Array[String] = []
var challenge_return_info: Dictionary = {}

# Settings and accessibility state
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var bgm_volume: float = 0.8
var reduce_flashing: bool = false
var screen_shake_enabled: bool = true
var touch_controls_enabled: bool = false

# Character selection
var selected_character: String = "hero" # "hero" or "elysia"

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
	if has_save():
		_peek_unlocked_chapter()
	print("[SaveManager] Initialized. Save file exists: %s, Max Unlocked Chapter: %d" % [has_save(), max_unlocked_chapter])

func _peek_unlocked_chapter() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			if parsed.has("unlocked_chapter"):
				max_unlocked_chapter = clampi(int(parsed["unlocked_chapter"]), 1, 7)
			if parsed.has("best_boss_rush_time"):
				best_boss_rush_time = float(parsed["best_boss_rush_time"])
			if parsed.has("relics"):
				for r in parsed["relics"]:
					if not unlocked_relics.has(str(r)):
						unlocked_relics.append(str(r))
			if parsed.has("crafted_perks"):
				for p in parsed["crafted_perks"]:
					if not crafted_relic_perks.has(str(p)):
						crafted_relic_perks.append(str(p))
			if parsed.has("settings"):
				var s = parsed["settings"]
				master_volume = float(s.get("master_volume", 1.0))
				sfx_volume = float(s.get("sfx_volume", 1.0))
				bgm_volume = float(s.get("bgm_volume", 0.8))
				reduce_flashing = bool(s.get("reduce_flashing", false))
				screen_shake_enabled = bool(s.get("screen_shake_enabled", true))
				touch_controls_enabled = bool(s.get("touch_controls_enabled", false))

func _load_initial_default_equipment() -> void:
	if ResourceLoader.exists("res://data/equipment/primordial_blade.tres"):
		primary_weapon = load("res://data/equipment/primordial_blade.tres") as EquipmentItem
	if ResourceLoader.exists("res://data/equipment/heavy_obsidian_cleaver.tres"):
		secondary_weapon = load("res://data/equipment/heavy_obsidian_cleaver.tres") as EquipmentItem
	if ResourceLoader.exists("res://data/equipment/stalker_leather_armor.tres"):
		current_armor = load("res://data/equipment/stalker_leather_armor.tres") as EquipmentItem

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_active_weapon() -> EquipmentItem:
	return secondary_weapon if active_weapon_slot == 1 and secondary_weapon else primary_weapon

func switch_weapon() -> EquipmentItem:
	if secondary_weapon:
		active_weapon_slot = 1 if active_weapon_slot == 0 else 0
		print("[SaveManager] Switched active weapon to slot %d: %s" % [active_weapon_slot, get_active_weapon().display_name if get_active_weapon() else "None"])
	return get_active_weapon()

func save_game(checkpoint_pos: Vector2 = Vector2.ZERO, scene_path: String = "", cp_id: String = "") -> bool:
	var player = get_tree().get_first_node_in_group("player") as Player

	var save_dict: Dictionary = {
		"version": "0.4.0",
		"timestamp": Time.get_unix_time_from_system(),
		"reset_count": ResetManager.reset_count if ResetManager else 0,
		"unlocked_chapter": max_unlocked_chapter,
		"best_boss_rush_time": best_boss_rush_time,
		"selected_character": selected_character,
		"relics": unlocked_relics,
		"crafted_perks": crafted_relic_perks,
		"settings": {
			"master_volume": master_volume,
			"sfx_volume": sfx_volume,
			"bgm_volume": bgm_volume,
			"reduce_flashing": reduce_flashing,
			"screen_shake_enabled": screen_shake_enabled,
			"touch_controls_enabled": touch_controls_enabled
		},
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

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		printerr("[SaveManager] Failed to open save file for writing: %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	current_save_data = save_dict
	print("[SaveManager] Game state successfully saved to %s" % SAVE_PATH)
	game_saved.emit()
	return true

func load_game() -> bool:
	if not has_save():
		print("[SaveManager] No save file found.")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		printerr("[SaveManager] Corrupt save file.")
		return false

	current_save_data = parsed

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

	# 8. Restore settings
	if current_save_data.has("settings"):
		var st = current_save_data["settings"]
		master_volume = float(st.get("master_volume", master_volume))
		sfx_volume = float(st.get("sfx_volume", sfx_volume))
		bgm_volume = float(st.get("bgm_volume", bgm_volume))
		reduce_flashing = bool(st.get("reduce_flashing", reduce_flashing))
		screen_shake_enabled = bool(st.get("screen_shake_enabled", screen_shake_enabled))
		touch_controls_enabled = bool(st.get("touch_controls_enabled", touch_controls_enabled))
		apply_settings()

	print("[SaveManager] Game successfully loaded. Max Unlocked Chapter: %d" % max_unlocked_chapter)
	game_loaded.emit()
	return true

func set_selected_character(char_id: String) -> void:
	if char_id in ["hero", "elysia"]:
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
		_persist_boss_rush_time()
	return is_new_record

func get_best_boss_rush_time() -> float:
	return best_boss_rush_time

func _persist_boss_rush_time() -> void:
	var save_dict: Dictionary = {}
	if FileAccess.file_exists(SAVE_PATH):
		var read_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if read_file:
			var text = read_file.get_as_text()
			read_file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary:
				save_dict = parsed
	save_dict["best_boss_rush_time"] = best_boss_rush_time
	if not save_dict.has("unlocked_chapter"):
		save_dict["unlocked_chapter"] = max_unlocked_chapter
	var write_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if write_file:
		write_file.store_string(JSON.stringify(save_dict, "\t"))
		write_file.close()

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
	_load_initial_default_equipment()
	active_weapon_slot = 0
	if skill_tree:
		skill_tree.unlocked_skill_ids.clear()
		skill_tree.available_skill_points = 0
		skill_tree.skill_points_changed.emit(0)

func apply_to_player(player: Player) -> void:
	if not player or current_save_data.is_empty():
		return

	# Apply stats
	if current_save_data.has("player"):
		var p_data = current_save_data["player"]
		player.current_health = int(p_data.get("health", player.current_health))
		player.current_mana = float(p_data.get("mana", player.current_mana))
		player.heal_charges = int(p_data.get("heal_charges", player.heal_charges))
		player.health_changed.emit(player.current_health, player.tuning.max_health)
		player.mana_changed.emit(player.current_mana, float(player.tuning.max_mana))
		player.heal_charges_changed.emit(player.heal_charges, player.tuning.max_heal_charges)

	# Apply position if valid checkpoint
	if current_save_data.has("checkpoint"):
		var cp = current_save_data["checkpoint"]
		var px = float(cp.get("pos_x", 0.0))
		var py = float(cp.get("pos_y", 0.0))
		if px != 0.0 or py != 0.0:
			player.global_position = Vector2(px, py)

# ----------------------------------------------------
# Relic & Crafting Pipelines
# ----------------------------------------------------
func add_relic(relic_id: String) -> void:
	if not unlocked_relics.has(relic_id):
		unlocked_relics.append(relic_id)
		print("[SaveManager] Acquired Relic: %s" % relic_id)

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

# ----------------------------------------------------
# Challenge Return Routing
# ----------------------------------------------------
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

# ----------------------------------------------------
# Settings & Accessibility
# ----------------------------------------------------
func apply_settings() -> void:
	if SoundManager:
		SoundManager.set_sfx_volume(sfx_volume * master_volume)
		SoundManager.set_bgm_volume(bgm_volume * master_volume)

