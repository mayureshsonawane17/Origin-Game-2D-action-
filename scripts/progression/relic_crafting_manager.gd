class_name RelicCraftingManager
extends RefCounted

## RelicCraftingManager: Defines and tracks craftable perks derived from
## the 6 Tier 1 Regular Boss relics.

const RELIC_DEFINITIONS: Dictionary = {
	"clay_core": {
		"name": "Earthen Core",
		"boss": "PRE-02 Mud Golem",
		"era": "Prehistoric",
		"icon_col": Color(0.85, 0.5, 0.2),
		"description": "Ancient sediment infuses hero vitals. Increases Max HP by +1."
	},
	"gargoyle_talons": {
		"name": "Gargoyle's Talons",
		"boss": "MED-02 Gargoyle Patriarch",
		"era": "Medieval",
		"icon_col": Color(0.55, 0.62, 0.72),
		"description": "Sharpened cathedral talons. Jump attacks deal +1 bonus damage."
	},
	"spirit_ribbon": {
		"name": "Spirit Ribbon",
		"boss": "HIST-02 Onryo of the Mist",
		"era": "Historical",
		"icon_col": Color(0.85, 0.25, 0.45),
		"description": "Mist-woven crimson silk. Reduces Magic Mana cost from 15 to 10."
	},
	"brass_chassis": {
		"name": "Clockwork Chassis",
		"boss": "IND-02 Spider Sentry",
		"era": "Industrial",
		"icon_col": Color(0.85, 0.55, 0.2),
		"description": "Pneumatic brass plating. Reduces incoming damage by 15%."
	},
	"riot_visor": {
		"name": "Tactical Visor",
		"boss": "MOD-02 SWAT Juggernaut",
		"era": "Modern",
		"icon_col": Color(0.2, 0.65, 0.9),
		"description": "Optical telemetry matrix. Extends dodge invulnerability frames."
	},
	"ion_cell": {
		"name": "Ion Plasma Core",
		"boss": "FUT-02 Sentinel Swarm",
		"era": "Futuristic",
		"icon_col": Color(0.1, 0.9, 0.8),
		"description": "Charged plasma capacitor. Magic projectiles fly faster and deal +1 damage."
	}
}

static func get_relic_list() -> Array[String]:
	var list: Array[String] = []
	for k in RELIC_DEFINITIONS.keys():
		list.append(str(k))
	return list

static func get_relic_info(relic_id: String) -> Dictionary:
	return RELIC_DEFINITIONS.get(relic_id, {})
