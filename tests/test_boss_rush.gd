extends Node2D

## Automated Headless Integration Test Suite for Boss Rush / Time-Attack Mode.
## Validates:
## 1. Boss Rush scene initialization (Player, arena platforms, boundaries, title card, health bar, speedrun HUD)
## 2. Complete 13-boss encounter queue spanning 6 eras + The Fortress
## 3. SaveManager speedrun timer persistence and time formatting
## 4. Boss defeat, vital restoration, intermission restock, and sequential progression
## 5. Dynamic era background and BGM audio switching across eras
## 6. 13th boss (The Architect) Boss Rush mode fracture mechanics and gauntlet victory rank

func _ready() -> void:
	call_deferred("_run_boss_rush_tests")

func _run_boss_rush_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Boss Rush / Time-Attack Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Scene Initialization & Components
	# ----------------------------------------------------
	total_tests += 1
	var rush_scene = preload("res://scenes/levels/boss_rush.tscn")
	var rush = rush_scene.instantiate()
	add_child(rush)
	await get_tree().process_frame

	var nodes_valid = (
		rush.player != null and
		rush.background != null and
		rush.title_card != null and
		rush.health_bar != null and
		rush.time_label != null and
		rush.progress_label != null and
		rush.intermission_panel != null and
		rush.victory_modal != null and
		rush.defeat_modal != null
	)

	var platforms_valid = rush.get_node_or_null("Platforms/Ground") != null and rush.get_node_or_null("Boundaries/LeftWall") != null

	if nodes_valid and platforms_valid:
		print("✔ PASS [1/6]: Boss Rush arena cleanly initialized with Player, boundaries, platforms, title card, and speedrun HUD")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Boss Rush arena initialization failed (nodes: %s, platforms: %s)" % [nodes_valid, platforms_valid])

	# ----------------------------------------------------
	# 2. Encounter Queue Validation (All 13 Bosses)
	# ----------------------------------------------------
	total_tests += 1
	var expected_boss_count = 13
	var actual_count = rush.BOSS_ENCOUNTERS.size()
	var all_scenes_exist: bool = true
	var expected_ids: Array[String] = [
		"PRE-01", "PRE-ERA",
		"MED-01", "MED-ERA",
		"HIST-01", "HIST-ERA",
		"IND-01", "IND-ERA",
		"MOD-01", "MOD-ERA",
		"FUT-01", "FUT-ERA",
		"VIL-IMMORTAL"
	]
	var ids_matched: bool = true

	for i in range(actual_count):
		var enc = rush.BOSS_ENCOUNTERS[i]
		if not ResourceLoader.exists(enc["scene_path"]):
			all_scenes_exist = false
			printerr("Missing boss scene: %s" % enc["scene_path"])
		if i < expected_ids.size() and enc["id"] != expected_ids[i]:
			ids_matched = false
			printerr("Encounter ID mismatch at %d: got %s, expected %s" % [i, enc["id"], expected_ids[i]])

	if actual_count == expected_boss_count and all_scenes_exist and ids_matched:
		print("✔ PASS [2/6]: Boss encounter queue verified: 13 sequential bosses across all 6 Eras + Fortress finale")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Boss encounter queue failed (count: %d/%d, scenes: %s, ids: %s)" % [actual_count, expected_boss_count, all_scenes_exist, ids_matched])

	# ----------------------------------------------------
	# 3. SaveManager Speedrun Pipeline & Formatting
	# ----------------------------------------------------
	total_tests += 1
	var t_fmt_neg = SaveManager.format_time(-1.0) == "--:--.--"
	var t_fmt_zero = SaveManager.format_time(0.0) == "00:00.00"
	var t_fmt_sample = SaveManager.format_time(324.56) == "05:24.56"

	# Test recording record
	SaveManager.best_boss_rush_time = -1.0 # Reset baseline
	var first_record = SaveManager.record_boss_rush_time(400.0) # 6m40s
	var recorded_ok = (first_record == true and is_equal_approx(SaveManager.get_best_boss_rush_time(), 400.0))

	# Faster time sets new record
	var faster_record = SaveManager.record_boss_rush_time(350.0)
	var faster_ok = (faster_record == true and is_equal_approx(SaveManager.get_best_boss_rush_time(), 350.0))

	# Slower time does NOT overwrite
	var slower_record = SaveManager.record_boss_rush_time(420.0)
	var slower_rejected = (slower_record == false and is_equal_approx(SaveManager.get_best_boss_rush_time(), 350.0))

	if t_fmt_neg and t_fmt_zero and t_fmt_sample and recorded_ok and faster_ok and slower_rejected:
		print("✔ PASS [3/6]: SaveManager speedrun pipeline correctly formats times, records bests, and rejects slower runs")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: SaveManager speedrun pipeline failed (fmt: %s/%s/%s, rec: %s/%s/%s)" % [
			t_fmt_neg, t_fmt_zero, t_fmt_sample, recorded_ok, faster_ok, slower_rejected
		])

	# ----------------------------------------------------
	# 4. Boss Defeat, Healing Restock & Gauntlet Progression
	# ----------------------------------------------------
	total_tests += 1
	# Simulate player taking damage prior to boss defeat
	rush.player.current_health = 2
	rush.player.heal_charges = 1
	rush.player.current_mana = 10.0

	# Simulate current boss defeat
	rush._on_boss_defeated()

	var healed_ok = (rush.player.current_health == 4 and rush.player.heal_charges == 2 and is_equal_approx(rush.player.current_mana, float(rush.player.tuning.max_mana)))
	var intermission_shown = rush.intermission_panel.visible == true and rush.is_intermission == true
	var count_incremented = rush.bosses_defeated == 1

	# Advance to next encounter
	rush._proceed_to_next()
	var advanced_ok = (rush.current_encounter_index == 1 and rush.progress_label.text.contains("2 / 13"))

	if healed_ok and intermission_shown and count_incremented and advanced_ok:
		print("✔ PASS [4/6]: Boss defeat restores player vitals (+2 HP, +1 Charge, Full Mana), triggers intermission, and advances gauntlet")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Boss defeat and progression failed (healed: %s, inter: %s, cnt: %s, adv: %s)" % [
			healed_ok, intermission_shown, count_incremented, advanced_ok
		])

	# ----------------------------------------------------
	# 5. Dynamic Background Era Theme & BGM Switching
	# ----------------------------------------------------
	total_tests += 1
	var bg = rush.background
	bg.set_era_theme("Medieval")
	var medieval_ok = (bg.current_era == "Medieval" and bg.accent_color == Color(0.9, 0.4, 0.2, 0.3))

	bg.set_era_theme("Futuristic")
	var futuristic_ok = (bg.current_era == "Futuristic" and bg.accent_color == Color(0.4, 0.8, 1.0, 0.4))

	bg.set_era_theme("The Fortress")
	var fortress_ok = (bg.current_era == "The Fortress" and bg.accent_color == Color(0.95, 0.2, 0.85, 0.45))

	var bgm_playing = SoundManager != null and SoundManager.is_bgm_playing()

	if medieval_ok and futuristic_ok and fortress_ok and bgm_playing:
		print("✔ PASS [5/6]: Dynamic era background smoothly re-themes silhouettes and palette while SoundManager streams era BGM")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Dynamic background or BGM switching failed (med: %s, fut: %s, fort: %s, bgm: %s)" % [
			medieval_ok, futuristic_ok, fortress_ok, bgm_playing
		])

	# ----------------------------------------------------
	# 6. Final Boss (The Architect) Fracture & Gauntlet Victory
	# ----------------------------------------------------
	total_tests += 1
	# Clean up previous boss
	if rush.active_boss and is_instance_valid(rush.active_boss):
		rush.active_boss.queue_free()
		rush.active_boss = null
	await get_tree().process_frame

	# Start final boss encounter (Index 12)
	rush._start_encounter(12)
	await get_tree().process_frame

	var villain = rush.active_boss as BossVillainImmortal
	var villain_valid = villain != null and villain.boss_rush_mode == true and villain.current_health == 16

	# Land attacks on the villain in Boss Rush mode
	var hp_before = villain.current_health
	villain.hurtbox.receive_hit(4, Vector2(20, 0), 4, rush.player, false)
	var took_damage = villain.current_health < hp_before

	# Complete gauntlet victory
	rush.elapsed_time = 310.0 # 5m10s -> S Rank (<360s)
	rush._on_gauntlet_victory()

	var victory_shown = rush.victory_modal.visible == true
	var rank_is_s = rush.victory_rank_label.text.begins_with("S RANK")
	var time_displayed = rush.victory_time_label.text.contains("05:10.00")

	if villain_valid and took_damage and victory_shown and rank_is_s and time_displayed:
		print("✔ PASS [6/6]: The Architect enters fractured Boss Rush mode, receives combat damage, and triggers S-Rank victory modal")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Boss Rush finale validation failed (vil: %s, dmg: %s, vic: %s, rank: %s, time: %s)" % [
			villain_valid, took_damage, victory_shown, rank_is_s, time_displayed
		])

	# Cleanup
	rush.queue_free()
	await get_tree().process_frame

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Boss Rush Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL BOSS RUSH TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME BOSS RUSH TESTS FAILED <<<")
		get_tree().quit(1)
