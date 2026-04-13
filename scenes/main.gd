extends Node2D


@onready var world_root: Node = $WorldRoot
var _suppress_autosave := false
var _transition_prompt := ""


func _ready() -> void:
	if not EventBus.request_ui_prompt.is_connected(_on_ui_prompt):
		EventBus.request_ui_prompt.connect(_on_ui_prompt)
	if not EventBus.world_flag_changed.is_connected(_on_runtime_state_changed):
		EventBus.world_flag_changed.connect(_on_runtime_state_changed)
	if not EventBus.quest_state_changed.is_connected(_on_quest_state_changed):
		EventBus.quest_state_changed.connect(_on_quest_state_changed)
	if not EventBus.quest_updated.is_connected(_on_quest_updated):
		EventBus.quest_updated.connect(_on_quest_updated)
	if not EventBus.map_changed.is_connected(_on_map_changed):
		EventBus.map_changed.connect(_on_map_changed)

	_load_runtime_state()
	EventBus.request_ui_prompt.emit("World loaded. Explore regions and speak with townsfolk.")


func _process(_delta: float) -> void:
	_process_map_transition_request()


func _on_ui_prompt(_text: String) -> void:
	# HUD listens directly to EventBus and renders prompts.
	pass


func _exit_tree() -> void:
	_save_runtime_state()


func _load_runtime_state() -> void:
	QuestManager.reload_quests()
	_suppress_autosave = true
	var save_data := SaveManager.load_game(1)
	SaveManager.apply_loaded_data(save_data)
	if SaveManager.has_save(1) and save_data.map_scene_path.strip_edges() != "":
		SceneRouter.change_map(save_data.map_scene_path, StringName(save_data.spawn_id), world_root)
		_restore_player_position(save_data.player_position)
	else:
		SceneRouter.load_initial_map(world_root)
	_suppress_autosave = false


func _save_runtime_state() -> void:
	if _suppress_autosave:
		return
	SaveManager.save_game(1, SaveManager.get_cached_data())


func _on_runtime_state_changed(_flag_key: String, _value: Variant) -> void:
	_save_runtime_state()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	_save_runtime_state()


func _on_quest_updated(_quest_id: StringName, _objective_id: StringName, _progress: int) -> void:
	_save_runtime_state()


func _on_map_changed(_map_scene_path: String) -> void:
	_transition_prompt = ""
	_save_runtime_state()


func _process_map_transition_request() -> void:
	if _suppress_autosave or DialogueManager.is_dialogue_active():
		return
	var map := SceneRouter.get_current_map()
	if map == null or not map.has_method("resolve_transition"):
		return

	var player := get_tree().get_first_node_in_group("player")
	if not (player is Node2D):
		return

	var player_position := (player as Node2D).global_position
	var transition := map.call("resolve_transition", player_position)
	if typeof(transition) != TYPE_DICTIONARY:
		return

	var data := transition as Dictionary
	var map_scene_path := String(data.get("map_scene_path", "")).strip_edges()
	var spawn_id := StringName(String(data.get("spawn_id", "start")).strip_edges())
	if map_scene_path.is_empty():
		if _transition_prompt != "":
			_transition_prompt = ""
			EventBus.request_ui_prompt.emit("Explore this region for quests, lore, and NPC stories.")
		return

	var prompt := "Travel to %s [Press Confirm]" % _scene_label(map_scene_path)
	if _transition_prompt != prompt:
		_transition_prompt = prompt
		EventBus.request_ui_prompt.emit(prompt)

	if Input.is_action_just_pressed("confirm"):
		SceneRouter.request_map_change(map_scene_path, spawn_id)


func _restore_player_position(saved_position: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		(player as Node2D).global_position = saved_position


func _scene_label(scene_path: String) -> String:
	var file_name := scene_path.get_file()
	file_name = file_name.trim_suffix(".tscn")
	return file_name.replace("_", " ").capitalize()
