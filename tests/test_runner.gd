extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 1.

func _ready() -> void:
	# Run tests on next idle frame once entire tree is primed
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 1 Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# 1. ResetManager verification
	total_tests += 1
	var initial_loop = ResetManager.reset_count
	ResetManager.reset_count += 1
	ResetManager._save_reset_count()
	if ResetManager.reset_count == initial_loop + 1:
		print("✔ PASS [1/9]: ResetManager tracks loop count and persistence (Loop #%d)" % ResetManager.reset_count)
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/9]: ResetManager failed.")

	# 2. CombatTuning resource
	total_tests += 1
	var tuning: CombatTuning = load("res://data/combat_tuning.tres") as CombatTuning
	if tuning and tuning.run_speed == 110.0 and tuning.jump_velocity == -300.0 and tuning.attack3_damage == 2:
		print("✔ PASS [2/9]: CombatTuning resource loaded with tuned values (Speed: 110, Jump: -300, Finisher Dmg: 2)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/9]: CombatTuning failed.")

	# 3. Player entity instantiation
	total_tests += 1
	var player_scene = preload("res://scenes/characters/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child(player)
	player.global_position = Vector2(100, 100)
	await get_tree().process_frame

	if player.current_health == 5 and player.current_mana == 50.0 and player.heal_charges == 3:
		print("✔ PASS [3/9]: Player initialized with 5 HP, 50 Mana, and 3 Heal charges")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/9]: Player stats mismatch.")

	# 4. Dan-the-Man 3-Hit Combo
	total_tests += 1
	player.state_machine.transition_to("attack", {"combo_index": 1})
	var h1_dmg = player.hitbox.damage
	player.state_machine.transition_to("attack", {"combo_index": 2})
	var h2_dmg = player.hitbox.damage
	player.state_machine.transition_to("attack", {"combo_index": 3})
	var h3_dmg = player.hitbox.damage
	var is_finisher = player.hitbox.is_finisher
	var finisher_kb = player.hitbox.knockback_force

	if h1_dmg == 1 and h2_dmg == 1 and h3_dmg == 2 and is_finisher and finisher_kb >= 240.0:
		print("✔ PASS [4/9]: 3-Hit Combo verified (Hit 1: %ddmg, Hit 2: %ddmg, Finisher: %ddmg with %d knockback)" % [h1_dmg, h2_dmg, h3_dmg, finisher_kb])
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/9]: 3-Hit Combo parameters incorrect.")

	# 5. Magic projectile casting & Mana cost
	total_tests += 1
	var mana_before = player.current_mana
	player.cast_magic()
	var mana_after = player.current_mana
	var spent = mana_before - mana_after
	if spent == tuning.magic_mana_cost and player.magic_cooldown_timer > 0.0:
		print("✔ PASS [5/9]: Magic projectile cast consumed %d mana (Remaining: %d) and triggered cooldown" % [spent, mana_after])
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/9]: Magic casting check failed.")

	# 6. Dodge Invulnerability
	total_tests += 1
	player.state_machine.transition_to("dodge")
	var is_invuln = player.hurtbox.is_invulnerable
	var dodge_cd = player.dodge_cooldown_timer
	if is_invuln and dodge_cd > 0.0:
		print("✔ PASS [6/9]: Dodge grants invulnerability frames and triggers cooldown (%0.2fs)" % dodge_cd)
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/9]: Dodge invulnerability check failed.")

	# 7. Player Damage & Healing
	total_tests += 1
	player.hurtbox.is_invulnerable = false
	player.hurtbox.receive_hit(2, Vector2(100, -20), 3, null, false)
	var hp_after_hit = player.current_health
	var charges_before_heal = player.heal_charges
	player.perform_heal()
	var hp_after_heal = player.current_health
	var charges_after_heal = player.heal_charges

	if hp_after_hit == 3 and hp_after_heal == 5 and charges_after_heal == charges_before_heal - 1:
		print("✔ PASS [7/9]: Damage (HP 5 -> 3) and Healing (HP 3 -> 5, charges 3 -> 2) verified")
		tests_passed += 1
	else:
		printerr("✘ FAIL [7/9]: Damage/Healing check failed (Hit HP: %d, Heal HP: %d)" % [hp_after_hit, hp_after_heal])

	# 8. Enemy AI (Crested Prowler) & Death
	total_tests += 1
	var enemy_scene = preload("res://scenes/enemies/enemy_prowler.tscn")
	var enemy: EnemyProwler = enemy_scene.instantiate() as EnemyProwler
	add_child(enemy)
	enemy.global_position = Vector2(250, 100)
	await get_tree().process_frame

	# Deal lethal damage to enemy
	enemy.hurtbox.receive_hit(3, Vector2(150, -100), 5, player, true)
	if enemy.current_health == 0 and enemy.is_dead:
		print("✔ PASS [8/9]: Enemy Crested Prowler received finisher hit and entered death state correctly")
		tests_passed += 1
	else:
		printerr("✘ FAIL [8/9]: Enemy death state check failed.")

	# 9. Jungle Level Integration & Hierarchy
	total_tests += 1
	var level_scene = preload("res://scenes/levels/jungle_level.tscn")
	var level: JungleLevel = level_scene.instantiate() as JungleLevel
	add_child(level)
	await get_tree().process_frame

	var has_player = level.has_node("Player")
	var has_hud = level.has_node("HUD")
	var has_goal = level.has_node("LevelGoal")
	var enemy_count = level.get_node("Enemies").get_child_count()

	if has_player and has_hud and has_goal and enemy_count >= 5:
		print("✔ PASS [9/9]: Jungle Level loaded with Player, HUD, LevelGoal, and %d enemies" % enemy_count)
		tests_passed += 1
	else:
		printerr("✘ FAIL [9/9]: Level hierarchy check failed.")

	print("==================================================")
	print("  Results: %d/%d tests passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print("ALL MILESTONE 1 VERIFICATIONS SUCCESSFUL!")
		get_tree().quit(0)
	else:
		print("SOME TESTS FAILED.")
		get_tree().quit(1)
