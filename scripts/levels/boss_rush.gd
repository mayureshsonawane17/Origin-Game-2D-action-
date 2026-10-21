class_name BossRush
extends Node2D

## Dedicated Boss Rush / Time-Attack Mode.
## Gauntlet sequencing through all 13 bosses across 6 Eras + The Fortress.
## Tracks speedrun time, personal bests, and ranks with dynamic era theming and BGM.

const BOSS_ENCOUNTERS: Array[Dictionary] = [
	{
		"id": "PRE-01",
		"name": "Primal Stalker",
		"era": "Prehistoric",
		"bgm": "prehistoric",
		"scene_path": "res://scenes/bosses/boss_primal_stalker.tscn"
	},
	{
		"id": "PRE-ERA",
		"name": "Titan of the Deep Earth",
		"era": "Prehistoric",
		"bgm": "prehistoric",
		"scene_path": "res://scenes/bosses/boss_titan_deep_earth.tscn"
	},
	{
		"id": "MED-01",
		"name": "Sir Gareth the Ironclad",
		"era": "Medieval",
		"bgm": "medieval",
		"scene_path": "res://scenes/bosses/boss_sir_gareth.tscn"
	},
	{
		"id": "MED-ERA",
		"name": "Lord Malakor",
		"era": "Medieval",
		"bgm": "medieval",
		"scene_path": "res://scenes/bosses/boss_lord_malakor.tscn"
	},
	{
		"id": "HIST-01",
		"name": "Kensei Jinzo",
		"era": "Historical",
		"bgm": "historical",
		"scene_path": "res://scenes/bosses/boss_kensei_jinzo.tscn"
	},
	{
		"id": "HIST-ERA",
		"name": "Shogun Kageyasu",
		"era": "Historical",
		"bgm": "historical",
		"scene_path": "res://scenes/bosses/boss_shogun_kageyasu.tscn"
	},
	{
		"id": "IND-01",
		"name": "Chief Overseer Brant",
		"era": "Industrial",
		"bgm": "industrial",
		"scene_path": "res://scenes/bosses/boss_overseer_brant.tscn"
	},
	{
		"id": "IND-ERA",
		"name": "Baron Von Steinhardt",
		"era": "Industrial",
		"bgm": "industrial",
		"scene_path": "res://scenes/bosses/boss_baron_steinhardt.tscn"
	},
	{
		"id": "MOD-01",
		"name": "Commander Reyes",
		"era": "Modern",
		"bgm": "modern",
		"scene_path": "res://scenes/bosses/boss_commander_reyes.tscn"
	},
	{
		"id": "MOD-ERA",
		"name": "General Vance",
		"era": "Modern",
		"bgm": "modern",
		"scene_path": "res://scenes/bosses/boss_general_vance.tscn"
	},
	{
		"id": "FUT-01",
		"name": "Unit 73 Infiltrator",
		"era": "Futuristic",
		"bgm": "futuristic",
		"scene_path": "res://scenes/bosses/boss_cyber_unit73.tscn"
	},
	{
		"id": "FUT-ERA",
		"name": "Unit 00-NEXUS",
		"era": "Futuristic",
		"bgm": "futuristic",
		"scene_path": "res://scenes/bosses/boss_apex_nexus.tscn"
	},
	{
		"id": "VIL-IMMORTAL",
		"name": "The Architect (Final Loop)",
		"era": "The Fortress",
		"bgm": "fortress",
		"scene_path": "res://scenes/bosses/boss_villain_immortal.tscn"
	}
]

@export var starting_encounter_index: int = 0

@onready var player: Player = $Player
@onready var background: Node2D = $BossRushBackground
@onready var title_card: BossTitleCard = $BossTitleCard
@onready var health_bar: BossHealthBar = $CanvasLayer/BossHealthBar
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var player_spawn: Marker2D = $PlayerSpawn

# Rush HUD
@onready var progress_label: Label = $CanvasLayer/RushHUD/TopHBox/ProgressVBox/ProgressLabel
@onready var era_badge: Label = $CanvasLayer/RushHUD/TopHBox/ProgressVBox/EraBadge
@onready var time_label: Label = $CanvasLayer/RushHUD/TopHBox/TimerVBox/TimeLabel
@onready var best_label: Label = $CanvasLayer/RushHUD/TopHBox/TimerVBox/BestLabel

# Modals
@onready var intermission_panel: Control = $CanvasLayer/IntermissionPanel
@onready var intermission_title: Label = $CanvasLayer/IntermissionPanel/Center/VBox/TitleLabel
@onready var intermission_heal_hint: Label = $CanvasLayer/IntermissionPanel/Center/VBox/HealHint
@onready var intermission_countdown_label: Label = $CanvasLayer/IntermissionPanel/Center/VBox/CountdownLabel
@onready var intermission_summon_btn: Button = $CanvasLayer/IntermissionPanel/Center/VBox/SummonButton

