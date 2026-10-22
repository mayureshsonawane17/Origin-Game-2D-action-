class_name UIManagerScript
extends CanvasLayer

## UIManager: Central UI Manager for ORIGIN (Part A).
## - Screen stack management (push, pop, replace)
## - Input mode auto-detection (keyboard, gamepad, touch) & button prompt generation
## - Global HUD visibility control (hide_hud / show_hud)
## - Non-blocking stacking toast notification system (autosave, unlocks, items)
## - Calm pixel screen transitions between scenes

signal input_mode_changed(mode: String)
signal hud_visibility_changed(visible: bool)

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }

var current_input_mode: InputMode = InputMode.KEYBOARD
var is_hud_visible: bool = true
var screen_stack: Array[Node] = []

# Transition overlay nodes
var transition_overlay: ColorRect
var transition_tween: Tween

# Toast container node
var toast_container: VBoxContainer

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_setup_transition_overlay()
	_setup_toast_container()
	_detect_initial_input_mode()
	print("[UIManager] Initialized. Unified UI Stack & Input detection ready.")

func _input(event: InputEvent) -> void:
	var prev_mode = current_input_mode
	if event is InputEventKey or event is InputEventMouseButton:
		current_input_mode = InputMode.KEYBOARD
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.4):
		current_input_mode = InputMode.GAMEPAD
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		current_input_mode = InputMode.TOUCH

	if current_input_mode != prev_mode:
		var mode_name = get_input_mode_name()
		input_mode_changed.emit(mode_name)

func get_input_mode_name() -> String:
	match current_input_mode:
		InputMode.KEYBOARD: return "keyboard"
		InputMode.GAMEPAD: return "gamepad"
		InputMode.TOUCH: return "touch"
	return "keyboard"

func get_action_prompt(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "[%s]" % action.to_upper()

	if current_input_mode == InputMode.GAMEPAD:
		for ev in events:
			if ev is InputEventJoypadButton:
				return "(Btn %d)" % ev.button_index
		return "(Pad)"
	elif current_input_mode == InputMode.TOUCH:
		return "[TAP]"
	else:
		for ev in events:
			if ev is InputEventKey:
				var keycode = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
				return "[%s]" % OS.get_keycode_string(keycode)
		return "[%s]" % action.to_upper()

# ----------------------------------------------------
# Global HUD Control
# ----------------------------------------------------
func show_hud() -> void:
	is_hud_visible = true
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = true
	hud_visibility_changed.emit(true)

func hide_hud() -> void:
	is_hud_visible = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = false
	hud_visibility_changed.emit(false)

# ----------------------------------------------------
# Screen Stack (push, pop, replace)
# ----------------------------------------------------
func push_screen(scene_resource: Variant) -> Node:
	var node: Node = null
	if scene_resource is String:
		var packed = load(scene_resource) as PackedScene
		if packed:
			node = packed.instantiate()
	elif scene_resource is PackedScene:
		node = scene_resource.instantiate()
	elif scene_resource is Node:
		node = scene_resource

	if not node:
		printerr("[UIManager] Failed to push screen.")
		return null

	if not screen_stack.is_empty():
		var top = screen_stack.back()
		if top is CanvasItem:
			top.visible = false

	add_child(node)
	screen_stack.append(node)
	return node

func pop_screen() -> Node:
	if screen_stack.is_empty():
		return null
	var top = screen_stack.pop_back()
	if is_instance_valid(top):
		top.queue_free()

	if not screen_stack.is_empty():
		var new_top = screen_stack.back()
		if new_top is CanvasItem:
			new_top.visible = true
			# Ensure focus is recovered on top screen
			_focus_first_interactive(new_top)
	return top

func replace_screen(scene_resource: Variant) -> Node:
	pop_screen()
	return push_screen(scene_resource)

func _focus_first_interactive(root_node: Node) -> void:
	var found = _find_first_focusable(root_node)
	if found and found is Control:
		found.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	if node is Control and node.visible and node.focus_mode != Control.FOCUS_NONE:
		if node is Button and not node.disabled:
			return node
		elif node is Slider:
			return node
	for child in node.get_children():
		var res = _find_first_focusable(child)
		if res:
			return res
	return null

# ----------------------------------------------------
# Calm Pixel Screen Transitions
# ----------------------------------------------------
func _setup_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0.03, 0.07, 0.08, 0.0) # #081213 near-black teal
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition_overlay)

func transition_to_scene(scene_path: String, duration: float = 0.25) -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "color:a", 1.0, duration)
	await transition_tween.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "color:a", 0.0, duration)
	await transition_tween.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ----------------------------------------------------
# Stacking Non-Blocking Toast Notifications
# ----------------------------------------------------
func _setup_toast_container() -> void:
	toast_container = VBoxContainer.new()
	toast_container.custom_minimum_size = Vector2(160, 0)
	toast_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toast_container.offset_left = -170
	toast_container.offset_top = 8
	toast_container.offset_right = -10
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_container.add_theme_constant_override("separation", 4)
	add_child(toast_container)

func show_toast(text: String, icon_badge: String = "✔") -> void:
	var toast = PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.custom_minimum_size = Vector2(140, 20)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)

	var badge = Label.new()
	badge.text = icon_badge
	badge.add_theme_color_override("font_color", Color("#ae7e54"))
	badge.add_theme_font_size_override("font_size", 8)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color("#ebd2bd"))
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(badge)
	hbox.add_child(lbl)
	toast.add_child(hbox)
	toast_container.add_child(toast)

	# Animate toast entry and dismissal
	toast.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.2)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	await tween.finished
	if is_instance_valid(toast):
		toast.queue_free()

func _detect_initial_input_mode() -> void:
	if DisplayServer.is_touchscreen_available():
		current_input_mode = InputMode.TOUCH
	elif Input.get_connected_joypads().size() > 0:
		current_input_mode = InputMode.GAMEPAD
	else:
		current_input_mode = InputMode.KEYBOARD
