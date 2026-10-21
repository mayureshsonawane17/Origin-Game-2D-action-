class_name BossController
extends CharacterBody2D

## Base class and framework for all ORIGIN bosses (Section 6).
## Driven by BossData; manages phase transitions, telegraphs, armor, and vulnerability.

signal boss_health_changed(current: int, max_hp: int)
signal boss_armor_changed(current: int, max_armor: int)
signal boss_phase_changed(phase: int, total_phases: int)
signal boss_staggered(duration: float)
signal boss_defeated()

const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var data: BossData

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual_root: Node2D = $VisualRoot

var current_health: int = 15
var current_armor: int = 0
var current_phase: int = 1
var facing_direction: int = -1

var is_vulnerable: bool = false
var is_staggered: bool = false
var is_dead: bool = false

var hitstop_timer: float = 0.0
var flash_timer: float = 0.0
var stagger_timer: float = 0.0
var telegraph_timer: float = 0.0

var player_ref: Player

func _ready() -> void:
	if data:
		current_health = data.max_health
		current_armor = data.armor_health if data.total_phases == 1 else 0
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self
	boss_health_changed.emit(current_health, data.max_health if data else current_health)
	boss_armor_changed.emit(current_armor, data.armor_health if data else current_armor)
	boss_phase_changed.emit(current_phase, data.total_phases if data else 1)

func _process(delta: float) -> void:
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			visual_root.modulate = Color.WHITE

	if stagger_timer > 0.0:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
			is_vulnerable = false
			visual_root.modulate = Color.WHITE

	if telegraph_timer > 0.0:
		telegraph_timer -= delta

func _physics_process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Player

func set_facing(dir: int) -> void:
	if dir == 0:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)
	hitbox.position.x = abs(hitbox.position.x) * float(dir)

func apply_hitstop(frames: int) -> void:
	hitstop_timer = float(frames) / 60.0

func flash_white(duration: float = 0.08) -> void:
	flash_timer = duration
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

func telegraph(duration: float, color: Color = Color(1.0, 0.4, 0.1)) -> void:
	telegraph_timer = duration
	visual_root.modulate = color

func stagger(duration: float = 0.6) -> void:
	is_staggered = true
	is_vulnerable = true
	stagger_timer = duration
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	visual_root.modulate = Color(1.0, 0.9, 0.3, 1.0) # Golden stagger glow
	boss_staggered.emit(duration)

func _on_hurtbox_hit_received(dmg: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# Breakable Armor Handling (e.g. Era Boss Phase 2)
	if current_armor > 0:
		current_armor = max(0, current_armor - dmg)
		boss_armor_changed.emit(current_armor, data.armor_health)
		flash_white(0.08)
		apply_hitstop(hitstop_frames)
		var spark = HIT_SPARK_SCENE.instantiate()
		spark.global_position = global_position + Vector2(0, -20)
		spark.spark_color = Color(0.7, 0.6, 0.5, 1.0) # Rock shatter spark
		get_parent().add_child(spark)

		if current_armor <= 0:
			# Armor shattered! Big stagger window
			stagger(2.0)
		return

	# Vulnerability multiplier
	var final_damage = dmg
	if is_vulnerable:
		final_damage = int(round(dmg * 1.5))

	current_health = max(0, current_health - final_damage)
	boss_health_changed.emit(current_health, data.max_health)
	apply_hitstop(hitstop_frames)
	flash_white(0.1)

	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -20)
	spark.is_heavy = is_finisher or is_vulnerable
	get_parent().add_child(spark)

	# Check Phase Transition
	_check_phase_transition()

	if current_health <= 0:
		_die()

func _check_phase_transition() -> void:
	if not data or data.total_phases <= 1 or is_dead:
		return

	var hp_ratio = float(current_health) / float(data.max_health)
	var new_phase = current_phase

	if data.total_phases == 3:
		if hp_ratio <= 0.33 and current_phase < 3:
			new_phase = 3
		elif hp_ratio <= 0.66 and current_phase < 2:
			new_phase = 2

	if new_phase != current_phase:
		current_phase = new_phase
		boss_phase_changed.emit(current_phase, data.total_phases)
		if SoundManager:
			SoundManager.play_sfx("boss_phase")
		_on_phase_entered(current_phase)

func _on_phase_entered(phase: int) -> void:
	# Virtual hook for concrete boss subclasses
	flash_white(0.3)
	apply_hitstop(8)

func _die() -> void:
	is_dead = true
	if SoundManager:
		SoundManager.play_sfx("boss_roar")
	boss_defeated.emit()
	hurtbox.is_invulnerable = true
	hurtbox.monitoring = false
	hitbox.monitoring = false
	velocity = Vector2.ZERO
	# Dramatic defeat fade
	var tween = create_tween()
	tween.tween_property(visual_root, "modulate:a", 0.0, 1.5)
	tween.tween_callback(queue_free)
