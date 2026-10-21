class_name EpilogueRealWorld
extends Node2D

## Real-World Epilogue (docs/STORY.md Beats 11, 12, 13).
## No health bars, no enemies, no signs of the loop.
## The hero awakens beside his wife. The villain appears to reclaim power;
## the hero ends his reign permanently. Hero and wife walk into the sunrise. Credits roll.

const POST_CREDITS_PATH = "res://scenes/ui/post_credits_sting.tscn"

@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var credits_panel: Control = $CanvasLayer/CreditsPanel
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var sunrise_rect: ColorRect = $SunriseGlow

var sequence_step: int = 0
var credits_rolling: bool = false
var credits_scroll_y: float = 0.0

func _ready() -> void:
	credits_panel.visible = false
	fade_rect.modulate.a = 1.0
	if SoundManager:
		SoundManager.play_bgm("epilogue")

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	tween.tween_callback(_start_awakening_sequence)

func _start_awakening_sequence() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "Hero", "text": "...The air is warm. There are no health bars. No loops."},
		{"speaker": "Wife", "text": "You're awake... We made it back. We're really home."},
		{"speaker": "The Villain", "text": "NO! My crystal... my reality! Give it back to me!"}
	]
	dialogue_box.dialogue_finished.connect(_confront_villain, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(lines)

func _confront_villain() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "Hero", "text": "Your game is over. Forever."},
		{"speaker": "The Villain", "text": "Without the gemstone... I am nothing... NOOOO!"}
	]
	dialogue_box.dialogue_finished.connect(_walk_into_sunrise, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(lines)

func _walk_into_sunrise() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "Wife", "text": "The sun is rising. Let's walk home together."},
		{"speaker": "Hero", "text": "Together. Free."}
	]
	dialogue_box.dialogue_finished.connect(_roll_credits, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(lines)

func _roll_credits() -> void:
	credits_panel.visible = true
	credits_rolling = true
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 4.5)
	tween.tween_interval(1.5)
	tween.tween_callback(_transition_to_post_credits)

func _transition_to_post_credits() -> void:
	if ResourceLoader.exists(POST_CREDITS_PATH):
		get_tree().change_scene_to_file(POST_CREDITS_PATH)
	else:
		print("[Epilogue] Credits finished. Transitioning to post-credits.")
