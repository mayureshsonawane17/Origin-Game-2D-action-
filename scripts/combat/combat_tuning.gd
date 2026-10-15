class_name CombatTuning
extends Resource

## CombatTuning: Central resource holding all movement, combat feel, and frame data.
## Editable in inspector and saved to data/combat_tuning.tres.

@export_group("Movement")
@export var run_speed: float = 110.0
@export var jump_velocity: float = -300.0
@export var jump_cut_multiplier: float = 0.5
@export var gravity: float = 900.0
@export var fall_gravity_multiplier: float = 1.3
@export var coyote_time: float = 0.1 # ~6 frames at 60fps
@export var jump_buffer_time: float = 0.1 # ~6 frames at 60fps

@export_group("Combo Melee")
@export var combo_window: float = 0.4
# Attack 1
@export var attack1_damage: int = 1
@export var attack1_knockback: float = 80.0
@export var attack1_hitstop_frames: int = 3
@export var attack1_startup: float = 0.05
@export var attack1_active: float = 0.12
@export var attack1_recovery: float = 0.12

# Attack 2
@export var attack2_damage: int = 1
@export var attack2_knockback: float = 100.0
@export var attack2_hitstop_frames: int = 3
@export var attack2_startup: float = 0.05
@export var attack2_active: float = 0.12
@export var attack2_recovery: float = 0.12

# Attack 3 (Finisher)
@export var attack3_damage: int = 2
@export var attack3_knockback: float = 240.0
@export var attack3_hitstop_frames: int = 5
@export var attack3_startup: float = 0.08
@export var attack3_active: float = 0.15
@export var attack3_recovery: float = 0.22

@export_group("Magic Projectile")
@export var projectile_speed: float = 220.0
@export var projectile_damage: int = 2
@export var magic_cooldown: float = 0.5
@export var magic_mana_cost: int = 15
@export var max_mana: int = 50
@export var mana_regen_rate: float = 6.0

@export_group("Dodge")
@export var dodge_duration: float = 0.25
@export var dodge_invuln_duration: float = 0.2
@export var dodge_cooldown: float = 0.6
@export var dodge_speed: float = 200.0

@export_group("Health & Healing")
@export var max_health: int = 5
@export var max_heal_charges: int = 3
@export var heal_amount: int = 2
@export var heal_cooldown: float = 1.0
