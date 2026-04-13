extends CanvasLayer

@onready var prompt_label: Label = $MarginContainer/VBoxContainer/PromptLabel


func _ready() -> void:
	prompt_label.visible = false
	EventBus.request_ui_prompt.connect(_on_ui_prompt)


func _on_ui_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text.strip_edges() != ""
