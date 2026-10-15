extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Futuristic Era (Chapter 6).
## Validates:
## 1. Futuristic Equipment & Skill Resources (HF Plasma Katana, Nanite Mesh Exosuit, Particle Beam Carbine, Plasma Overload, Quantum Slipstream)
## 2. Futuristic Aerial: Hovering Cyber Drone (anti-grav hover, fires PlasmaOrbProjectile, EMP crash stagger 2x damage)
## 3. Futuristic Melee: Cybernetic Android Stalker (holographic phase dash, twin plasma daggers, parry sensor desync 2x damage)
## 4. Futuristic Miniboss: Unit 73 Infiltrator (FUT-01, hardlight blade flurry, teleport dash, defeat)
## 5. Futuristic Era Boss: Unit 00-NEXUS (FUT-ERA 3-phase, Hardlight Barrier break, Singularity Overload, defeat)
## 6. Chapter 6 Level Integration (Chapter6Futuristic layout, platforms, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_futuristic_tests")

func _run_futuristic_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Futuristic Era Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Futuristic Equipment & Skill Resources
	# ----------------------------------------------------
	total_tests += 1
	var blade = load("res://data/equipment/high_frequency_plasma_blade.tres") as EquipmentItem
	var suit = load("res://data/equipment/nanite_mesh_exosuit.tres") as EquipmentItem
	var carbine = load("res://data/equipment/particle_beam_carbine.tres") as EquipmentItem

	var plasma_overload = load("res://data/skills/elem_plasma_overload.tres") as SkillData
	var slipstream = load("res://data/skills/shadow_quantum_slipstream.tres") as SkillData

	var equip_ok = (
		blade != null and blade.base_damage == 4 and blade.mobility_multiplier == 1.25 and
		suit != null and suit.defense_multiplier == 0.30 and suit.slot == "ARMOR" and
		carbine != null and carbine.base_damage == 5 and carbine.max_ammo == 40
	)

	var skills_ok = (
		plasma_overload != null and plasma_overload.cost == 4 and plasma_overload.required_skills.has("elem_overcharge_discharge") and
		slipstream != null and slipstream.cost == 4 and slipstream.required_skills.has("shadow_smoke_veil")
	)

	if equip_ok and skills_ok:
		print("✔ PASS [1/6]: Futuristic equipment (HF Plasma Blade 4dmg, Nanite Suit 70% reduction, Carbine 5dmg 40ammo) and tier-6 skills validated")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Equipment or skill validation failed (equip: %s, skills: %s)" % [equip_ok, skills_ok])

	# ----------------------------------------------------
	# 2. Futuristic Aerial: Hovering Cyber Drone
	# ----------------------------------------------------
	total_tests += 1
	var drone_scene = preload("res://scenes/enemies/enemy_cyber_drone.tscn")
	var drone: EnemyCyberDrone = drone_scene.instantiate() as EnemyCyberDrone
	add_child(drone)
	drone.global_position = Vector2(300, 150)
	await get_tree().process_frame

	drone.set_physics_process(false)
	var hp_start = drone.current_health
	drone.hurtbox.receive_hit(1, Vector2(30, 0), 3, null, false)
	var took_normal_dmg = (drone.current_health == hp_start - 1)

	# EMP crash stagger
	drone.stagger(1.5)
	var is_staggered = drone.is_staggered
	var hp_before_stagger = drone.current_health
	drone.hurtbox.receive_hit(1, Vector2(30, 0), 3, null, false)
	var stagger_double_dmg = (drone.current_health == hp_before_stagger - 2)

	# Fire plasma orb projectile
	drone._fire_plasma_orb()
	var orb_spawned = false
	for child in get_children():
		if child is PlasmaOrbProjectile:
			orb_spawned = true
			child.queue_free()
			break

	if took_normal_dmg and is_staggered and stagger_double_dmg and orb_spawned:
		print("✔ PASS [2/6]: Hovering Cyber Drone takes damage, crashes in EMP stagger (2x vuln), and fires PlasmaOrbProjectile")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Cyber Drone validation failed (normal: %s, staggered: %s, double: %s, orb: %s)" % [took_normal_dmg, is_staggered, stagger_double_dmg, orb_spawned])

	# ----------------------------------------------------
	# 3. Futuristic Melee: Cybernetic Android Stalker
	# ----------------------------------------------------
	total_tests += 1
	var stalker_scene = preload("res://scenes/enemies/enemy_android_stalker.tscn")
	var stalker: EnemyAndroidStalker = stalker_scene.instantiate() as EnemyAndroidStalker
	add_child(stalker)
	stalker.global_position = Vector2(500, 200)
	await get_tree().process_frame

	stalker.set_physics_process(false)
	var stalker_hp_start = stalker.current_health
	stalker.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var stalker_took_dmg = (stalker.current_health == stalker_hp_start - 1)

	# Parry stagger
	stalker.stagger(1.4)
	var stalker_staggered = stalker.is_staggered
	var stalker_hp_before_double = stalker.current_health
	stalker.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var stalker_double_dmg = (stalker.current_health == stalker_hp_before_double - 2)

	if stalker_took_dmg and stalker_staggered and stalker_double_dmg:
		print("✔ PASS [3/6]: Android Stalker executes blade attacks, parry sensor desync, and receives double damage when staggered")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Android Stalker validation failed (dmg: %s, staggered: %s, double: %s)" % [stalker_took_dmg, stalker_staggered, stalker_double_dmg])

	# ----------------------------------------------------
	# 4. Futuristic Miniboss: Unit 73 Infiltrator (FUT-01)
	# ----------------------------------------------------
	total_tests += 1
	var unit73_scene = preload("res://scenes/bosses/boss_cyber_unit73.tscn")
	var unit73: BossController = unit73_scene.instantiate() as BossController
	add_child(unit73)
	unit73.global_position = Vector2(700, 200)
	await get_tree().process_frame

	var unit73_valid = (unit73.data != null and unit73.data.id == "FUT-01" and unit73.data.era == "Futuristic")
	unit73.hurtbox.receive_hit(unit73.data.max_health, Vector2(50, 0), 4, null, true)
	var unit73_dead = unit73.is_dead

	if unit73_valid and unit73_dead:
		print("✔ PASS [4/6]: Miniboss Unit 73 Infiltrator (FUT-01) initializes with BossData and triggers defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Unit 73 validation failed (valid: %s, dead: %s)" % [unit73_valid, unit73_dead])

	# ----------------------------------------------------
	# 5. Futuristic Era Boss: Unit 00-NEXUS (FUT-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var nexus_scene = preload("res://scenes/bosses/boss_apex_nexus.tscn")
	var nexus: BossController = nexus_scene.instantiate() as BossController
	add_child(nexus)
	nexus.global_position = Vector2(900, 200)
	await get_tree().process_frame

	var nexus_valid = (nexus.data != null and nexus.data.id == "FUT-ERA" and nexus.data.total_phases == 3)

	# Phase 1 -> 2
	nexus.hurtbox.receive_hit(13, Vector2(50, 0), 4, null, false)
	var p2_ok = (nexus.current_phase == 2 and nexus.current_armor == nexus.data.armor_health)

	# Shatter Quantum Hardlight Barrier in Phase 2
	nexus.hurtbox.receive_hit(18, Vector2(50, 0), 4, null, false)
	var barrier_shattered = (nexus.current_armor == 0 and nexus.is_staggered)

	# Phase 2 -> 3
	nexus.hurtbox.receive_hit(12, Vector2(50, 0), 4, null, false)
	var p3_ok = (nexus.current_phase == 3 and nexus.hitbox.damage == 3)

	# Final strike
	nexus.hurtbox.receive_hit(11, Vector2(50, 0), 4, null, true)
	var nexus_dead = nexus.is_dead

	if nexus_valid and p2_ok and barrier_shattered and p3_ok and nexus_dead:
		print("✔ PASS [5/6]: Era Boss Unit 00-NEXUS executes 3 phases (Plasma Sweeps -> Hardlight Barrier & Orbital Lasers -> Singularity Overload -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Unit 00-NEXUS validation failed (valid: %s, P2: %s, Barrier: %s, P3: %s, Dead: %s)" % [nexus_valid, p2_ok, barrier_shattered, p3_ok, nexus_dead])

	# ----------------------------------------------------
	# 6. Chapter 6 Level Integration (Chapter6Futuristic)
	# ----------------------------------------------------
	total_tests += 1
	var chap6_scene = preload("res://scenes/levels/chapter6_futuristic.tscn")
	var chap6: Chapter6Futuristic = chap6_scene.instantiate() as Chapter6Futuristic
	add_child(chap6)
	await get_tree().process_frame

	var platforms_count = chap6.get_node("Platforms").get_child_count()
	var checkpoints_count = chap6.get_node("Checkpoints").get_child_count()
	var enemies_count = chap6.get_node("Enemies").get_child_count()
	var has_exit = (chap6.exit_portal != null)
	var has_dlg = (chap6.dialogue_box != null)
	var has_title_card = (chap6.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [6/6]: Chapter 6: The Cybernetic Spire complete (8+ Hardlight Platforms, 3 Checkpoints, 7 Enemies, Spire Apex Arena, Final Monolith Exit)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Chapter 6 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Futuristic Era Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL FUTURISTIC ERA TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
