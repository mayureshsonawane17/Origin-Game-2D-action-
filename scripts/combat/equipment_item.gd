class_name EquipmentItem
extends Resource

## Data-driven equipment resource (Weapons, Catalysts, Armor) (Section 5).
## Modifies damage, defense, mobility, resource use, and attack properties.

@export var id: String = "item_id"
@export var display_name: String = "Equipment Name"
@export_multiline var description: String = ""
@export_enum("MELEE", "RANGED", "CATALYST", "ARMOR") var slot: String = "MELEE"

@export_group("Combat & Stat Modifiers")
@export var base_damage: int = 1
@export var defense_multiplier: float = 1.0 # < 1.0 takes less damage, > 1.0 takes more
@export var mobility_multiplier: float = 1.0 # Multiplies run speed
@export var mana_cost_multiplier: float = 1.0
@export var ammo_type: String = "" # "" for melee/catalysts, "bone_arrows" for ranged
@export var max_ammo: int = 0
@export var current_ammo: int = 0
@export var knockback_bonus: float = 0.0
@export var weapon_accent_color: Color = Color(0.85, 0.88, 0.95)
