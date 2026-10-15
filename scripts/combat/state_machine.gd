class_name StateMachine
extends Node

## Reusable finite state machine for characters (Player, Enemies, Bosses).

signal transitioned(state_name: String)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Wait for owner to be ready
	await owner.ready
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.machine = self
			child.entity = owner as CharacterBody2D
			
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var key = target_state_name.to_lower()
	if not states.has(key):
		push_warning("[StateMachine] State not found: %s in %s" % [target_state_name, owner.name if owner else "unowned"])
		return
	if current_state:
		current_state.exit()
	current_state = states[key]
	current_state.enter(msg)
	transitioned.emit(target_state_name)

func get_current_state_name() -> String:
	return current_state.name if current_state else ""
