extends Node
## Dialogue and Portrait Manager — global Autoload.
##
## Primary entry point: start_dialogue(npc_id, dialogue_key)
##   Resolves character data from characters.json, pauses Player and the active
##   NPC's _process, then fires the dialogue pipeline through EventBus so the
##   existing DialogueBox UI renders the conversation.
##
## Per-line signal: dialogue_line_ready(speaker_name, text, portrait_path)
##   Emitted each time a new dialogue entry is shown. Connect from subtitles,
##   voice-over triggers, or any system that needs to react to spoken lines.
##
## Choice signals: dialogue_choices_ready / dialogue_choice_made
##   dialogue_choices_ready fires when the player is presented a choice list.
##   dialogue_choice_made fires after a choice is confirmed — connect from
##   QuestManager or any system that branches on player decisions.

## Emitted per visible line; portrait_path is "" when no sprite exists yet.
signal dialogue_line_ready(speaker_name: String, text: String, portrait_path: String)
## Emitted when the player is shown a choice list. choices is Array[Dictionary].
signal dialogue_choices_ready(dialogue_id: StringName, choices: Array)
## Emitted after a choice is confirmed. Allows QuestManager to react without
## coupling directly to the dialogue UI.
signal dialogue_choice_made(dialogue_id: StringName, choice_index: int, choice_data: Dictionary)

const DIALOGUE_PATH   := "res://data/dialogue/dialogues.json"
const CHARACTERS_PATH := "res://data/characters.json"

var _dialogues:  Dictionary = {}
var _characters: Dictionary = {}
var _is_loaded := false

var _active_dialogue_id: StringName = &""
var _active_context:     Dictionary = {}
var _active_npc_node:    Node       = null


func _ready() -> void:
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	_load_data()


# ── Public API ────────────────────────────────────────────────────────────────

## Main entry point. Looks up npc_id in characters.json, resolves the portrait
## path, pauses Player and the NPC node, then starts the dialogue.
func start_dialogue(npc_id: String, dialogue_key: String) -> void:
	if not _is_loaded:
		_load_data()
	var dialogue_sn := StringName(dialogue_key)
	if not has_dialogue(dialogue_sn):
		push_warning("DialogueManager: dialogue key '%s' not found." % dialogue_key)
		return

	_active_npc_node = _find_npc_node(npc_id)
	_pause_npc(_active_npc_node)

	var char_data  := get_character(npc_id)
	var context    := {
		"speaker_id":   npc_id,
		"speaker_name": _display_name_from(npc_id, char_data),
	}
	request_dialogue(dialogue_sn, context)


## Emit dialogue_line_ready for the current speaker + text.
## Called by DialogueBox._advance_to_next_entry() just before rendering.
func emit_line(speaker_token: String, text: String) -> void:
	var char_id      := _resolve_character_id(speaker_token)
	var display_name := _display_name_from(char_id, get_character(char_id))
	if display_name.is_empty():
		display_name = speaker_token
	var portrait := get_portrait_path(char_id)
	dialogue_line_ready.emit(display_name, text, portrait)


## Emit dialogue_choices_ready. Called by DialogueBox._enter_choice_mode().
func emit_choices(dialogue_id: StringName, choices: Array) -> void:
	dialogue_choices_ready.emit(dialogue_id, choices)


## Emit dialogue_choice_made. Called by DialogueBox._confirm_choice() before
## applying effects, so quest-system listeners act on the raw choice data.
func confirm_choice(choice_index: int, choice_data: Dictionary) -> void:
	dialogue_choice_made.emit(_active_dialogue_id, choice_index, choice_data)
	EventBus.dialogue_choice_confirmed.emit(_active_dialogue_id, choice_index)


## Fire EventBus.dialogue_requested (used by NPC/world code that bypass
## start_dialogue, e.g. scripted cutscene triggers).
func request_dialogue(dialogue_id: StringName, context: Dictionary = {}) -> void:
	EventBus.dialogue_requested.emit(dialogue_id, context)


func has_dialogue(dialogue_id: StringName) -> bool:
	return _dialogues.has(String(dialogue_id))


func get_dialogue(dialogue_id: StringName) -> Dictionary:
	return _dialogues.get(String(dialogue_id), {})


