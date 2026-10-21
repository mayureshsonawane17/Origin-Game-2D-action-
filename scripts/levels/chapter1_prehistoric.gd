class_name Chapter1Prehistoric
extends Node2D

## Chapter 1: Prehistoric Wilderness (Milestone 4).
## Full chapter level integrating multiple enemy types, Miniboss (Primal Stalker),
## 3-Phase Era Boss (Titan of the Deep Earth), checkpoints, story dialogue, and rewards.

const BOSS_STALKER_SCENE = preload("res://scenes/bosses/boss_primal_stalker.tscn")
const BOSS_TITAN_SCENE = preload("res://scenes/bosses/boss_titan_deep_earth.tscn")
const CHALLENGE_PORTAL_SCENE = preload("res://scenes/levels/challenge_portal.tscn")

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var title_card: BossTitleCard = $BossTitleCard
@onready var boss_health_bar: BossHealthBar = $CanvasLayer/BossHealthBar

# Arena Gates
@onready var miniboss_gate_left: ArenaGate = $MinibossGates/GateLeft
@onready var miniboss_gate_right: ArenaGate = $MinibossGates/GateRight
@onready var era_gate_left: ArenaGate = $EraGates/GateLeft
@onready var era_gate_right: ArenaGate = $EraGates/GateRight

# Triggers & Markers
@onready var miniboss_spawn: Marker2D = $Markers/MinibossSpawn
@onready var era_boss_spawn: Marker2D = $Markers/EraBossSpawn
@onready var exit_portal: Area2D = $ExitPortal
@onready var chapter_complete_panel: Control = $CanvasLayer/ChapterCompletePanel
@onready var chapter_reward_label: Label = $CanvasLayer/ChapterCompletePanel/Center/VBox/RewardLabel

var miniboss_triggered: bool = false
var miniboss_defeated: bool = false
var era_boss_triggered: bool = false
var era_boss_defeated: bool = false
var chapter_completed: bool = false

var active_boss: BossController

func _ready() -> void:
	chapter_complete_panel.visible = false
	boss_health_bar.visible = false
	if SoundManager:
		SoundManager.play_bgm("prehistoric")

	# Initial camera bounds (entire chapter)
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 2650
		player.camera.limit_bottom = 290

	exit_portal.body_entered.connect(_on_exit_portal_entered)
	_spawn_challenge_portal()

	# Trigger opening dialogue sequence after a brief beat
	await get_tree().create_timer(0.6).timeout
	if not miniboss_triggered:
		_play_opening_dialogue()

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return

	# Fall into pit
	if player.global_position.y > 290.0:
		player.is_dead = true
		player.player_died.emit()
		ResetManager.trigger_reset("fall_into_abyss")
		return

	var px = player.global_position.x

	# Miniboss Arena Trigger (Zone 3: X: 1240)
	if not miniboss_triggered and px >= 1240.0 and px < 1550.0:
		_trigger_miniboss_encounter()

	# Era Boss Arena Trigger (Zone 5: X: 2040)
	if not era_boss_triggered and px >= 2040.0 and px < 2550.0:
		_trigger_era_boss_encounter()

func _play_opening_dialogue() -> void:
	var lines = [
		{"speaker": "Hero", "text": "The crystal... I can feel its pulse vibrating through the ancient earth."},
		{"speaker": "Hero", "text": "I will find you. No matter how many resets it takes to tear through this prison."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_miniboss_encounter() -> void:
	miniboss_triggered = true
	miniboss_gate_left.close_gate()
	miniboss_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1180
		player.camera.limit_right = 1620

	active_boss = BOSS_STALKER_SCENE.instantiate() as BossController
	active_boss.global_position = miniboss_spawn.global_position
	add_child(active_boss)
	active_boss.boss_defeated.connect(_on_miniboss_defeated)

	title_card.intro_finished.connect(func():
		boss_health_bar.bind_boss(active_boss)
	, CONNECT_ONE_SHOT)
	title_card.play_intro(active_boss.data)

func _on_miniboss_defeated() -> void:
	miniboss_defeated = true
	miniboss_gate_right.open_gate()

	# Restore camera limits toward next zone
	if player and player.camera:
		player.camera.limit_left = 1180
		player.camera.limit_right = 2650

	# Award Hunter Fang + 1 Skill Point
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(1)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_miniboss_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "The Gemstone", "text": "...Another apex beast felled. The repeating loop churns and tightens..."},
		{"speaker": "Hero", "text": "The path forward opens into the obsidian caverns. Keep moving."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_era_boss_encounter() -> void:
	era_boss_triggered = true
	era_gate_left.close_gate()
	era_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1980
		player.camera.limit_right = 2650

	active_boss = BOSS_TITAN_SCENE.instantiate() as BossController
	active_boss.global_position = era_boss_spawn.global_position
	add_child(active_boss)
	active_boss.boss_defeated.connect(_on_era_boss_defeated)

	title_card.intro_finished.connect(func():
		boss_health_bar.bind_boss(active_boss)
	, CONNECT_ONE_SHOT)
	title_card.play_intro(active_boss.data)

func _on_era_boss_defeated() -> void:
	era_boss_defeated = true
	era_gate_right.open_gate()

	# Award Prehistoric Remnant + 3 Skill Points + Save
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(3)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_prehistoric_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The earth trembles... and the Prehistoric Remnant breaks free from the stone."},
		{"speaker": "Hero", "text": "One shard closer to shattering this prison once and for all."},
		{"speaker": "The Gemstone", "text": "WARNING: ANOMALY DETECTED IN ERA 01. TEMPORAL GATEWAY ENGAGING..."}
	]
	dialogue_box.start_dialogue(lines)

const NEXT_CHAPTER_SCENE_PATH = "res://scenes/levels/chapter2_medieval.tscn"

func _on_exit_portal_entered(body: Node) -> void:
	if body is Player and era_boss_defeated and not chapter_completed:
		chapter_completed = true
		if SaveManager:
			SaveManager.unlock_chapter(2)
		_show_chapter_complete()

func _show_chapter_complete() -> void:
	chapter_reward_label.text = "REWARDS CLAIMED:\n• Hunter Fang (Miniboss)\n• Prehistoric Remnant (Era 1 Key Shard)\n• +4 Total Skill Points\n\nLoop Counter: #%d" % ResetManager.reset_count
	chapter_complete_panel.visible = true

func _on_replay_chapter_pressed() -> void:
	advance_to_next_chapter()

func advance_to_next_chapter() -> void:
	if SaveManager:
		SaveManager.unlock_chapter(2)
		SaveManager.save_game(Vector2.ZERO, NEXT_CHAPTER_SCENE_PATH, "cp_ch2_start")
	if ResourceLoader.exists(NEXT_CHAPTER_SCENE_PATH):
		get_tree().change_scene_to_file(NEXT_CHAPTER_SCENE_PATH)
	else:
		ResetManager.trigger_reset("chapter_advance_fallback")

func _unhandled_input(event: InputEvent) -> void:
	if chapter_complete_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			advance_to_next_chapter()

func _spawn_challenge_portal() -> void:
	var portal = CHALLENGE_PORTAL_SCENE.instantiate()
	portal.global_position = Vector2(580, 230)
	portal.target_boss_type = "mud_golem"
	portal.portal_era = "Prehistoric"
	portal.required_relic_id = "clay_core"
	portal.portal_color = Color(0.85, 0.5, 0.2, 1.0)
	add_child(portal)

