class_name Chapter7Fortress
extends Node2D

## Chapter 7: The Fortress of the Gemstone & The Unbeatable One (Milestone 6).
## Implements the climax from docs/STORY.md:
## 1. Confrontation at the crystal barrier trapping the Hero's wife.
## 2. Reveal of the endless repeating loop powered by the Hero's determination.
## 3. Battle against the Immortal Villain (health bar: IMMORTAL — NO WEAKNESS DETECTED).
## 4. Deliberate reset mechanic causing reality destabilization (frozen enemies, merged eras).
## 5. Hero's line: "That's the problem. I kept playing your game."
## 6. Gemstone cracking and transition to collapsing reality escape run.

const BOSS_VILLAIN_SCENE = preload("res://scenes/bosses/boss_villain_immortal.tscn")
const ESCAPE_SCENE_PATH = "res://scenes/levels/escape_collapse.tscn"

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var title_card: BossTitleCard = $BossTitleCard
@onready var boss_health_bar: BossHealthBar = $CanvasLayer/BossHealthBar
@onready var glitch_overlay = $GlitchOverlay
@onready var arena_gate_left: ArenaGate = $ArenaGates/GateLeft
@onready var arena_gate_right: ArenaGate = $ArenaGates/GateRight
@onready var boss_spawn: Marker2D = $Markers/BossSpawn
@onready var frozen_enemies_group: Node2D = $FrozenEnemies
@onready var merged_eras_group: Node2D = $MergedEraFragments
@onready var deliberate_reset_btn: Button = $CanvasLayer/DeliberateResetButton

var active_boss: BossVillainImmortal
var battle_started: bool = false
var deliberate_resets: int = 0
var story_in_progress: bool = false

func _ready() -> void:
	boss_health_bar.visible = false
	frozen_enemies_group.visible = false
	merged_eras_group.visible = false
	deliberate_reset_btn.visible = false
	deliberate_reset_btn.pressed.connect(_on_deliberate_reset_pressed)

	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 2950
		player.camera.limit_bottom = 290

	await get_tree().create_timer(0.6).timeout
	_play_opening_truth_dialogue()

func _play_opening_truth_dialogue() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "The Villain", "text": "You finally made it here. Again."},
		{"speaker": "The Villain", "text": "You have repeated this journey thousands of times, and every victory has reset reality, making the gemstone stronger."},
		{"speaker": "The Villain", "text": "You were never meant to escape; your endless determination to save your wife was the very thing powering your prison."},
		{"speaker": "Hero", "text": "No... my determination... was your fuel?!"},
		{"speaker": "The Villain", "text": "Now strike me if you dare. Let the cycle continue for all eternity!"}
	]
	dialogue_box.dialogue_finished.connect(_start_boss_battle, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(lines)

func _start_boss_battle() -> void:
	battle_started = true
	arena_gate_left.close_gate()
	arena_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1200
		player.camera.limit_right = 2000

	active_boss = BOSS_VILLAIN_SCENE.instantiate() as BossVillainImmortal
	active_boss.global_position = boss_spawn.global_position
	add_child(active_boss)
	active_boss.mock_triggered.connect(_on_villain_mock)
	active_boss.villain_begs_fight.connect(_on_villain_begs_fight)

	title_card.intro_finished.connect(func():
		boss_health_bar.bind_boss(active_boss)
		deliberate_reset_btn.visible = true
	, CONNECT_ONE_SHOT)
	title_card.play_intro(active_boss.data)

func _on_villain_mock(quote: String) -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "The Villain", "text": quote},
		{"speaker": "Hero", "text": "My attacks do nothing... I cannot win by following the rules of this world."}
	]
	dialogue_box.start_dialogue(lines)

func _on_villain_begs_fight() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "The Villain", "text": "Stop this! Fight me! What are you doing?!"}
	]
	dialogue_box.start_dialogue(lines)

func _on_deliberate_reset_pressed() -> void:
	trigger_deliberate_reset()

func trigger_deliberate_reset() -> void:
	deliberate_resets += 1
	ResetManager.trigger_reset("deliberate_loop_break_%d" % deliberate_resets, false)
	
	if active_boss:
		active_boss.set_instability(deliberate_resets)

	match deliberate_resets:
		1:
			# Reality glitches, prior enemies freeze in place
			glitch_overlay.set_glitch_level(1)
			frozen_enemies_group.visible = true
			var lines: Array[Dictionary] = [
				{"speaker": "The Gemstone", "text": "WARNING: REALITY INSTABILITY DETECTED. TEMPORAL FRAMES DESYNCHRONIZING..."},
				{"speaker": "Hero", "text": "It's working. The rules are bending."}
			]
			dialogue_box.start_dialogue(lines)

		2:
			# Levels merge: fragments from all 6 eras appear
			glitch_overlay.set_glitch_level(2)
			merged_eras_group.visible = true
			var lines: Array[Dictionary] = [
				{"speaker": "The Villain", "text": "Stop this! Fight me! What are you doing?!"},
				{"speaker": "The Gemstone", "text": "CRITICAL: SIX ERAS COLLAPSING INTO FRAGMENTS. ANCHOR FAILING."}
			]
			dialogue_box.start_dialogue(lines)

		3:
			# Hero delivers the verbatim fixed line from docs/STORY.md
			glitch_overlay.set_glitch_level(3)
			var lines: Array[Dictionary] = [
				{"speaker": "The Villain", "text": "Why won't you fight?! Face me like you always do!"},
				{"speaker": "Hero", "text": "That's the problem. I kept playing your game."}
			]
			dialogue_box.dialogue_finished.connect(_trigger_final_gemstone_shatter, CONNECT_ONE_SHOT)
			dialogue_box.start_dialogue(lines)

		4:
			_trigger_final_gemstone_shatter()

func _trigger_final_gemstone_shatter() -> void:
	glitch_overlay.set_glitch_level(4)
	if active_boss:
		active_boss.set_instability(4)

	await get_tree().create_timer(1.2).timeout
	var lines: Array[Dictionary] = [
		{"speaker": "The Gemstone", "text": "ERROR: CORE FRACTURE. REALITY COLLAPSE IMMINENT. ESCAPE THE PRISON."}
	]
	dialogue_box.dialogue_finished.connect(_transition_to_escape_collapse, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(lines)

func _transition_to_escape_collapse() -> void:
	if ResourceLoader.exists(ESCAPE_SCENE_PATH):
		get_tree().change_scene_to_file(ESCAPE_SCENE_PATH)
	else:
		print("[Chapter7] Transitioning to collapse escape run")

func _unhandled_input(event: InputEvent) -> void:
	if battle_started and not dialogue_box.visible:
		# 'R' key or deliberate reset trigger
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			trigger_deliberate_reset()
