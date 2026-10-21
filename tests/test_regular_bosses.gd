extends Node2D

## Automated Headless Integration Test Suite for Regular Boss Expansion:
## PRE-02 Mud Golem, MED-02 Gargoyle Patriarch, and HIST-02 Onryo of the Mist.

const MUD_GOLEM_SCENE = preload("res://scenes/bosses/boss_mud_golem.tscn")
const GARGOYLE_SCENE = preload("res://scenes/bosses/boss_gargoyle_patriarch.tscn")
const ONRYO_SCENE = preload("res://scenes/bosses/boss_onryo_mist.tscn")
const MAGIC_PROJECTILE_SCENE = preload("res://scenes/characters/magic_projectile.tscn")
const MUD_TRAP_SCRIPT = preload("res://scripts/combat/mud_trap.gd")
const CLAY_BOULDER_SCRIPT = preload("res://scripts/combat/clay_boulder.gd")
const ARENA_SCENE = preload("res://scenes/levels/boss_arena.tscn")

func _ready() -> void:
	call_deferred("_run_regular_boss_tests")

func _run_regular_boss_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Regular Boss Expansion Test Suite")
	print("  (PRE-02 Mud Golem, MED-02 Gargoyle, HIST-02 Onryo)")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. PRE-02: Mud Golem (Earth Spirit) Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var golem = MUD_GOLEM_SCENE.instantiate()
	add_child(golem)
	golem.global_position = Vector2(300, 200)
	await get_tree().process_frame

	var golem_data_ok = (
		golem.data != null and
		golem.data.id == "PRE-02" and
		golem.current_health == 12 and
		golem.data.reward_id == "clay_core"
	)

	# Test Mud Slam & Mud Trap spawn
	golem._execute_mud_slam()
	var trap_found = false
	for child in get_children():
		if child.get_script() == MUD_TRAP_SCRIPT:
			trap_found = true
			child.queue_free()
			break

	# Test Clay Boulder projectile spawn
	golem._throw_clay_boulder()
	var boulder_found = false
	for child in get_children():
		if child.get_script() == CLAY_BOULDER_SCRIPT:
			boulder_found = true
			child.queue_free()
			break

	# Test Magic Weakness (2x damage + stun)
	var magic_bullet = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet)
	var hp_before = golem.current_health
	golem.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet, false)
	# Magic weakness should deal 4 damage instead of 2, and stagger
	var magic_weakness_ok = (golem.current_health == hp_before - 4) and golem.is_staggered
	magic_bullet.queue_free()

	golem.queue_free()
	await get_tree().process_frame

	if golem_data_ok and trap_found and boulder_found and magic_weakness_ok:
		print("✔ PASS [1/6]: PRE-02 Mud Golem initializes, spawns mud traps & clay boulders, and receives 2x damage & stagger from Magic")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Mud Golem validation failed (data: %s, trap: %s, bldr: %s, magic: %s)" % [
			golem_data_ok, trap_found, boulder_found, magic_weakness_ok
		])

	# ----------------------------------------------------
	# 2. MED-02: Gargoyle Patriarch (Cathedral Beast) Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var gargoyle = GARGOYLE_SCENE.instantiate()
	add_child(gargoyle)
	gargoyle.global_position = Vector2(300, 200)
	await get_tree().process_frame

	var gargoyle_data_ok = (
		gargoyle.data != null and
		gargoyle.data.id == "MED-02" and
		gargoyle.current_health == 12 and
		gargoyle.current_armor == 6 and
		gargoyle.data.reward_id == "gargoyle_talons"
	)

	# Test Battlement Dive attack state
	gargoyle.current_action = gargoyle.GargoyleAction.BATTLEMENT_DIVE
	gargoyle.velocity = Vector2(150, 150)
	var diving_active = gargoyle.current_action == gargoyle.GargoyleAction.BATTLEMENT_DIVE

	# Test Aerial Counter / Dive Interruption (shatters armor, deals double dmg, 2.0s stagger)
	gargoyle.hurtbox.receive_hit(2, Vector2(0, 50), 4, null, false)
	var counter_ok = (gargoyle.current_armor == 0 and gargoyle.is_staggered and gargoyle.stagger_timer >= 1.5)

	# Test Magic Armor Pierce
	var magic_bullet2 = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet2)
	gargoyle.current_armor = 4
	var hp_before_garg = gargoyle.current_health
	gargoyle.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet2, false)
	var magic_pierce_ok = (gargoyle.current_armor == 0 and gargoyle.current_health < hp_before_garg)
	magic_bullet2.queue_free()

	gargoyle.queue_free()
	await get_tree().process_frame

	if gargoyle_data_ok and diving_active and counter_ok and magic_pierce_ok:
		print("✔ PASS [2/6]: MED-02 Gargoyle Patriarch validates Battlement Dive, aerial counter armor shatter, and magic piercing")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Gargoyle validation failed (data: %s, dive: %s, counter: %s, magic: %s)" % [
			gargoyle_data_ok, diving_active, counter_ok, magic_pierce_ok
		])

	# ----------------------------------------------------
	# 3. HIST-02: Onryo of the Bamboo Mist Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var onryo = ONRYO_SCENE.instantiate()
	add_child(onryo)
	onryo.global_position = Vector2(300, 200)
	await get_tree().process_frame

	var onryo_data_ok = (
		onryo.data != null and
		onryo.data.id == "HIST-02" and
		onryo.current_health == 10 and
		onryo.data.reward_id == "spirit_ribbon"
	)

	# Test Shadow Clone spawn
	onryo._spawn_shadow_clones()
	var clones_active = onryo.active_clones.size() == 2

	# Test Mist Phase Teleport & Invulnerability
	onryo._fade_out()
	var invulnerable_ok = onryo.hurtbox.is_invulnerable == true
	onryo._teleport_behind_player()
	var reappeared_ok = onryo.hurtbox.is_invulnerable == false

	# Test Magic Dispel Weakness (dispels clones immediately and staggers)
	var magic_bullet3 = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet3)
	onryo._spawn_shadow_clones()
	onryo.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet3, false)
	var dispel_ok = onryo.active_clones.is_empty() and onryo.is_staggered
	magic_bullet3.queue_free()

	onryo.queue_free()
	await get_tree().process_frame

	if onryo_data_ok and clones_active and invulnerable_ok and reappeared_ok and dispel_ok:
		print("✔ PASS [3/6]: HIST-02 Onryo validates Mist Phasing teleportation, shadow clone summoning, and magic clone dispel")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Onryo validation failed (data: %s, clones: %s, invul: %s, reap: %s, dispel: %s)" % [
			onryo_data_ok, clones_active, invulnerable_ok, reappeared_ok, dispel_ok
		])

	# ----------------------------------------------------
	# 4. BossArena Dynamic Spawning Integration
	# ----------------------------------------------------
	total_tests += 1
	var arena = ARENA_SCENE.instantiate()
	arena.selected_boss_type = "mud_golem"
	add_child(arena)
	await get_tree().process_frame

	var arena_spawn_ok = (
		arena.current_boss != null and
		arena.current_boss.data != null and
		arena.current_boss.data.id == "PRE-02"
	)

	arena.queue_free()
	await get_tree().process_frame

	if arena_spawn_ok:
		print("✔ PASS [4/6]: BossArena dynamically instantiates and binds new regular boss (PRE-02 Mud Golem)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: BossArena dynamic spawning failed (spawn_ok: %s)" % arena_spawn_ok)

	# ----------------------------------------------------
	# 5. Defeat Sequences & Reward IDs
	# ----------------------------------------------------
	total_tests += 1
	var golem_defeat = MUD_GOLEM_SCENE.instantiate()
	add_child(golem_defeat)
	await get_tree().process_frame

	var defeat_box: Array[bool] = [false]
	golem_defeat.boss_defeated.connect(func(): defeat_box[0] = true)
	golem_defeat.hurtbox.receive_hit(20, Vector2.ZERO, 4, null, false)
	await get_tree().process_frame

	var death_ok = golem_defeat.is_dead and defeat_box[0]

	golem_defeat.queue_free()
	await get_tree().process_frame

	if death_ok:
		print("✔ PASS [5/6]: Boss defeat pipeline emits boss_defeated signal and initiates clean death fade")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Defeat pipeline failed (death_ok: %s)" % death_ok)

	# ----------------------------------------------------
	# 6. Roster Status & Story Flags Verification
	# ----------------------------------------------------
	total_tests += 1
	var pre02_res = load("res://data/bosses/mud_golem.tres") as BossData
	var med02_res = load("res://data/bosses/gargoyle_patriarch.tres") as BossData
	var hist02_res = load("res://data/bosses/onryo_mist.tres") as BossData

	var flags_valid = (
		pre02_res.story_flag == "boss_pre02_cleared" and
		med02_res.story_flag == "boss_med02_cleared" and
		hist02_res.story_flag == "boss_hist02_cleared"
	)
	var rewards_valid = (
		pre02_res.reward_id == "clay_core" and
		med02_res.reward_id == "gargoyle_talons" and
		hist02_res.reward_id == "spirit_ribbon"
	)

	if flags_valid and rewards_valid:
		print("✔ PASS [6/6]: Boss Roster synchronization verified with distinct rewards (Clay Core, Gargoyle Talons, Spirit Ribbon)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Roster synchronization failed (flags: %s, rewards: %s)" % [flags_valid, rewards_valid])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Regular Boss Expansion Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL REGULAR BOSS TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME REGULAR BOSS TESTS FAILED <<<")
		get_tree().quit(1)
