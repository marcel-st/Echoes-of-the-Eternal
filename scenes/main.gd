extends Node2D


@onready var game_root: Node = $GameRoot
var _suppress_autosave := false
var _transition_prompt := ""
var _autosave_pending := false
var _autosave_timer := 0.0

const AUTOSAVE_DEBOUNCE_SECONDS := 0.45

## Map scene path -> music track id (AudioManager TRACKS). Unlisted maps use "overworld".
const MAP_MUSIC := {
	"res://scenes/world/overworld.tscn": "overworld",
	"res://scenes/world/starter_map.tscn": "overworld",
	"res://scenes/world/whispering_vales.tscn": "veldt",
	"res://scenes/world/cinder_peaks.tscn": "cinder",
	"res://scenes/world/sinking_sands.tscn": "dunes",
	"res://scenes/world/sunken_library_entry.tscn": "mystic",
}

var _last_music_track_id := ""


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
	if not EventBus.lore_discovered.is_connected(_on_lore_discovered):
		EventBus.lore_discovered.connect(_on_lore_discovered)

	_load_runtime_state()
	_play_music_for_current_map()
	EventBus.request_ui_prompt.emit("World loaded. Explore regions and speak with townsfolk.")


func _process(delta: float) -> void:
	_process_map_transition_request()
	_process_autosave_timer(delta)


func _on_ui_prompt(_text: String) -> void:
	# HUD listens directly to EventBus and renders prompts.
	pass


func _exit_tree() -> void:
	_flush_pending_autosave()
	_save_runtime_state()


func _load_runtime_state() -> void:
	QuestManager.reload_quests()
	_suppress_autosave = true
	var save_data := SaveManager.load_game(1)
	SaveManager.apply_loaded_data(save_data)
	if SaveManager.has_save(1) and save_data.map_scene_path.strip_edges() != "":
		SceneRouter.change_map(save_data.map_scene_path, StringName(save_data.spawn_id), game_root)
		_restore_player_position(save_data.player_position)
	else:
		SceneRouter.load_initial_map(game_root)
	_suppress_autosave = false


func _save_runtime_state() -> void:
	if _suppress_autosave:
		return
	SaveManager.save_game(1, SaveManager.get_cached_data())


func _on_runtime_state_changed(_flag_key: String, _value: Variant) -> void:
	_request_autosave()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	_request_autosave()


func _on_quest_updated(_quest_id: StringName, _objective_id: StringName, _progress: int) -> void:
	_request_autosave()


func _on_lore_discovered(_entry_id: String) -> void:
	_request_autosave()


func _on_map_changed(_map_scene_path: String) -> void:
	_transition_prompt = ""
	AudioManager.play_world_sfx("map_transition")
	_play_music_for_current_map()
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
	var transition: Variant = map.call("resolve_transition", player_position)
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


func _request_autosave() -> void:
	if _suppress_autosave:
		return
	_autosave_pending = true
	_autosave_timer = AUTOSAVE_DEBOUNCE_SECONDS


func _process_autosave_timer(delta: float) -> void:
	if not _autosave_pending:
		return
	_autosave_timer -= delta
	if _autosave_timer > 0.0:
		return
	_autosave_pending = false
	_save_runtime_state()


func _flush_pending_autosave() -> void:
	if not _autosave_pending:
		return
	_autosave_pending = false
	_save_runtime_state()


func _play_music_for_current_map() -> void:
	var path := SceneRouter.get_current_map_path()
	var track_id: String = String(MAP_MUSIC.get(path, "overworld"))
	if track_id == _last_music_track_id:
		return
	if _last_music_track_id.is_empty():
		AudioManager.play_music_track(track_id)
	else:
		AudioManager.fade_music_to_track(track_id, 1.2)
	_last_music_track_id = track_id
