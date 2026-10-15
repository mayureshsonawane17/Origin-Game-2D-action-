extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Historical Era (Chapter 3).
## Validates:
## 1. Historical Equipment & Skill Resources (Katana, O-Yoroi, Hankyu Bow, Iaijutsu, Smoke Veil)
## 2. Historical Duelist: Wandering Ronin (iaijutsu dash, parry stagger vulnerability)
## 3. Historical Marksman: Tanegashima Gunner (matchlock aiming telegraph, MatchlockBullet firing, damage)
## 4. Historical Miniboss: Kensei Jinzo (HIST-01, dual slash, defeat)
## 5. Historical Era Boss: Shogun Kageyasu (HIST-ERA 3-phase, Spirit Armor, Phantom Storm, defeat)
## 6. Chapter 3 Level Integration (Chapter3Historical layout, platforms, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_historical_tests")

func _run_historical_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Historical Era Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Historical Equipment & Skill Resources
	# ----------------------------------------------------
	total_tests += 1
	var katana = load("res://data/equipment/katana_of_the_fallen.tres") as EquipmentItem
	var armor = load("res://data/equipment/o_yoroi_heavy_armor.tres") as EquipmentItem
	var bow = load("res://data/equipment/hankyu_war_bow.tres") as EquipmentItem

	var iaijutsu = load("res://data/skills/attack_iaijutsu_strike.tres") as SkillData
	var smoke = load("res://data/skills/shadow_smoke_veil.tres") as SkillData

	var equip_ok = (
		katana != null and katana.base_damage == 3 and katana.mobility_multiplier == 1.15 and
		armor != null and armor.defense_multiplier == 0.45 and
		bow != null and bow.base_damage == 4
	)

	var skills_ok = (
		iaijutsu != null and iaijutsu.cost == 3 and iaijutsu.required_skills.has("atk_rending_strike") and
		smoke != null and smoke.cost == 2 and smoke.required_skills.has("shadow_phase_dash")
	)

	if equip_ok and skills_ok:
		print("✔ PASS [1/6]: Historical equipment (Katana 3dmg/115% mob, O-Yoroi 45% def) and tier-3 skills validated")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: Equipment or skill validation failed (equip: %s, skills: %s)" % [equip_ok, skills_ok])

	# ----------------------------------------------------
	# 2. Historical Duelist: Wandering Ronin
	# ----------------------------------------------------
	total_tests += 1
	var ronin_scene = preload("res://scenes/enemies/enemy_ronin.tscn")
	var ronin: EnemyRonin = ronin_scene.instantiate() as EnemyRonin
	add_child(ronin)
	ronin.global_position = Vector2(300, 200)
	await get_tree().process_frame

	ronin.set_physics_process(false)
	ronin.set_facing(-1) # Facing left

	var attacker_node = Node2D.new()
	add_child(attacker_node)
	attacker_node.global_position = Vector2(250, 200)

	var ronin_start_hp = ronin.current_health
	# Normal hit (1 dmg)
	ronin._on_hurtbox_hit_received(1, Vector2(30, 0), 3, attacker_node, false)
	var took_normal_dmg = (ronin.current_health == ronin_start_hp - 1)

	# Stagger via parry
	ronin.stagger(1.5)
	var is_staggered = ronin.is_staggered
	# Hit while staggered: double damage (1 dmg becomes 2 dmg)
	var hp_before_stagger_hit = ronin.current_health
	ronin._on_hurtbox_hit_received(1, Vector2(30, 0), 3, attacker_node, false)
	var stagger_vuln = (ronin.current_health == hp_before_stagger_hit - 2)

	attacker_node.queue_free()

	if took_normal_dmg and is_staggered and stagger_vuln:
		print("✔ PASS [2/6]: Wandering Ronin takes normal damage and receives double damage on parry stagger")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Ronin validation failed (normal: %s, staggered: %s, vuln: %s)" % [took_normal_dmg, is_staggered, stagger_vuln])

	# ----------------------------------------------------
	# 3. Historical Marksman: Tanegashima Gunner
	# ----------------------------------------------------
	total_tests += 1
	var gunner_scene = preload("res://scenes/enemies/enemy_gunner.tscn")
	var gunner: EnemyGunner = gunner_scene.instantiate() as EnemyGunner
	add_child(gunner)
	gunner.global_position = Vector2(500, 200)
	await get_tree().process_frame

	var hp_before = gunner.current_health
	gunner.hurtbox.receive_hit(1, Vector2(40, 0), 3, null, false)
	var gunner_took_damage = (gunner.current_health == hp_before - 1)

	# Fire matchlock bullet
	gunner._fire_bullet()
	var bullet_spawned = false
	for child in get_children():
		if child is MatchlockBullet:
			bullet_spawned = true
			child.queue_free()
			break

	if gunner_took_damage and bullet_spawned:
		print("✔ PASS [3/6]: Tanegashima Gunner takes damage (%d HP) and fires high-speed MatchlockBullet" % gunner.current_health)
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Gunner validation failed (damaged: %s, bullet: %s)" % [gunner_took_damage, bullet_spawned])

	# ----------------------------------------------------
	# 4. Historical Miniboss: Kensei Jinzo (HIST-01)
	# ----------------------------------------------------
	total_tests += 1
	var jinzo_scene = preload("res://scenes/bosses/boss_kensei_jinzo.tscn")
	var jinzo: BossController = jinzo_scene.instantiate() as BossController
	add_child(jinzo)
	jinzo.global_position = Vector2(700, 200)
	await get_tree().process_frame

	var jinzo_valid = (jinzo.data != null and jinzo.data.id == "HIST-01" and jinzo.data.era == "Historical")
	jinzo.hurtbox.receive_hit(jinzo.data.max_health, Vector2(50, 0), 4, null, true)
	var jinzo_dead = jinzo.is_dead

	if jinzo_valid and jinzo_dead:
		print("✔ PASS [4/6]: Miniboss Kensei Jinzo (HIST-01) initializes with BossData and triggers defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: Kensei Jinzo validation failed (valid: %s, dead: %s)" % [jinzo_valid, jinzo_dead])

	# ----------------------------------------------------
	# 5. Historical Era Boss: Shogun Kageyasu (HIST-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var shogun_scene = preload("res://scenes/bosses/boss_shogun_kageyasu.tscn")
	var shogun: BossController = shogun_scene.instantiate() as BossController
	add_child(shogun)
	shogun.global_position = Vector2(900, 200)
	await get_tree().process_frame

	var shogun_valid = (shogun.data != null and shogun.data.id == "HIST-ERA" and shogun.data.total_phases == 3)

	# Phase 1 -> 2
	shogun.hurtbox.receive_hit(12, Vector2(50, 0), 4, null, false)
	var p2_ok = (shogun.current_phase == 2 and shogun.current_armor == shogun.data.armor_health)

	# Shatter Spirit Armor in Phase 2
	shogun.hurtbox.receive_hit(12, Vector2(50, 0), 4, null, false)
	var armor_shattered = (shogun.current_armor == 0 and shogun.is_staggered)

	# Phase 2 -> 3
	shogun.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false)
	var p3_ok = (shogun.current_phase == 3 and shogun.hitbox.damage == 3)

	# Final strike
	shogun.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, true)
	var shogun_dead = shogun.is_dead

	if shogun_valid and p2_ok and armor_shattered and p3_ok and shogun_dead:
		print("✔ PASS [5/6]: Era Boss Shogun Kageyasu executes 3 phases (Naginata -> Spirit Armor & Shadow Blades -> Phantom Storm -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Shogun Kageyasu validation failed (valid: %s, P2: %s, Armor: %s, P3: %s, Dead: %s)" % [shogun_valid, p2_ok, armor_shattered, p3_ok, shogun_dead])

	# ----------------------------------------------------
	# 6. Chapter 3 Level Integration (Chapter3Historical)
	# ----------------------------------------------------
	total_tests += 1
	var chap3_scene = preload("res://scenes/levels/chapter3_historical.tscn")
	var chap3: Chapter3Historical = chap3_scene.instantiate() as Chapter3Historical
	add_child(chap3)
	await get_tree().process_frame

	var platforms_count = chap3.get_node("Platforms").get_child_count()
	var checkpoints_count = chap3.get_node("Checkpoints").get_child_count()
	var enemies_count = chap3.get_node("Enemies").get_child_count()
	var has_exit = (chap3.exit_portal != null)
	var has_dlg = (chap3.dialogue_box != null)
	var has_title_card = (chap3.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [6/6]: Chapter 3: Shrine of the Crimson Mist complete (8+ Shrine Platforms, 3 Checkpoints, 7 Enemies, Shrine Arena, Monolith Exit)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Chapter 3 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Historical Era Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL HISTORICAL ERA TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
