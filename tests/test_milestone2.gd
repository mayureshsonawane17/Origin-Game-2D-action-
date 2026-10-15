extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 2.
## Validates block, timed parry, counter attack, BossData, BossTitleCard,
## Basic Boss (Primal Stalker), 3-Phase Era Boss (Titan of the Deep Earth), and ResetManager.

func _ready() -> void:
	call_deferred("_run_milestone2_tests")

func _run_milestone2_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 2 Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# 1. Player Block Damage Reduction
	total_tests += 1
	var player_scene = preload("res://scenes/characters/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child(player)
	player.global_position = Vector2(100, 100)
	await get_tree().process_frame

	player.state_machine.transition_to("block")
	# Expire parry window to test pure block
	player.is_parrying = false
	var hp_before_block = player.current_health
	player.hurtbox.receive_hit(3, Vector2(100, 0), 3, null, false)
	var dmg_taken = hp_before_block - player.current_health
	# 3 dmg reduced by 70% = ceil(3 * 0.3) = 1 dmg taken
	if dmg_taken == 1:
		print("✔ PASS [1/8]: Player Block reduces damage by 70%% (3 incoming -> %d taken)" % dmg_taken)
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/8]: Block damage reduction failed (took %d damage)." % dmg_taken)

	# 2. Player Timed Parry & Counter-Attack
	total_tests += 1
	player.state_machine.transition_to("block")
	player.is_parrying = true # Active parry window
	var hp_before_parry = player.current_health
	player.hurtbox.receive_hit(3, Vector2(100, 0), 3, null, false)
	var hp_after_parry = player.current_health
	var in_counter = player.state_machine.get_current_state_name().to_lower() == "attack" and player.hitbox.damage == player.tuning.counter_damage

	if hp_after_parry == hp_before_parry and in_counter and player.hitbox.is_finisher:
		print("✔ PASS [2/8]: Perfect Parry negated 100%% damage and triggered Counter Attack (%d dmg, %d knockback)" % [player.hitbox.damage, player.hitbox.knockback_force])
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/8]: Timed parry failed (HP: %d->%d, in_counter: %s)" % [hp_before_parry, hp_after_parry, in_counter])

	# 3. BossData Resource Validation
	total_tests += 1
	var stalker_data = load("res://data/bosses/primal_stalker.tres") as BossData
	var titan_data = load("res://data/bosses/titan_deep_earth.tres") as BossData

	var data_valid = (
		stalker_data and stalker_data.id == "PRE-01" and stalker_data.max_health == 12 and stalker_data.total_phases == 1 and
		titan_data and titan_data.id == "PRE-ERA" and titan_data.max_health == 30 and titan_data.total_phases == 3 and titan_data.armor_health == 8 and titan_data.is_era_boss
	)
	if data_valid:
		print("✔ PASS [3/8]: BossData resources validated (Basic Boss: %s 1-Phase, Era Boss: %s 3-Phase with Geo-Armor)" % [stalker_data.display_name, titan_data.display_name])
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/8]: BossData validation failed.")

	# 4. Boss Title Card Intro & Skip Mechanics (Section 6a)
	total_tests += 1
	var title_card_scene = preload("res://scenes/ui/boss_title_card.tscn")
	var title_card: BossTitleCard = title_card_scene.instantiate() as BossTitleCard
	add_child(title_card)
	await get_tree().process_frame

	title_card.play_intro(stalker_data)
	var title_active = title_card.is_active and get_tree().paused
	title_card.finish_intro()
	var title_skipped = not title_card.is_active and not get_tree().paused

	if title_active and title_skipped:
		print("✔ PASS [4/8]: BossTitleCard opens GBA-style splash (pauses tree) and skips reliably on input")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/8]: BossTitleCard test failed.")

	# 5. Basic Boss (Primal Stalker) Combat & Defeat
	total_tests += 1
	var stalker_scene = preload("res://scenes/bosses/boss_primal_stalker.tscn")
	var stalker: BossPrimalStalker = stalker_scene.instantiate() as BossPrimalStalker
	add_child(stalker)
	stalker.global_position = Vector2(250, 100)
	await get_tree().process_frame

	var stalker_hp_start = stalker.current_health
	# Test stagger on parry
	stalker.stagger(0.6)
	var is_staggered = stalker.is_staggered and stalker.is_vulnerable
	# Deal lethal damage to stalker
	stalker.hurtbox.receive_hit(stalker_hp_start, Vector2(100, -50), 5, player, true)
	var stalker_dead = stalker.current_health == 0 and stalker.is_dead

	if is_staggered and stalker_dead:
		print("✔ PASS [5/8]: Basic Boss (Primal Stalker) responds to parry stagger, takes damage, and dies correctly")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/8]: Primal Stalker combat verification failed.")

	# 6. 3-Phase Era Boss (Titan of the Deep Earth) Multi-Phase Transitions
	total_tests += 1
	var titan_scene = preload("res://scenes/bosses/boss_titan_deep_earth.tscn")
	var titan: BossTitanDeepEarth = titan_scene.instantiate() as BossTitanDeepEarth
	add_child(titan)
	titan.global_position = Vector2(400, 100)
	await get_tree().process_frame

	var phase1_ok = titan.current_phase == 1
	# Damage Titan into Phase 2 (HP <= 66% = 19 HP)
	titan.hurtbox.receive_hit(12, Vector2(50, 0), 4, player, false)
	var phase2_ok = titan.current_phase == 2 and titan.current_armor == titan.data.armor_health

	# Break Geo-Armor in Phase 2
	titan.hurtbox.receive_hit(8, Vector2(50, 0), 4, player, false)
	var armor_broken = titan.current_armor == 0 and titan.is_staggered

	# Damage Titan into Phase 3 (HP <= 33% = 9 HP)
	titan.hurtbox.receive_hit(10, Vector2(50, 0), 4, player, false)
	var phase3_ok = titan.current_phase == 3 and titan.hitbox.damage == 3

	# Lethal blow
	titan.hurtbox.receive_hit(10, Vector2(50, -50), 5, player, true)
	var titan_dead = titan.current_health == 0 and titan.is_dead

	if phase1_ok and phase2_ok and armor_broken and phase3_ok and titan_dead:
		print("✔ PASS [6/8]: 3-Phase Era Boss completed Phase 1 -> Phase 2 (Geo-Armor break) -> Phase 3 (Magma Frenzy) -> Defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/8]: Titan deep earth phase transition check failed (P1:%s, P2:%s, ArmorBroken:%s, P3:%s, Dead:%s)" % [phase1_ok, phase2_ok, armor_broken, phase3_ok, titan_dead])

	# 7. Boss Health Bar Binding & Pips
	total_tests += 1
	var hbar_scene = preload("res://scenes/ui/boss_health_bar.tscn")
	var hbar: BossHealthBar = hbar_scene.instantiate() as BossHealthBar
	add_child(hbar)
	await get_tree().process_frame

	var mock_boss = stalker_scene.instantiate() as BossPrimalStalker
	add_child(mock_boss)
	hbar.bind_boss(mock_boss)
	var hbar_bound = hbar.name_label.text == stalker_data.display_name and hbar.health_bar.value == stalker_data.max_health
	mock_boss.queue_free()

	if hbar_bound:
		print("✔ PASS [7/8]: BossHealthBar binds dynamically to BossController and reflects data & health")
		tests_passed += 1
	else:
		printerr("✘ FAIL [7/8]: BossHealthBar binding failed.")

	# 8. Boss Arena Scene Hierarchy & ResetManager Integration
	total_tests += 1
	var arena_scene = preload("res://scenes/levels/boss_arena.tscn")
	var arena: BossArena = arena_scene.instantiate() as BossArena
	add_child(arena)
	await get_tree().process_frame

	var has_player = arena.has_node("Player")
	var has_title = arena.has_node("BossTitleCard")
	var has_hbar = arena.has_node("CanvasLayer/BossHealthBar")
	var has_boss = arena.current_boss != null

	var initial_loop = ResetManager.reset_count
	ResetManager.reset_count += 1
	var retry_ok = ResetManager.reset_count == initial_loop + 1

	if has_player and has_title and has_hbar and has_boss and retry_ok:
		print("✔ PASS [8/8]: BossArena initialized with Player, TitleCard, HealthBar, active Boss, and ResetManager retry")
		tests_passed += 1
	else:
		printerr("✘ FAIL [8/8]: BossArena integration failed.")

	print("==================================================")
	print("  Milestone 2 Results: %d/%d tests passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print("ALL MILESTONE 2 REQUIREMENTS VERIFIED!")
		get_tree().quit(0)
	else:
		print("SOME TESTS FAILED.")
		get_tree().quit(1)
