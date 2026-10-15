class_name Chapter4Industrial
extends Node2D

## Chapter 4: Smog Docks & The Iron Foundry (Industrial Era).
## Full chapter level integrating Industrial enemies (Automaton, Grenadier),
## Miniboss (Chief Overseer Brant IND-01), 3-Phase Era Boss (Baron Von Steinhardt IND-ERA),
## checkpoints, story dialogue, and the fourth Era Key Item (Industrial Remnant).

const BOSS_BRANT_SCENE = preload("res://scenes/bosses/boss_overseer_brant.tscn")
const BOSS_STEINHARDT_SCENE = preload("res://scenes/bosses/boss_baron_steinhardt.tscn")

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
		player.camera.limit_right = 2950
		player.camera.limit_bottom = 290

	exit_portal.body_entered.connect(_on_exit_portal_entered)

	await get_tree().create_timer(0.6).timeout
	if not miniboss_triggered:
		_play_opening_dialogue()

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return

	# Bottomless pit kill plane (smog vats)
	if player.global_position.y > 290.0:
		player.is_dead = true
		player.player_died.emit()
		ResetManager.trigger_reset("fall_into_smog_vat")
		return

	var px = player.global_position.x

	# Miniboss Arena Trigger (Zone 3: X: 1300)
	if not miniboss_triggered and px >= 1300.0 and px < 1650.0:
		_trigger_miniboss_encounter()

	# Era Boss Arena Trigger (Zone 5: X: 2180)
	if not era_boss_triggered and px >= 2180.0 and px < 2800.0:
		_trigger_era_boss_encounter()

func _play_opening_dialogue() -> void:
	var lines = [
		{"speaker": "Hero", "text": "Black smoke, boiling copper... the loop has dragged me into the gears of industry."},
		{"speaker": "The Gemstone", "text": "An age of machines. They believed they could conquer nature, just as you believe you can break this prison."},
		{"speaker": "Hero", "text": "Machines can be dismantled. And so can this crystal."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_miniboss_encounter() -> void:
	miniboss_triggered = true
	miniboss_gate_left.close_gate()
	miniboss_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1240
		player.camera.limit_right = 1720

	active_boss = BOSS_BRANT_SCENE.instantiate() as BossController
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
		player.camera.limit_right = 2950

	# Award Overseer Cog + 1 Skill Point
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(1)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_brant_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The foundry overseer collapses among shattered gears. The boiler room is unlocked."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_era_boss_encounter() -> void:
	era_boss_triggered = true
	era_gate_left.close_gate()
	era_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 2120
		player.camera.limit_right = 2950

	active_boss = BOSS_STEINHARDT_SCENE.instantiate() as BossController
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

	# Award Industrial Remnant + 3 Skill Points + Save
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(3)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_industrial_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "The iron leviathan explodes in steam and fire. The Industrial Remnant is mine."},
		{"speaker": "The Gemstone", "text": "SYSTEM COMPROMISED. FOUR REMNANTS ASSEMBLED. THE WALLS OF REALITY ARE CRACKING..."}
	]
	dialogue_box.start_dialogue(lines)

func _on_exit_portal_entered(body: Node) -> void:
	if body is Player and era_boss_defeated and not chapter_completed:
		chapter_completed = true
		_show_chapter_complete()

func _show_chapter_complete() -> void:
	chapter_reward_label.text = "REWARDS CLAIMED:\n• Overseer Cog (Miniboss)\n• Industrial Remnant (Era 4 Key Shard)\n• +4 Total Skill Points\n\nLoop Counter: #%d" % ResetManager.reset_count
	chapter_complete_panel.visible = true

func _on_replay_chapter_pressed() -> void:
	ResetManager.trigger_reset("chapter_replay")

func _unhandled_input(event: InputEvent) -> void:
	if chapter_complete_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			_on_replay_chapter_pressed()