@onready var victory_modal: Control = $CanvasLayer/VictoryModal
@onready var victory_time_label: Label = $CanvasLayer/VictoryModal/Center/VBox/FinalTimeLabel
@onready var victory_record_label: Label = $CanvasLayer/VictoryModal/Center/VBox/RecordLabel
@onready var victory_rank_label: Label = $CanvasLayer/VictoryModal/Center/VBox/RankLabel
@onready var victory_retry_btn: Button = $CanvasLayer/VictoryModal/Center/VBox/ButtonHBox/RetryButton
@onready var victory_menu_btn: Button = $CanvasLayer/VictoryModal/Center/VBox/ButtonHBox/MenuButton

@onready var defeat_modal: Control = $CanvasLayer/DefeatModal
@onready var defeat_encounter_label: Label = $CanvasLayer/DefeatModal/Center/VBox/EncounterLabel
@onready var defeat_time_label: Label = $CanvasLayer/DefeatModal/Center/VBox/TimeLabel
@onready var defeat_retry_btn: Button = $CanvasLayer/DefeatModal/Center/VBox/ButtonHBox/RetryButton
@onready var defeat_menu_btn: Button = $CanvasLayer/DefeatModal/Center/VBox/ButtonHBox/MenuButton

var current_encounter_index: int = 0
var active_boss: BossController = null
var timer_running: bool = false
var elapsed_time: float = 0.0
var is_intermission: bool = false
var intermission_timer: float = 0.0
var bosses_defeated: int = 0
var gauntlet_finished: bool = false

func _ready() -> void:
	intermission_panel.visible = false
	victory_modal.visible = false
	defeat_modal.visible = false
	health_bar.visible = false

	# Setup camera constraints
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -60
		player.camera.limit_right = 640
		player.camera.limit_bottom = 290

	if player:
		player.player_died.connect(_on_player_died)
		if SaveManager:
			SaveManager.apply_to_player(player)

	# Setup buttons
	intermission_summon_btn.pressed.connect(_proceed_to_next)
	victory_retry_btn.pressed.connect(_retry_gauntlet)
	victory_menu_btn.pressed.connect(_return_to_title)
	defeat_retry_btn.pressed.connect(_retry_gauntlet)
	defeat_menu_btn.pressed.connect(_return_to_title)

	# Display personal best
	_refresh_best_time_display()

	# Start encounter
	current_encounter_index = clampi(starting_encounter_index, 0, BOSS_ENCOUNTERS.size() - 1)
	_start_encounter(current_encounter_index)

func _process(delta: float) -> void:
	if timer_running and not gauntlet_finished:
		elapsed_time += delta
		time_label.text = SaveManager.format_time(elapsed_time)

	if is_intermission:
		intermission_timer -= delta
		intermission_countdown_label.text = "NEXT ENCOUNTER IN: %.1fs\n[Press ATTACK or Click to Summon Now]" % maxf(0.0, intermission_timer)
		if intermission_timer <= 0.0:
			_proceed_to_next()

func _refresh_best_time_display() -> void:
	var best_time = SaveManager.get_best_boss_rush_time() if SaveManager else -1.0
	if best_time > 0.0:
		best_label.text = "RECORD: %s" % SaveManager.format_time(best_time)
	else:
		best_label.text = "RECORD: --:--.--"

func _start_encounter(index: int) -> void:
	if index < 0 or index >= BOSS_ENCOUNTERS.size():
		return

	is_intermission = false
	intermission_panel.visible = false
	current_encounter_index = index
	var enc = BOSS_ENCOUNTERS[index]

	# Update HUD
	progress_label.text = "ENCOUNTER %d / %d" % [index + 1, BOSS_ENCOUNTERS.size()]
	era_badge.text = "[ %s ERA ]" % enc["era"].to_upper()

	# Switch era backdrop & BGM
	if background:
		background.set_era_theme(enc["era"])
	if SoundManager:
		SoundManager.play_bgm(enc["bgm"])

	# Reposition player if needed
	if player and is_instance_valid(player) and not player.is_dead:
		player.velocity = Vector2.ZERO
		player.global_position = player_spawn.global_position

	# Load & instantiate boss
	var scene = load(enc["scene_path"]) as PackedScene
	if not scene:
		printerr("[BossRush] Failed to load boss scene: %s" % enc["scene_path"])
		return

	active_boss = scene.instantiate() as BossController
	active_boss.global_position = boss_spawn.global_position
	add_child(active_boss)

	# Special mode for final boss (The Architect)
	if active_boss is BossVillainImmortal:
		var villain = active_boss as BossVillainImmortal
		villain.enable_boss_rush(16)

	active_boss.boss_defeated.connect(_on_boss_defeated)

	# Title Card Splash
	if title_card and active_boss.data:
		title_card.intro_finished.connect(func():
			if active_boss and is_instance_valid(active_boss):
				health_bar.bind_boss(active_boss)
				health_bar.visible = true
				timer_running = true
		, CONNECT_ONE_SHOT)
		title_card.play_intro(active_boss.data)
	else:
		health_bar.bind_boss(active_boss)
		health_bar.visible = true
		timer_running = true

