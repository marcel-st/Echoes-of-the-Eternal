extends CanvasLayer

@onready var prompt_label: Label = $MarginContainer/VBoxContainer/PromptLabel
@onready var journal_panel: PanelContainer = $JournalPanel


func _ready() -> void:
	prompt_label.visible = false
	EventBus.request_ui_prompt.connect(_on_ui_prompt)
	if journal_panel:
		journal_panel.visible = false


func _on_ui_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text.strip_edges() != ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if journal_panel and journal_panel.has_method("toggle_panel"):
			journal_panel.call("toggle_panel")
			get_viewport().set_input_as_handled()
