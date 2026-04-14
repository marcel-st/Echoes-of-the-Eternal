extends Node

const DEFAULT_MAP_SCENE: String = "res://scenes/world/oakhaven.tscn"

var _current_map: Node = null
var _current_map_path: String = ""


func _ready() -> void:
	if not EventBus.map_change_requested.is_connected(change_map):
		EventBus.map_change_requested.connect(change_map)


func load_initial_map(target_parent: Node) -> void:
	change_map(DEFAULT_MAP_SCENE, &"start", target_parent)


func change_map(map_scene_path: String, spawn_id: StringName = &"start", target_parent: Node = null) -> void:
	var parent: Node = target_parent
	if parent == null:
		parent = get_tree().get_current_scene().get_node_or_null("WorldRoot")
		if parent == null:
			parent = get_tree().get_current_scene()

	if _current_map != null:
		_current_map.queue_free()
		_current_map = null

	var packed: PackedScene = load(map_scene_path)
	if packed == null:
		push_error("Could not load map scene: %s" % map_scene_path)
		return

	_current_map = packed.instantiate()
	_current_map_path = map_scene_path
	parent.add_child(_current_map)
	EventBus.map_changed.emit(map_scene_path)

	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("warp_to_spawn"):
		player.call("warp_to_spawn", spawn_id, _current_map)
	# Map nodes (e.g. full-screen ColorRect) must draw under the player; add_child puts the map last.
	if player != null and player.get_parent() == parent:
		parent.move_child(player, parent.get_child_count() - 1)


func request_map_change(map_scene_path: String, spawn_id: StringName = &"start") -> void:
	change_map(map_scene_path, spawn_id)


func get_current_map() -> Node:
	return _current_map


func get_current_map_path() -> String:
	return _current_map_path
