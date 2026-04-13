extends Control

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/SpeakerLabel
@onready var line_label: Label = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel
@onready var portrait_panel: ColorRect = $Panel/MarginContainer/VBoxContainer/HeaderContainer/PortraitPanel
@onready var portrait_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/PortraitPanel/PortraitLabel

var _active_dialogue_id: StringName = &""
var _entries: Array = []
var _entry_index := -1
var _current_entry: Dictionary = {}
var _active_choices: Array = []
var _choice_index := 0
var _choice_mode := false
var _context: Dictionary = {}

func _ready() -> void:
	visible = false
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("cancel"):
		AudioManager.play_ui("error")
		DialogueManager.close_active_dialogue()
		get_viewport().set_input_as_handled()
		return

	if _choice_mode:
		if event.is_action_pressed("move_up"):
			AudioManager.play_ui("select")
			_update_choice_index(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_down"):
			AudioManager.play_ui("select")
			_update_choice_index(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("confirm"):
			AudioManager.play_ui("confirm")
			_confirm_choice()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("confirm"):
		AudioManager.play_ui("confirm")
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _on_dialogue_requested(dialogue_id: StringName, context: Dictionary) -> void:
	var dialogue := DialogueManager.get_dialogue(dialogue_id)
	var entries_variant := dialogue.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY or (entries_variant as Array).is_empty():
		return

	_active_dialogue_id = dialogue_id
	_context = context.duplicate(true)
	_entries = (entries_variant as Array).duplicate(true)
	_entry_index = -1
	_current_entry.clear()
	_active_choices.clear()
	_choice_mode = false
	_clear_choices()
	_set_hint("Confirm: continue   Cancel: close")
	visible = true
	AudioManager.play_ui("open")
	_advance_to_next_entry()


func _on_dialogue_closed(_dialogue_id: StringName) -> void:
	_active_dialogue_id = &""
	_entries.clear()
	_entry_index = -1
	_current_entry.clear()
	_active_choices.clear()
	_choice_mode = false
	_context.clear()
	speaker_label.text = ""
	line_label.text = ""
	portrait_label.text = "?"
	portrait_panel.color = Color(0.31, 0.46, 0.74, 1.0)
	_clear_choices()
	visible = false
	AudioManager.play_ui("close")


func _advance_dialogue() -> void:
	if _current_entry.is_empty():
		_resolve_dialogue_end()
		return

	if _apply_effects_from_value(_current_entry.get("effect", null)):
		return
	if _apply_effects_from_value(_current_entry.get("effects", null)):
		return
	if _apply_effects_from_value(_current_entry.get("outcomes", null)):
		return

	var choices_variant := _current_entry.get("choices", [])
	if typeof(choices_variant) == TYPE_ARRAY and not (choices_variant as Array).is_empty():
		_enter_choice_mode(choices_variant as Array)
		return

	_advance_to_next_entry()


func _advance_to_next_entry() -> void:
	_entry_index += 1
	while _entry_index < _entries.size():
		var entry_variant: Variant = _entries[_entry_index]
		if typeof(entry_variant) != TYPE_DICTIONARY:
			_entry_index += 1
			continue

		var entry := entry_variant as Dictionary
		if entry.has("conditions") and not DialogueManager.are_conditions_met(entry["conditions"]):
			_entry_index += 1
			continue

		_current_entry = entry
		var speaker_raw := String(entry.get("speaker", "Unknown"))
		speaker_label.text = PortraitRegistry.resolve_display_name(speaker_raw)
		_update_portrait(speaker_raw)
		line_label.text = String(entry.get("text", ""))
		_set_hint("Confirm: continue   Cancel: close")
		return

	_resolve_dialogue_end()


func _enter_choice_mode(raw_choices: Array) -> void:
	_active_choices.clear()
	for choice_variant in raw_choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice := choice_variant as Dictionary
		if choice.has("conditions") and not DialogueManager.are_conditions_met(choice["conditions"]):
			continue
		_active_choices.append(choice)

	if _active_choices.is_empty():
		_advance_to_next_entry()
		return

	_choice_mode = true
	_choice_index = 0
	choices_container.visible = true
	_set_hint("Up/Down: select   Confirm: choose   Cancel: close")
	_render_choices()


func _confirm_choice() -> void:
	if _active_choices.is_empty():
		_choice_mode = false
		_advance_to_next_entry()
		return

	var selected := _active_choices[_choice_index] as Dictionary
	_choice_mode = false
	_clear_choices()
	choices_container.visible = false
	_set_hint("Confirm: continue   Cancel: close")

	if _apply_effects_from_value(selected.get("effect", null)):
		return
	if _apply_effects_from_value(selected.get("effects", null)):
		return
	if _apply_effects_from_value(selected.get("outcomes", null)):
		return

	var next_id := StringName(String(selected.get("next", "")).strip_edges())
	if not next_id.is_empty():
		DialogueManager.request_dialogue(next_id, _context)
		return

	_advance_to_next_entry()


func _update_choice_index(delta: int) -> void:
	if _active_choices.is_empty():
		return
	_choice_index = posmod(_choice_index + delta, _active_choices.size())
	_render_choices()


func _render_choices() -> void:
	_clear_choices()
	choices_container.visible = true
	for index in _active_choices.size():
		var choice := _active_choices[index] as Dictionary
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var prefix := "   "
		if index == _choice_index:
			prefix = "> "
		row.text = "%s%s" % [prefix, String(choice.get("text", "..."))]
		choices_container.add_child(row)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _set_hint(text: String) -> void:
	hint_label.text = text


func _update_portrait(speaker_token: String) -> void:
	var color := PortraitRegistry.resolve_portrait_color(speaker_token)
	portrait_panel.color = color
	var portrait_name := PortraitRegistry.resolve_display_name(speaker_token)
	portrait_label.text = _portrait_initials(portrait_name)


func _portrait_initials(name: String) -> String:
	var words := name.strip_edges().split(" ")
	var initials := ""
	for token in words:
		var cleaned := token.strip_edges()
		if cleaned.is_empty():
			continue
		initials += cleaned.substr(0, 1).to_upper()
		if initials.length() >= 2:
			break
	if initials.is_empty():
		return "?"
	return initials


func _apply_effects_from_value(effects: Variant) -> bool:
	if effects == null:
		return false

	var jump_target := DialogueManager.apply_effects(effects, _context)
	if jump_target.is_empty():
		return false

	DialogueManager.request_dialogue(jump_target, _context)
	return true


func _resolve_dialogue_end() -> void:
	var dialogue := DialogueManager.get_dialogue(_active_dialogue_id)
	if typeof(dialogue) == TYPE_DICTIONARY:
		if _apply_effects_from_value(dialogue.get("effect", null)):
			return
		if _apply_effects_from_value(dialogue.get("effects", null)):
			return
		if _apply_effects_from_value(dialogue.get("outcomes", null)):
			return

		var meta_variant := dialogue.get("meta", {})
		if typeof(meta_variant) == TYPE_DICTIONARY:
			var meta := meta_variant as Dictionary
			if meta.has("action"):
				EventBus.request_ui_prompt.emit("Action: %s" % String(meta["action"]))

	DialogueManager.close_active_dialogue()
