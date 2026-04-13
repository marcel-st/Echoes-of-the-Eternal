extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $MarginContainer/VBoxContainer/ContentLabel
@onready var empty_label: Label = $MarginContainer/VBoxContainer/EmptyLabel

var _is_open := false


func _ready() -> void:
	visible = false
	_refresh_content()
	EventBus.quest_started.connect(_on_quest_runtime_changed)
	EventBus.quest_updated.connect(_on_quest_runtime_changed)
	EventBus.quest_completed.connect(_on_quest_runtime_changed)
	EventBus.quest_state_changed.connect(_on_quest_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_content()
		EventBus.request_ui_prompt.emit("Journal open. Press Esc/Start to close.")
	else:
		EventBus.request_ui_prompt.emit("Journal closed.")


func _refresh_content() -> void:
	var active_quests := QuestManager.get_active_quests()
	if active_quests.is_empty():
		content_label.visible = false
		empty_label.visible = true
		empty_label.text = "No active quests."
		return

	content_label.visible = true
	empty_label.visible = false
	var lines: Array[String] = []
	for quest in active_quests:
		var quest_id := StringName(String(quest.get("id", "")))
		lines.append("[b]%s[/b]" % String(quest.get("title", quest_id)))
		lines.append(String(quest.get("description", "")))
		lines.append("State: %s" % QuestManager.get_quest_state(quest_id))

		var objectives_variant := quest.get("objectives", [])
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

	content_label.text = "\n".join(lines).strip_edges()


func _on_quest_runtime_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	if _is_open:
		_refresh_content()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	if _is_open:
		_refresh_content()