func _on_boss_defeated() -> void:
	bosses_defeated += 1
	health_bar.visible = false

	if SoundManager:
		SoundManager.play_sfx("checkpoint")

	# Restore vitals between battles
	if player and is_instance_valid(player) and not player.is_dead:
		player.current_health = mini(player.tuning.max_health, player.current_health + 2)
		player.heal_charges = mini(player.tuning.max_heal_charges, player.heal_charges + 1)
		player.current_mana = float(player.tuning.max_mana)
		player.health_changed.emit(player.current_health, player.tuning.max_health)
		player.heal_charges_changed.emit(player.heal_charges, player.tuning.max_heal_charges)
		player.mana_changed.emit(player.current_mana, float(player.tuning.max_mana))
		if SoundManager:
			SoundManager.play_sfx("heal")

	# Check if gauntlet completed!
	if current_encounter_index >= BOSS_ENCOUNTERS.size() - 1:
		_on_gauntlet_victory()
	else:
		_start_intermission()

func _start_intermission() -> void:
	is_intermission = true
	intermission_timer = 2.8
	var current_enc = BOSS_ENCOUNTERS[current_encounter_index]
	var next_enc = BOSS_ENCOUNTERS[current_encounter_index + 1]

	intermission_title.text = "✔ %s DEFEATED!" % current_enc["name"].to_upper()
	intermission_heal_hint.text = "+2 Health Restored • +1 Heal Charge • Full Mana Recharged"
	intermission_summon_btn.text = "SUMMON %s NOW [ENTER / J]" % next_enc["name"].to_upper()
	intermission_panel.visible = true
	intermission_summon_btn.grab_focus()

func _proceed_to_next() -> void:
	if not is_intermission or gauntlet_finished:
		return
	is_intermission = false
	intermission_panel.visible = false
	if active_boss and is_instance_valid(active_boss):
		active_boss.queue_free()
		active_boss = null
	_start_encounter(current_encounter_index + 1)

func _on_gauntlet_victory() -> void:
	gauntlet_finished = true
	timer_running = false

	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
		SoundManager.play_bgm("epilogue")

	var formatted_time = SaveManager.format_time(elapsed_time) if SaveManager else "00:00.00"
	var is_record: bool = false
	if SaveManager:
		is_record = SaveManager.record_boss_rush_time(elapsed_time)
		_refresh_best_time_display()

	victory_time_label.text = "FINAL TIME: %s" % formatted_time
	if is_record:
		victory_record_label.text = "★ NEW SPEEDRUN RECORD ESTABLISHED! ★"
		victory_record_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		var best_val = SaveManager.get_best_boss_rush_time() if SaveManager else elapsed_time
		victory_record_label.text = "Best Record: %s" % SaveManager.format_time(best_val)
		victory_record_label.modulate = Color(0.7, 0.85, 1.0)

	# Rank calculation
	var rank_text = "S RANK [GODLIKE SPEEDRUNNER]"
	var rank_color = Color(1.0, 0.85, 0.2)
	if elapsed_time > 720.0:
		rank_text = "C RANK [CYCLE CONQUEROR]"
		rank_color = Color(0.7, 0.7, 0.8)
	elif elapsed_time > 540.0:
		rank_text = "B RANK [MASTER OF ERAS]"
		rank_color = Color(0.3, 0.8, 1.0)
	elif elapsed_time > 360.0:
		rank_text = "A RANK [TEMPORAL BLUR]"
		rank_color = Color(0.4, 1.0, 0.5)

	victory_rank_label.text = rank_text
	victory_rank_label.modulate = rank_color
	victory_modal.visible = true
	victory_retry_btn.grab_focus()

func _on_player_died() -> void:
	if gauntlet_finished:
		return
	timer_running = false
	var enc = BOSS_ENCOUNTERS[current_encounter_index]
	defeat_encounter_label.text = "FALLEN AT ENCOUNTER %d / %d:\n%s (%s ERA)" % [
		current_encounter_index + 1,
		BOSS_ENCOUNTERS.size(),
		enc["name"].to_upper(),
		enc["era"].to_upper()
	]
	defeat_time_label.text = "TIME SURVIVED: %s" % SaveManager.format_time(elapsed_time)
	await get_tree().create_timer(0.6).timeout
	defeat_modal.visible = true
	defeat_retry_btn.grab_focus()

func _retry_gauntlet() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_confirm")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_to_title() -> void:
	if SoundManager:
		SoundManager.play_sfx("ui_select")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if is_intermission:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			_proceed_to_next()
