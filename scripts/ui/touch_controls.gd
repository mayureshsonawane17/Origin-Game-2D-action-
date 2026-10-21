class_name TouchControls
extends CanvasLayer

## Virtual on-screen touch controls for mobile/tablet gameplay.
## Maps touch buttons directly to Godot input actions:
## move_left, move_right, jump, attack, magic, dodge, heal.

@onready var root_control: Control = $RootControl
@onready var btn_left: Button = $RootControl/DPad/BtnLeft
@onready var btn_right: Button = $RootControl/DPad/BtnRight
@onready var btn_jump: Button = $RootControl/Actions/BtnJump
@onready var btn_attack: Button = $RootControl/Actions/BtnAttack
@onready var btn_magic: Button = $RootControl/Actions/BtnMagic
@onready var btn_dodge: Button = $RootControl/Actions/BtnDodge
@onready var btn_heal: Button = $RootControl/Actions/BtnHeal

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_touch_button(btn_left, "move_left")
	_bind_touch_button(btn_right, "move_right")
	_bind_touch_button(btn_jump, "jump")
	_bind_touch_button(btn_attack, "attack")
	_bind_touch_button(btn_magic, "magic")
	_bind_touch_button(btn_dodge, "dodge")
	_bind_touch_button(btn_heal, "heal")
	refresh_visibility()

func refresh_visibility() -> void:
	var should_show = false
	if SaveManager and SaveManager.touch_controls_enabled:
		should_show = true
	elif DisplayServer.is_touchscreen_available():
		should_show = true
	root_control.visible = should_show

func _bind_touch_button(btn: Button, action_name: String) -> void:
	if not btn:
		return
	btn.button_down.connect(func():
		Input.action_press(action_name)
	)
	btn.button_up.connect(func():
		Input.action_release(action_name)
	)
