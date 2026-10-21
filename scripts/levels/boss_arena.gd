class_name BossArena
extends Node2D

## Reusable Boss Arena supporting instant retry and dynamic boss loading.

const BOSS_STALKER_SCENE = preload("res://scenes/bosses/boss_primal_stalker.tscn")
const BOSS_TITAN_SCENE = preload("res://scenes/bosses/boss_titan_deep_earth.tscn")
const BOSS_MUD_GOLEM_SCENE = preload("res://scenes/bosses/boss_mud_golem.tscn")
const BOSS_GARGOYLE_SCENE = preload("res://scenes/bosses/boss_gargoyle_patriarch.tscn")
const BOSS_ONRYO_SCENE = preload("res://scenes/bosses/boss_onryo_mist.tscn")
const BOSS_SPIDER_SCENE = preload("res://scenes/bosses/boss_spider_sentry.tscn")
const BOSS_SWAT_SCENE = preload("res://scenes/bosses/boss_swat_juggernaut.tscn")
const BOSS_SWARM_SCENE = preload("res://scenes/bosses/boss_sentinel_swarm.tscn")

@export var selected_boss_type: String = "primal_stalker" # "primal_stalker", "mud_golem", "titan_deep_earth", "gargoyle_patriarch", "onryo_mist", "spider_sentry", "swat_juggernaut", "sentinel_swarm"

@onready var player: Player = $Player
@onready var boss_spawn_point: Marker2D = $BossSpawnPoint
@onready var title_card: BossTitleCard = $BossTitleCard
@onready var health_bar: BossHealthBar = $CanvasLayer/BossHealthBar
@onready var victory_panel: Control = $CanvasLayer/VictoryPanel
@onready var reward_label: Label = $CanvasLayer/VictoryPanel/CenterContainer/VBox/RewardLabel

var current_boss: BossController

func _ready() -> void:
	victory_panel.visible = false

	# Setup camera limits
	if player and player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = -50
		player.camera.limit_right = 640
		player.camera.limit_bottom = 290

	# Spawn boss
	_spawn_boss()

	# Start Title Card sequence
	if current_boss and current_boss.data:
		title_card.intro_finished.connect(_on_intro_finished)
		title_card.play_intro(current_boss.data)
	else:
		_start_fight()

func _spawn_boss() -> void:
	match selected_boss_type:
		"titan_deep_earth":
			current_boss = BOSS_TITAN_SCENE.instantiate() as BossController
		"mud_golem":
			current_boss = BOSS_MUD_GOLEM_SCENE.instantiate() as BossController
		"gargoyle_patriarch":
			current_boss = BOSS_GARGOYLE_SCENE.instantiate() as BossController
		"onryo_mist":
			current_boss = BOSS_ONRYO_SCENE.instantiate() as BossController
		"spider_sentry":
			current_boss = BOSS_SPIDER_SCENE.instantiate() as BossController
		"swat_juggernaut":
			current_boss = BOSS_SWAT_SCENE.instantiate() as BossController
		"sentinel_swarm":
			current_boss = BOSS_SWARM_SCENE.instantiate() as BossController
		_:
			current_boss = BOSS_STALKER_SCENE.instantiate() as BossController

	current_boss.global_position = boss_spawn_point.global_position
	add_child(current_boss)
	current_boss.boss_defeated.connect(_on_boss_defeated)

func _on_intro_finished() -> void:
	_start_fight()

func _start_fight() -> void:
	if current_boss:
		health_bar.bind_boss(current_boss)

func _on_boss_defeated() -> void:
	await get_tree().create_timer(1.0).timeout
	if current_boss and current_boss.data:
		reward_label.text = "REWARD ACQUIRED: %s\n\"The gemstone shifts, recording this outcome.\"" % current_boss.data.reward_id.to_upper()
	victory_panel.visible = true

func _on_retry_pressed() -> void:
	ResetManager.trigger_reset("boss_replay")

func _on_switch_boss_pressed() -> void:
	# Switch boss and restart arena
	selected_boss_type = "titan_deep_earth" if selected_boss_type == "primal_stalker" else "primal_stalker"
	ResetManager.trigger_reset("switch_boss")

func _unhandled_input(event: InputEvent) -> void:
	if victory_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			_on_retry_pressed()
