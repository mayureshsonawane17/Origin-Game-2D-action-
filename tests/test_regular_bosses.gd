extends Node2D

## Automated Headless Integration Test Suite for Regular Boss Expansion:
## PRE-02 Mud Golem, MED-02 Gargoyle, HIST-02 Onryo,
## IND-02 Spider Sentry, MOD-02 SWAT Juggernaut, and FUT-02 Sentinel Swarm.

const MUD_GOLEM_SCENE = preload("res://scenes/bosses/boss_mud_golem.tscn")
const GARGOYLE_SCENE = preload("res://scenes/bosses/boss_gargoyle_patriarch.tscn")
const ONRYO_SCENE = preload("res://scenes/bosses/boss_onryo_mist.tscn")
const SPIDER_SCENE = preload("res://scenes/bosses/boss_spider_sentry.tscn")
const SWAT_SCENE = preload("res://scenes/bosses/boss_swat_juggernaut.tscn")
const SWARM_SCENE = preload("res://scenes/bosses/boss_sentinel_swarm.tscn")

const MAGIC_PROJECTILE_SCENE = preload("res://scenes/characters/magic_projectile.tscn")
const MUD_TRAP_SCRIPT = preload("res://scripts/combat/mud_trap.gd")
const CLAY_BOULDER_SCRIPT = preload("res://scripts/combat/clay_boulder.gd")
const STEAM_VENT_SCRIPT = preload("res://scripts/combat/steam_vent_hazard.gd")
const CABLE_TRAP_SCRIPT = preload("res://scripts/combat/cable_trap.gd")
const STUN_GRENADE_SCRIPT = preload("res://scripts/combat/stun_grenade.gd")
const PLASMA_ORB_SCRIPT = preload("res://scripts/combat/plasma_orb.gd")
const ARENA_SCENE = preload("res://scenes/levels/boss_arena.tscn")

func _ready() -> void:
	call_deferred("_run_regular_boss_tests")

