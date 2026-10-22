class_name BossTitleCard
extends CanvasLayer

## Reusable GBA Pokémon-style Boss Title Card intro (Section 6a).
## Fully driven by BossData; supports transitions, typewriter quote, and skipping.

signal intro_finished()

@export var reduce_flashing: bool = false

@onready var wipe_rect: ColorRect = $WipeRect
@onready var versus_container: Control = $VersusContainer
@onready var player_slide: Control = $VersusContainer/PlayerSlide
@onready var boss_slide: Control = $VersusContainer/BossSlide
@onready var boss_name_label: Label = $Nameplate/BossName
@onready var boss_title_label: Label = $Nameplate/BossTitle
@onready var era_label: Label = $Nameplate/EraLabel
@onready var quote_label: Label = $QuoteContainer/QuoteLabel
@onready var skip_hint: Label = $SkipHint

var boss_data: BossData
var is_active: bool = false
var intro_time: float = 0.0
var quote_target_text: String = ""
var typewriter_index: int = 0
var typewriter_timer: float = 0.0
var max_intro_duration: float = 3.2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func play_intro(data: BossData) -> void:
	boss_data = data
	is_active = true
	visible = true
	intro_time = 0.0
	typewriter_index = 0
	typewriter_timer = 0.0

	# Apply BossData fields
	boss_name_label.text = data.display_name
	boss_title_label.text = data.title
	quote_target_text = "\"%s\"" % data.intro_quote
	quote_label.text = ""

	if data.is_era_boss:
		era_label.text = "◆ ERA BOSS — %s ◆" % data.era.to_upper()
		era_label.modulate = Color(1.0, 0.85, 0.2)
		max_intro_duration = 3.8
	else:
		era_label.text = "[ %s ERA ]" % data.era.to_upper()
		era_label.modulate = Color(0.7, 0.85, 1.0)
		max_intro_duration = 2.8

	# Accent color styling
	boss_name_label.modulate = data.accent_color
	boss_slide.get_node("AccentBar").modulate = data.accent_color

	# Pause underlying gameplay
	get_tree().paused = true

	# Disable HUD and Pause Menu while title card plays
	if UIManager:
		UIManager.hide_hud()
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.is_pause_disabled = true

	# Initial positions
	player_slide.position.x = -240.0
	boss_slide.position.x = 480.0
	wipe_rect.modulate.a = 0.0 if reduce_flashing else 1.0

func _process(delta: float) -> void:
	if not is_active:
		return

	intro_time += delta

	# 1. Screen Wipe / Flash (0.0s - 0.4s)
	if intro_time < 0.4:
		var t = intro_time / 0.4
		wipe_rect.modulate.a = lerp(1.0, 0.0, t)

	# 2. Versus Slide-in (0.2s - 0.8s)
	if intro_time >= 0.2 and intro_time < 1.0:
		var st = clamp((intro_time - 0.2) / 0.6, 0.0, 1.0)
		var ease_st = 1.0 - pow(1.0 - st, 3) # Cubic ease out
		player_slide.position.x = lerp(-240.0, 20.0, ease_st)
		boss_slide.position.x = lerp(480.0, 240.0, ease_st)

	# 3. Typewriter Quote (0.8s onwards)
	if intro_time >= 0.8 and typewriter_index < quote_target_text.length():
		typewriter_timer += delta
		if typewriter_timer >= 0.035:
			typewriter_timer = 0.0
			typewriter_index += 1
			quote_label.text = quote_target_text.substr(0, typewriter_index)

	# 4. Auto Finish
	if intro_time >= max_intro_duration:
		finish_intro()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	# Any action or click skips the card
	if event.is_pressed():
		finish_intro()

func finish_intro() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	get_tree().paused = false

	# Restore HUD and Pause Menu
	if UIManager:
		UIManager.show_hud()
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.is_pause_disabled = false

	intro_finished.emit()
