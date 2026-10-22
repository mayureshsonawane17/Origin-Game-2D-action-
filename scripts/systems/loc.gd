class_name Loc
extends RefCounted

## Centralized Localization and UI String Provider.
## Loads strings from data/strings.json to avoid hard-coded strings across scenes.

static var _strings: Dictionary = {}
static var _loaded: bool = false

static func init_strings() -> void:
	if _loaded:
		return
	var path = "res://data/strings.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary:
				_strings = parsed
				_loaded = true
				return
	_loaded = true

static func get_str(key: String, default_val: String = "") -> String:
	init_strings()
	var parts = key.split(".")
	var current: Variant = _strings
	for p in parts:
		if current is Dictionary and current.has(p):
			current = current[p]
		else:
			return default_val if default_val != "" else key
	if current is String:
		return current
	return default_val if default_val != "" else key

static func get_text(key: String, default_val: String = "") -> String:
	return get_str(key, default_val)
