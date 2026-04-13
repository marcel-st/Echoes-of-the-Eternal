extends Node

const QUESTS_PATH := "res://data/quests/quests.json"

var quest_definitions: Dictionary = {}
var quest_states: Dictionary = {}
var quest_progress: Dictionary = {}


func _ready() -> void:
	reload_quests()


func reload_quests(path: String = QUESTS_PATH) -> void:
	quest_definitions.clear()
	quest_states.clear()
	quest_progress.clear()

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
		var objectives_variant := quest.get("objectives", [])
		var progress_by_objective: Dictionary = {}
		if typeof(objectives_variant) == TYPE_ARRAY:
			for objective_variant in objectives_variant:
				if typeof(objective_variant) != TYPE_DICTIONARY:
					continue
				var objective := objective_variant as Dictionary
				var objective_id := StringName(objective.get("id", ""))
				if objective_id.is_empty():
					continue
				progress_by_objective[objective_id] = 0
		quest_progress[quest_id] = progress_by_objective


func get_quest(quest_id: StringName) -> Dictionary:
	return quest_definitions.get(quest_id, {}).duplicate(true)


func get_quest_state(quest_id: StringName) -> String:
	return quest_states.get(quest_id, "unknown")


func get_objective_progress(quest_id: StringName, objective_id: StringName) -> int:
	var progress_by_objective := quest_progress.get(quest_id, {})
	if typeof(progress_by_objective) != TYPE_DICTIONARY:
		return 0
	return int((progress_by_objective as Dictionary).get(objective_id, 0))


func get_active_quests() -> Array:
	var output: Array = []
	for quest_id_variant in quest_states.keys():
		var quest_id := StringName(quest_id_variant)
		var state := String(quest_states.get(quest_id, "unknown"))
		if state != "active":
			continue

		var quest := get_quest(quest_id)
		if quest.is_empty():
			continue
		var objectives_output: Array = []
		var objectives_variant := quest.get("objectives", [])
		if typeof(objectives_variant) == TYPE_ARRAY:
			for objective_variant in objectives_variant as Array:
				if typeof(objective_variant) != TYPE_DICTIONARY:
					continue
				var objective := objective_variant as Dictionary
				var objective_id := StringName(objective.get("id", ""))
				if objective_id.is_empty():
					continue
				objectives_output.append(
					{
						"id": String(objective_id),
						"description": String(objective.get("description", "")),
						"required": int(objective.get("required", 1)),
						"progress": get_objective_progress(quest_id, objective_id),
					}
				)

		output.append(
			{
				"id": String(quest_id),
				"title": String(quest.get("title", String(quest_id))),
				"description": String(quest.get("description", "")),
				"objectives": objectives_output,
			}
		)
	return output


func set_quest_state(quest_id: StringName, new_state: String) -> void:
	if not quest_definitions.has(quest_id):
		return
	quest_states[quest_id] = new_state
	EventBus.quest_state_changed.emit(String(quest_id), new_state)
	if new_state == "active":
		EventBus.quest_started.emit(quest_id)
	elif new_state == "completed":
		EventBus.quest_completed.emit(quest_id)
		_unlock_follow_up_quest(quest_id)


func start_quest(quest_id: StringName) -> bool:
	if not quest_definitions.has(quest_id):
		return false
	var current_state := get_quest_state(quest_id)
	if current_state == "active" or current_state == "completed":
		return false
	set_quest_state(quest_id, "active")
	return true


func complete_objective(quest_id: StringName, objective_id: StringName, amount: int = 1) -> bool:
	if not quest_definitions.has(quest_id):
		return false
	if not quest_progress.has(quest_id):
		return false

	var objective_progress := quest_progress[quest_id] as Dictionary
	if not objective_progress.has(objective_id):
		return false

	var next_progress := int(objective_progress[objective_id]) + maxi(1, amount)
	objective_progress[objective_id] = next_progress
	quest_progress[quest_id] = objective_progress
	EventBus.quest_updated.emit(quest_id, objective_id, next_progress)

	if _is_quest_objectives_complete(quest_id):
		complete_quest(quest_id)
	return true


func complete_quest(quest_id: StringName) -> bool:
	if not quest_definitions.has(quest_id):
		return false
	set_quest_state(quest_id, "completed")
	return true


func export_state() -> Dictionary:
	return {
		"states": quest_states.duplicate(true),
		"progress": quest_progress.duplicate(true),
	}


func import_state(payload: Dictionary) -> void:
	if payload.has("states") and typeof(payload["states"]) == TYPE_DICTIONARY:
		var imported_states := (payload["states"] as Dictionary).duplicate(true)
		for quest_id_variant in quest_definitions.keys():
			var quest_id := StringName(quest_id_variant)
			if imported_states.has(quest_id):
				quest_states[quest_id] = imported_states[quest_id]
	if payload.has("progress") and typeof(payload["progress"]) == TYPE_DICTIONARY:
		var imported_progress := (payload["progress"] as Dictionary).duplicate(true)
		for quest_id_variant in quest_definitions.keys():
			var quest_id := StringName(quest_id_variant)
			if imported_progress.has(quest_id) and typeof(imported_progress[quest_id]) == TYPE_DICTIONARY:
				quest_progress[quest_id] = (imported_progress[quest_id] as Dictionary).duplicate(true)


func _is_quest_objectives_complete(quest_id: StringName) -> bool:
	var quest := get_quest(quest_id)
	var objectives_variant := quest.get("objectives", [])
	if typeof(objectives_variant) != TYPE_ARRAY:
		return false

	var progress := quest_progress.get(quest_id, {}) as Dictionary
	for objective_variant in objectives_variant as Array:
		if typeof(objective_variant) != TYPE_DICTIONARY:
			continue
		var objective := objective_variant as Dictionary
		var objective_id := StringName(objective.get("id", ""))
		if objective_id.is_empty():
			continue
		var required := int(objective.get("required", 1))
		var current := int(progress.get(objective_id, 0))
		if current < required:
			return false
	return true


func _unlock_follow_up_quest(quest_id: StringName) -> void:
	var quest := get_quest(quest_id)
	var next_quest := StringName(String(quest.get("next_quest", "")).strip_edges())
	if next_quest.is_empty():
		return
	if not quest_definitions.has(next_quest):
		return
	if get_quest_state(next_quest) == "locked":
		set_quest_state(next_quest, "available")
