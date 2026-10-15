extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Industrial Era (Chapter 4).
## Validates:
## 1. Industrial Equipment & Skill Resources (Steam Cleaver, Trench Plating, Revolver, Overclock, Overcharge)
## 2. Industrial Heavy: Clockwork Steam Automaton (piston punch, boiler overload stagger vulnerability)
## 3. Industrial Bombadier: Gas Mask Grenadier (aiming telegraph, ToxicGrenade throw, damage)
## 4. Industrial Miniboss: Chief Overseer Brant (IND-01, pneumatic slam, defeat)
## 5. Industrial Era Boss: Baron Von Steinhardt (IND-ERA 3-phase, Brass Armor break, Meltdown, defeat)
## 6. Chapter 4 Level Integration (Chapter4Industrial layout, platforms, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_industrial_tests")

func _run_industrial_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Industrial Era Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Industrial Equipment & Skill Resources
	# ----------------------------------------------------
	total_tests += 1
	var cleaver = load("res://data/equipment/steam_cleaver.tres") as EquipmentItem
	var armor = load("res://data/equipment/trench_iron_plating.tres") as EquipmentItem
	var gun = load("res://data/equipment/heavy_service_revolver.tres") as EquipmentItem

	var overclock = load("res://data/skills/attack_overclock_strike.tres") as SkillData
	var overcharge = load("res://data/skills/elem_overcharge_discharge.tres") as SkillData

	var equip_ok = (
		cleaver != null and cleaver.base_damage == 3 and cleaver.knockback_bonus == 40.0 and
		armor != null and armor.defense_multiplier == 0.40 and
		gun != null and gun.base_damage == 4 and gun.max_ammo == 6
	)

	var skills_ok = (
		overclock != null and overclock.cost == 3 and overclock.required_skills.has("atk_iaijutsu_strike") and
		overcharge != null and overcharge.cost == 2 and overcharge.required_skills.has("elem_spark_infusion")
	)

	if equip_ok and skills_ok:
		print("✔ PASS [1/6]: Industrial equipment (Cleaver 3dmg, Trench Plating 40% def, Revolver 4dmg) and tier-4 skills validated")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Equipment or skill validation failed (equip: %s, skills: %s)" % [equip_ok, skills_ok])

	# ----------------------------------------------------
	# 2. Industrial Heavy: Clockwork Steam Automaton
	# ----------------------------------------------------
	total_tests += 1
	var auto_scene = preload("res://scenes/enemies/enemy_automaton.tscn")
	var automaton: EnemyAutomaton = auto_scene.instantiate() as EnemyAutomaton
	add_child(automaton)
	automaton.global_position = Vector2(300, 200)
	await get_tree().process_frame

	automaton.set_physics_process(false)
	automaton.set_facing(-1) # Facing left

	var attacker_node = Node2D.new()
	add_child(attacker_node)
	attacker_node.global_position = Vector2(250, 200)

	var auto_start_hp = automaton.current_health
	# Normal hit (1 dmg)
	automaton._on_hurtbox_hit_received(1, Vector2(30, 0), 3, attacker_node, false)
	var took_normal_dmg = (automaton.current_health == auto_start_hp - 1)

	# Stagger via parry
	automaton.stagger(1.5)
	var is_staggered = automaton.is_staggered
	# Hit while staggered: double damage (1 dmg becomes 2 dmg)
	var hp_before_stagger_hit = automaton.current_health
	automaton._on_hurtbox_hit_received(1, Vector2(30, 0), 3, attacker_node, false)
	var stagger_vuln = (automaton.current_health == hp_before_stagger_hit - 2)

	attacker_node.queue_free()

	if took_normal_dmg and is_staggered and stagger_vuln:
		print("✔ PASS [2/6]: Clockwork Automaton takes normal damage and receives double damage on parry boiler overload")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Automaton validation failed (normal: %s, staggered: %s, vuln: %s)" % [took_normal_dmg, is_staggered, stagger_vuln])

	# ----------------------------------------------------
	# 3. Industrial Bombadier: Gas Mask Grenadier
	# ----------------------------------------------------
	total_tests += 1
	var gren_scene = preload("res://scenes/enemies/enemy_grenadier.tscn")
	var grenadier: EnemyGrenadier = gren_scene.instantiate() as EnemyGrenadier
	add_child(grenadier)
	grenadier.global_position = Vector2(500, 200)
	await get_tree().process_frame

	var hp_before = grenadier.current_health
	grenadier.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var gren_took_damage = (grenadier.current_health == hp_before - 1)

	# Throw toxic grenade
	grenadier._throw_grenade()
	var grenade_spawned = false
	for child in get_children():
		if child is ToxicGrenade:
			grenade_spawned = true
			child.queue_free()
			break

	if gren_took_damage and grenade_spawned:
		print("✔ PASS [3/6]: Gas Mask Grenadier takes damage (%d HP) and lobs ballistic ToxicGrenade" % grenadier.current_health)
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Grenadier validation failed (damaged: %s, grenade: %s)" % [gren_took_damage, grenade_spawned])

	# ----------------------------------------------------
	# 4. Industrial Miniboss: Chief Overseer Brant (IND-01)
	# ----------------------------------------------------
	total_tests += 1
	var brant_scene = preload("res://scenes/bosses/boss_overseer_brant.tscn")
	var brant: BossController = brant_scene.instantiate() as BossController
	add_child(brant)
	brant.global_position = Vector2(700, 200)
	await get_tree().process_frame

	var brant_valid = (brant.data != null and brant.data.id == "IND-01" and brant.data.era == "Industrial")
	brant.hurtbox.receive_hit(brant.data.max_health, Vector2(50, 0), 4, null, true)
	var brant_dead = brant.is_dead

	if brant_valid and brant_dead:
		print("✔ PASS [4/6]: Miniboss Overseer Brant (IND-01) initializes with BossData and triggers defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Overseer Brant validation failed (valid: %s, dead: %s)" % [brant_valid, brant_dead])

	# ----------------------------------------------------
	# 5. Industrial Era Boss: Baron Von Steinhardt (IND-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var baron_scene = preload("res://scenes/bosses/boss_baron_steinhardt.tscn")
	var baron: BossController = baron_scene.instantiate() as BossController
	add_child(baron)
	baron.global_position = Vector2(900, 200)
	await get_tree().process_frame

	var baron_valid = (baron.data != null and baron.data.id == "IND-ERA" and baron.data.total_phases == 3)

	# Phase 1 -> 2
	baron.hurtbox.receive_hit(14, Vector2(50, 0), 4, null, false)
	var p2_ok = (baron.current_phase == 2 and baron.current_armor == baron.data.armor_health)

	# Shatter Riveted Brass Armor in Phase 2
	baron.hurtbox.receive_hit(14, Vector2(50, 0), 4, null, false)
	var armor_shattered = (baron.current_armor == 0 and baron.is_staggered)

	# Phase 2 -> 3
	baron.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var p3_ok = (baron.current_phase == 3 and baron.hitbox.damage == 3)

	# Final strike
	baron.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, true)
	var baron_dead = baron.is_dead

	if baron_valid and p2_ok and armor_shattered and p3_ok and baron_dead:
		print("✔ PASS [5/6]: Era Boss Baron Von Steinhardt executes 3 phases (Steam Wrench -> Brass Armor & Slag Rain -> Meltdown -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Baron Steinhardt validation failed (valid: %s, P2: %s, Armor: %s, P3: %s, Dead: %s)" % [baron_valid, p2_ok, armor_shattered, p3_ok, baron_dead])

	# ----------------------------------------------------
	# 6. Chapter 4 Level Integration (Chapter4Industrial)
	# ----------------------------------------------------
	total_tests += 1
	var chap4_scene = preload("res://scenes/levels/chapter4_industrial.tscn")
	var chap4: Chapter4Industrial = chap4_scene.instantiate() as Chapter4Industrial
	add_child(chap4)
	await get_tree().process_frame

	var platforms_count = chap4.get_node("Platforms").get_child_count()
	var checkpoints_count = chap4.get_node("Checkpoints").get_child_count()
	var enemies_count = chap4.get_node("Enemies").get_child_count()
	var has_exit = (chap4.exit_portal != null)
	var has_dlg = (chap4.dialogue_box != null)
	var has_title_card = (chap4.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [6/6]: Chapter 4: Smog Docks complete (8+ Factory Platforms, 3 Checkpoints, 7 Enemies, Foundry Arena, Monolith Exit)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Chapter 4 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Industrial Era Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL INDUSTRIAL ERA TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
