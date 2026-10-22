class_name Chapter3Historical
extends Node2D

## Chapter 3: Shrine of the Crimson Mist (Historical Era).
## Full chapter level integrating Historical enemies (Ronin, Gunner),
## Miniboss (Kensei Jinzo HIST-01), 3-Phase Era Boss (Shogun Kageyasu HIST-ERA),
## checkpoints, story dialogue, and the third Era Key Item (Historical Remnant).

const BOSS_JINZO_SCENE = preload("res://scenes/bosses/boss_kensei_jinzo.tscn")
const BOSS_SHOGUN_SCENE = preload("res://scenes/bosses/boss_shogun_kageyasu.tscn")
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
	if SoundManager:
		SoundManager.play_bgm("historical")

	# Initial camera bounds (entire chapter)
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 2900
		player.camera.limit_bottom = 290

	exit_portal.body_entered.connect(_on_exit_portal_entered)
	_spawn_challenge_portal()

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
		ResetManager.trigger_reset("fall_into_ravine")
		return

	var px = player.global_position.x

	# Miniboss Arena Trigger (Zone 3: X: 1300)
	if not miniboss_triggered and px >= 1300.0 and px < 1650.0:
		_trigger_miniboss_encounter()

	# Era Boss Arena Trigger (Zone 5: X: 2150)
	if not era_boss_triggered and px >= 2150.0 and px < 2750.0:
		_trigger_era_boss_encounter()

func _play_opening_dialogue() -> void:
	var lines = [
		{"speaker": "Hero", "text": "A misty mountain shrine... another era woven into this endless prison."},
		{"speaker": "The Gemstone", "text": "A land of blade and blood. Their devotion to duty mirrors your own futile quest."},
		{"speaker": "Hero", "text": "I will cut through every phantom until I reach her."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_miniboss_encounter() -> void:
	miniboss_triggered = true
	miniboss_gate_left.close_gate()
	miniboss_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1240
		player.camera.limit_right = 1720

	active_boss = BOSS_JINZO_SCENE.instantiate() as BossController
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
		player.camera.limit_left = 1240
		player.camera.limit_right = 2900

	# Award Kensei Tsuba + 1 Skill Point
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(1)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_jinzo_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The swordmaster bows and vanishes into mist. The inner shrine gate is open."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_era_boss_encounter() -> void:
	era_boss_triggered = true
	era_gate_left.close_gate()
	era_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 2080
		player.camera.limit_right = 2900

	active_boss = BOSS_SHOGUN_SCENE.instantiate() as BossController
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

	# Award Historical Remnant + 3 Skill Points + Save
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(3)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_historical_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The Shadow Sovereign has fallen. The Historical Remnant resonates with the other two."},
		{"speaker": "The Gemstone", "text": "REALITY MATRIX OSCILLATING. THREE REMNANTS RECOVERED. WHY DO YOU PERSIST...?"}
	]
	dialogue_box.start_dialogue(lines)

const NEXT_CHAPTER_SCENE_PATH = "res://scenes/levels/chapter4_industrial.tscn"

func _on_exit_portal_entered(body: Node) -> void:
	if body is Player and era_boss_defeated and not chapter_completed:
		chapter_completed = true
		if SaveManager:
			SaveManager.unlock_chapter(4)
		_show_chapter_complete()

func _show_chapter_complete() -> void:
	chapter_reward_label.text = "REWARDS CLAIMED:\n• Kensei Tsuba (Miniboss)\n• Historical Remnant (Era 3 Key Shard)\n• +4 Total Skill Points\n\nLoop Counter: #%d" % ResetManager.reset_count
	chapter_complete_panel.visible = true

func _on_replay_chapter_pressed() -> void:
	advance_to_next_chapter()

func advance_to_next_chapter() -> void:
	if SaveManager:
		SaveManager.unlock_chapter(4)
		SaveManager.save_game(Vector2.ZERO, NEXT_CHAPTER_SCENE_PATH, "cp_ch4_start")
	if ResourceLoader.exists(NEXT_CHAPTER_SCENE_PATH):
		get_tree().change_scene_to_file(NEXT_CHAPTER_SCENE_PATH)
	else:
		ResetManager.trigger_reset("chapter_advance_fallback")

func _unhandled_input(event: InputEvent) -> void:
	if chapter_complete_panel and chapter_complete_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			advance_to_next_chapter()

func _spawn_challenge_portal() -> void:
	var portal = CHALLENGE_PORTAL_SCENE.instantiate()
	portal.global_position = Vector2(580, 230)
	portal.target_boss_type = "onryo_mist"
	portal.portal_era = "Historical"
	portal.required_relic_id = "spirit_ribbon"
	portal.portal_color = Color(0.85, 0.25, 0.45, 1.0)
	add_child(portal)