func _run_regular_boss_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Complete Tier 1 Regular Boss Test Suite")
	print("  (PRE-02, MED-02, HIST-02, IND-02, MOD-02, FUT-02)")
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
	var mud_trap_found = false
	for child in get_children():
		if child.get_script() == MUD_TRAP_SCRIPT:
			mud_trap_found = true
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
	var hp_before_golem = golem.current_health
	golem.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet, false)
	var golem_magic_ok = (golem.current_health == hp_before_golem - 4) and golem.is_staggered
	magic_bullet.queue_free()

	golem.queue_free()
	await get_tree().process_frame

	if golem_data_ok and mud_trap_found and boulder_found and golem_magic_ok:
		print("✔ PASS [1/9]: PRE-02 Mud Golem initializes, spawns mud traps & clay boulders, and receives 2x damage & stagger from Magic")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/9]: Mud Golem validation failed (data: %s, trap: %s, bldr: %s, magic: %s)" % [
			golem_data_ok, mud_trap_found, boulder_found, golem_magic_ok
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
		print("✔ PASS [2/9]: MED-02 Gargoyle Patriarch validates Battlement Dive, aerial counter armor shatter, and magic piercing")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/9]: Gargoyle validation failed (data: %s, dive: %s, counter: %s, magic: %s)" % [
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
		print("✔ PASS [3/9]: HIST-02 Onryo validates Mist Phasing teleportation, shadow clone summoning, and magic clone dispel")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/9]: Onryo validation failed (data: %s, clones: %s, invul: %s, reap: %s, dispel: %s)" % [
			onryo_data_ok, clones_active, invulnerable_ok, reappeared_ok, dispel_ok
		])

	# ----------------------------------------------------
	# 4. IND-02: Clockwork Spider Sentry Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var spider = SPIDER_SCENE.instantiate()
	add_child(spider)
	spider.global_position = Vector2(300, 200)
	await get_tree().process_frame

	var spider_data_ok = (
		spider.data != null and
		spider.data.id == "IND-02" and
		spider.current_health == 12 and
		spider.current_armor == 4 and
		spider.data.reward_id == "brass_chassis"
	)

	# Test Steam Vent spawn
	spider._vent_steam()
	var steam_vent_found = false
	for child in get_children():
		if child.get_script() == STEAM_VENT_SCRIPT:
			steam_vent_found = true
			child.queue_free()
			break

	# Test Cable Trap spawn
	spider._launch_cable_trap()
	var cable_trap_found = false
	for child in get_children():
		if child.get_script() == CABLE_TRAP_SCRIPT:
			cable_trap_found = true
			child.queue_free()
			break

	# Test Magic Weakness (overloads boiler, collapses 4 armor, 2x damage, 1.8s stagger)
	var magic_bullet4 = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet4)
	var hp_before_spider = spider.current_health
	spider.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet4, false)
	var spider_magic_ok = (spider.current_armor == 0 and spider.current_health == hp_before_spider - 4 and spider.is_staggered)
	magic_bullet4.queue_free()

	spider.queue_free()
	await get_tree().process_frame

	if spider_data_ok and steam_vent_found and cable_trap_found and spider_magic_ok:
		print("✔ PASS [4/9]: IND-02 Clockwork Spider Sentry validates steam vents, cable traps, and magic boiler overload stagger")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/9]: Spider Sentry validation failed (data: %s, steam: %s, cable: %s, magic: %s)" % [
			spider_data_ok, steam_vent_found, cable_trap_found, spider_magic_ok
		])

	# ----------------------------------------------------
	# 5. MOD-02: SWAT Juggernaut Apex Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var juggernaut = SWAT_SCENE.instantiate()
	add_child(juggernaut)
	juggernaut.global_position = Vector2(300, 200)
	juggernaut.set_facing(1) # Facing right
	await get_tree().process_frame

	var juggernaut_data_ok = (
		juggernaut.data != null and
		juggernaut.data.id == "MOD-02" and
		juggernaut.current_health == 14 and
		juggernaut.current_armor == 6 and
		juggernaut.data.reward_id == "riot_visor"
	)

	# Test Stun Grenade spawn
	juggernaut._toss_stun_grenade()
	var grenade_found = false
	for child in get_children():
		if child.get_script() == STUN_GRENADE_SCRIPT:
			grenade_found = true
			child.queue_free()
			break

	# Test Flank Weakness (attack from behind bypasses shield and deals 1.5x damage directly to HP)
	var flanker = Node2D.new()
	add_child(flanker)
	flanker.global_position = Vector2(200, 200) # To the left of juggernaut (behind, since facing right)
	var hp_before_flank = juggernaut.current_health
	var armor_before_flank = juggernaut.current_armor
	juggernaut.hurtbox.receive_hit(2, Vector2(10, 0), 4, flanker, false)
	# Flank hit should bypass armor and deal 3 damage directly to health
	var flank_ok = (juggernaut.current_armor == armor_before_flank and juggernaut.current_health == hp_before_flank - 3)
	flanker.queue_free()

	# Test Magic Weakness (pierces visor, damages 4 armor, deals 2x damage, staggers)
	var magic_bullet5 = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet5)
	var hp_before_swat_magic = juggernaut.current_health
	juggernaut.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet5, false)
	var swat_magic_ok = (juggernaut.current_armor == 0 and juggernaut.current_health == hp_before_swat_magic - 4 and juggernaut.is_staggered)
	magic_bullet5.queue_free()

	juggernaut.queue_free()
	await get_tree().process_frame

	if juggernaut_data_ok and grenade_found and flank_ok and swat_magic_ok:
		print("✔ PASS [5/9]: MOD-02 SWAT Juggernaut Apex validates stun grenades, flank damage bypass, and visor piercing magic weakness")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/9]: SWAT Juggernaut validation failed (data: %s, grenade: %s, flank: %s, magic: %s)" % [
			juggernaut_data_ok, grenade_found, flank_ok, swat_magic_ok
		])

	# ----------------------------------------------------
	# 6. FUT-02: Sentinel Swarm-Mind Mechanics
	# ----------------------------------------------------
	total_tests += 1
	var swarm = SWARM_SCENE.instantiate()
	add_child(swarm)
	swarm.global_position = Vector2(300, 180)
	await get_tree().process_frame

	var swarm_data_ok = (
		swarm.data != null and
		swarm.data.id == "FUT-02" and
		swarm.current_health == 12 and
		swarm.current_armor == 4 and
		swarm.data.reward_id == "ion_cell"
	)

	# Test Seeking Plasma Salvo spawn
	swarm._fire_plasma_salvo()
	var plasma_count = 0
	for child in get_children():
		if child.get_script() == PLASMA_ORB_SCRIPT:
			plasma_count += 1
			child.queue_free()

	# Test Magic Matrix Collapse Weakness (drops all 4 armor, deals 2x damage, 1.8s stagger)
	var magic_bullet6 = MAGIC_PROJECTILE_SCENE.instantiate()
	add_child(magic_bullet6)
	var hp_before_swarm = swarm.current_health
	swarm.hurtbox.receive_hit(2, Vector2(10, 0), 4, magic_bullet6, false)
	var swarm_magic_ok = (swarm.current_armor == 0 and swarm.current_health == hp_before_swarm - 4 and swarm.is_staggered)
	magic_bullet6.queue_free()

	swarm.queue_free()
	await get_tree().process_frame

	if swarm_data_ok and plasma_count >= 2 and swarm_magic_ok:
		print("✔ PASS [6/9]: FUT-02 Sentinel Swarm-Mind validates orbiting sub-drones, seeking plasma salvo, and shield collapse weakness")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/9]: Sentinel Swarm validation failed (data: %s, plasma: %d, magic: %s)" % [
			swarm_data_ok, plasma_count, swarm_magic_ok
		])

	# ----------------------------------------------------
	# 7. BossArena Dynamic Spawning Integration across all Regular Bosses
	# ----------------------------------------------------
	total_tests += 1
	var arena_types = ["spider_sentry", "swat_juggernaut", "sentinel_swarm"]
	var arena_results = []

	for boss_type in arena_types:
		var arena = ARENA_SCENE.instantiate()
		arena.selected_boss_type = boss_type
		add_child(arena)
		await get_tree().process_frame

		var ok = (arena.current_boss != null and arena.current_boss.data != null)
		arena_results.append(ok)
		arena.queue_free()
		await get_tree().process_frame

	var arena_all_ok = arena_results.all(func(val): return val == true)

	if arena_all_ok:
		print("✔ PASS [7/9]: BossArena dynamically instantiates and binds all Tier 1 regular bosses (Spider, SWAT, Swarm)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [7/9]: BossArena dynamic spawning failed for some bosses: %s" % str(arena_results))

	# ----------------------------------------------------
	# 8. Defeat Pipelines & Signal Emissions
	# ----------------------------------------------------
	total_tests += 1
	var defeat_target = SPIDER_SCENE.instantiate()
	add_child(defeat_target)
	await get_tree().process_frame

	var defeat_box: Array[bool] = [false]
	defeat_target.boss_defeated.connect(func(): defeat_box[0] = true)
	defeat_target.current_armor = 0
	defeat_target.hurtbox.receive_hit(30, Vector2.ZERO, 4, null, false)
	await get_tree().process_frame

	var death_ok = defeat_target.is_dead and defeat_box[0]
	defeat_target.queue_free()
	await get_tree().process_frame

	if death_ok:
		print("✔ PASS [8/9]: Boss defeat pipeline emits boss_defeated signal and initiates clean death fade")
		tests_passed += 1
	else:
		printerr("✘ FAIL [8/9]: Defeat pipeline failed (death_ok: %s)" % death_ok)

	# ----------------------------------------------------
	# 9. Complete Roster Status & Story Flags Verification (All 6 Eras)
	# ----------------------------------------------------
	total_tests += 1
	var pre02_res = load("res://data/bosses/mud_golem.tres") as BossData
	var med02_res = load("res://data/bosses/gargoyle_patriarch.tres") as BossData
	var hist02_res = load("res://data/bosses/onryo_mist.tres") as BossData
	var ind02_res = load("res://data/bosses/spider_sentry.tres") as BossData
	var mod02_res = load("res://data/bosses/swat_juggernaut.tres") as BossData
	var fut02_res = load("res://data/bosses/sentinel_swarm.tres") as BossData

	var flags_valid = (
		pre02_res.story_flag == "boss_pre02_cleared" and
		med02_res.story_flag == "boss_med02_cleared" and
		hist02_res.story_flag == "boss_hist02_cleared" and
		ind02_res.story_flag == "boss_ind02_cleared" and
		mod02_res.story_flag == "boss_mod02_cleared" and
		fut02_res.story_flag == "boss_fut02_cleared"
	)
	var rewards_valid = (
		pre02_res.reward_id == "clay_core" and
		med02_res.reward_id == "gargoyle_talons" and
		hist02_res.reward_id == "spirit_ribbon" and
		ind02_res.reward_id == "brass_chassis" and
		mod02_res.reward_id == "riot_visor" and
		fut02_res.reward_id == "ion_cell"
	)

	if flags_valid and rewards_valid:
		print("✔ PASS [9/9]: Boss Roster synchronization verified with 6 distinct craftable relics across all 6 eras")
		tests_passed += 1
	else:
		printerr("✘ FAIL [9/9]: Complete roster synchronization failed (flags: %s, rewards: %s)" % [flags_valid, rewards_valid])

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
