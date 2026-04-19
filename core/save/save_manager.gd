extends Node

const SAVE_DIR := "user://saves"
const SAVE_SLOT_TEMPLATE := "slot_%d.save"
const SaveDataScript = preload("res://core/save/save_data.gd")

var _cache: Resource = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func has_save(slot: int = 1) -> bool:
	return FileAccess.file_exists(_save_path(slot))


func load_game(slot: int = 1) -> Resource:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		_cache = SaveDataScript.new()
		return _cache

	var loaded := ResourceLoader.load(path)
	if loaded != null and loaded is SaveDataScript:
		_cache = loaded
		return _cache

	push_warning("Unable to parse save file. Creating new save data.")
	_cache = SaveDataScript.new()
	return _cache


func save_game(slot: int = 1, data: Resource = null) -> bool:
	var payload := data if data != null else _cache
	if payload == null:
		payload = SaveDataScript.new()

	payload.world_flags = WorldFlags.export_flags()
	var quest_state := QuestManager.export_state()
	payload.active_quests = (quest_state.get("states", {}) as Dictionary).duplicate(true)
	payload.quest_progress = (quest_state.get("progress", {}) as Dictionary).duplicate(true)
	payload.map_scene_path = SceneRouter.get_current_map_path()
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		payload.player_position = (player as Node2D).global_position
	payload.lore_discovered = LoreManager.export_discovered_entries()

	var path := _save_path(slot)
	var result := ResourceSaver.save(payload, path)
	return result == OK


func get_cached_data() -> Resource:
	if _cache == null:
		_cache = SaveDataScript.new()
	return _cache


func apply_loaded_data(data: Resource) -> void:
	if data == null or not (data is SaveDataScript):
		return
	_cache = data
	WorldFlags.import_flags(data.world_flags)
	QuestManager.import_state(
		{
			"states": data.active_quests,
			"progress": data.quest_progress,
		}
	)
	LoreManager.import_discovered_entries(data.lore_discovered)


func _save_path(slot: int) -> String:
	return SAVE_DIR.path_join(SAVE_SLOT_TEMPLATE % slot)
