extends Node2D


@onready var world_root: Node = $WorldRoot


func _ready() -> void:
	if not EventBus.request_ui_prompt.is_connected(_on_ui_prompt):
		EventBus.request_ui_prompt.connect(_on_ui_prompt)
	if not EventBus.world_flag_changed.is_connected(_on_runtime_state_changed):
		EventBus.world_flag_changed.connect(_on_runtime_state_changed)
	if not EventBus.quest_state_changed.is_connected(_on_quest_state_changed):
		EventBus.quest_state_changed.connect(_on_quest_state_changed)
	if not EventBus.quest_updated.is_connected(_on_quest_updated):
		EventBus.quest_updated.connect(_on_quest_updated)

	_load_runtime_state()
	SceneRouter.load_initial_map(world_root)
	EventBus.request_ui_prompt.emit("World loaded. Explore the map. Press E to trigger dialogue.")


func _on_ui_prompt(_text: String) -> void:
	# HUD listens directly to EventBus and renders prompts.
	pass


func _exit_tree() -> void:
	_save_runtime_state()


func _load_runtime_state() -> void:
	QuestManager.reload_quests()
	var save_data := SaveManager.load_game(1)
	SaveManager.apply_loaded_data(save_data)


func _save_runtime_state() -> void:
	SaveManager.save_game(1, SaveManager.get_cached_data())


func _on_runtime_state_changed(_flag_key: String, _value: Variant) -> void:
	_save_runtime_state()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	_save_runtime_state()


func _on_quest_updated(_quest_id: StringName, _objective_id: StringName, _progress: int) -> void:
	_save_runtime_state()
