extends Node2D

## Automated Headless Integration Test Suite for ORIGIN SoundManager & Procedural Audio Engine.
## Validates:
## 1. SoundManager initialization, player pool, and dual crossfade channels
## 2. Core combat sound effects synthesis & waveform integrity
## 3. Enemy & Boss encounter audio synthesis
## 4. UI, Checkpoint, and Reality Glitch audio synthesis & signal emission
## 5. All 9 Era BGM loop themes synthesis, loop mode, and crossfade playback
## 6. Master, SFX, BGM volume control & mute toggles

func _ready() -> void:
	call_deferred("_run_audio_tests")

func _run_audio_tests() -> void:
	print("==================================================")
	print("  ORIGIN: Audio Engine & SoundManager Test Suite")
	print("==================================================")

	var tests_passed: int = 0
	var total_tests: int = 0

	# ----------------------------------------------------
	# 1. SoundManager Initialization & Pool Architecture
	# ----------------------------------------------------
	total_tests += 1
	var sm = SoundManager
	var sm_exists = (sm != null)
	var pool_size_valid = (sm._sfx_players.size() == SoundManager.SFX_POOL_SIZE)
	var bgm_players_valid = (sm._bgm_player_a != null and sm._bgm_player_b != null and sm._active_bgm_player != null)

	if sm_exists and pool_size_valid and bgm_players_valid:
		print("✔ PASS [1/6]: SoundManager autoload initialized with 10-player SFX pool and dual BGM crossfade channels")
		tests_passed += 1
	else:
		printerr("✘ FAIL [1/6]: SoundManager initialization failed (sm: %s, pool: %d, bgm: %s)" % [sm_exists, sm._sfx_players.size() if sm else 0, bgm_players_valid])

	# ----------------------------------------------------
	# 2. Combat & Movement SFX Synthesis
	# ----------------------------------------------------
	total_tests += 1
	var combat_sfx: Array[String] = [
		"slash_1", "slash_2", "slash_finisher",
		"parry", "block", "dodge", "jump",
		"hurt", "heal", "magic_cast", "switch_weapon"
	]
	var combat_all_valid: bool = true
	for sfx_name in combat_sfx:
		var stream = sm._get_or_create_sfx(sfx_name)
		if not stream or stream.get_length() <= 0.0 or stream.format != AudioStreamWAV.FORMAT_16_BITS:
			combat_all_valid = false
			printerr("Combat SFX failed: %s" % sfx_name)
			break

	if combat_all_valid:
		print("✔ PASS [2/6]: 11 Core Combat & Movement SFX synthesized with valid 16-bit PCM buffers (swipes, parry, heal, cast)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [2/6]: Combat SFX synthesis validation failed")

	# ----------------------------------------------------
	# 3. Enemy & Boss Encounter SFX Synthesis
	# ----------------------------------------------------
	total_tests += 1
	var encounter_sfx: Array[String] = ["enemy_hit", "enemy_die", "boss_roar", "boss_phase"]
	var encounter_all_valid: bool = true
	for sfx_name in encounter_sfx:
		var stream = sm._get_or_create_sfx(sfx_name)
		if not stream or stream.get_length() <= 0.0:
			encounter_all_valid = false
			printerr("Encounter SFX failed: %s" % sfx_name)
			break

	if encounter_all_valid:
		print("✔ PASS [3/6]: Enemy & Boss SFX synthesized (impact crunches, death dissolution, deep roar, alarm sweep)")
		tests_passed += 1
	else:
		printerr("✘ FAIL [3/6]: Enemy & Boss SFX synthesis validation failed")

	# ----------------------------------------------------
	# 4. UI, Checkpoint, and Glitch Audio & Signal Emission
	# ----------------------------------------------------
	total_tests += 1
	var signal_box: Array[String] = [""]
	var on_sfx = func(sfx_name: String):
		signal_box[0] = sfx_name

	sm.sfx_played.connect(on_sfx)
	sm.play_sfx("ui_confirm")
	await get_tree().process_frame

	var signal_ok = (signal_box[0] == "ui_confirm")
	var cp_stream = sm._get_or_create_sfx("checkpoint")
	var glitch_stream = sm._get_or_create_sfx("loop_glitch")
	var ui_all_valid = (signal_ok and cp_stream != null and glitch_stream != null)
	sm.sfx_played.disconnect(on_sfx)

	if ui_all_valid:
		print("✔ PASS [4/6]: UI, Checkpoint, and Reality Glitch audio synthesized and signal emissions verified")
		tests_passed += 1
	else:
		printerr("✘ FAIL [4/6]: UI & Glitch audio validation failed (signal: %s, cp: %s, glitch: %s)" % [signal_ok, cp_stream != null, glitch_stream != null])

	# ----------------------------------------------------
	# 5. Era BGM Loop Synthesis & Crossfading
	# ----------------------------------------------------
	total_tests += 1
	var eras: Array[String] = [
		"title", "prehistoric", "medieval", "historical",
		"industrial", "modern", "futuristic", "fortress", "epilogue"
	]
	var bgm_all_valid: bool = true
	for era_name in eras:
		var stream = sm._get_or_create_bgm(era_name)
		if not stream or stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or stream.get_length() < 3.0:
			bgm_all_valid = false
			printerr("BGM loop failed: %s" % era_name)
			break

	# Test BGM playback & transition
	sm.play_bgm("prehistoric", 0.05)
	await get_tree().process_frame
	var active_track_ok = (sm._current_bgm_name == "prehistoric" and sm._active_bgm_player.playing)

	sm.play_bgm("title", 0.05)
	await get_tree().process_frame
	var title_track_ok = (sm._current_bgm_name == "title" and sm._active_bgm_player.playing)

	if bgm_all_valid and active_track_ok and title_track_ok:
		print("✔ PASS [5/6]: All 9 Era BGM themes synthesized with forward seamless loop points & verified active crossfading")
		tests_passed += 1
	else:
		printerr("✘ FAIL [5/6]: Era BGM loop synthesis failed (all_valid: %s, active: %s, title: %s)" % [bgm_all_valid, active_track_ok, title_track_ok])

	# ----------------------------------------------------
	# 6. Volume Control & Mute Pipeline
	# ----------------------------------------------------
	total_tests += 1
	sm.set_sfx_volume(0.65)
	sm.set_bgm_volume(0.45)
	var vol_ok = (abs(sm.sfx_volume - 0.65) < 0.01 and abs(sm.bgm_volume - 0.45) < 0.01)

	sm.set_muted(true)
	var mute_ok = sm.is_muted
	# Playing SFX when muted should be no-op
	var mute_box: Array[bool] = [false]
	var mute_callback = func(_name): mute_box[0] = true
	sm.sfx_played.connect(mute_callback)
	sm.play_sfx("jump")
	sm.sfx_played.disconnect(mute_callback)
	var mute_blocked_ok = not mute_box[0]

	sm.set_muted(false)
	var unmute_ok = not sm.is_muted

	if vol_ok and mute_ok and mute_blocked_ok and unmute_ok:
		print("✔ PASS [6/6]: Volume control pipeline & mute toggles correctly govern SFX and BGM channels")
		tests_passed += 1
	else:
		printerr("✘ FAIL [6/6]: Volume and mute validation failed")

	# ----------------------------------------------------
	# Summary
	# ----------------------------------------------------
	print("==================================================")
	print("  Audio Engine Test Results: %d/%d Passed" % [tests_passed, total_tests])
	print("==================================================")

	if tests_passed == total_tests:
		print(">>> ALL AUDIO ENGINE TESTS PASSED <<<")
		get_tree().quit(0)
	else:
		printerr(">>> AUDIO ENGINE TESTS FAILED: %d/%d <<<" % [tests_passed, total_tests])
		get_tree().quit(1)
