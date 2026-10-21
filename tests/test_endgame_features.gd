extends Node2D

## Automated Integration Test Suite for ORIGIN Endgame & Accessibility Features:
## 1. Challenge Portals & Campaign Return Routing
## 2. Boss Relics & Passive Combat Perk Buffs
## 3. Arcade Combo Counter & Momentum Mana Refund
## 4. Settings & Accessibility Engine (Audio, Shake, Photosensitivity)
## 5. Mobile Virtual Touch Controls Event Pipeline
## 6. Secondary Playable Character (Elysia the Chrono-Wanderer)
## 7. Relic Forge UI & Boss Roster Synchronization

func _ready() -> void:
	call_deferred("_run_all_endgame_tests")

func _run_all_endgame_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Endgame & Accessibility Feature Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# Test 1: Challenge Portal & Return Routing
	# ----------------------------------------------------
	total_tests += 1
	var portal_scene = preload("res://scenes/levels/challenge_portal.tscn")
	var portal = portal_scene.instantiate()
	add_child(portal)
	portal.global_position = Vector2(580, 230)
	portal.target_boss_type = "mud_golem"
	portal.portal_era = "Prehistoric"
	portal.required_relic_id = "clay_core"

	SaveManager.set_challenge_return("res://scenes/levels/chapter1_prehistoric.tscn", Vector2(580, 230))
	var has_return = SaveManager.has_challenge_return()
	var ret_info = SaveManager.get_challenge_return()

	if has_return and ret_info.get("scene_path") == "res://scenes/levels/chapter1_prehistoric.tscn" and ret_info.get("pos_x") == 580.0:
		print("✔ PASS [1/7]: Challenge Portal instantiated and Campaign return routing recorded (Pos: 580, 230)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/7]: Challenge Portal or return routing mismatch.")
	portal.queue_free()

	# ----------------------------------------------------
	# Test 2: Boss Relic Crafting & Stat Perk Buffs
	# ----------------------------------------------------
	total_tests += 1
	SaveManager.unlocked_relics.clear()
	SaveManager.crafted_relic_perks.clear()

	SaveManager.add_relic("clay_core")
	SaveManager.add_relic("spirit_ribbon")
	SaveManager.add_relic("brass_chassis")

	var crafted_clay = SaveManager.craft_relic_perk("clay_core")
	var crafted_ribbon = SaveManager.craft_relic_perk("spirit_ribbon")
	var crafted_brass = SaveManager.craft_relic_perk("brass_chassis")

	var player_scene = preload("res://scenes/characters/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	player.character_id = "hero"
	add_child(player)
	await get_tree().process_frame

	# clay_core grants +1 HP (5 -> 6)
	var hp_with_relic = player.current_health
	# spirit_ribbon discounts mana cost by 5 (15 -> 10)
	var mana_before = player.current_mana
	player.cast_magic()
	var mana_spent = mana_before - player.current_mana

	if crafted_clay and crafted_ribbon and crafted_brass and hp_with_relic == 6 and mana_spent == 10.0:
		print("✔ PASS [2/7]: Relic Perk Crafting verified: Clay Core (+1 Max HP = %d), Spirit Ribbon (Mana cost = %d)" % [hp_with_relic, int(mana_spent)])
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/7]: Relic perks failed (HP: %d, Mana spent: %0.1f)" % [hp_with_relic, mana_spent])

	# ----------------------------------------------------
	# Test 3: Arcade Combo Counter & Momentum Refund
	# ----------------------------------------------------
	total_tests += 1
	var combo_scene = preload("res://scenes/ui/combo_counter.tscn")
	var combo: ComboCounter = combo_scene.instantiate() as ComboCounter
	add_child(combo)
	combo.bind_player(player)

	# Drain some mana from player so we can test refund
	player.current_mana = 20.0

	# Register hits
	for i in range(4):
		combo.register_hit(1, false)
	var c4_tier = combo.current_tier

	combo.register_hit(1, false) # 5 hits -> GOOD!
	var c5_tier = combo.current_tier
	var c5_mult = combo.current_multiplier

	for i in range(5):
		combo.register_hit(1, false) # 10 hits -> GREAT!
	var c10_tier = combo.current_tier
	var c10_mult = combo.current_multiplier
	var mp_after_10 = player.current_mana

	for i in range(10):
		combo.register_hit(1, false) # 20 hits -> EXCELLENT!
	var c20_tier = combo.current_tier
	var c20_mult = combo.current_multiplier

	for i in range(15):
		combo.register_hit(1, false) # 35 hits -> UNSTOPPABLE!
	var c35_tier = combo.current_tier
	var c35_mult = combo.current_multiplier

	# Test timer decay
	combo._process(3.0)
	var decayed_combo = combo.current_combo

	if c4_tier == "COMBO" and c5_tier == "GOOD!" and c5_mult == 1.25 and c10_tier == "GREAT!" and c10_mult == 1.5 and mp_after_10 > 20.0 and c20_tier == "EXCELLENT!" and c35_tier == "UNSTOPPABLE!" and c35_mult == 3.0 and decayed_combo == 0:
		print("✔ PASS [3/7]: Arcade Combo Counter verified across 5 tiers (GOOD, GREAT, EXCELLENT, UNSTOPPABLE) with momentum MP refund and timer decay")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/7]: Combo counter validation mismatch.")
	combo.queue_free()

	# ----------------------------------------------------
	# Test 4: Options & Accessibility Engine
	# ----------------------------------------------------
	total_tests += 1
	var opt_scene = preload("res://scenes/ui/options_menu.tscn")
	var opt_menu = opt_scene.instantiate() as OptionsMenu
	add_child(opt_menu)
	await get_tree().process_frame

	opt_menu.master_slider.value = 75.0
	opt_menu.sfx_slider.value = 50.0
	opt_menu.bgm_slider.value = 60.0
	opt_menu.flash_checkbox.button_pressed = true
	opt_menu.shake_checkbox.button_pressed = false
	opt_menu.touch_checkbox.button_pressed = true

	opt_menu._on_master_slider_changed(75.0)
	opt_menu._on_sfx_slider_changed(50.0)
	opt_menu._on_bgm_slider_changed(60.0)
	opt_menu._on_flash_toggled(true)
	opt_menu._on_shake_toggled(false)
	opt_menu._on_touch_toggled(true)

	var s_master = SaveManager.master_volume
	var s_sfx = SaveManager.sfx_volume
	var s_bgm = SaveManager.bgm_volume
	var s_flash = SaveManager.reduce_flashing
	var s_shake = SaveManager.screen_shake_enabled
	var s_touch = SaveManager.touch_controls_enabled

	if is_equal_approx(s_master, 0.75) and is_equal_approx(s_sfx, 0.50) and is_equal_approx(s_bgm, 0.60) and s_flash == true and s_shake == false and s_touch == true:
		print("✔ PASS [4/7]: Settings & Accessibility verified: Master 75%, SFX 50%, BGM 60%, Flash Muted, Shake Disabled, Touch Active")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/7]: Options persistence mismatch.")
	opt_menu.queue_free()

	# ----------------------------------------------------
	# Test 5: Virtual Mobile Touch Controls Dispatch
	# ----------------------------------------------------
	total_tests += 1
	var touch_scene = preload("res://scenes/ui/touch_controls.tscn")
	var touch = touch_scene.instantiate() as TouchControls
	add_child(touch)
	await get_tree().process_frame

	touch.btn_jump.emit_signal("button_down")
	var jump_pressed = Input.is_action_pressed("jump")
	touch.btn_jump.emit_signal("button_up")
	var jump_released = not Input.is_action_pressed("jump")

	touch.btn_attack.emit_signal("button_down")
	var atk_pressed = Input.is_action_pressed("attack")
	touch.btn_attack.emit_signal("button_up")
	var atk_released = not Input.is_action_pressed("attack")

	if jump_pressed and jump_released and atk_pressed and atk_released:
		print("✔ PASS [5/7]: Virtual Mobile Touch Controls successfully emulate native Godot Input actions (Jump, Attack)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/7]: Touch control input emulation failed.")
	touch.queue_free()

	# ----------------------------------------------------
	# Test 6: Secondary Playable Character (Elysia the Chrono-Wanderer)
	# ----------------------------------------------------
	total_tests += 1
	SaveManager.set_selected_character("elysia")

	var chrono_scene = preload("res://scenes/characters/chrono_wanderer.tscn")
	var elysia: Player = chrono_scene.instantiate() as Player
	add_child(elysia)
	await get_tree().process_frame

	var elysia_speed = elysia.tuning.run_speed
	var elysia_jump = elysia.tuning.jump_velocity
	var elysia_max_mana = elysia.tuning.max_mana
	var elysia_dodge_cd = elysia.tuning.dodge_cooldown
	var visuals = elysia.visual_root.get_node_or_null("PlayerVisuals")
	var visual_char_id = visuals.character_id if visuals else ""

	if elysia.character_id == "elysia" and elysia_speed == 125.0 and elysia_jump == -315.0 and elysia_max_mana == 60 and elysia_dodge_cd == 0.45 and visual_char_id == "elysia":
		print("✔ PASS [6/7]: Elysia the Chrono-Wanderer initialized with agile kit (Speed: %0.0f, Jump: %0.0f, Mana: %d, Blink CD: %0.2fs, Chronoblades visual)" % [elysia_speed, elysia_jump, elysia_max_mana, elysia_dodge_cd])
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/7]: Elysia character stats mismatch (Speed: %f, Jump: %f, Mana: %d, Char: %s)" % [elysia_speed, elysia_jump, elysia_max_mana, visual_char_id])
	elysia.queue_free()
	player.queue_free()

	# ----------------------------------------------------
	# Test 7: Relic Forge Menu UI & Boss Synchronization
	# ----------------------------------------------------
	total_tests += 1
	var relic_menu_scene = preload("res://scenes/ui/relic_menu.tscn")
	var relic_menu: RelicMenu = relic_menu_scene.instantiate() as RelicMenu
	add_child(relic_menu)
	await get_tree().process_frame

	var card_count = relic_menu.relic_list_container.get_child_count()
	var has_all_6 = card_count == 6

	if has_all_6:
		print("✔ PASS [7/7]: Relic Forge Menu accurately synchronizes all 6 Era Regular Boss Relics")
		tests_passed += 1
	else:
		printerr("✘ FAIL [7/7]: Relic menu card count mismatch (Expected 6, found %d)" % card_count)
	relic_menu.queue_free()

	# Restore default hero character
	SaveManager.set_selected_character("hero")

	print("==================================================")
	print("  Results: %d/%d endgame feature tests passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL ENDGAME & ACCESSIBILITY TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		print("✘ SOME ENDGAME TESTS FAILED.")
		get_tree().quit(1)
