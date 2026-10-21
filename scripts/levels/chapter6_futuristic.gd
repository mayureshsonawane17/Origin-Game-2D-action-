class_name Chapter6Futuristic
extends Node2D

## Chapter 6: The Cybernetic Spire (Futuristic Era).
## Full chapter level integrating Futuristic enemies (Cyber Drone, Android Stalker),
## Miniboss (Unit 73 Infiltrator FUT-01), 3-Phase Era Boss (Unit 00-NEXUS FUT-ERA),
## checkpoints, story dialogue, and the sixth Era Key Item (Futuristic Remnant).

const BOSS_UNIT73_SCENE = preload("res://scenes/bosses/boss_cyber_unit73.tscn")
const BOSS_NEXUS_SCENE = preload("res://scenes/bosses/boss_apex_nexus.tscn")
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
		SoundManager.play_bgm("futuristic")

	# Initial camera bounds (entire chapter)
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 2950
		player.camera.limit_bottom = 290

	exit_portal.body_entered.connect(_on_exit_portal_entered)
	_spawn_challenge_portal()

	await get_tree().create_timer(0.6).timeout
	if not miniboss_triggered:
		_play_opening_dialogue()

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return

	# Bottomless pit kill plane (spire void fall)
	if player.global_position.y > 290.0:
		player.is_dead = true
		player.player_died.emit()
		ResetManager.trigger_reset("fall_into_quantum_void")
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
		{"speaker": "Hero", "text": "Zero gravity... endless data streams. This is the apex of the loop's design."},
		{"speaker": "The Gemstone", "text": "YOU STAND AT THE PINNACLE OF SIMULATED TIME. BEYOND THIS SPIRE LIES THE CORE. TURN BACK, OR BE PURGED."},
		{"speaker": "Hero", "text": "I have fought through five ages of this prison. I am not turning back."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_miniboss_encounter() -> void:
	miniboss_triggered = true
	miniboss_gate_left.close_gate()
	miniboss_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 1240
		player.camera.limit_right = 1720

	active_boss = BOSS_UNIT73_SCENE.instantiate() as BossController
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

	# Award Quantum Processor + 1 Skill Point
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(1)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_unit73_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "Unit 73 has dissipated into raw data. The ascent to the Spire Core is clear."}
	]
	dialogue_box.start_dialogue(lines)

func _trigger_era_boss_encounter() -> void:
	era_boss_triggered = true
	era_gate_left.close_gate()
	era_gate_right.close_gate()

	if player and player.camera:
		player.camera.limit_left = 2120
		player.camera.limit_right = 2950

	active_boss = BOSS_NEXUS_SCENE.instantiate() as BossController
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

	# Award Futuristic Remnant + 3 Skill Points + Save
	if SaveManager:
		if SaveManager.skill_tree:
			SaveManager.skill_tree.add_skill_points(3)
		SaveManager.save_game(player.global_position, scene_file_path, "cp_futuristic_cleared")

	await get_tree().create_timer(1.2).timeout
	var lines = [
		{"speaker": "Hero", "text": "Unit 00-NEXUS has collapsed. The sixth and final Remnant is secured."},
		{"speaker": "The Gemstone", "text": "CRITICAL ALERT: ALL SIX REMNANTS CONVERGED. THE LOCKS OF TIME ARE BROKEN. THE WAY TO THE FORTRESS IS OPEN."}
	]
	dialogue_box.start_dialogue(lines)

const NEXT_CHAPTER_SCENE_PATH = "res://scenes/levels/chapter7_fortress.tscn"

func _on_exit_portal_entered(body: Node) -> void:
	if body is Player and era_boss_defeated and not chapter_completed:
		chapter_completed = true
		if SaveManager:
			SaveManager.unlock_chapter(7)
		_show_chapter_complete()

func _show_chapter_complete() -> void:
	chapter_reward_label.text = "REWARDS CLAIMED:\n• Quantum Processor (Miniboss)\n• Futuristic Remnant (Era 6 Key Shard - 6/6 Complete!)\n• +4 Total Skill Points\n\nLoop Counter: #%d" % ResetManager.reset_count
	chapter_complete_panel.visible = true

func _on_replay_chapter_pressed() -> void:
	advance_to_next_chapter()

func advance_to_next_chapter() -> void:
	if SaveManager:
		SaveManager.unlock_chapter(7)
		SaveManager.save_game(Vector2.ZERO, NEXT_CHAPTER_SCENE_PATH, "cp_ch7_start")
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
	portal.target_boss_type = "sentinel_swarm"
	portal.portal_era = "Futuristic"
	portal.required_relic_id = "ion_cell"
	portal.portal_color = Color(0.1, 0.9, 0.8, 1.0)
	add_child(portal)

