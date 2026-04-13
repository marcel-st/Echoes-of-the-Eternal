extends Node

const DIALOGUE_PATH := "res://data/dialogue/dialogues.json"

var _dialogues: Dictionary = {}
var _is_loaded := false
var _active_dialogue_id: StringName = &""
var _active_context: Dictionary = {}


func _ready() -> void:
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	reload_dialogues()


func reload_dialogues() -> void:
	if not FileAccess.file_exists(DIALOGUE_PATH):
		push_warning("Dialogue file missing at %s" % DIALOGUE_PATH)
		_dialogues.clear()
		_is_loaded = false
		return

	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Unable to open dialogues file.")
		return

	var parser := JSON.new()
	var parse_result := parser.parse(file.get_as_text())
	if parse_result != OK:
		push_warning("Unable to parse dialogues.json: %s" % parser.get_error_message())
		return

	var data := parser.data
	_dialogues = data if data is Dictionary else {}
	_is_loaded = true


func request_dialogue(dialogue_id: StringName, context: Dictionary = {}) -> void:
	EventBus.dialogue_requested.emit(dialogue_id, context)


func has_dialogue(dialogue_id: StringName) -> bool:
	return _dialogues.has(String(dialogue_id))


func get_dialogue(dialogue_id: StringName) -> Dictionary:
	return _dialogues.get(String(dialogue_id), {})


func close_active_dialogue() -> void:
	if _active_dialogue_id.is_empty():
		return
	EventBus.dialogue_finished.emit(String(_active_dialogue_id))
	EventBus.dialogue_closed.emit(_active_dialogue_id)
	_active_dialogue_id = &""
	_active_context.clear()


func are_conditions_met(conditions: Variant) -> bool:
	if conditions == null:
		return true
	if typeof(conditions) == TYPE_STRING:
		return _evaluate_condition_token(String(conditions))
	if typeof(conditions) != TYPE_ARRAY:
		return true

	for condition in conditions as Array:
		if not _evaluate_condition_token(String(condition)):
			return false
	return true


func apply_effects(effects: Variant, context: Dictionary = {}) -> StringName:
	var jump_target := &""
	if effects == null:
		return jump_target

	if typeof(effects) == TYPE_STRING:
		jump_target = _apply_effect_token(String(effects), context)
	elif typeof(effects) == TYPE_ARRAY:
		for effect in effects as Array:
			if typeof(effect) == TYPE_STRING:
				var resolved_target := _apply_effect_token(String(effect), context)
				if not resolved_target.is_empty():
					jump_target = resolved_target
	elif typeof(effects) == TYPE_DICTIONARY:
		var effect_dict := effects as Dictionary
		for key in effect_dict.keys():
			var token := "%s:%s" % [String(key), String(effect_dict[key])]
			var dict_target := _apply_effect_token(token, context)
			if not dict_target.is_empty():
				jump_target = dict_target

	return jump_target


func get_active_context() -> Dictionary:
	return _active_context.duplicate(true)


func _evaluate_condition_token(token: String) -> bool:
	var cleaned := token.strip_edges()
	if cleaned.is_empty():
		return true

	var parts := cleaned.split("==")
	if parts.size() == 2:
		var key := parts[0].strip_edges()
		var expected_value_raw := parts[1].strip_edges().to_lower()
		var expected_value: Variant = expected_value_raw
		if expected_value_raw == "true":
			expected_value = true
		elif expected_value_raw == "false":
			expected_value = false
		var actual := WorldFlags.get_flag(StringName(key), false)
		return actual == expected_value

	if cleaned.begins_with("quest_state:"):
		var quest_parts := cleaned.split(":")
		if quest_parts.size() >= 3:
			var quest_id := StringName(quest_parts[1].strip_edges())
			var expected_state := quest_parts[2].strip_edges()
			return QuestManager.get_quest_state(quest_id) == expected_state
		return false

	return bool(WorldFlags.get_flag(StringName(cleaned), false))


func _apply_effect_token(token: String, context: Dictionary) -> StringName:
	var cleaned := token.strip_edges()
	if cleaned.is_empty():
		return &""

	if cleaned.begins_with("set_flag:"):
		var payload := cleaned.trim_prefix("set_flag:")
		var flag_parts := payload.split("=")
		if flag_parts.size() == 2:
			var flag_key := flag_parts[0].strip_edges()
			var raw_value := flag_parts[1].strip_edges().to_lower()
			var flag_value: Variant = raw_value
			if raw_value == "true":
				flag_value = true
			elif raw_value == "false":
				flag_value = false
			WorldFlags.set_flag(StringName(flag_key), flag_value)
		return &""

	if cleaned.begins_with("start_quest:"):
		var quest_id := StringName(cleaned.trim_prefix("start_quest:").strip_edges())
		QuestManager.start_quest(quest_id)
		return &""

	if cleaned.begins_with("set_quest_state:"):
		var payload := cleaned.trim_prefix("set_quest_state:")
		var quest_state_parts := payload.split(":")
		if quest_state_parts.size() >= 2:
			var quest_id := StringName(quest_state_parts[0].strip_edges())
			var quest_state := quest_state_parts[1].strip_edges()
			QuestManager.set_quest_state(quest_id, quest_state)
		return &""

	if cleaned.begins_with("give_item:"):
		var payload := cleaned.trim_prefix("give_item:")
		var item_parts := payload.split(":")
		var item_id := StringName(item_parts[0].strip_edges())
		var amount := 1
		if item_parts.size() >= 2:
			amount = maxi(1, int(item_parts[1].strip_edges()))
		EventBus.item_received.emit(item_id, amount)
		return &""

	if cleaned.begins_with("jump_to:"):
		var jump_to := cleaned.trim_prefix("jump_to:").strip_edges()
		return StringName(jump_to)

	if cleaned.begins_with("prompt:"):
		EventBus.request_ui_prompt.emit(cleaned.trim_prefix("prompt:").strip_edges())
		return &""

	# Backwards compatible shorthand.
	WorldFlags.set_flag(StringName(cleaned), true)
	if context.has("effect_log") and context["effect_log"] is Array:
		(context["effect_log"] as Array).append(cleaned)
	return &""


func _on_dialogue_requested(dialogue_id: StringName, context: Dictionary) -> void:
	if not _is_loaded:
		reload_dialogues()

	if not has_dialogue(dialogue_id):
		push_warning("Dialogue id not found: %s" % String(dialogue_id))
		return

	_active_dialogue_id = dialogue_id
	_active_context = context.duplicate(true)
	EventBus.dialogue_started.emit(String(dialogue_id))
	EventBus.request_ui_prompt.emit("Dialogue started: %s (Confirm to close)" % String(dialogue_id))
