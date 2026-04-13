extends Node

const DEFAULT_MAP_SCENE: String = "res://scenes/world/starter_map.tscn"

var _current_map: Node = null


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
	parent.add_child(_current_map)
	EventBus.map_changed.emit(map_scene_path)

	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("warp_to_spawn"):
		player.call("warp_to_spawn", spawn_id, _current_map)
