class_name Chapter2Medieval
extends Node2D

## Chapter 2: Castle of the Cursed Keep (Milestone 5).
## Full chapter level integrating Medieval enemies (Footman, Crossbow),
## Miniboss (Sir Gareth the Ironclad MED-01), 3-Phase Era Boss (Lord Malakor MED-ERA),
## checkpoints, story dialogue, and the second Era Key Item (Medieval Remnant).

const BOSS_GARETH_SCENE = preload("res://scenes/bosses/boss_sir_gareth.tscn")
const BOSS_MALAKOR_SCENE = preload("res://scenes/bosses/boss_lord_malakor.tscn")

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

# Markers & Exits
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

	# Initial camera bounds (entire chapter)
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 2650
		player.camera.limit_bottom = 290

	exit_portal.body_entered.connect(_on_exit_portal_entered)

	await get_tree().create_timer(0.6).timeout
	if not miniboss_triggered:
		_play_opening_dialogue()

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return

	# Bottomless pit kill plane
	if player.global_position.y > 290.0:
		player.is_dead = true
		player.player_died.emit()
		ResetManager.trigger_reset("fall_into_castle_moat")
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
		{"speaker": "Hero", "text": "The gemstone dragged me centuries forward... into an age of stone and cold steel."},
		{"speaker": "The Gemstone", "text": "A fortress of despair. Countless knights have perished here in repetition."},
		{"speaker": "Hero", "text": "I don't care how deep this castle goes. I am tearing it down."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_miniboss_encounter() -> void:
	miniboss_triggered = true
	miniboss_gate_left.close_gate()
	miniboss_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1180
		player.camera.limit_right = 1620

	active_boss = BOSS_GARETH_SCENE.instantiate() as BossController
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

	if player and player.camera:
		player.camera.limit_left = 1180
		player.camera.limit_right = 2650

	# Award Knight Crest + 1 Skill Point
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(1)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_gareth_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The gatekeeper has fallen. The inner keep lies ahead."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_era_boss_encounter() -> void:
	era_boss_triggered = true
	era_gate_left.close_gate()
	era_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1980
		player.camera.limit_right = 2650

	active_boss = BOSS_MALAKOR_SCENE.instantiate() as BossController
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

	# Award Medieval Remnant + 3 Skill Points + Save
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(3)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_medieval_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The Iron Bastion crumbles. The Medieval Remnant is ours."},
		{"speaker": "The Gemstone", "text": "ANOMALY PROPAGATING. TWO REMNANTS DETECTED. THE FABRIC FRACTURES..."}
	]
	dialogue_box.start_dialogue(lines)

const NEXT_CHAPTER_SCENE_PATH = "res://scenes/levels/chapter3_historical.tscn"

func _on_exit_portal_entered(body: Node) -> void:
	if body is Player and era_boss_defeated and not chapter_completed:
		chapter_completed = true
		if SaveManager:
			SaveManager.unlock_chapter(3)
		_show_chapter_complete()

func _show_chapter_complete() -> void:
	chapter_reward_label.text = "REWARDS CLAIMED:\n• Knight Crest (Miniboss)\n• Medieval Remnant (Era 2 Key Shard)\n• +4 Total Skill Points\n\nLoop Counter: #%d" % ResetManager.reset_count
	chapter_complete_panel.visible = true

func _on_replay_chapter_pressed() -> void:
	advance_to_next_chapter()

func advance_to_next_chapter() -> void:
	if SaveManager:
		SaveManager.unlock_chapter(3)
		SaveManager.save_game(Vector2.ZERO, NEXT_CHAPTER_SCENE_PATH, "cp_ch3_start")
	if ResourceLoader.exists(NEXT_CHAPTER_SCENE_PATH):
		get_tree().change_scene_to_file(NEXT_CHAPTER_SCENE_PATH)
	else:
		ResetManager.trigger_reset("chapter_advance_fallback")

func _unhandled_input(event: InputEvent) -> void:
	if chapter_complete_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			advance_to_next_chapter()
