class_name RelicMenu
extends Control

## Boss Relics & Perk Crafting Menu.
## Allows players to forge acquired Boss Relics into permanent passive combat perks.

signal closed()

const RELIC_DATA: Array[Dictionary] = [
	{
		"id": "clay_core",
		"name": "Clay Core",
		"boss": "Mud Golem (PRE-02)",
		"era": "Prehistoric",
		"desc": "+1 Maximum Health Pip permanently added to vital capacity.",
		"color": Color(0.85, 0.5, 0.2)
	},
	{
		"id": "gargoyle_talons",
		"name": "Gargoyle Talons",
		"boss": "Gargoyle Patriarch (MED-02)",
		"era": "Medieval",
		"desc": "+1 Bonus Damage to all Aerial Jump and Downward Slashes.",
		"color": Color(0.6, 0.7, 0.8)
	},
	{
		"id": "spirit_ribbon",
		"name": "Spirit Ribbon",
		"boss": "Onryo Mist (HIST-02)",
		"era": "Historical",
		"desc": "-5 Mana Cost discount on magic spells (15 MP -> 10 MP).",
		"color": Color(0.9, 0.3, 0.5)
	},
	{
		"id": "brass_chassis",
		"name": "Brass Chassis",
		"boss": "Spider Sentry (IND-02)",
		"era": "Industrial",
		"desc": "15% incoming damage reduction against physical and boss hits.",
		"color": Color(0.85, 0.65, 0.2)
	},
	{
		"id": "riot_visor",
		"name": "Riot Visor",
		"boss": "SWAT Juggernaut (MOD-02)",
		"era": "Modern",
		"desc": "+0.06s Dodge roll invulnerability window (0.20s -> 0.26s).",
		"color": Color(0.2, 0.7, 1.0)
	},
	{
		"id": "ion_cell",
		"name": "Ion Cell",
		"boss": "Sentinel Swarm-Mind (FUT-02)",
		"era": "Futuristic",
		"desc": "+30% Plasma Magic Velocity (220 -> 280) and +1 Spell Damage.",
		"color": Color(0.2, 0.95, 0.85)
	}
]

@onready var relic_list_container: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/RelicList
@onready var close_btn: Button = $Center/Panel/Margin/VBox/CloseButton

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	refresh_relics()

func open() -> void:
	visible = true
	refresh_relics()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func refresh_relics() -> void:
	for child in relic_list_container.get_children():
		child.queue_free()

	for r in RELIC_DATA:
		var relic_id: String = r["id"]
		var has_relic = SaveManager and SaveManager.has_relic(relic_id)
		var is_crafted = SaveManager and SaveManager.has_relic_perk(relic_id)

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 36)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# Era & Name VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_label = Label.new()
		title_label.text = "%s [%s Era]" % [r["name"], r["era"]]
		title_label.add_theme_font_size_override("font_size", 8)
		title_label.add_theme_color_override("font_color", r["color"] if has_relic else Color(0.5, 0.5, 0.5))

		var desc_label = Label.new()
		desc_label.text = r["desc"] if has_relic else "Defeat %s via secret challenge portal to acquire." % r["boss"]
		desc_label.add_theme_font_size_override("font_size", 7)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9) if has_relic else Color(0.4, 0.4, 0.45))

		info_vbox.add_child(title_label)
		info_vbox.add_child(desc_label)

		# Action Button
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(85, 24)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action_btn.add_theme_font_size_override("font_size", 7)

		if not has_relic:
			action_btn.text = "LOCKED"
			action_btn.disabled = true
		elif is_crafted:
			action_btn.text = "PERK ACTIVE ✔"
			action_btn.disabled = true
			action_btn.add_theme_color_override("font_color", Color(0.3, 0.95, 0.6))
		else:
			action_btn.text = "FORGE PERK"
			action_btn.pressed.connect(func():
				_forge_relic(relic_id)
			)

		hbox.add_child(info_vbox)
		hbox.add_child(action_btn)
		card.add_child(hbox)
		relic_list_container.add_child(card)

func _forge_relic(relic_id: String) -> void:
	if SaveManager and SaveManager.craft_relic_perk(relic_id):
		if SoundManager:
			SoundManager.play_sfx("checkpoint")
		refresh_relics()
