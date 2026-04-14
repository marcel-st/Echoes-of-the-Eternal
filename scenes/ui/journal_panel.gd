extends PanelContainer

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ContentLabel
@onready var empty_label: Label = $Panel/MarginContainer/VBoxContainer/EmptyLabel

var _is_open := false


func _ready() -> void:
	visible = false
	title_label.text = "Journal"
	_refresh_content()
	EventBus.quest_started.connect(_on_quest_runtime_changed)
	EventBus.quest_updated.connect(_on_quest_runtime_changed)
	EventBus.quest_completed.connect(_on_quest_runtime_changed)
	EventBus.quest_state_changed.connect(_on_quest_state_changed)
	EventBus.lore_discovered.connect(_on_lore_runtime_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_content()
		AudioManager.play_ui("open")
		EventBus.request_ui_prompt.emit("Journal open. Press Esc/Start to close.")
	else:
		AudioManager.play_ui("close")
		EventBus.request_ui_prompt.emit("Journal closed.")


func _refresh_content() -> void:
	var active_quests := QuestManager.get_active_quests()
	var lore_lines := _build_lore_section_lines()
	var lines: Array[String] = []

	if not active_quests.is_empty():
		lines.append("[b]Active quests[/b]")
		lines.append("")
	for quest in active_quests:
		var quest_id := StringName(String(quest.get("id", "")))
		lines.append("[b]%s[/b]" % String(quest.get("title", quest_id)))
		lines.append(String(quest.get("description", "")))
		lines.append("State: %s" % QuestManager.get_quest_state(quest_id))

		var objectives_variant: Variant = quest.get("objectives", [])
		if typeof(objectives_variant) == TYPE_ARRAY:
			for objective_variant in objectives_variant as Array:
				if typeof(objective_variant) != TYPE_DICTIONARY:
					continue
				var objective := objective_variant as Dictionary
				var objective_id := StringName(objective.get("id", ""))
				var required := int(objective.get("required", 1))
				var current := QuestManager.get_objective_progress(quest_id, objective_id)
				var marker := "[ ]"
				if current >= required:
					marker = "[x]"
				lines.append(
					"  %s %s (%d/%d)"
					% [marker, String(objective.get("description", "")), current, required]
				)
		lines.append("")

	if not lore_lines.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append("[b]Discovered lore[/b]")
		lines.append("")
		lines.append_array(lore_lines)

	var text := "\n".join(lines).strip_edges()
	if text.is_empty():
		content_label.visible = false
		empty_label.visible = true
		empty_label.text = "No active quests or discovered lore yet."
		return

	content_label.visible = true
	empty_label.visible = false
	content_label.text = text


func _build_lore_section_lines() -> Array[String]:
	var out: Array[String] = []
	for lore_id in LoreManager.get_lore_ids():
		if not LoreManager.is_entry_discovered(lore_id):
			continue
		var entry := LoreManager.get_lore(StringName(lore_id))
		var title := String(entry.get("title", lore_id))
		out.append("  • [b]%s[/b]" % title)
	return out


func _on_quest_runtime_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	if _is_open:
		_refresh_content()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	if _is_open:
		_refresh_content()


func _on_lore_runtime_changed(_entry_id: String) -> void:
	if _is_open:
		_refresh_content()
