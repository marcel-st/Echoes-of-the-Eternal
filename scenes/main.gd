extends Node2D


@onready var world_root: Node = $WorldRoot


func _ready() -> void:
	if not EventBus.request_ui_prompt.is_connected(_on_ui_prompt):
		EventBus.request_ui_prompt.connect(_on_ui_prompt)

	SceneRouter.load_initial_map(world_root)
	QuestManager.reload_quests()
	EventBus.request_ui_prompt.emit("World loaded. Explore the map. Press E to trigger dialogue.")


func _on_ui_prompt(_text: String) -> void:
	# HUD listens directly to EventBus and renders prompts.
	pass
