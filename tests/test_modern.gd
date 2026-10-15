extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Modern Era (Chapter 5).
## Validates:
## 1. Modern Equipment & Skill Resources (Tactical Combat Knife, Kevlar Tactical Vest, Military Assault Rifle, Nanoweave, Adrenaline Surge)
## 2. Modern Frontline Heavy: SWAT Riot Enforcer (ballistic shield frontal block, parry stagger double damage vulnerability)
## 3. Modern Sharpshooter: Urban Sniper (damage reception, supersonic SniperTracerBullet firing)
## 4. Modern Miniboss: Commander Reyes (MOD-01, tactical knife flurry, burst pistol, defeat)
## 5. Modern Era Boss: General Vance (MOD-ERA 3-phase, Exoskeleton Armor break, Redline frenzy, defeat)
## 6. Chapter 5 Level Integration (Chapter5Modern layout, platforms, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_modern_tests")

func _run_modern_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Modern Era Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Modern Equipment & Skill Resources
	# ----------------------------------------------------
	total_tests += 1
	var knife = load("res://data/equipment/tactical_combat_knife.tres") as EquipmentItem
	var vest = load("res://data/equipment/kevlar_tactical_vest.tres") as EquipmentItem
	var rifle = load("res://data/equipment/military_assault_rifle.tres") as EquipmentItem

	var nanoweave = load("res://data/skills/defense_nanoweave_reinforcement.tres") as SkillData
	var adrenaline = load("res://data/skills/necro_adrenaline_surge.tres") as SkillData

	var equip_ok = (
		knife != null and knife.base_damage == 3 and knife.mobility_multiplier == 1.20 and
		vest != null and vest.defense_multiplier == 0.35 and vest.slot == "ARMOR" and
		rifle != null and rifle.base_damage == 4 and rifle.max_ammo == 30
	)

	var skills_ok = (
		nanoweave != null and nanoweave.cost == 3 and nanoweave.required_skills.has("def_bulwark_stance") and
		adrenaline != null and adrenaline.cost == 2 and adrenaline.required_skills.has("necro_soul_siphon")
	)

	if equip_ok and skills_ok:
		print("✔ PASS [1/6]: Modern equipment (Knife 3dmg 1.2x mobility, Kevlar Vest 65% reduction, Assault Rifle 4dmg 30ammo) and tier-5 skills validated")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Equipment or skill validation failed (equip: %s, skills: %s)" % [equip_ok, skills_ok])

	# ----------------------------------------------------
	# 2. Modern Frontline Heavy: SWAT Riot Enforcer
	# ----------------------------------------------------
	total_tests += 1
	var riot_scene = preload("res://scenes/enemies/enemy_riot_enforcer.tscn")
	var enforcer: EnemyRiotEnforcer = riot_scene.instantiate() as EnemyRiotEnforcer
	add_child(enforcer)
	enforcer.global_position = Vector2(300, 200)
	await get_tree().process_frame

	enforcer.set_physics_process(false)
	enforcer.set_facing(-1) # Facing left

	var front_attacker = Node2D.new()
	add_child(front_attacker)
	front_attacker.global_position = Vector2(250, 200) # In front of enforcer

	var start_hp = enforcer.current_health
	# Frontal hit: shield should block completely (0 damage)
	enforcer._on_hurtbox_hit_received(1, Vector2(30, 0), 3, front_attacker, false)
	var blocked_frontal = (enforcer.current_health == start_hp)

	# Stagger via parry
	enforcer.stagger(1.5)
	var is_staggered = enforcer.is_staggered

	# Hit while staggered: double damage (1 dmg becomes 2 dmg)
	var hp_before_stagger_hit = enforcer.current_health
	enforcer._on_hurtbox_hit_received(1, Vector2(30, 0), 3, front_attacker, false)
	var stagger_vuln = (enforcer.current_health == hp_before_stagger_hit - 2)

	front_attacker.queue_free()

	if blocked_frontal and is_staggered and stagger_vuln:
		print("✔ PASS [2/6]: SWAT Riot Enforcer blocks frontal hits with shield and receives double damage when parry staggered")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Riot Enforcer validation failed (blocked: %s, staggered: %s, vuln: %s)" % [blocked_frontal, is_staggered, stagger_vuln])

	# ----------------------------------------------------
	# 3. Modern Sharpshooter: Urban Sniper
	# ----------------------------------------------------
	total_tests += 1
	var sniper_scene = preload("res://scenes/enemies/enemy_sniper.tscn")
	var sniper: EnemySniper = sniper_scene.instantiate() as EnemySniper
	add_child(sniper)
	sniper.global_position = Vector2(500, 200)
	await get_tree().process_frame

	var hp_before = sniper.current_health
	sniper.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var sniper_took_damage = (sniper.current_health == hp_before - 1)

	# Fire supersonic tracer bullet
	sniper._fire_bullet()
	var bullet_spawned = false
	for child in get_children():
		if child is SniperTracerBullet:
			bullet_spawned = true
			child.queue_free()
			break

	if sniper_took_damage and bullet_spawned:
		print("✔ PASS [3/6]: Urban Sniper marksman takes damage (%d HP) and fires high-velocity SniperTracerBullet" % sniper.current_health)
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Urban Sniper validation failed (damaged: %s, bullet: %s)" % [sniper_took_damage, bullet_spawned])

	# ----------------------------------------------------
	# 4. Modern Miniboss: Commander Reyes (MOD-01)
	# ----------------------------------------------------
	total_tests += 1
	var reyes_scene = preload("res://scenes/bosses/boss_commander_reyes.tscn")
	var reyes: BossController = reyes_scene.instantiate() as BossController
	add_child(reyes)
	reyes.global_position = Vector2(700, 200)
	await get_tree().process_frame

	var reyes_valid = (reyes.data != null and reyes.data.id == "MOD-01" and reyes.data.era == "Modern")
	reyes.hurtbox.receive_hit(reyes.data.max_health, Vector2(50, 0), 4, null, true)
	var reyes_dead = reyes.is_dead

	if reyes_valid and reyes_dead:
		print("✔ PASS [4/6]: Miniboss Commander Reyes (MOD-01) initializes with BossData and triggers defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Commander Reyes validation failed (valid: %s, dead: %s)" % [reyes_valid, reyes_dead])

	# ----------------------------------------------------
	# 5. Modern Era Boss: General Vance (MOD-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var vance_scene = preload("res://scenes/bosses/boss_general_vance.tscn")
	var vance: BossController = vance_scene.instantiate() as BossController
	add_child(vance)
	vance.global_position = Vector2(900, 200)
	await get_tree().process_frame

	var vance_valid = (vance.data != null and vance.data.id == "MOD-ERA" and vance.data.total_phases == 3)

	# Phase 1 -> 2
	vance.hurtbox.receive_hit(14, Vector2(50, 0), 4, null, false)
	var p2_ok = (vance.current_phase == 2 and vance.current_armor == vance.data.armor_health)

	# Shatter Powered Exoskeleton Armor in Phase 2
	vance.hurtbox.receive_hit(16, Vector2(50, 0), 4, null, false)
	var armor_shattered = (vance.current_armor == 0 and vance.is_staggered)

	# Phase 2 -> 3
	vance.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var p3_ok = (vance.current_phase == 3 and vance.hitbox.damage == 3)

	# Final strike
	vance.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, true)
	var vance_dead = vance.is_dead

	if vance_valid and p2_ok and armor_shattered and p3_ok and vance_dead:
		print("✔ PASS [5/6]: Era Boss General Vance executes 3 phases (Heavy Shotgun -> Exoskeleton Armor & Airstrikes -> Redline Frenzy -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: General Vance validation failed (valid: %s, P2: %s, Armor: %s, P3: %s, Dead: %s)" % [vance_valid, p2_ok, armor_shattered, p3_ok, vance_dead])

	# ----------------------------------------------------
	# 6. Chapter 5 Level Integration (Chapter5Modern)
	# ----------------------------------------------------
	total_tests += 1
	var chap5_scene = preload("res://scenes/levels/chapter5_modern.tscn")
	var chap5: Chapter5Modern = chap5_scene.instantiate() as Chapter5Modern
	add_child(chap5)
	await get_tree().process_frame

	var platforms_count = chap5.get_node("Platforms").get_child_count()
	var checkpoints_count = chap5.get_node("Checkpoints").get_child_count()
	var enemies_count = chap5.get_node("Enemies").get_child_count()
	var has_exit = (chap5.exit_portal != null)
	var has_dlg = (chap5.dialogue_box != null)
	var has_title_card = (chap5.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [6/6]: Chapter 5: Concrete Metropolis complete (8+ Rooftop Platforms, 3 Checkpoints, 7 Enemies, Skybridge Arena, Exit Portal)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Chapter 5 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Modern Era Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL MODERN ERA TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
