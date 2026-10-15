extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 3.
## Validates:
## 1. Skill trees across 6 branches (SkillTreeManager, prerequisites, stat aggregation)
## 2. Data-driven equipment resources & combat scaling (damage, defense, mobility)
## 3. Real-time weapon switching (slot toggle, active weapon query)
## 4. Checkpoint system (vital restoration & automatic state persistence)
## 5. Full Save / Quit / Load cycle ("Save, quit, load restores everything")
## 6. Inventory & Progression UI overlay (modal pause, card population, unlock flow)

func _ready() -> void:
	call_deferred("_run_milestone3_tests")

func _run_milestone3_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 3 Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# Ensure SaveManager is accessible
	if not SaveManager:
		printerr("FATAL: SaveManager autoload not found!")
		get_tree().quit(1)
		return

	# ----------------------------------------------------
	# 1. Skill Trees Across 6 Branches
	# ----------------------------------------------------
	total_tests += 1
	var st = SkillTreeManager.new()
	add_child(st)
	st.available_skill_points = 3
	st.unlocked_skill_ids.clear()

	var loaded_skills = st.all_skills.size()
	var branch_count = 0
	var branches_found: Dictionary = {}
	for sk_id in st.all_skills.keys():
		var sk = st.all_skills[sk_id] as SkillData
		branches_found[sk.branch] = true
	branch_count = branches_found.size()

	var unlock_success = st.unlock_skill("atk_finisher_mastery")
	var points_remaining = st.available_skill_points
	var mods = st.get_total_stat_modifiers()
	var bonus_dmg = mods.get("bonus_damage", 0)

	if loaded_skills >= 6 and branch_count == 6 and unlock_success and points_remaining == 2 and bonus_dmg == 1:
		print("✔ PASS [1/6]: SkillTreeManager handles 6 branches, unlocks skills, deducts SP (%d remaining), and aggregates stats (+%d damage)" % [points_remaining, bonus_dmg])
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: SkillTreeManager validation failed (loaded: %d, branches: %d, unlocked: %s, SP: %d, bonus_dmg: %d)" % [loaded_skills, branch_count, unlock_success, points_remaining, bonus_dmg])

	# ----------------------------------------------------
	# 2. Data-Driven Equipment System
	# ----------------------------------------------------
	total_tests += 1
	var blade = load("res://data/equipment/primordial_blade.tres") as EquipmentItem
	var cleaver = load("res://data/equipment/heavy_obsidian_cleaver.tres") as EquipmentItem
	var armor = load("res://data/equipment/titan_carapace_armor.tres") as EquipmentItem

	var equip_resources_valid = (
		blade != null and blade.base_damage == 1 and blade.mobility_multiplier == 1.0 and
		cleaver != null and cleaver.base_damage == 3 and cleaver.mobility_multiplier == 0.88 and
		armor != null and armor.defense_multiplier == 0.70 and armor.mobility_multiplier == 0.85
	)

	# Test player equipment stat scaling
	var player_scene = preload("res://scenes/characters/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child(player)
	player.global_position = Vector2(100, 100)
	await get_tree().process_frame

	SaveManager.primary_weapon = blade
	SaveManager.secondary_weapon = cleaver
	SaveManager.active_weapon_slot = 0 # Blade active
	SaveManager.current_armor = armor

	var mob_blade = player.get_mobility_multiplier() # 1.0 * 0.88 = 0.88 (+ any skill bonus)
	var def_titan = player.get_defense_multiplier() # 0.70

	# Test attack state damage calculation with cleaver equipped
	SaveManager.active_weapon_slot = 1 # Switch to cleaver (base dmg 3)
	player.state_machine.transition_to("attack", {"combo_index": 1})
	var hitbox_dmg = player.hitbox.damage # 1 (base attack1) + (3-1) (cleaver bonus) + (skill bonus if any)

	if equip_resources_valid and def_titan < 1.0 and hitbox_dmg >= 3:
		print("✔ PASS [2/6]: Data-Driven Equipment modifies attack damage (%d dmg with Cleaver) and defense (%.0f%% incoming)" % [hitbox_dmg, def_titan * 100.0])
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Equipment system validation failed (equip_valid: %s, def: %.2f, hitbox_dmg: %d)" % [equip_resources_valid, def_titan, hitbox_dmg])

	# ----------------------------------------------------
	# 3. Real-Time Weapon Switching
	# ----------------------------------------------------
	total_tests += 1
	SaveManager.active_weapon_slot = 0
	var wep_before = SaveManager.get_active_weapon()
	player.switch_weapon()
	var wep_after = SaveManager.get_active_weapon()
	var slot_after = SaveManager.active_weapon_slot

	if wep_before.id == "primordial_blade" and wep_after.id == "heavy_obsidian_cleaver" and slot_after == 1:
		print("✔ PASS [3/6]: Weapon switching cycles active slot (%s -> %s) seamlessly" % [wep_before.display_name, wep_after.display_name])
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Weapon switching failed (slot: %d, wep: %s)" % [slot_after, wep_after.display_name if wep_after else "null"])

	# ----------------------------------------------------
	# 4. Checkpoint System
	# ----------------------------------------------------
	total_tests += 1
	var checkpoint_scene = preload("res://scenes/levels/checkpoint.tscn")
	var cp: Checkpoint = checkpoint_scene.instantiate() as Checkpoint
	add_child(cp)
	cp.global_position = Vector2(250, 100)
	await get_tree().process_frame

	# Deplete player vitals
	player.current_health = 2
	player.heal_charges = 0
	# Trigger checkpoint interaction
	cp._on_body_entered(player)

	var vitals_restored = (player.current_health == player.tuning.max_health and player.heal_charges == player.tuning.max_heal_charges)
	var cp_activated = cp.is_activated
	var save_recorded_cp = (SaveManager.current_save_data.has("checkpoint") and SaveManager.current_save_data["checkpoint"]["id"] == cp.checkpoint_id)

	if vitals_restored and cp_activated and save_recorded_cp:
		print("✔ PASS [4/6]: Checkpoint activates, fully restores vitals (%d HP, %d Charges), and persists position" % [player.current_health, player.heal_charges])
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Checkpoint validation failed (restored: %s, active: %s, save_has_cp: %s)" % [vitals_restored, cp_activated, save_recorded_cp])

	# ----------------------------------------------------
	# 5. Full Save / Quit / Load Persistence Loop
	# ----------------------------------------------------
	total_tests += 1
	# Setup distinctive state
	if ResetManager:
		ResetManager.reset_count = 7
	SaveManager.skill_tree.available_skill_points = 1
	var initial_skills: Array[String] = ["atk_finisher_mastery", "def_fortified_parry"]
	SaveManager.skill_tree.unlocked_skill_ids = initial_skills
	SaveManager.active_weapon_slot = 1
	player.current_health = 4
	player.current_mana = 35.0
	player.heal_charges = 2
	var test_save_pos = Vector2(340, 180)

	var save_ok = SaveManager.save_game(test_save_pos, "res://scenes/levels/prehistoric_jungle.tscn", "cp_deep_jungle")

	# Simulate Quit: wipe memory state
	if ResetManager:
		ResetManager.reset_count = 0
	SaveManager.skill_tree.available_skill_points = 0
	SaveManager.skill_tree.unlocked_skill_ids.clear()
	SaveManager.active_weapon_slot = 0
	SaveManager.current_save_data = {}

	# Simulate Load: read from disk
	var load_ok = SaveManager.load_game()

	# Create a fresh player to receive loaded state
	var fresh_player: Player = player_scene.instantiate() as Player
	add_child(fresh_player)
	await get_tree().process_frame

	var loop_restored = (ResetManager.reset_count == 7) if ResetManager else true
	var skills_restored = (SaveManager.skill_tree.available_skill_points == 1 and SaveManager.skill_tree.unlocked_skill_ids.has("atk_finisher_mastery") and SaveManager.skill_tree.unlocked_skill_ids.has("def_fortified_parry"))
	var wep_slot_restored = (SaveManager.active_weapon_slot == 1)
	var vitals_restored_loaded = (fresh_player.current_health == 4 and abs(fresh_player.current_mana - 35.0) < 1.0 and fresh_player.heal_charges == 2)
	var pos_restored = (fresh_player.global_position == test_save_pos)

	if save_ok and load_ok and loop_restored and skills_restored and wep_slot_restored and vitals_restored_loaded and pos_restored:
		print("✔ PASS [5/6]: Save/Quit/Load restores entire world state 100%% (Loop 7, 2 Skills, Vitals 4HP/35MP, Pos %s)" % fresh_player.global_position)
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Save/Quit/Load failed (save: %s, load: %s, loop: %s, skills: %s, slot: %s, vitals: %s, pos: %s)" % [save_ok, load_ok, loop_restored, skills_restored, wep_slot_restored, vitals_restored_loaded, pos_restored])

	# ----------------------------------------------------
	# 6. Inventory & Progression Overlay UI
	# ----------------------------------------------------
	total_tests += 1
	var inv_scene = preload("res://scenes/ui/inventory_menu.tscn")
	var inv: InventoryMenu = inv_scene.instantiate() as InventoryMenu
	add_child(inv)
	await get_tree().process_frame

	inv.open()
	var is_open_paused = inv.is_open and get_tree().paused and inv.visible
	var cards_populated = inv.skills_grid.get_child_count() >= 6
	inv.close()
	var is_closed_unpaused = not inv.is_open and not get_tree().paused and not inv.visible

	if is_open_paused and cards_populated and is_closed_unpaused:
		print("✔ PASS [6/6]: Inventory & Progression UI modal toggles, pauses game tree, and displays %d skill cards" % inv.skills_grid.get_child_count())
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Inventory UI validation failed (open_paused: %s, cards: %d, closed_unpaused: %s)" % [is_open_paused, inv.skills_grid.get_child_count(), is_closed_unpaused])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Milestone 3 Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL MILESTONE 3 TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
