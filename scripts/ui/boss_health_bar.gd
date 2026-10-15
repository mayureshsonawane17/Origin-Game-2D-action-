class_name BossHealthBar
extends Control

## Dynamic boss health bar with breakable armor and phase pips (Section 6).

@onready var name_label: Label = $VBoxContainer/Header/NameLabel
@onready var title_label: Label = $VBoxContainer/Header/TitleLabel
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var armor_bar: ProgressBar = $VBoxContainer/HealthBar/ArmorBar
@onready var pips_container: HBoxContainer = $VBoxContainer/Header/PhasePips

var bound_boss: BossController

func _ready() -> void:
	visible = false

func bind_boss(boss: BossController) -> void:
	bound_boss = boss
	if not boss:
		return

	if boss.data:
		name_label.text = boss.data.display_name
		title_label.text = boss.data.title
		name_label.modulate = boss.data.accent_color
		health_bar.max_value = boss.data.max_health
		health_bar.value = boss.current_health

		# Phase pips setup
		for child in pips_container.get_children():
			child.queue_free()
		if boss.data.total_phases > 1:
			for i in boss.data.total_phases:
				var pip = ColorRect.new()
				pip.custom_minimum_size = Vector2(6, 6)
				pip.color = Color(1.0, 0.85, 0.2)
				pips_container.add_child(pip)

	boss.boss_health_changed.connect(_on_health_changed)
	boss.boss_armor_changed.connect(_on_armor_changed)
	boss.boss_phase_changed.connect(_on_phase_changed)
	boss.boss_defeated.connect(_on_defeated)

	# Slide in
	visible = true
	position.y = -40.0
	var tween = create_tween()
	tween.tween_property(self, "position:y", 12.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_health_changed(current: int, _max_hp: int) -> void:
	health_bar.value = current

func _on_armor_changed(current: int, max_armor: int) -> void:
	if max_armor > 0:
		armor_bar.visible = current > 0
		armor_bar.max_value = max_armor
		armor_bar.value = current
	else:
		armor_bar.visible = false

func _on_phase_changed(phase: int, total_phases: int) -> void:
	var children = pips_container.get_children()
	for i in children.size():
		var pip = children[i] as ColorRect
		if i < phase:
			pip.color = Color(1.0, 0.2, 0.2) # Spent phase
		else:
			pip.color = Color(1.0, 0.85, 0.2) # Active phase

func _on_defeated() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): visible = false)