func get_character(character_id: String) -> Dictionary:
	return _characters.get(character_id, {})


func get_portrait_path(character_id: String) -> String:
	return String(get_character(character_id).get("portrait", ""))


func register_runtime_dialogue(dialogue_id: String, payload: Dictionary) -> void:
	var key := dialogue_id.strip_edges()
	if not key.is_empty():
		_dialogues[key] = payload.duplicate(true)


func close_active_dialogue() -> void:
	if _active_dialogue_id.is_empty():
		return
	EventBus.dialogue_finished.emit(String(_active_dialogue_id))
	EventBus.dialogue_closed.emit(_active_dialogue_id)
	_resume_npc(_active_npc_node)
	_active_dialogue_id = &""
	_active_context.clear()
	_active_npc_node = null


func is_dialogue_active() -> bool:
	return not _active_dialogue_id.is_empty()


func get_active_context() -> Dictionary:
	return _active_context.duplicate(true)


## Force-reload both JSON files (useful in-editor or after hot-swap).
func reload_dialogues() -> void:
	_load_data()


# ── Condition / effect engine ─────────────────────────────────────────────────

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


## Processes all effects and returns a jump-target StringName (or &"" if none).
func apply_effects(effects: Variant, context: Dictionary = {}) -> StringName:
	var jump_target := &""
	if effects == null:
		return jump_target

	if typeof(effects) == TYPE_STRING:
		jump_target = _apply_effect_token(String(effects), context)
	elif typeof(effects) == TYPE_ARRAY:
		for effect in effects as Array:
			if typeof(effect) == TYPE_STRING:
				var resolved := _apply_effect_token(String(effect), context)
				if not resolved.is_empty():
					jump_target = resolved
	elif typeof(effects) == TYPE_DICTIONARY:
		var ed := effects as Dictionary
		for key in ed.keys():
			var token := "%s:%s" % [String(key), String(ed[key])]
			var dt := _apply_effect_token(token, context)
			if not dt.is_empty():
				jump_target = dt
	return jump_target


# ── Actor pausing ─────────────────────────────────────────────────────────────

## Suspends _process on the target NPC so wander and cooldown timers freeze.
## Player movement is handled by player.gd listening to EventBus.dialogue_started.
func _pause_npc(npc_node: Node) -> void:
	if npc_node == null:
		return
	npc_node.set_process(false)


func _resume_npc(npc_node: Node) -> void:
	if npc_node == null:
		return
	npc_node.set_process(true)


# ── Data loading ──────────────────────────────────────────────────────────────

func _load_data() -> void:
	_dialogues.clear()
	_characters.clear()
	_is_loaded = false
	_load_dialogues()
	_load_characters()
	_is_loaded = true


func _load_dialogues() -> void:
	if not FileAccess.file_exists(DIALOGUE_PATH):
		push_warning("DialogueManager: dialogue file missing at %s" % DIALOGUE_PATH)
		return
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		push_warning("DialogueManager: cannot open dialogues file.")
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("DialogueManager: parse error — %s" % parser.get_error_message())
		return
	var data: Variant = parser.data
	if data is Dictionary:
		_dialogues = data as Dictionary


