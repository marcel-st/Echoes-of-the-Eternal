extends Node

const DIALOGUE_PATH := "res://data/dialogue/sample_dialogue.json"

var _dialogues: Dictionary = {}
var _is_loaded := false
var _active_dialogue_id: StringName = &""


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


func _on_dialogue_requested(dialogue_id: StringName, context: Dictionary) -> void:
	if not _is_loaded:
		reload_dialogues()

	if not has_dialogue(dialogue_id):
		push_warning("Dialogue id not found: %s" % String(dialogue_id))
		return

	_active_dialogue_id = dialogue_id
	EventBus.dialogue_started.emit(String(dialogue_id))
	EventBus.request_ui_prompt.emit("Dialogue started: %s (Confirm to close)" % String(dialogue_id))
