extends Control

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var line_label: Label = $Panel/MarginContainer/VBoxContainer/TextLabel


func _ready() -> void:
	visible = false
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("confirm"):
		DialogueManager.close_active_dialogue()


func _on_dialogue_requested(dialogue_id: StringName, _context: Dictionary) -> void:
	var dialogue := DialogueManager.get_dialogue(dialogue_id)
	var entries_variant := dialogue.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY or (entries_variant as Array).is_empty():
		return

	var first_entry := (entries_variant as Array)[0]
	if typeof(first_entry) != TYPE_DICTIONARY:
		return

	var entry := first_entry as Dictionary
	speaker_label.text = String(entry.get("speaker", "Unknown"))
	line_label.text = String(entry.get("text", ""))
	visible = true


func _on_dialogue_closed(_dialogue_id: StringName) -> void:
	speaker_label.text = ""
	line_label.text = ""
	visible = false
