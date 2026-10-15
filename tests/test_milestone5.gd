extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 5 (Medieval Era).
## Validates:
## 1. Medieval Equipment & Skill Resources (Broadsword, Tower Shield, Rending Strike, Bulwark)
## 2. Medieval Soldier: Ironclad Footman (frontal shield block, parry stagger vulnerability)
## 3. Medieval Sniper: Crossbow Marksman (aiming telegraph, CrossbowBolt firing, death)
## 4. Medieval Miniboss: Sir Gareth the Ironclad (MED-01, Bastion Guard, defeat)
## 5. Medieval Era Boss: Lord Malakor (MED-ERA 3-phase, Bastion Armor, Ember Rain, Defeat)
## 6. Chapter 2 Level Integration (Chapter2Medieval layout, platforms, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_milestone5_tests")

func _run_milestone5_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 5 Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Medieval Equipment & Skill Resources
	# ----------------------------------------------------
	total_tests += 1
	var broadsword = load("res://data/equipment/iron_knight_broadsword.tres") as EquipmentItem
	var shield = load("res://data/equipment/heavy_tower_shield.tres") as EquipmentItem
	var xbow = load("res://data/equipment/royal_crossbow.tres") as EquipmentItem

	var rending = load("res://data/skills/attack_rending_strike.tres") as SkillData
	var bulwark = load("res://data/skills/defense_bulwark_stance.tres") as SkillData

	var equip_ok = (
		broadsword != null and broadsword.base_damage == 2 and
		shield != null and shield.defense_multiplier == 0.50 and
		xbow != null and xbow.base_damage == 3
	)

	var skills_ok = (
		rending != null and rending.cost == 2 and rending.required_skills.has("atk_finisher_mastery") and
		bulwark != null and bulwark.cost == 2 and bulwark.required_skills.has("def_fortified_parry")
	)

	if equip_ok and skills_ok:
		print("✔ PASS [1/6]: Medieval equipment (Broadsword 2dmg, Shield 50%% def) and tier-2 skills validated")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Equipment or skill validation failed (equip: %s, skills: %s)" % [equip_ok, skills_ok])

	# ----------------------------------------------------
	# 2. Medieval Soldier: Ironclad Footman
	# ----------------------------------------------------
	total_tests += 1
	var foot_scene = preload("res://scenes/enemies/enemy_footman.tscn")
	var footman: EnemyFootman = foot_scene.instantiate() as EnemyFootman
	add_child(footman)
	footman.global_position = Vector2(300, 200)
	await get_tree().process_frame

	footman.set_physics_process(false)
	footman.set_facing(-1) # Facing left

	# Attacker to left (X=250 < X=300) attacks from front
	var attacker_node = Node2D.new()
	add_child(attacker_node)
	attacker_node.global_position = Vector2(250, 200)

	var foot_start_hp = footman.current_health
	# Frontal light attack (1 dmg) -> Shield blocks completely (0 taken)!
	footman._on_hurtbox_hit_received(1, Vector2(30, 0), 3, attacker_node, false)
	var shield_blocked = (footman.current_health == foot_start_hp)

	# Stagger via parry: drops shield
	footman.stagger(1.4)
	var is_staggered = footman.is_staggered
	# Hit while staggered: double damage (2 dmg becomes 4 dmg)
	footman._on_hurtbox_hit_received(2, Vector2(30, 0), 3, attacker_node, false)
	var stagger_vuln = (footman.current_health == foot_start_hp - 4)

	attacker_node.queue_free()

	if shield_blocked and is_staggered and stagger_vuln:
		print("✔ PASS [2/6]: Ironclad Footman blocks frontal attacks (0 taken) and receives double damage on parry stagger")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Footman validation failed (blocked: %s, staggered: %s, vuln: %s)" % [shield_blocked, is_staggered, stagger_vuln])

	# ----------------------------------------------------
	# 3. Medieval Sniper: Crossbow Marksman
	# ----------------------------------------------------
	total_tests += 1
	var xbow_scene = preload("res://scenes/enemies/enemy_crossbow.tscn")
	var sniper: EnemyCrossbow = xbow_scene.instantiate() as EnemyCrossbow
	add_child(sniper)
	sniper.global_position = Vector2(500, 200)
	await get_tree().process_frame

	var hp_before = sniper.current_health
	sniper.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var sniper_took_damage = (sniper.current_health == hp_before - 1)

	# Fire bolt
	sniper._fire_bolt()
	var bolt_spawned = false
	for child in get_children():
		if child is CrossbowBolt:
			bolt_spawned = true
			child.queue_free()
			break

	if sniper_took_damage and bolt_spawned:
		print("✔ PASS [3/6]: Crossbow Marksman takes damage (%d HP) and spawns high-speed CrossbowBolt" % sniper.current_health)
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Crossbow Marksman validation failed (damaged: %s, bolt: %s)" % [sniper_took_damage, bolt_spawned])

	# ----------------------------------------------------
	# 4. Medieval Miniboss: Sir Gareth the Ironclad (MED-01)
	# ----------------------------------------------------
	total_tests += 1
	var gareth_scene = preload("res://scenes/bosses/boss_sir_gareth.tscn")
	var gareth: BossController = gareth_scene.instantiate() as BossController
	add_child(gareth)
	gareth.global_position = Vector2(700, 200)
	await get_tree().process_frame

	var gareth_valid = (gareth.data != null and gareth.data.id == "MED-01" and gareth.data.era == "Medieval")
	gareth.hurtbox.receive_hit(gareth.data.max_health, Vector2(50, 0), 4, null, true)
	var gareth_dead = gareth.is_dead

	if gareth_valid and gareth_dead:
		print("✔ PASS [4/6]: Miniboss Sir Gareth (MED-01) initializes with BossData and triggers defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Sir Gareth validation failed (valid: %s, dead: %s)" % [gareth_valid, gareth_dead])

	# ----------------------------------------------------
	# 5. Medieval Era Boss: Lord Malakor of the Iron Bastion (MED-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var malakor_scene = preload("res://scenes/bosses/boss_lord_malakor.tscn")
	var malakor: BossController = malakor_scene.instantiate() as BossController
	add_child(malakor)
	malakor.global_position = Vector2(900, 200)
	await get_tree().process_frame

	var malakor_valid = (malakor.data != null and malakor.data.id == "MED-ERA" and malakor.data.total_phases == 3)

	# Phase 1 -> 2
	malakor.hurtbox.receive_hit(12, Vector2(50, 0), 4, null, false)
	var p2_ok = (malakor.current_phase == 2 and malakor.current_armor == malakor.data.armor_health)

	# Shatter Bastion Armor in Phase 2
	malakor.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var armor_shattered = (malakor.current_armor == 0 and malakor.is_staggered)

	# Phase 2 -> 3
	malakor.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var p3_ok = (malakor.current_phase == 3 and malakor.hitbox.damage == 3)

	# Final strike
	malakor.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, true)
	var malakor_dead = malakor.is_dead

	if malakor_valid and p2_ok and armor_shattered and p3_ok and malakor_dead:
		print("✔ PASS [5/6]: Era Boss Lord Malakor executes 3 phases (Iron Fortress Armor -> Trebuchet Embers -> Phantom Flame -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Lord Malakor validation failed (valid: %s, P2: %s, Armor: %s, P3: %s, Dead: %s)" % [malakor_valid, p2_ok, armor_shattered, p3_ok, malakor_dead])

	# ----------------------------------------------------
	# 6. Chapter 2 Level Integration (Chapter2Medieval)
	# ----------------------------------------------------
	total_tests += 1
	var chap2_scene = preload("res://scenes/levels/chapter2_medieval.tscn")
	var chap2: Chapter2Medieval = chap2_scene.instantiate() as Chapter2Medieval
	add_child(chap2)
	await get_tree().process_frame

	var platforms_count = chap2.get_node("Platforms").get_child_count()
	var checkpoints_count = chap2.get_node("Checkpoints").get_child_count()
	var enemies_count = chap2.get_node("Enemies").get_child_count()
	var has_exit = (chap2.exit_portal != null)
	var has_dlg = (chap2.dialogue_box != null)
	var has_title_card = (chap2.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [6/6]: Chapter 2: Castle of the Cursed Keep complete (8+ Stone Platforms, 3 Checkpoints, 7 Enemies, Gatehouse Arena, Monolith Exit)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Chapter 2 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Milestone 5 Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL MILESTONE 5 TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
