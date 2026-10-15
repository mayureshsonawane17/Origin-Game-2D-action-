extends Node

## ResetManager: Authoritative single reset pipeline for ORIGIN.
## Manages global loop count, restart/retry routing, and persistence (Section 7a).

signal reset_triggered(count: int, reason: String)

const SAVE_PATH: String = "user://origin_loop_data.json"

var reset_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_reset_count()
	_setup_default_input_map()
	print("[ResetManager] Initialized. Current loop count: %d" % reset_count)

func trigger_reset(reason: String = "defeat", reload_scene: bool = true) -> void:
	reset_count += 1
	_save_reset_count()
	print("[ResetManager] Reset triggered (Loop #%d) Reason: %s" % [reset_count, reason])
	reset_triggered.emit(reset_count, reason)
	
	# Reload current scene cleanly
	if reload_scene and get_tree():
		get_tree().paused = false
		get_tree().reload_current_scene()

func restart_scene() -> void:
	trigger_reset("manual_restart")

func _save_reset_count() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"reset_count": reset_count,
			"timestamp": Time.get_unix_time_from_system()
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_reset_count() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary and parsed.has("reset_count"):
			reset_count = int(parsed["reset_count"])

func _setup_default_input_map() -> void:
	# Define core actions with keyboard & gamepad defaults
	var key_mappings: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"attack": [KEY_J],
		"magic": [KEY_K],
		"dodge": [KEY_L, KEY_SHIFT],
		"block": [KEY_I, KEY_S, KEY_DOWN],
		"heal": [KEY_H],
		"pause": [KEY_ESCAPE, KEY_P],
		"debug_hitbox": [KEY_F1],
		"switch_weapon": [KEY_Q, KEY_E],
		"toggle_inventory": [KEY_TAB, KEY_U]
	}
	
	var joy_button_mappings: Dictionary = {
		"move_left": [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"jump": [JOY_BUTTON_A],
		"attack": [JOY_BUTTON_X],
		"magic": [JOY_BUTTON_Y],
		"dodge": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER],
		"block": [JOY_BUTTON_LEFT_SHOULDER],
		"heal": [JOY_BUTTON_DPAD_UP],
		"pause": [JOY_BUTTON_START],
		"switch_weapon": [JOY_BUTTON_BACK, JOY_BUTTON_DPAD_DOWN],
		"toggle_inventory": [JOY_BUTTON_TOUCHPAD, JOY_BUTTON_GUIDE]
	}

	for action in key_mappings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in key_mappings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = keycode
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
				
	for action in joy_button_mappings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for btn in joy_button_mappings[action]:
			var event = InputEventJoypadButton.new()
			event.button_index = btn
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
				
	# Left Stick Motion
	var left_stick_left = InputEventJoypadMotion.new()
	left_stick_left.axis = JOY_AXIS_LEFT_X
	left_stick_left.axis_value = -1.0
	if not InputMap.action_has_event("move_left", left_stick_left):
		InputMap.action_add_event("move_left", left_stick_left)

	var left_stick_right = InputEventJoypadMotion.new()
	left_stick_right.axis = JOY_AXIS_LEFT_X
	left_stick_right.axis_value = 1.0
	if not InputMap.action_has_event("move_right", left_stick_right):
		InputMap.action_add_event("move_right", left_stick_right)
