class_name EnemyState
extends State

var enemy: EnemyProwler

func _ready() -> void:
	await owner.ready
	enemy = owner as EnemyProwler
