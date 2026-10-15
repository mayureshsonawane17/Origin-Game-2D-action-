class_name SkillTreeManager
extends Node

## SkillTreeManager: Manages progression, skill unlock trees, and stat aggregates (Section 5).

signal skill_unlocked(skill: SkillData)
signal skill_points_changed(points: int)

@export var available_skill_points: int = 3

var unlocked_skill_ids: Array[String] = []
var all_skills: Dictionary = {} # id -> SkillData

func _ready() -> void:
	_load_registered_skills()

func _load_registered_skills() -> void:
	var skill_paths = [
		"res://data/skills/attack_finisher_mastery.tres",
		"res://data/skills/defense_fortified_parry.tres",
		"res://data/skills/healing_vital_regen.tres",
		"res://data/skills/necro_soul_siphon.tres",
		"res://data/skills/shadow_phase_dash.tres",
		"res://data/skills/elemental_spark_infusion.tres",
		"res://data/skills/attack_rending_strike.tres",
		"res://data/skills/defense_bulwark_stance.tres",
		"res://data/skills/attack_iaijutsu_strike.tres",
		"res://data/skills/shadow_smoke_veil.tres",
		"res://data/skills/attack_overclock_strike.tres",
		"res://data/skills/elem_overcharge_discharge.tres",
		"res://data/skills/defense_nanoweave_reinforcement.tres",
		"res://data/skills/necro_adrenaline_surge.tres"
	]
	for path in skill_paths:
		if ResourceLoader.exists(path):
			var res = load(path) as SkillData
			if res and not res.id.is_empty():
				all_skills[res.id] = res

func can_unlock_skill(skill_id: String) -> bool:
	if not all_skills.has(skill_id):
		return false
	if unlocked_skill_ids.has(skill_id):
		return false
	var skill = all_skills[skill_id] as SkillData
	if available_skill_points < skill.cost:
		return false
	for req in skill.required_skills:
		if not unlocked_skill_ids.has(req):
			return false
	return true

func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	var skill = all_skills[skill_id] as SkillData
	available_skill_points -= skill.cost
	unlocked_skill_ids.append(skill_id)
	skill_points_changed.emit(available_skill_points)
	skill_unlocked.emit(skill)
	return true

func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skill_ids.has(skill_id)

func add_skill_points(amount: int) -> void:
	available_skill_points += amount
	skill_points_changed.emit(available_skill_points)

func get_total_stat_modifiers() -> Dictionary:
	var totals: Dictionary = {}
	for id in unlocked_skill_ids:
		if all_skills.has(id):
			var skill = all_skills[id] as SkillData
			for key in skill.stat_modifiers.keys():
				var val = skill.stat_modifiers[key]
				if totals.has(key):
					totals[key] += val
				else:
					totals[key] = val
	return totals

func serialize() -> Dictionary:
	return {
		"available_skill_points": available_skill_points,
		"unlocked_skill_ids": unlocked_skill_ids
	}

func deserialize(data: Dictionary) -> void:
	if data.has("available_skill_points"):
		available_skill_points = int(data["available_skill_points"])
	if data.has("unlocked_skill_ids"):
		unlocked_skill_ids = []
		for id in data["unlocked_skill_ids"]:
			unlocked_skill_ids.append(str(id))
	skill_points_changed.emit(available_skill_points)
