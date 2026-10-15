class_name Player
extends CharacterBody2D

## Player controller for ORIGIN.
## Integrates combat tuning, state machine, Dan-the-Man combo, and unified inputs.

signal health_changed(current: int, max_hp: int)
signal mana_changed(current: float, max_mp: float)
signal heal_charges_changed(current: int, max_charges: int)
signal dodge_cooldown_updated(remaining: float, total: float)
signal player_died()

const MAGIC_PROJECTILE_SCENE = preload("res://scenes/characters/magic_projectile.tscn")
const HIT_SPARK_SCENE = preload("res://scenes/characters/hit_spark.tscn")

@export var tuning: CombatTuning

@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual_root: Node2D = $VisualRoot
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var camera: Camera2D = $Camera2D

var current_health: int = 5
var current_mana: float = 50.0
var heal_charges: int = 3
var facing_direction: int = 1

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var magic_cooldown_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var heal_cooldown_timer: float = 0.0
var hitstop_timer: float = 0.0

var is_dead: bool = false
var is_blocking: bool = false
var is_parrying: bool = false
var flash_timer: float = 0.0

func _ready() -> void:
	if not tuning:
		tuning = load("res://data/combat_tuning.tres") as CombatTuning
		if not tuning:
			tuning = CombatTuning.new()

	current_health = tuning.max_health
	current_mana = float(tuning.max_mana)
	heal_charges = tuning.max_heal_charges

	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	hitbox.attacker_owner = self

	# Emit initial state for HUD
	emit_signal("health_changed", current_health, tuning.max_health)
	emit_signal("mana_changed", current_mana, float(tuning.max_mana))
	emit_signal("heal_charges_changed", heal_charges, tuning.max_heal_charges)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_hitbox"):
		Hitbox.debug_show_hitboxes = not Hitbox.debug_show_hitboxes
		print("[ORIGIN Debug] Hitboxes visible: %s" % Hitbox.debug_show_hitboxes)

func _process(delta: float) -> void:
	# Hit-stop handling
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	# Mana regeneration
	if current_mana < tuning.max_mana and not is_dead:
		current_mana = min(current_mana + tuning.mana_regen_rate * delta, float(tuning.max_mana))
		mana_changed.emit(current_mana, float(tuning.max_mana))

	# Cooldown timers
	if magic_cooldown_timer > 0.0:
		magic_cooldown_timer -= delta
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
		dodge_cooldown_updated.emit(dodge_cooldown_timer, tuning.dodge_cooldown)
	if heal_cooldown_timer > 0.0:
		heal_cooldown_timer -= delta

	# Hit flash restoration
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			visual_root.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	if hitstop_timer > 0.0:
		return

	# Timers update
	if is_on_floor():
		coyote_timer = tuning.coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = tuning.jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	visual_root.scale.x = float(dir)
	# Align hitbox offset to facing
	hitbox.position.x = abs(hitbox.position.x) * float(dir)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav = tuning.gravity
		if velocity.y > 0.0:
			grav *= tuning.fall_gravity_multiplier
		velocity.y += grav * delta

func can_dodge() -> bool:
	return dodge_cooldown_timer <= 0.0 and not is_dead

func can_cast_magic() -> bool:
	return magic_cooldown_timer <= 0.0 and current_mana >= tuning.magic_mana_cost and not is_dead

func can_heal() -> bool:
	return heal_charges > 0 and current_health < tuning.max_health and heal_cooldown_timer <= 0.0 and not is_dead

func cast_magic() -> void:
	if not can_cast_magic():
		return
	current_mana -= tuning.magic_mana_cost
	magic_cooldown_timer = tuning.magic_cooldown
	mana_changed.emit(current_mana, float(tuning.max_mana))

	var proj = MAGIC_PROJECTILE_SCENE.instantiate() as MagicProjectile
	proj.global_position = global_position + Vector2(facing_direction * 18.0, -18.0)
	proj.direction = Vector2(facing_direction, 0.0)
	proj.speed = tuning.projectile_speed
	proj.damage = tuning.projectile_damage
	proj.caster = self
	get_parent().add_child(proj)

func perform_heal() -> void:
	if not can_heal():
		return
	heal_charges -= 1
	heal_cooldown_timer = tuning.heal_cooldown
	current_health = min(current_health + tuning.heal_amount, tuning.max_health)
	health_changed.emit(current_health, tuning.max_health)
	heal_charges_changed.emit(heal_charges, tuning.max_heal_charges)

	# Visual heal pulse
	_spawn_heal_fx()

func apply_hitstop(frames: int) -> void:
	hitstop_timer = float(frames) / 60.0

func flash_white(duration: float = 0.08) -> void:
	flash_timer = duration
	visual_root.modulate = Color(4.0, 4.0, 4.0, 1.0)

func _spawn_heal_fx() -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -20)
	spark.spark_color = Color(0.2, 1.0, 0.4, 1.0)
	spark.is_heavy = true
	get_parent().add_child(spark)

func _on_hurtbox_hit_received(damage: int, knockback: Vector2, hitstop_frames: int, attacker: Node2D, is_finisher: bool) -> void:
	if is_dead:
		return

	# 1. Timed Parry Check
	if is_parrying:
		# PERFECT PARRY! Negate damage entirely and counter
		apply_hitstop(tuning.counter_hitstop_frames)
		flash_white(0.15)
		var spark = HIT_SPARK_SCENE.instantiate()
		spark.global_position = global_position + Vector2(facing_direction * 10, -18)
		spark.spark_color = Color(1.0, 0.9, 0.2, 1.0) # Golden parry flash
		spark.is_heavy = true
		get_parent().add_child(spark)
		if camera and camera.has_method("shake"):
			camera.shake(3.0, 0.2)
		if attacker and attacker.has_method("stagger"):
			attacker.stagger(0.6)
		# Trigger counter attack
		state_machine.transition_to("attack", {"combo_index": 3, "is_counter": true})
		return

	# 2. Normal Block Check
	if is_blocking:
		# Reduced damage and absorbed knockback
		var reduced_dmg = max(1, int(ceil(float(damage) * (1.0 - tuning.block_damage_reduction))))
		current_health = max(0, current_health - reduced_dmg)
		health_changed.emit(current_health, tuning.max_health)
		apply_hitstop(hitstop_frames)
		var spark = HIT_SPARK_SCENE.instantiate()
		spark.global_position = global_position + Vector2(facing_direction * 10, -18)
		spark.spark_color = Color(0.3, 0.7, 1.0, 1.0) # Blue block spark
		get_parent().add_child(spark)
		velocity = knockback * 0.2
		return

	# 3. Standard Unblocked Hit
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, tuning.max_health)
	
	apply_hitstop(hitstop_frames)
	flash_white(0.1)

	# Hit spark
	var spark = HIT_SPARK_SCENE.instantiate()
	spark.global_position = global_position + Vector2(0, -18)
	spark.is_heavy = is_finisher
	get_parent().add_child(spark)

	# Camera shake
	if camera and camera.has_method("shake"):
		camera.shake(4.0 if is_finisher else 2.0, 0.2)

	if current_health <= 0:
		is_dead = true
		player_died.emit()
		state_machine.transition_to("die")
	else:
		state_machine.transition_to("hurt", {"knockback": knockback})
