class_name SkillData
extends Resource

## Data-driven Skill specification for the 6 Skill Branches (Section 5).
## Branches: Attack, Defense, Healing, Necromancy, Shadow, Elemental.

@export var id: String = "skill_id"
@export_enum("Attack", "Defense", "Healing", "Necromancy", "Shadow", "Elemental") var branch: String = "Attack"
@export var display_name: String = "Skill Name"
@export_multiline var description: String = "Description of the skill."
@export var cost: int = 1
@export var required_skills: Array[String] = []

@export_group("Modifiers & Payloads")
# e.g. {"bonus_damage": 1, "bonus_speed": 15.0, "damage_reduction": 0.1, "mana_cost_reduction": 3}
@export var stat_modifiers: Dictionary = {}
@export var granted_ability: String = ""
