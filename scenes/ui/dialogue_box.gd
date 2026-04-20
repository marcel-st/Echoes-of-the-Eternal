extends CanvasLayer

@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: RichTextLabel = %TextLabel
@onready var choices_container: VBoxContainer = $Root/Panel/MarginContainer/HBox/TextColumn/ChoicesContainer
@onready var hint_label: Label = $Root/Panel/MarginContainer/HBox/TextColumn/HintLabel
@onready var portrait_rect: TextureRect = %Portrait
@onready var _portrait_backdrop: ColorRect = $Root/Panel/MarginContainer/HBox/PortraitFrame/PortraitBackdrop
@onready var _continue_arrow: TextureRect = $Root/Panel/ContinueArrow
@onready var _typewriter_timer: Timer = %TypewriterTimer

const _BACKDROP_DEFAULT := Color(0.08, 0.09, 0.12, 1.0)

var _active_dialogue_id: StringName = &""
var _entries: Array = []
var _entry_index := -1
var _current_entry: Dictionary = {}
var _active_choices: Array = []
var _choice_index := 0
var _choice_mode := false
var _context: Dictionary = {}
var _bold_rx: RegEx

## Letter-by-letter reveal (RichTextLabel); one step per `TypewriterTimer` tick + `SoundManager.play_sfx`.
var _typewriting := false
var _type_target_chars := 0
const TYPEWRITER_SEC_PER_CHAR := 0.038

func _ready() -> void:
	_bold_rx = RegEx.new()
	_bold_rx.compile("\\*\\*([^*]+?)\\*\\*")
	visible = false
	_typewriter_timer.wait_time = TYPEWRITER_SEC_PER_CHAR
	if not _typewriter_timer.timeout.is_connected(_on_typewriter_timer_timeout):
		_typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	if not DialogueManager.dialogue_line_ready.is_connected(_on_dialogue_line_ready):
		DialogueManager.dialogue_line_ready.connect(_on_dialogue_line_ready)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _on_dialogue_line_ready(speaker_name: String, text: String, portrait_path: String) -> void:
	if not visible:
		return
	speaker_label.text = speaker_name
	_apply_portrait(speaker_name, portrait_path)
	_begin_typewriter_line(_format_body_for_richtext(text))


## Loads a portrait sprite from portrait_path when it exists; otherwise tints
## the backdrop with the character's colour from PortraitRegistry so every
## speaker has a distinct visual identity even before portrait art ships.
func _apply_portrait(speaker_name: String, portrait_path: String) -> void:
	var trimmed := portrait_path.strip_edges()
	if not trimmed.is_empty() and ResourceLoader.exists(trimmed):
		portrait_rect.texture = load(trimmed) as Texture2D
		_portrait_backdrop.color = _BACKDROP_DEFAULT
	else:
		portrait_rect.texture = null
		_portrait_backdrop.color = PortraitRegistry.resolve_portrait_color(speaker_name)


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
		if event.is_action_pressed("confirm") or event.is_action_pressed("interact"):
			AudioManager.play_ui("confirm")
			_confirm_choice()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("confirm") or event.is_action_pressed("interact"):
		if _try_complete_typewriter():
			get_viewport().set_input_as_handled()
			return
		AudioManager.play_ui("confirm")
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _on_dialogue_requested(dialogue_id: StringName, context: Dictionary) -> void:
	var dialogue := DialogueManager.get_dialogue(dialogue_id)
	var entries_variant: Variant = dialogue.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY or (entries_variant as Array).is_empty():
		push_warning("Dialogue '%s' has no entries; closing." % String(dialogue_id))
		DialogueManager.close_active_dialogue()
		return

	_active_dialogue_id = dialogue_id
	_context = context.duplicate(true)
	_entries = (entries_variant as Array).duplicate(true)
	_entry_index = -1
	_current_entry.clear()
	_active_choices.clear()
	_choice_mode = false
	_clear_choices()
	_set_hint("E / Space: continue   Cancel: close")
	speaker_label.text = ""
	line_label.text = ""
	portrait_rect.texture = null
	_portrait_backdrop.color = _BACKDROP_DEFAULT
	_stop_typewriter()
	visible = true
	AudioManager.play_ui("open")
	_advance_to_next_entry()


func _process(_delta: float) -> void:
	_update_continue_arrow()


func _on_typewriter_timer_timeout() -> void:
	if not _typewriting or not visible:
		_typewriter_timer.stop()
		return
	var cur: int = line_label.visible_characters
	if cur < 0:
		cur = 0
	var next: int = cur + 1
	if next >= _type_target_chars:
		line_label.visible_characters = -1
		_typewriting = false
		_typewriter_timer.stop()
		return
	line_label.visible_characters = next
	SoundManager.play_sfx("dialogue_blip", -14.0, true)


