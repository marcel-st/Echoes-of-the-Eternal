extends Node2D


func _ready() -> void:
	EventBus.request_ui_prompt.emit("Explore the map. Press E to interact.")
