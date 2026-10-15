class_name State
extends Node

## Base class for all states in the state machine.

var machine: StateMachine
var entity: CharacterBody2D

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
