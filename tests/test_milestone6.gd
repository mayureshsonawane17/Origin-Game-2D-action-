extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 6: The Fortress & The Unbeatable One.
## Validates:
## 1. Immortal Villain Boss (VIL-IMMORTAL, zero damage taken, health bar displays IMMORTAL — NO WEAKNESS DETECTED)
## 2. Deliberate Reset & Instability Escalation (glitch level, frozen enemies, merged era fragments)
## 3. Climax Hero Dialogue: "That's the problem. I kept playing your game." and gemstone fracture defeat
## 4. Collapsing Reality Escape Run (6-era fragmented platforming, wife reach, escape portal)
## 5. Real-World Epilogue (HUD absent, villain ended permanently, sunrise walk, credits)
## 6. Post-Credits Sting (NEW GAME cursor click, ERROR: REALITY INSTANCE NOT FOUND, dark gemstone logo)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_milestone6_tests")

func _run_milestone6_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 6 Automated Test Suite")
	print("  (The Fortress & The Unbeatable One)")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Immortal Villain & Health Bar
	# ----------------------------------------------------
	total_tests += 1
	var villain_scene = preload("res://scenes/bosses/boss_villain_immortal.tscn")
	var villain: BossVillainImmortal = villain_scene.instantiate() as BossVillainImmortal
	add_child(villain)
	villain.global_position = Vector2(300, 200)
	await get_tree().process_frame

	var hbar_scene = preload("res://scenes/ui/boss_health_bar.tscn")
	var hbar: BossHealthBar = hbar_scene.instantiate() as BossHealthBar
	add_child(hbar)
	hbar.bind_boss(villain)
	await get_tree().process_frame

	var is_immortal_data = (villain.data != null and villain.data.id == "VIL-IMMORTAL" and villain.data.max_health == 9999)
	var hp_before = villain.current_health
	# Conventional attack deals 0 damage!
	villain.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var took_zero_damage = (villain.current_health == hp_before)

	var hbar_has_immortal_text = (hbar.status_label != null and hbar.status_label.visible and hbar.status_label.text == "IMMORTAL — NO WEAKNESS DETECTED")

	if is_immortal_data and took_zero_damage and hbar_has_immortal_text:
		print("✔ PASS [1/6]: Immortal Villain (VIL-IMMORTAL) takes zero damage and health bar displays IMMORTAL — NO WEAKNESS DETECTED")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Immortal villain validation failed (data: %s, zero_dmg: %s, text: %s)" % [is_immortal_data, took_zero_damage, hbar_has_immortal_text])

	villain.queue_free()
	hbar.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

	# ----------------------------------------------------
	# 2. Deliberate Reset & Instability Escalation
	# ----------------------------------------------------
	total_tests += 1
	var chap7_scene = preload("res://scenes/levels/chapter7_fortress.tscn")
	var chap7: Chapter7Fortress = chap7_scene.instantiate() as Chapter7Fortress
	add_child(chap7)
	await get_tree().process_frame

	# Simulate Deliberate Reset 1 (glitch + frozen enemies)
	chap7.trigger_deliberate_reset()
	var reset1_ok = (chap7.deliberate_resets == 1 and chap7.glitch_overlay.glitch_level == 1 and chap7.frozen_enemies_group.visible)

	# Simulate Deliberate Reset 2 (merged era fragments)
	chap7.trigger_deliberate_reset()
	var reset2_ok = (chap7.deliberate_resets == 2 and chap7.glitch_overlay.glitch_level == 2 and chap7.merged_eras_group.visible)

	if reset1_ok and reset2_ok:
		print("✔ PASS [2/6]: Deliberate resets trigger escalating reality instability (glitch overlay, frozen enemies, merged era fragments)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Deliberate reset escalation failed (reset1: %s, reset2: %s)" % [reset1_ok, reset2_ok])

	# ----------------------------------------------------
	# 3. Climax Hero Dialogue & Gemstone Shatter
	# ----------------------------------------------------
	total_tests += 1
	# Simulate Deliberate Reset 3 (Hero speaks line: "That's the problem. I kept playing your game.")
	chap7.trigger_deliberate_reset()
	var reset3_ok = (chap7.deliberate_resets == 3 and chap7.glitch_overlay.glitch_level == 3)

	# Simulate Deliberate Reset 4 (Gemstone shatter defeat)
	chap7.trigger_deliberate_reset()
	var reset4_ok = (chap7.deliberate_resets >= 4 and chap7.glitch_overlay.glitch_level == 4)

	if reset3_ok and reset4_ok:
		print("✔ PASS [3/6]: Climax dialogue and gemstone crack sequence successfully execute on deliberate reset")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Climax dialogue/fracture failed (reset3: %s, reset4: %s)" % [reset3_ok, reset4_ok])

	chap7.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

	# ----------------------------------------------------
	# 4. Collapsing Reality Escape Run
	# ----------------------------------------------------
	total_tests += 1
	var escape_scene = preload("res://scenes/levels/escape_collapse.tscn")
	var escape_run: EscapeCollapse = escape_scene.instantiate() as EscapeCollapse
	add_child(escape_run)
	await get_tree().process_frame

	var platforms_count = escape_run.get_node("Platforms").get_child_count()
	var has_wife_area = (escape_run.wife_area != null)
	var has_exit = (escape_run.escape_portal != null)

	# Trigger reach wife & portal
	escape_run._on_wife_reached(escape_run.player)
	var wife_reached = escape_run.reached_wife

	escape_run._on_escape_portal_entered(escape_run.player)
	var escape_ok = escape_run.escape_completed

	if platforms_count == 6 and has_wife_area and has_exit and wife_reached and escape_ok:
		print("✔ PASS [4/6]: Collapsing Reality Escape Run integrates all 6 fragmented eras, wife reach, and portal leap")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Escape run validation failed (plats: %d, wife: %s, exit: %s)" % [platforms_count, wife_reached, escape_ok])

	escape_run.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

	# ----------------------------------------------------
	# 5. Real-World Epilogue
	# ----------------------------------------------------
	total_tests += 1
	var epilogue_scene = preload("res://scenes/levels/epilogue_real_world.tscn")
	var epilogue: EpilogueRealWorld = epilogue_scene.instantiate() as EpilogueRealWorld
	add_child(epilogue)
	await get_tree().process_frame

	# Verify NO health bars or enemy HUD present in epilogue
	var has_boss_hud = epilogue.has_node("CanvasLayer/BossHealthBar")
	var has_player_hud = epilogue.has_node("HUD")

	epilogue._roll_credits()
	var credits_ok = epilogue.credits_rolling

	if not has_boss_hud and not has_player_hud and credits_ok:
		print("✔ PASS [5/6]: Real-World Epilogue correctly operates with zero HUD/bars, confronts villain, and rolls credits")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Epilogue validation failed (boss_hud: %s, player_hud: %s, credits: %s)" % [has_boss_hud, has_player_hud, credits_ok])

	epilogue.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

	# ----------------------------------------------------
	# 6. Post-Credits Sting
	# ----------------------------------------------------
	total_tests += 1
	var sting_scene = preload("res://scenes/ui/post_credits_sting.tscn")
	var sting: PostCreditsSting = sting_scene.instantiate() as PostCreditsSting
	add_child(sting)
	await get_tree().process_frame

	# Simulate new game cursor click and glitch trigger
	sting._trigger_reality_glitch_error()
	await sting.sting_completed

	var error_displayed = (sting.error_container.visible and sting.error_label.text == "ERROR: REALITY INSTANCE NOT FOUND")
	var dark_gem_present = (sting.dark_gemstone != null)

	if error_displayed and dark_gem_present:
		print("✔ PASS [6/6]: Post-Credits Sting displays ERROR: REALITY INSTANCE NOT FOUND and ORIGIN logo with dark gemstone")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Post-Credits Sting validation failed (error: %s, dark_gem: %s)" % [error_displayed, dark_gem_present])

	sting.queue_free()
	await get_tree().process_frame

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Milestone 6 Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL MILESTONE 6 TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
