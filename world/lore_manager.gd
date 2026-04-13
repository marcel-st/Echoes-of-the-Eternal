extends Node

const LORE_PATH := "res://data/world/lore_entries.json"

var _entries: Dictionary = {}
var _ordered_ids: Array[String] = []
var _is_loaded := false
var _generated_dialogues: Dictionary = {}
var _discovered_ids: Dictionary = {}


func _ready() -> void:
	reload_lore()


func reload_lore() -> void:
	_entries.clear()
	_ordered_ids.clear()
	_generated_dialogues.clear()
	_is_loaded = false

	if not FileAccess.file_exists(LORE_PATH):
		push_warning("Lore entries file missing at %s" % LORE_PATH)
		return

	var file := FileAccess.open(LORE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Unable to open lore entries.")
		return

	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("Unable to parse lore_entries.json: %s" % parser.get_error_message())
		return

	var payload := parser.data
	if typeof(payload) != TYPE_DICTIONARY:
		return

	var entries_variant := (payload as Dictionary).get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY:
		return

	for entry_variant in entries_variant as Array:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		var entry_id := String(entry.get("id", "")).strip_edges()
		if entry_id.is_empty():
			continue
		_entries[entry_id] = entry
		_ordered_ids.append(entry_id)

	_is_loaded = true


func mark_entry_discovered(lore_entry_id: String) -> void:
	var entry_id := lore_entry_id.strip_edges()
	if entry_id.is_empty():
		return
	if not has_lore(StringName(entry_id)):
		return
	_discovered_ids[entry_id] = true


func is_entry_discovered(lore_entry_id: String) -> bool:
	return _discovered_ids.get(lore_entry_id.strip_edges(), false)


func get_or_create_dialogue_for_lore(lore_entry_id: String) -> String:
	_ensure_loaded()
	var entry_id := lore_entry_id.strip_edges()
	if entry_id.is_empty():
		return ""
	if not _entries.has(entry_id):
		return ""
	if _generated_dialogues.has(entry_id):
		return String(_generated_dialogues[entry_id])

	var dialogue_id := "LORE_%s" % entry_id.to_upper()
	var entry := _entries[entry_id] as Dictionary
	var title := String(entry.get("title", "Lore"))
	var text := String(entry.get("text", ""))
	_generated_dialogues[entry_id] = dialogue_id
	DialogueManager.register_runtime_dialogue(
		dialogue_id,
		{
			"entries": [
				{
					"speaker": "Lore",
					"text": title,
				},
				{
					"speaker": "Lore",
					"text": text,
				},
			],
			"meta": {
				"source": String(entry.get("source", "")),
				"lore_entry_id": entry_id,
			},
		}
	)
	mark_entry_discovered(entry_id)
	return dialogue_id


func has_lore(lore_id: StringName) -> bool:
	_ensure_loaded()
	return _entries.has(String(lore_id))


func get_lore(lore_id: StringName) -> Dictionary:
	_ensure_loaded()
	return _entries.get(String(lore_id), {}).duplicate(true)


func get_lore_ids() -> Array[String]:
	_ensure_loaded()
	return _ordered_ids.duplicate()


func export_discovered_entries() -> Dictionary:
	return _discovered_ids.duplicate(true)


func import_discovered_entries(payload: Dictionary) -> void:
	_discovered_ids.clear()
	for key_variant in payload.keys():
		var key := String(key_variant).strip_edges()
		if key.is_empty():
			continue
		_discovered_ids[key] = bool(payload[key_variant])


func _ensure_loaded() -> void:
	if not _is_loaded:
		reload_lore()