func _update_continue_arrow() -> void:
	if _continue_arrow == null:
		return
	var has_body := not line_label.text.strip_edges().is_empty()
	var show := visible and not _choice_mode and has_body and not _typewriting
	_continue_arrow.visible = show
	if not show:
		return
	var pulse := 0.38 + 0.62 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.007))
	_continue_arrow.modulate = Color(1, 1, 1, pulse)


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
	portrait_rect.texture = null
	_portrait_backdrop.color = _BACKDROP_DEFAULT
	_clear_choices()
	_stop_typewriter()
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

	var choices_variant: Variant = _current_entry.get("choices", [])
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

		var entry: Dictionary = entry_variant as Dictionary
		if entry.has("conditions") and not DialogueManager.are_conditions_met(entry["conditions"]):
			_entry_index += 1
			continue

		_current_entry = entry
		var speaker_raw := String(entry.get("speaker", "Unknown"))
		var text_raw    := String(entry.get("text", ""))
		_set_hint("E / Space: continue   Cancel: close")
		DialogueManager.emit_line(speaker_raw, text_raw)
		return

	_resolve_dialogue_end()


func _enter_choice_mode(raw_choices: Array) -> void:
	_active_choices.clear()
	for choice_variant in raw_choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_variant as Dictionary
		if choice.has("conditions") and not DialogueManager.are_conditions_met(choice["conditions"]):
			continue
		_active_choices.append(choice)

	if _active_choices.is_empty():
		_advance_to_next_entry()
		return

	_choice_mode = true
	_choice_index = 0
	choices_container.visible = true
	_set_hint("Up/Down: select   E / Space: choose   Cancel: close")
	_render_choices()
	DialogueManager.emit_choices(_active_dialogue_id, _active_choices)


func _confirm_choice() -> void:
	if _active_choices.is_empty():
		_choice_mode = false
		_advance_to_next_entry()
		return

	var selected: Dictionary = _active_choices[_choice_index] as Dictionary
	_choice_mode = false
	_clear_choices()
	choices_container.visible = false
	_set_hint("E / Space: continue   Cancel: close")
	DialogueManager.confirm_choice(_choice_index, selected)

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
	var inherited_font := speaker_label.get_theme_font("font")
	for index in _active_choices.size():
		var choice: Dictionary = _active_choices[index] as Dictionary
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if inherited_font != null:
			row.add_theme_font_override("font", inherited_font)
		row.add_theme_font_size_override("font_size", 22)
		var col := Color(0.94, 0.95, 0.97, 1.0) if index == _choice_index else Color(0.65, 0.68, 0.75, 1.0)
		row.add_theme_color_override("font_color", col)
		var prefix := "  " if index != _choice_index else "> "
		row.text = "%s%s" % [prefix, String(choice.get("text", "..."))]
		choices_container.add_child(row)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _set_hint(text: String) -> void:
	hint_label.text = text


func _begin_typewriter_line(formatted_bbcode: String) -> void:
	_stop_typewriter()
	line_label.text = formatted_bbcode
	_type_target_chars = line_label.get_total_character_count()
	if _type_target_chars <= 0:
		line_label.visible_characters = -1
		_typewriting = false
		return
	line_label.visible_characters = 0
	_typewriting = true
	_typewriter_timer.wait_time = TYPEWRITER_SEC_PER_CHAR
	_typewriter_timer.start()


func _stop_typewriter() -> void:
	_typewriting = false
	_typewriter_timer.stop()
	if line_label != null:
		line_label.visible_characters = -1


func _try_complete_typewriter() -> bool:
	if not _typewriting:
		return false
	line_label.visible_characters = -1
	_typewriting = false
	_typewriter_timer.stop()
	return true


func _format_body_for_richtext(raw: String) -> String:
	var t := raw.strip_edges()
	if t.is_empty():
		return ""
	# Lore JSON uses " * " between labeled sections; break into readable paragraphs.
	t = t.replace(" * ", "\n\n")
	t = _bold_rx.sub(t, "[b]$1[/b]", true)
	var lines := t.split("\n")
	for i in lines.size():
		var p := lines[i].strip_edges()
		while p.begins_with("*"):
			p = p.substr(1).strip_edges()
		lines[i] = p
	return "\n".join(lines)


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

		var meta_variant: Variant = dialogue.get("meta", {})
		if typeof(meta_variant) == TYPE_DICTIONARY:
			var meta := meta_variant as Dictionary
			if meta.has("action"):
				EventBus.request_ui_prompt.emit("Action: %s" % String(meta["action"]))

	DialogueManager.close_active_dialogue()
