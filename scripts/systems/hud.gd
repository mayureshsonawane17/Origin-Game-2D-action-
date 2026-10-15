class_name GameHUD
extends CanvasLayer

## In-game HUD displaying Health, Mana, Heal charges, Dodge cooldown,
## Loop counter, On-screen touch buttons, and Defeat/Victory overlays.

@onready var health_container: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/HealthContainer
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/ManaContainer/ManaBar
@onready var heal_label: Label = $MarginContainer/VBoxContainer/TopBar/HealContainer/HealLabel
@onready var dodge_progress: ProgressBar = $MarginContainer/VBoxContainer/TopBar/DodgeContainer/DodgeBar
@onready var loop_label: Label = $MarginContainer/VBoxContainer/TopBar/LoopLabel

@onready var defeat_panel: Control = $DefeatPanel
@onready var defeat_loop_label: Label = $DefeatPanel/CenterContainer/VBox/DefeatLoopLabel
@onready var complete_panel: Control = $CompletePanel

@onready var touch_controls: Control = $TouchControls

var player: Player

func _ready() -> void:
	defeat_panel.visible = false
	complete_panel.visible = false
	
	# Update loop counter from ResetManager
	_update_loop_display()

	# Find player and connect signals
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.mana_changed.connect(_on_player_mana_changed)
		player.heal_charges_changed.connect(_on_player_heal_charges_changed)
		player.dodge_cooldown_updated.connect(_on_player_dodge_cooldown_updated)
		player.player_died.connect(_on_player_died)

		# Initial values
		_on_player_health_changed(player.current_health, player.tuning.max_health)
		_on_player_mana_changed(player.current_mana, float(player.tuning.max_mana))
		_on_player_heal_charges_changed(player.heal_charges, player.tuning.max_heal_charges)

	_setup_touch_buttons()

func _update_loop_display() -> void:
	loop_label.text = "LOOP #%d" % ResetManager.reset_count

func _on_player_health_changed(current: int, max_hp: int) -> void:
	# Draw heart / health pips
	for child in health_container.get_children():
		child.queue_free()

	for i in max_hp:
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(8, 8)
		if i < current:
			pip.color = Color(0.9, 0.15, 0.2) # Active HP
		else:
			pip.color = Color(0.25, 0.1, 0.12) # Empty HP
		health_container.add_child(pip)

func _on_player_mana_changed(current: float, max_mp: float) -> void:
	mana_bar.max_value = max_mp
	mana_bar.value = current

func _on_player_heal_charges_changed(charges: int, max_charges: int) -> void:
	heal_label.text = "HEAL: %d/%d" % [charges, max_charges]

func _on_player_dodge_cooldown_updated(remaining: float, total: float) -> void:
	if total > 0.0:
		dodge_progress.value = (1.0 - (remaining / total)) * 100.0
	else:
		dodge_progress.value = 100.0

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	defeat_loop_label.text = "RESET #%d\n\"The loop begins again.\"" % (ResetManager.reset_count + 1)
	defeat_panel.visible = true

func show_level_complete() -> void:
	complete_panel.visible = true

func _on_restart_button_pressed() -> void:
	ResetManager.trigger_reset("defeat")

func _on_replay_button_pressed() -> void:
	ResetManager.trigger_reset("level_replay")

func _unhandled_input(event: InputEvent) -> void:
	if defeat_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			_on_restart_button_pressed()
	elif complete_panel.visible:
		if event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			_on_replay_button_pressed()

func _setup_touch_buttons() -> void:
	# Configure touch button event emulation for the unified input actions
	var left_btn = touch_controls.get_node_or_null("LeftBtn")
	var right_btn = touch_controls.get_node_or_null("RightBtn")
	var jump_btn = touch_controls.get_node_or_null("JumpBtn")
	var atk_btn = touch_controls.get_node_or_null("AtkBtn")
	var magic_btn = touch_controls.get_node_or_null("MagicBtn")
	var dodge_btn = touch_controls.get_node_or_null("DodgeBtn")
	var block_btn = touch_controls.get_node_or_null("BlockBtn")
	var heal_btn = touch_controls.get_node_or_null("HealBtn")

	_bind_touch(left_btn, "move_left")
	_bind_touch(right_btn, "move_right")
	_bind_touch(jump_btn, "jump")
	_bind_touch(atk_btn, "attack")
	_bind_touch(magic_btn, "magic")
	_bind_touch(dodge_btn, "dodge")
	_bind_touch(block_btn, "block")
	_bind_touch(heal_btn, "heal")

func _bind_touch(btn: Button, action_name: String) -> void:
	if not btn:
		return
	btn.button_down.connect(func(): Input.action_press(action_name))
	btn.button_up.connect(func(): Input.action_release(action_name))
