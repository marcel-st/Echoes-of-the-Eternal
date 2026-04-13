extends Node

const QUESTS_PATH := "res://data/quests/sample_quest.json"

var quest_definitions: Dictionary = {}
var quest_states: Dictionary = {}


func _ready() -> void:
	reload_quests()


func reload_quests(path: String = QUESTS_PATH) -> void:
	quest_definitions.clear()
	quest_states.clear()

	if not FileAccess.file_exists(path):
		push_warning("Quest file missing at %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open quests file: %s" % path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Quest data is invalid.")
		return

	var root := parsed as Dictionary
	var quests_variant := root.get("quests", [])
	if typeof(quests_variant) != TYPE_ARRAY:
		return

	for entry in quests_variant:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var quest := entry as Dictionary
		var quest_id := StringName(quest.get("id", ""))
		if quest_id.is_empty():
			continue
		quest_definitions[quest_id] = quest
		quest_states[quest_id] = String(quest.get("state", "locked"))


func get_quest(quest_id: StringName) -> Dictionary:
	return quest_definitions.get(quest_id, {}).duplicate(true)


func get_quest_state(quest_id: StringName) -> String:
	return quest_states.get(quest_id, "unknown")


func set_quest_state(quest_id: StringName, new_state: String) -> void:
	if not quest_definitions.has(quest_id):
		return
	quest_states[quest_id] = new_state
	EventBus.quest_state_changed.emit(String(quest_id), new_state)
