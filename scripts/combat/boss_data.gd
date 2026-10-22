class_name BossData
extends Resource

## Data-driven boss specification for ORIGIN (Section 6 & 6a).
## Holds boss identity, combat phases, weaknesses, title card data, and rewards.

@export_group("Identity & Title Card")
@export var id: String = "PRE-01"
@export var era: String = "Prehistoric"
@export var tier: int = 1 # 1-10 or 11 for era boss
@export var display_name: String = "Boss Name"
@export var title: String = "The Epithet"
@export_multiline var intro_quote: String = "..."
@export var accent_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var transition_style: String = "stripe_wipe" # stripe_wipe, diagonal_flash, spiral
@export var is_era_boss: bool = false
@export var intro_music_cue: String = "boss_cue_prehistoric"

@export_group("Combat Stats")
@export var max_health: int = 15
@export var total_phases: int = 1
@export var move_speed: float = 90.0
@export var armor_health: int = 0 # Breakable armor (0 if none)
@export var attacks: Array[String] = []
@export var weaknesses: Array[String] = []

@export_group("Rewards & Progression")
@export var reward_id: String = ""
@export var story_flag: String = ""
@export var arena_scene_path: String = "res://scenes/levels/boss_arena.tscn"

@export_group("UI Display")
@export var custom_status_text: String = ""
@export var is_fixed_text_mode: bool = false
