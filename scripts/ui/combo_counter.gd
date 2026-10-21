class_name ComboCounter
extends Control

## Arcade Combo Counter & Score Multiplier Widget.
## Inspired by classic arcade beat-'em-ups and Dan-the-Man feel.
## Tracks chained hits within a decaying 2.5s window.
## Displays animated hit streaks, score multipliers, and dynamic tier badges:
## - 1-4 hits: Basic combo
## - 5-9 hits: "GOOD!" (1.25x Score Multiplier)
## - 10-19 hits: "GREAT!" (1.5x Score Multiplier + Momentum MP refund)
## - 20-34 hits: "EXCELLENT!" (2.0x Score Multiplier)
## - 35+ hits: "UNSTOPPABLE!" (3.0x Score Multiplier)

signal combo_updated(count: int, multiplier: float, tier_name: String)
signal combo_dropped(final_count: int, final_score: int)

const COMBO_WINDOW_DURATION: float = 2.5

@export var max_duration: float = COMBO_WINDOW_DURATION

var current_combo: int = 0
var combo_timer: float = 0.0
var current_multiplier: float = 1.0
var total_combo_score: int = 0
var current_tier: String = ""

var bound_player: Player = null

@onready var container: VBoxContainer = $VBoxContainer
@onready var hit_label: Label = $VBoxContainer/HitLabel
@onready var tier_label: Label = $VBoxContainer/Header/TierLabel
@onready var mult_label: Label = $VBoxContainer/Header/MultLabel
@onready var timer_bar: ProgressBar = $VBoxContainer/TimerBar

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	timer_bar.max_value = max_duration
	timer_bar.value = max_duration

func bind_player(player: Player) -> void:
	if bound_player == player:
		return
	if bound_player and bound_player.is_connected("hit_landed", _on_player_hit_landed):
		bound_player.hit_landed.disconnect(_on_player_hit_landed)
	bound_player = player
	if bound_player:
		bound_player.hit_landed.connect(_on_player_hit_landed)

func _process(delta: float) -> void:
	if current_combo <= 0:
		return

	combo_timer -= delta
	timer_bar.value = max(0.0, combo_timer)

	if combo_timer <= 0.0:
		_drop_combo()

func register_hit(damage_dealt: int = 1, is_finisher: bool = false) -> void:
	current_combo += 1
	combo_timer = max_duration
	timer_bar.value = max_duration

	# Calculate multiplier and tier
	var prev_tier = current_tier
	_update_tier_and_multiplier()

	# Score accumulation
	var base_points = damage_dealt * 10
	if is_finisher:
		base_points += 25
	total_combo_score += int(float(base_points) * current_multiplier)

	# Momentum reward: Every 5 hits above 10 combo, refund +3 MP to player
	if current_combo >= 10 and (current_combo % 5) == 0:
		if bound_player and is_instance_valid(bound_player):
			bound_player.current_mana = min(float(bound_player.tuning.max_mana), bound_player.current_mana + 3.0)
			bound_player.emit_signal("mana_changed", bound_player.current_mana, float(bound_player.tuning.max_mana))

	# Update UI text & styling
	_refresh_display(prev_tier != current_tier)

	# Sound cue on tier upgrade
	if prev_tier != current_tier and current_combo >= 5:
		if SoundManager:
			SoundManager.play_sfx("ui_confirm")

	combo_updated.emit(current_combo, current_multiplier, current_tier)

func _on_player_hit_landed(_target: Hurtbox, damage_dealt: int, is_finisher: bool) -> void:
	register_hit(damage_dealt, is_finisher)

func _update_tier_and_multiplier() -> void:
	if current_combo >= 35:
		current_tier = "UNSTOPPABLE!"
		current_multiplier = 3.0
	elif current_combo >= 20:
		current_tier = "EXCELLENT!"
		current_multiplier = 2.0
	elif current_combo >= 10:
		current_tier = "GREAT!"
		current_multiplier = 1.5
	elif current_combo >= 5:
		current_tier = "GOOD!"
		current_multiplier = 1.25
	else:
		current_tier = "COMBO"
		current_multiplier = 1.0

func _refresh_display(tier_changed: bool) -> void:
	visible = true
	var target_alpha = 1.0
	if current_combo == 1:
		target_alpha = 0.85
	
	modulate.a = target_alpha
	hit_label.text = "%d HITS" % current_combo
	mult_label.text = "%0.2fx" % current_multiplier

	# Color scheme based on tier
	var tier_color = Color(0.8, 0.85, 0.9)
	match current_tier:
		"GOOD!":
			tier_color = Color(0.2, 0.9, 1.0) # Electric cyan
		"GREAT!":
			tier_color = Color(1.0, 0.85, 0.2) # Radiant gold
		"EXCELLENT!":
			tier_color = Color(1.0, 0.55, 0.1) # Blazing orange
		"UNSTOPPABLE!":
			tier_color = Color(1.0, 0.2, 0.6) # Neon magenta fire

	tier_label.text = current_tier
	tier_label.add_theme_color_override("font_color", tier_color)
	hit_label.add_theme_color_override("font_color", tier_color if current_combo >= 5 else Color.WHITE)

	# Punch scale pop animation
	var punch_scale = 1.25 if tier_changed else 1.12
	pivot_offset = size / 2.0
	scale = Vector2(punch_scale, punch_scale)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _drop_combo() -> void:
	var final_c = current_combo
	var final_s = total_combo_score
	current_combo = 0
	combo_timer = 0.0
	current_multiplier = 1.0
	current_tier = ""

	combo_dropped.emit(final_c, final_s)

	# Fade out smoothly
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	if current_combo == 0:
		visible = false