func _load_characters() -> void:
	if not FileAccess.file_exists(CHARACTERS_PATH):
		push_warning("DialogueManager: characters.json missing at %s" % CHARACTERS_PATH)
		return
	var file := FileAccess.open(CHARACTERS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_characters = (parsed as Dictionary).duplicate(true)


# ── EventBus handler ──────────────────────────────────────────────────────────

func _on_dialogue_requested(dialogue_id: StringName, context: Dictionary) -> void:
	if not _is_loaded:
		_load_data()
	if not has_dialogue(dialogue_id):
		push_warning("DialogueManager: dialogue id not found: %s" % String(dialogue_id))
		return
	_active_dialogue_id = dialogue_id
	_active_context = context.duplicate(true)
	EventBus.dialogue_started.emit(String(dialogue_id))


# ── Internal helpers ──────────────────────────────────────────────────────────

func _display_name_from(character_id: String, char_data: Dictionary) -> String:
	var from_json := String(char_data.get("name", ""))
	if not from_json.is_empty():
		return from_json
	return PortraitRegistry.resolve_display_name(character_id)


## Maps a raw dialogue speaker token (e.g. "Elara" or "elara_001") to its
## canonical character ID by checking characters.json and then PortraitRegistry.
func _resolve_character_id(speaker_token: String) -> String:
	var normalized := speaker_token.strip_edges().to_lower()
	for key_variant in _characters.keys():
		var key := String(key_variant)
		if key.to_lower() == normalized:
			return key
		var char_name := String(_characters[key_variant].get("name", "")).to_lower()
		if char_name == normalized:
			return key
	return String(PortraitRegistry.resolve_portrait_id(speaker_token))


func _find_npc_node(npc_id: String) -> Node:
	var target_sn := StringName(npc_id)
	for node in get_tree().get_nodes_in_group("npc"):
		if node.get("npc_id") == target_sn:
			return node
	return null


func _evaluate_condition_token(token: String) -> bool:
	var cleaned := token.strip_edges()
	if cleaned.is_empty():
		return true

	var parts := cleaned.split("==")
	if parts.size() == 2:
		var key     := parts[0].strip_edges()
		var raw_val := parts[1].strip_edges().to_lower()
		var expected: Variant = raw_val
		if raw_val == "true":
			expected = true
		elif raw_val == "false":
			expected = false
		return WorldFlags.get_flag(StringName(key), false) == expected

	if cleaned.begins_with("quest_state:"):
		var qp := cleaned.split(":")
		if qp.size() >= 3:
			return QuestManager.get_quest_state(StringName(qp[1].strip_edges())) == qp[2].strip_edges()
		return false

	return bool(WorldFlags.get_flag(StringName(cleaned), false))


func _apply_effect_token(token: String, context: Dictionary) -> StringName:
	var cleaned := token.strip_edges()
	if cleaned.is_empty():
		return &""

	if cleaned.begins_with("set_flag:"):
		var payload := cleaned.trim_prefix("set_flag:")
		var fp      := payload.split("=")
		if fp.size() == 2:
			var raw_val := fp[1].strip_edges().to_lower()
			var val: Variant = raw_val
			if raw_val == "true":  val = true
			elif raw_val == "false": val = false
			WorldFlags.set_flag(StringName(fp[0].strip_edges()), val)
		return &""

	if cleaned.begins_with("start_quest:"):
		QuestManager.start_quest(StringName(cleaned.trim_prefix("start_quest:").strip_edges()))
		return &""

	if cleaned.begins_with("set_quest_state:"):
		var payload := cleaned.trim_prefix("set_quest_state:")
		var qsp     := payload.split(":")
		if qsp.size() >= 2:
			QuestManager.set_quest_state(
				StringName(qsp[0].strip_edges()), qsp[1].strip_edges()
			)
		return &""

	if cleaned.begins_with("complete_objective:"):
		var payload := cleaned.trim_prefix("complete_objective:")
		var op      := payload.split(":")
		if op.size() >= 2:
			var amount := 1
			if op.size() >= 3:
				amount = maxi(1, int(op[2].strip_edges()))
			QuestManager.complete_objective(
				StringName(op[0].strip_edges()), StringName(op[1].strip_edges()), amount
			)
		return &""

	if cleaned.begins_with("complete_quest:"):
		QuestManager.complete_quest(StringName(cleaned.trim_prefix("complete_quest:").strip_edges()))
		return &""

	if cleaned.begins_with("give_item:"):
		var payload := cleaned.trim_prefix("give_item:")
		var ip      := payload.split(":")
		var amount  := 1
		if ip.size() >= 2:
			amount = maxi(1, int(ip[1].strip_edges()))
		EventBus.item_received.emit(StringName(ip[0].strip_edges()), amount)
		return &""

	if cleaned.begins_with("jump_to:"):
		return StringName(cleaned.trim_prefix("jump_to:").strip_edges())

	if cleaned.begins_with("prompt:"):
		EventBus.request_ui_prompt.emit(cleaned.trim_prefix("prompt:").strip_edges())
		return &""

	# Bare token treated as a flag set (backwards-compatible shorthand).
	WorldFlags.set_flag(StringName(cleaned), true)
	if context.has("effect_log") and context["effect_log"] is Array:
		(context["effect_log"] as Array).append(cleaned)
	return &""
