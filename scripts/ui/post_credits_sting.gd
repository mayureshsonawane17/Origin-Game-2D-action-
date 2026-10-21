class_name PostCreditsSting
extends Control

## Post-Credits Sting (docs/STORY.md Beat 14).
## Pitch black screen -> cursor clicks NEW GAME -> screen glitches ->
## ERROR: REALITY INSTANCE NOT FOUND -> ORIGIN logo with dark gemstone.

signal sting_completed()

@onready var menu_container: Control = $MenuContainer
@onready var new_game_btn: Button = $MenuContainer/VBox/NewGameButton
@onready var cursor_sprite: Control = $VirtualCursor
@onready var glitch_rect: ColorRect = $GlitchFlash
@onready var error_container: Control = $ErrorContainer
@onready var error_label: Label = $ErrorContainer/ErrorLabel
@onready var logo_container: Control = $ErrorContainer/LogoContainer
@onready var dark_gemstone: Control = $ErrorContainer/LogoContainer/DarkGemstone

var sting_step: int = 0
var timer: float = 0.0

func _ready() -> void:
	error_container.visible = false
	glitch_rect.visible = false
	cursor_sprite.visible = false
	menu_container.modulate.a = 0.0

	await get_tree().create_timer(1.0).timeout
	_start_menu_fade()

func _start_menu_fade() -> void:
	var tween = create_tween()
	tween.tween_property(menu_container, "modulate:a", 1.0, 1.2)
	tween.tween_interval(0.5)
	tween.tween_callback(_animate_cursor_click)

func _animate_cursor_click() -> void:
	cursor_sprite.visible = true
	cursor_sprite.position = Vector2(80, 240) # Start bottom-left

	var target_pos = new_game_btn.global_position + Vector2(new_game_btn.size.x * 0.5, new_game_btn.size.y * 0.5)
	var tween = create_tween()
	tween.tween_property(cursor_sprite, "global_position", target_pos, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.3)
	tween.tween_callback(_on_click_new_game)

func _on_click_new_game() -> void:
	# Click simulated
	new_game_btn.button_pressed = true
	_trigger_reality_glitch_error()

func _trigger_reality_glitch_error() -> void:
	menu_container.visible = false
	cursor_sprite.visible = false
	glitch_rect.visible = true

	# Glitch bursts
	var tween = create_tween()
	tween.tween_property(glitch_rect, "color", Color(1, 0.1, 0.2, 0.8), 0.08)
	tween.tween_property(glitch_rect, "color", Color(0.1, 0.8, 1, 0.8), 0.08)
	tween.tween_property(glitch_rect, "color", Color(0, 0, 0, 0), 0.12)
	tween.tween_callback(show_error_state)

const MAIN_MENU_PATH = "res://scenes/ui/main_menu.tscn"

func show_error_state() -> void:
	glitch_rect.visible = false
	error_container.visible = true
	error_label.text = "ERROR: REALITY INSTANCE NOT FOUND"
	sting_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if error_container.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			if ResourceLoader.exists(MAIN_MENU_PATH):
				get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _process(delta: float) -> void:
	if error_container.visible and dark_gemstone:
		dark_gemstone.queue_redraw()
