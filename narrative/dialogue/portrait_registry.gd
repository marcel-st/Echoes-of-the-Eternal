extends Node

const NPC_REGISTRY_PATH := "res://data/npcs/npc_registry.json"

var _lookup: Dictionary = {}
var _portrait_colors: Dictionary = {}
var _loaded := false


func _ready() -> void:
	reload_registry()


func reload_registry() -> void:
	_lookup.clear()
	_portrait_colors.clear()
	_loaded = false

	if not FileAccess.file_exists(NPC_REGISTRY_PATH):
		push_warning("NPC registry missing at %s" % NPC_REGISTRY_PATH)
		return

	var file := FileAccess.open(NPC_REGISTRY_PATH, FileAccess.READ)
	if file == null:
		push_warning("Unable to open NPC registry file.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("NPC registry data is invalid.")
		return

	var root := parsed as Dictionary
	var lookup_variant: Variant = root.get("lookup", {})
	if typeof(lookup_variant) == TYPE_DICTIONARY:
		_lookup = (lookup_variant as Dictionary).duplicate(true)

	_build_portrait_palette(root)
	_loaded = true


func resolve_display_name(speaker_token: String) -> String:
	_ensure_loaded()
	var portrait_id := String(resolve_portrait_id(speaker_token))
	if portrait_id.is_empty():
		return speaker_token
	if _lookup.has(portrait_id):
		return String(_lookup[portrait_id])
	return speaker_token


func resolve_portrait_id(speaker_token: String) -> StringName:
	_ensure_loaded()
	var normalized := speaker_token.strip_edges().to_lower()
	for key_variant in _lookup.keys():
		var key := String(key_variant)
		var display_name := String(_lookup[key_variant])
		if normalized == key.to_lower():
			return StringName(key)
		if normalized == display_name.to_lower():
			return StringName(key)
	return StringName(normalized.replace(" ", "_"))


func resolve_portrait_color(speaker_token: String) -> Color:
	_ensure_loaded()
	var portrait_id := String(resolve_portrait_id(speaker_token))
	if portrait_id.is_empty():
		return Color(0.31, 0.46, 0.74, 1.0)
	var lowered := portrait_id.to_lower()
	for key_variant in _portrait_colors.keys():
		var key := String(key_variant)
		if lowered == key.to_lower():
			return _portrait_colors[key_variant]
	return Color(0.31, 0.46, 0.74, 1.0)


func _ensure_loaded() -> void:
	if not _loaded:
		reload_registry()


func _build_portrait_palette(root: Dictionary) -> void:
	var palette := [
		Color(0.31, 0.46, 0.74, 1.0),
		Color(0.62, 0.31, 0.74, 1.0),
		Color(0.25, 0.62, 0.47, 1.0),
		Color(0.78, 0.52, 0.25, 1.0),
		Color(0.66, 0.33, 0.37, 1.0),
		Color(0.29, 0.57, 0.67, 1.0),
	]

	var ordered_ids: Array = []
	var characters_variant: Variant = root.get("characters", {})
	if typeof(characters_variant) == TYPE_DICTIONARY:
		for char_id in (characters_variant as Dictionary).keys():
			ordered_ids.append(String(char_id))

	var npcs_variant: Variant = root.get("npcs", {})
	if typeof(npcs_variant) == TYPE_DICTIONARY:
		for npc_id in (npcs_variant as Dictionary).keys():
			ordered_ids.append(String(npc_id))

	var index := 0
	for entry_id in ordered_ids:
		_portrait_colors[entry_id] = palette[index % palette.size()]
		index += 1
