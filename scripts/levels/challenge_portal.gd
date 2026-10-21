class_name ChallengePortal
extends Area2D

## Secret Challenge Portal allowing players to challenge an era's Regular Boss.
## Stores the player's return position in SaveManager and loads BossArena.

@export var target_boss_type: String = "mud_golem"
@export var portal_era: String = "Prehistoric"
@export var required_relic_id: String = "clay_core"
@export var portal_color: Color = Color(0.9, 0.6, 0.2, 1.0)

var is_player_inside: bool = false
var anim_timer: float = 0.0
var active_player: Player = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player body layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_inside or not active_player:
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("jump"):
		_enter_challenge()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_inside = true
		active_player = body as Player

func _on_body_exited(body: Node2D) -> void:
	if body == active_player:
		is_player_inside = false
		active_player = null

func _enter_challenge() -> void:
	if not active_player:
		return

	if SoundManager:
		SoundManager.play_sfx("ui_confirm", 1.2)

	# Store return state
	var current_scene_path = ""
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

	if SaveManager:
		SaveManager.set_challenge_return(current_scene_path, active_player.global_position)

	# Load boss arena with selected boss
	var arena_scene = load("res://scenes/levels/boss_arena.tscn")
	var arena = arena_scene.instantiate() as BossArena
	arena.selected_boss_type = target_boss_type

	# Replace current scene
	get_tree().root.add_child(arena)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = arena

func _draw() -> void:
	var pulse = sin(anim_timer * 4.0) * 3.0
	var col_outer = portal_color
	col_outer.a = 0.4
	var col_mid = portal_color
	col_mid.a = 0.8
	var col_core = Color.WHITE

	# Swirling portal oval
	_draw_portal_ellipse(Vector2(0, -20), 14.0 + pulse * 0.5, 24.0 + pulse, col_outer)
	_draw_portal_ellipse(Vector2(0, -20), 9.0 + pulse * 0.3, 17.0 + pulse * 0.6, col_mid)
	_draw_portal_ellipse(Vector2(0, -20), 4.0, 9.0, col_core)

	# Orbiting dimensional sparks
	for i in range(4):
		var angle = anim_timer * 3.0 + (float(i) * PI / 2.0)
		var sp_pos = Vector2(cos(angle) * 16.0, -20.0 + sin(angle) * 20.0)
		draw_circle(sp_pos, 2.0, col_core)

	# Interaction Prompt
	if is_player_inside:
		var has_relic = SaveManager and SaveManager.has_relic(required_relic_id)
		var prompt_bg = Color(0.05, 0.08, 0.12, 0.9)
		draw_rect(Rect2(-60, -60, 120, 18), prompt_bg)
		draw_rect(Rect2(-60, -60, 120, 18), portal_color, false, 1.0)

		# Text indicator
		var text = "[UP] REPLAY CHALLENGE" if has_relic else "[UP] ENTER BOSS RIFT"
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(-54, -47), text, HORIZONTAL_ALIGNMENT_CENTER, 108, 8, Color.WHITE)

func _draw_portal_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var points = PackedVector2Array()
	var segs = 20
	for i in range(segs):
		var a = (float(i) / float(segs)) * TAU
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, col)
