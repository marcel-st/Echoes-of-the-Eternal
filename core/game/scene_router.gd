extends Node

const DEFAULT_MAP_SCENE: String = "res://scenes/world/overworld.tscn"

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
		parent = get_tree().get_current_scene().get_node_or_null("GameRoot")
		if parent == null:
			parent = get_tree().get_current_scene()

	if _current_map != null:
		var player_before: Node = get_tree().get_first_node_in_group("player")
		if player_before != null and player_before.is_inside_tree() and _current_map.is_ancestor_of(player_before):
			player_before.reparent(parent)
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
	var entities: Node = _current_map.get_node_or_null("Entities")
	if player != null and entities != null:
		player.reparent(entities)
	if player != null and player.has_method("warp_to_spawn"):
		player.call("warp_to_spawn", spawn_id, _current_map)
	if entities is Node2D:
		sort_entities_children_by_y(entities as Node2D)
	elif player != null and entities == null and player.get_parent() == parent:
		parent.move_child(player, parent.get_child_count() - 1)


## Stable order for equal Y (e.g. spawn row): tie-break by node name so one actor is not stuck in front forever.
func sort_entities_children_by_y(ent: Node2D) -> void:
	var kids: Array[Node] = ent.get_children()
	if kids.size() < 2:
		return
	kids.sort_custom(
		func(a: Node, b: Node) -> bool:
			var ay := _entity_child_sort_y(a)
			var by := _entity_child_sort_y(b)
			if is_equal_approx(ay, by):
				return String(a.name) < String(b.name)
			return ay < by
	)
	for i in kids.size():
		var c: Node = kids[i]
		if c.get_parent() == ent:
			ent.move_child(c, i)


func _entity_child_sort_y(n: Node) -> float:
	if n is Node2D:
		return (n as Node2D).global_position.y
	return 0.0


func request_map_change(map_scene_path: String, spawn_id: StringName = &"start") -> void:
	change_map(map_scene_path, spawn_id)


func get_current_map() -> Node:
	return _current_map


func get_current_map_path() -> String:
	return _current_map_path
