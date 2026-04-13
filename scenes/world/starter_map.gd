extends Node2D


func _ready() -> void:
	EventBus.request_ui_prompt.emit("Explore Oakhaven. Speak to Elara to begin your journey.")
