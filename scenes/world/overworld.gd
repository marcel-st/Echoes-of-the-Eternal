extends Node2D

## Hub overworld: uniform grass from `mapping.txt` (custom atlas). Details / obstacles cleared.

const NORTH_MAP := "res://scenes/world/whispering_vales.tscn"
const SOUTH_MAP := "res://scenes/world/sunken_library_entry.tscn"
const EAST_MAP := "res://scenes/world/cinder_peaks.tscn"
const WEST_MAP := "res://scenes/world/sinking_sands.tscn"

const MAP_W := 120
const MAP_H := 68
const TILE_PX := 16
const SOURCE_ID := 0
const MAPPING_PATH := "res://assets/mapping.txt"

const TREE_SCENE := preload("res://scenes/objects/Tree.tscn")

var _atlas_grass: Vector2i = Vector2i.ZERO

@onready var _ground: TileMapLayer = $TileMaps/Ground
@onready var _details: TileMapLayer = $TileMaps/GroundDetails
@onready var _obstacles: TileMapLayer = $TileMaps/Obstacles
## Trees are parented here so each trunk shares the same y-sort plane as the player (no extra wrapper at y=0).
@onready var _trees_root: Node2D = $Entities


func _ready() -> void:
	_load_grass_from_mapping()
	_clear_tile_layers()
	_fill_ground_grass_only()
	_spawn_forest_boundary()
	EventBus.request_ui_prompt.emit("Oakhaven: the last warm hearth in a fading world.")
	EventBus.request_ui_prompt.emit("Search for lore plinths to uncover the age of remembrance.")
	LoreManager.mark_entry_discovered("world_lore_005")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.y <= 24.0:
		return {"map_scene_path": NORTH_MAP, "spawn_id": "from_oakhaven_south"}
	if player_position.y >= 1056.0:
		return {"map_scene_path": SOUTH_MAP, "spawn_id": "from_oakhaven_north"}
	if player_position.x >= 1896.0:
		return {"map_scene_path": EAST_MAP, "spawn_id": "from_oakhaven_west"}
	if player_position.x <= 24.0:
		return {"map_scene_path": WEST_MAP, "spawn_id": "from_oakhaven_east"}
	return {}


func _spawn_forest_boundary() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var w := float(MAP_W * TILE_PX)
	var h := float(MAP_H * TILE_PX)
	var exclusions: Array[Rect2] = [
		Rect2(840.0, 420.0, 320.0, 240.0),
		Rect2(880.0, 0.0, 160.0, 120.0),
		Rect2(880.0, h - 120.0, 160.0, 120.0),
		Rect2(0.0, 460.0, 120.0, 200.0),
		Rect2(w - 120.0, 460.0, 120.0, 200.0),
	]
	const clusters_per_edge := 11
	const trees_min := 10
	const trees_max := 18
	for _i in clusters_per_edge:
		var north_c := Vector2(rng.randf_range(64.0, w - 64.0), rng.randf_range(36.0, 108.0))
		_spawn_tree_cluster(north_c, rng, rng.randi_range(trees_min, trees_max), exclusions)
	for _i in clusters_per_edge:
		var south_c := Vector2(rng.randf_range(64.0, w - 64.0), rng.randf_range(h - 108.0, h - 36.0))
		_spawn_tree_cluster(south_c, rng, rng.randi_range(trees_min, trees_max), exclusions)
	for _i in clusters_per_edge:
		var west_c := Vector2(rng.randf_range(36.0, 108.0), rng.randf_range(120.0, h - 120.0))
		_spawn_tree_cluster(west_c, rng, rng.randi_range(trees_min, trees_max), exclusions)
	for _i in clusters_per_edge:
		var east_c := Vector2(rng.randf_range(w - 108.0, w - 36.0), rng.randf_range(120.0, h - 120.0))
		_spawn_tree_cluster(east_c, rng, rng.randi_range(trees_min, trees_max), exclusions)


func _spawn_tree_cluster(
	center: Vector2, rng: RandomNumberGenerator, count: int, exclusions: Array[Rect2]
) -> void:
	for _j in count:
		var pos := center + Vector2(rng.randfn(0.0, 42.0), rng.randfn(0.0, 32.0))
		pos.x = clampf(pos.x, 20.0, float(MAP_W * TILE_PX) - 20.0)
		pos.y = clampf(pos.y, 20.0, float(MAP_H * TILE_PX) - 20.0)
		if _point_in_any_rect(pos, exclusions):
			continue
		var tree: Node2D = TREE_SCENE.instantiate()
		tree.position = pos
		_trees_root.add_child(tree)


func _point_in_any_rect(p: Vector2, rects: Array[Rect2]) -> bool:
	for r: Rect2 in rects:
		if r.has_point(p):
			return true
	return false


func _clear_tile_layers() -> void:
	_ground.clear()
	_details.clear()
	_obstacles.clear()


func _fill_ground_grass_only() -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			_ground.set_cell(Vector2i(x, y), SOURCE_ID, _atlas_grass)


func _load_grass_from_mapping() -> void:
	var grass := Vector2i(-1, -1)
	var text := FileAccess.get_file_as_string(MAPPING_PATH)
	for line in text.split("\n"):
		var s := line.strip_edges()
		if s.is_empty() or s.begins_with("#"):
			continue
		var parsed: Variant = _parse_mapping_line_name_and_cell(s)
		if parsed == null:
			continue
		var key: String = parsed["name"]
		var cell: Vector2i = parsed["cell"]
		if key == "grass.png":
			grass = cell
			break
	if grass.x < 0:
		push_error(
			"Overworld: mapping.txt must define grass.png "
			+ "(e.g. `grass.png -> Grid Coord: (0, 0)` or `grass.png is at 0,0`)."
		)
		_atlas_grass = Vector2i.ZERO
	else:
		_atlas_grass = grass


## Supports `name.png -> Grid Coord: (col, row)` and `name.png is at col,row`.
func _parse_mapping_line_name_and_cell(s: String) -> Variant:
	const grid_mark := " -> Grid Coord: ("
	if s.contains(grid_mark):
		var gp := s.split(grid_mark, false, 1)
		if gp.size() != 2:
			return null
		var fname := gp[0].strip_edges()
		var tail := gp[1].strip_edges()
		if not tail.ends_with(")"):
			return null
		tail = tail.substr(0, tail.length() - 1)
		var coords := tail.split(",", false)
		if coords.size() != 2:
			return null
		var col := coords[0].strip_edges().to_int()
		var row := coords[1].strip_edges().to_int()
		return {"name": fname.to_lower(), "cell": Vector2i(col, row)}
	var marker := " is at "
	if not s.contains(marker):
		return null
	var parts := s.split(marker, false, 1)
	if parts.size() != 2:
		return null
	var key := parts[0].strip_edges().to_lower()
	var coords2 := parts[1].strip_edges().split(",")
	if coords2.size() != 2:
		return null
	var c0 := coords2[0].strip_edges().to_int()
	var r0 := coords2[1].strip_edges().to_int()
	return {"name": key, "cell": Vector2i(c0, r0)}
