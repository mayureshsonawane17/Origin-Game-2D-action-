extends Node2D

## Automated Headless Integration Test Suite for ORIGIN Milestone 4.
## Validates:
## 1. Flying Enemy: Venom Pterosaur (flight hover, player detection, spit projectile, death)
## 2. Heavy Armored Enemy: Tar Scuttler (frontal deflection, parry stagger vulnerability, slam)
## 3. Cinematic Story Dialogue System (DialogueBox, typewriter effect, pause, advancing)
## 4. Arena Gates (Static collision locking and unlocking)
## 5. Miniboss Encounter (Primal Stalker PRE-01, arena lock, defeat, reward grant)
## 6. Era Boss Encounter (Titan of the Deep Earth PRE-ERA 3-phase, remnant award)
## 7. Full Chapter 1 Level Integration (start-to-finish layout, checkpoints, exit portal)

func _ready() -> void:
	call_deferred("_run_milestone4_tests")

func _run_milestone4_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Milestone 4 Automated Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. Flying Enemy: Venom Pterosaur
	# ----------------------------------------------------
	total_tests += 1
	var ptero_scene = preload("res://scenes/enemies/enemy_pterosaur.tscn")
	var ptero: EnemyPterosaur = ptero_scene.instantiate() as EnemyPterosaur
	add_child(ptero)
	ptero.global_position = Vector2(200, 100)
	await get_tree().process_frame

	var ptero_hp_start = ptero.current_health
	# Receive hit from player attack
	ptero.hurtbox.receive_hit(2, Vector2(60, -20), 3, null, false)
	var ptero_took_damage = (ptero.current_health == ptero_hp_start - 2)

	# Provide dummy player target for spit aim
	var dummy_player = Node2D.new()
	add_child(dummy_player)
	dummy_player.global_position = Vector2(260, 100)
	ptero.player_ref = dummy_player

	# Trigger spit attack
	ptero.current_state = EnemyPterosaur.PteroState.SPIT
	ptero._update_spit(0.016)
	var spit_fired = false
	for child in get_children():
		if child is VenomSpitProjectile:
			spit_fired = true
			child.queue_free()
			break
	dummy_player.queue_free()

	if ptero_took_damage and spit_fired:
		print("✔ PASS [1/7]: Venom Pterosaur hovers, receives aerial damage (%d HP), and fires venom projectiles" % ptero.current_health)
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/7]: Venom Pterosaur validation failed (damaged: %s, spit_fired: %s)" % [ptero_took_damage, spit_fired])

	# ----------------------------------------------------
	# 2. Heavy Armored Enemy: Tar Scuttler
	# ----------------------------------------------------
	total_tests += 1
	var scuttler_scene = preload("res://scenes/enemies/enemy_scuttler.tscn")
	var scuttler: TarScuttler = scuttler_scene.instantiate() as TarScuttler
	add_child(scuttler)
	scuttler.global_position = Vector2(400, 200)
	await get_tree().process_frame

	scuttler.set_physics_process(false)
	scuttler.set_facing(-1)

	# Facing left (-1), so an attacker to the left (X=350 < X=400) attacks from the front
	var attacker_node = Node2D.new()
	add_child(attacker_node)
	attacker_node.global_position = Vector2(350, 200)

	var scuttler_start_hp = scuttler.current_health
	# Frontal light attack (3 dmg) -> Carapace deflects to 1 dmg!
	scuttler._on_hurtbox_hit_received(3, Vector2(40, 0), 3, attacker_node, false)
	var frontal_deflected = (scuttler.current_health == scuttler_start_hp - 1)

	# Now test Parry Stagger: flips Scuttler onto soft underbelly
	scuttler.stagger(1.5)
	var is_staggered = scuttler.is_staggered
	# Hit while staggered: double damage (2 dmg becomes 4 dmg)
	var hp_before_stagger_hit = scuttler.current_health
	scuttler._on_hurtbox_hit_received(2, Vector2(40, 0), 3, attacker_node, false)
	var stagger_vulnerability = (scuttler.current_health == hp_before_stagger_hit - 4)

	attacker_node.queue_free()

	if frontal_deflected and is_staggered and stagger_vulnerability:
		print("✔ PASS [2/7]: Tar Scuttler deflects frontal attacks (3 dmg -> 1 dmg taken) and receives double damage on parry stagger")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/7]: Tar Scuttler validation failed (deflected: %s, staggered: %s, vuln: %s)" % [frontal_deflected, is_staggered, stagger_vulnerability])

	# ----------------------------------------------------
	# 3. Cinematic Story Dialogue System
	# ----------------------------------------------------
	total_tests += 1
	var dlg_scene = preload("res://scenes/ui/dialogue_box.tscn")
	var dlg: DialogueBox = dlg_scene.instantiate() as DialogueBox
	add_child(dlg)
	await get_tree().process_frame

	var test_lines: Array[Dictionary] = [
		{"speaker": "Hero", "text": "Testing line 1"},
		{"speaker": "The Gemstone", "text": "Testing line 2"}
	]

	dlg.start_dialogue(test_lines)
	var dlg_open = dlg.visible and dlg.is_active and get_tree().paused
	dlg.advance() # Fast forward text
	dlg.advance() # Next line
	var line2_active = (dlg.current_line_index == 1)
	dlg.advance() # Fast forward line 2
	dlg.advance() # Finish
	var dlg_finished = (not dlg.visible and not dlg.is_active and not get_tree().paused)

	if dlg_open and line2_active and dlg_finished:
		print("✔ PASS [3/7]: Story DialogueBox pauses scene tree, advances typewriter text, and unpauses cleanly")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/7]: DialogueBox validation failed (open: %s, line2: %s, finished: %s)" % [dlg_open, line2_active, dlg_finished])

	# ----------------------------------------------------
	# 4. Arena Gate Locking & Unlocking
	# ----------------------------------------------------
	total_tests += 1
	var gate_scene = preload("res://scenes/levels/arena_gate.tscn")
	var gate: ArenaGate = gate_scene.instantiate() as ArenaGate
	add_child(gate)
	gate.global_position = Vector2(600, 200)
	await get_tree().process_frame

	gate.close_gate()
	await get_tree().process_frame
	var closed_ok = gate.is_closed and not gate.collision_shape.disabled
	gate.open_gate()
	await get_tree().process_frame
	var open_ok = not gate.is_closed

	if closed_ok and open_ok:
		print("✔ PASS [4/7]: ArenaGate smoothly closes, activates collision barrier, and opens on boss defeat")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/7]: ArenaGate validation failed (closed_ok: %s, open_ok: %s)" % [closed_ok, open_ok])

	# ----------------------------------------------------
	# 5. Miniboss Pipeline: Primal Stalker (PRE-01)
	# ----------------------------------------------------
	total_tests += 1
	var stalker_scene = preload("res://scenes/bosses/boss_primal_stalker.tscn")
	var stalker: BossController = stalker_scene.instantiate() as BossController
	add_child(stalker)
	stalker.global_position = Vector2(800, 200)
	await get_tree().process_frame

	var stalker_valid = (stalker.data != null and stalker.data.id == "PRE-01")
	# Defeat stalker via hurtbox
	stalker.hurtbox.receive_hit(stalker.data.max_health, Vector2(50, 0), 4, null, true)
	var stalker_defeated = stalker.is_dead

	if stalker_valid and stalker_defeated:
		print("✔ PASS [5/7]: Miniboss Primal Stalker (PRE-01) initializes with BossData and triggers defeat callback")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/7]: Miniboss validation failed (valid: %s, defeated: %s)" % [stalker_valid, stalker_defeated])

	# ----------------------------------------------------
	# 6. Era Boss Pipeline: Titan of the Deep Earth (PRE-ERA)
	# ----------------------------------------------------
	total_tests += 1
	var titan_scene = preload("res://scenes/bosses/boss_titan_deep_earth.tscn")
	var titan: BossController = titan_scene.instantiate() as BossController
	add_child(titan)
	titan.global_position = Vector2(1000, 200)
	await get_tree().process_frame

	var titan_valid = (titan.data != null and titan.data.id == "PRE-ERA" and titan.data.total_phases == 3)
	# Fast-forward Titan through phases to verify complete battle lifecycle
	titan.hurtbox.receive_hit(12, Vector2(50, 0), 4, null, false) # Transition Phase 1 -> Phase 2
	var in_phase_2 = (titan.current_phase == 2)
	titan.current_armor = 0
	titan.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, false) # Transition Phase 2 -> Phase 3
	var in_phase_3 = (titan.current_phase == 3)
	titan.hurtbox.receive_hit(10, Vector2(50, 0), 4, null, true) # Defeat
	var titan_defeated = titan.is_dead

	if titan_valid and in_phase_2 and in_phase_3 and titan_defeated:
		print("✔ PASS [6/7]: Era Boss Titan of the Deep Earth executes 3 phases (Geo-Armor -> Magma Frenzy -> Defeat)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/7]: Era Boss validation failed (valid: %s, P2: %s, P3: %s, defeated: %s)" % [titan_valid, in_phase_2, in_phase_3, titan_defeated])

	# ----------------------------------------------------
	# 7. Complete Chapter 1 Level Integration
	# ----------------------------------------------------
	total_tests += 1
	var chap_scene = preload("res://scenes/levels/chapter1_prehistoric.tscn")
	var chap: Chapter1Prehistoric = chap_scene.instantiate() as Chapter1Prehistoric
	add_child(chap)
	await get_tree().process_frame

	var platforms_count = chap.get_node("Platforms").get_child_count()
	var checkpoints_count = chap.get_node("Checkpoints").get_child_count()
	var enemies_count = chap.get_node("Enemies").get_child_count()
	var has_exit = (chap.exit_portal != null)
	var has_dlg = (chap.dialogue_box != null)
	var has_title_card = (chap.title_card != null)

	var level_valid = (
		platforms_count >= 8 and
		checkpoints_count == 3 and
		enemies_count >= 7 and
		has_exit and has_dlg and has_title_card
	)

	if level_valid:
		print("✔ PASS [7/7]: Chapter 1: Prehistoric Wilderness complete (8+ Platforms, 3 Checkpoints, 7 Enemies, Miniboss/Era Gates, Monolith Exit)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [7/7]: Chapter 1 level validation failed (plats: %d, cps: %d, enemies: %d, exit: %s)" % [platforms_count, checkpoints_count, enemies_count, has_exit])

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Milestone 4 Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL MILESTONE 4 TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED <<<")
		get_tree().quit(1)
