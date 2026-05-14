extends RefCounted

const TINY_TOWN_TILESET := preload("res://assets/tilesets/tiny_town.tres")
const TREE_SCENE := preload("res://scenes/objects/Tree.tscn")
const Tiles := preload("res://world/tiny_town_tiles.gd")

const MAP_W := 120
const MAP_H := 68
const TILE_PX := 16
const SOURCE_ID := 0

const PLAZA := Tiles.DIRT_CENTER


static func paint_oakhaven(root: Node2D) -> void:
	var layers := _prepare_layers(root)
	_fill(layers.ground, Tiles.GRASS)
	_scatter(layers.details, Tiles.FLOWERS, 52, 1341, Rect2i(8, 6, MAP_W - 16, MAP_H - 12))
	_scatter(layers.details, Tiles.GRASS_SPECKLE, 95, 1803, Rect2i(4, 4, MAP_W - 8, MAP_H - 8))
	_paint_crossroads(layers.details)
	_paint_dirt_rect(layers.details, Rect2i(52, 28, 16, 9))
	_paint_path(layers.details, [Vector2i(42, 23), Vector2i(50, 25), Vector2i(56, 31)], 2, Tiles.DIRT_CENTER)
	_paint_path(layers.details, [Vector2i(68, 39), Vector2i(82, 45), Vector2i(103, 48)], 2, Tiles.DIRT_CENTER)
	_paint_dirt_rect(layers.details, Rect2i(35, 20, 7, 3))
	_paint_dirt_rect(layers.details, Rect2i(79, 24, 7, 3))
	_paint_dirt_rect(layers.details, Rect2i(34, 50, 7, 3))
	_paint_dirt_rect(layers.details, Rect2i(84, 49, 7, 3))
	_stamp(layers.details, Vector2i(50, 31), Tiles.SIGN)
	_paint_flower_field(layers.details, Rect2i(15, 14, 12, 9), 2401)
	_paint_flower_field(layers.details, Rect2i(95, 14, 11, 8), 2402)
	_paint_flower_field(layers.details, Rect2i(18, 48, 10, 8), 2403)
	_spawn_boundary_trees(root, 1347, 13, true)
	_spawn_grove(root, Vector2(320, 270), 18, 341)
	_spawn_grove(root, Vector2(1620, 790), 16, 777)


static func paint_vales(root: Node2D) -> void:
	var layers := _prepare_layers(root)
	_fill(layers.ground, Tiles.GRASS)
	_scatter(layers.details, Tiles.GRASS_SPECKLE, 140, 813, Rect2i(2, 2, MAP_W - 4, MAP_H - 4))
	_scatter(layers.details, Tiles.FLOWERS, 80, 814, Rect2i(8, 7, MAP_W - 16, MAP_H - 14))
	_paint_path(layers.details, [Vector2i(61, 0), Vector2i(56, 13), Vector2i(62, 28), Vector2i(57, 45), Vector2i(60, 67)], 3, Tiles.DIRT_CENTER)
	_paint_dirt_rect(layers.details, Rect2i(54, 58, 12, 10))
	_paint_path(layers.details, [Vector2i(61, 30), Vector2i(76, 27), Vector2i(94, 28), Vector2i(112, 30)], 2, Tiles.DIRT_CENTER)
	_paint_flower_field(layers.details, Rect2i(18, 18, 20, 14), 3101)
	_paint_flower_field(layers.details, Rect2i(77, 39, 19, 12), 3102)
	_stamp(layers.details, Vector2i(59, 58), Tiles.SIGN)
	_spawn_boundary_trees(root, 381, 20, true)
	_spawn_grove(root, Vector2(520, 350), 24, 951)
	_spawn_grove(root, Vector2(1330, 330), 20, 952)
	_spawn_grove(root, Vector2(250, 780), 14, 953)


static func paint_library(root: Node2D) -> void:
	var layers := _prepare_layers(root)
	_fill(layers.ground, Tiles.GRASS)
	_scatter(layers.details, Tiles.GRASS_SPECKLE, 70, 219, Rect2i(38, 4, MAP_W - 44, MAP_H - 12))
	_paint_rect(layers.details, Rect2i(0, 48, MAP_W, 20), Tiles.STONE_FLOOR_A)
	_paint_rect(layers.details, Rect2i(0, 0, 34, MAP_H), Tiles.STONE_FLOOR_B)
	_paint_rect(layers.details, Rect2i(36, 20, 43, 17), PLAZA)
	_paint_rect(layers.details, Rect2i(45, 14, 24, 8), Tiles.RUIN_FLOOR)
	_paint_rect(layers.details, Rect2i(45, 12, 24, 2), Tiles.RUIN_WALL)
	_paint_rect(layers.details, Rect2i(43, 14, 2, 12), Tiles.RUIN_WALL)
	_paint_rect(layers.details, Rect2i(69, 14, 2, 12), Tiles.RUIN_WALL)
	_paint_path(layers.details, [Vector2i(0, 34), Vector2i(28, 34), Vector2i(45, 29), Vector2i(57, 29)], 3, Tiles.DIRT_CENTER)
	_paint_path(layers.details, [Vector2i(57, 37), Vector2i(72, 49), Vector2i(91, 58), Vector2i(119, 58)], 4, Tiles.DIRT_CENTER)
	_scatter(layers.details, Tiles.SMALL_ROCK, 28, 220, Rect2i(8, 42, 34, 18))
	_scatter(layers.details, Tiles.STONE_FLOOR_C, 52, 221, Rect2i(6, 8, MAP_W - 12, MAP_H - 16))
	_stamp(layers.details, Vector2i(51, 38), Tiles.SIGN)
	_spawn_boundary_trees(root, 720, 8, false)
	_spawn_grove(root, Vector2(1510, 260), 11, 722)


static func paint_sands(root: Node2D) -> void:
	var layers := _prepare_layers(root)
	_fill(layers.ground, Tiles.DIRT_CENTER)
	_scatter(layers.details, Tiles.DIRT_TOP, 80, 602, Rect2i(4, 4, MAP_W - 8, MAP_H - 8))
	_scatter(layers.details, Tiles.DIRT_BOTTOM, 80, 603, Rect2i(4, 4, MAP_W - 8, MAP_H - 8))
	_paint_dirt_rect(layers.details, Rect2i(50, 0, 20, 16))
	_paint_path(layers.details, [Vector2i(0, 34), Vector2i(24, 34), Vector2i(43, 30), Vector2i(62, 12)], 4, Tiles.DIRT_CENTER)
	_paint_path(layers.details, [Vector2i(42, 31), Vector2i(64, 35), Vector2i(88, 33), Vector2i(119, 34)], 3, Tiles.DIRT_CENTER)
	_paint_dirt_rect(layers.details, Rect2i(14, 23, 28, 14))
	_paint_rect(layers.details, Rect2i(84, 46, 18, 10), Tiles.STONE_FLOOR_A)
	_scatter(layers.details, Tiles.STONE_FLOOR_C, 50, 604, Rect2i(3, 8, MAP_W - 6, MAP_H - 14))
	_stamp(layers.details, Vector2i(39, 29), Tiles.SIGN)


static func paint_cinder(root: Node2D) -> void:
	var layers := _prepare_layers(root)
	_fill(layers.ground, Tiles.STONE_FLOOR_A)
	_scatter(layers.details, Tiles.STONE_FLOOR_B, 160, 909, Rect2i(3, 3, MAP_W - 6, MAP_H - 6))
	_scatter(layers.details, Tiles.STONE_FLOOR_C, 80, 910, Rect2i(3, 3, MAP_W - 6, MAP_H - 6))
	_paint_path(layers.details, [Vector2i(0, 34), Vector2i(18, 34), Vector2i(36, 42), Vector2i(61, 61)], 4, Tiles.DIRT_CENTER)
	_paint_rect(layers.details, Rect2i(0, 26, 20, 16), PLAZA)
	_paint_rect(layers.details, Rect2i(52, 57, 18, 11), PLAZA)
	_paint_rect(layers.details, Rect2i(75, 18, 24, 10), Tiles.RUIN_FLOOR)
	_paint_rect(layers.details, Rect2i(75, 16, 24, 2), Tiles.RUIN_WALL)
	_stamp(layers.details, Vector2i(16, 29), Tiles.SIGN)
	_stamp(layers.details, Vector2i(62, 60), Tiles.SMALL_ROCK)


static func _prepare_layers(root: Node2D) -> Dictionary:
	for child in root.get_children():
		if child is ColorRect or child.name == "TileMaps":
			child.visible = false
	var terrain := root.get_node_or_null("GeneratedTerrain")
	if terrain != null:
		terrain.queue_free()
	var entities := root.get_node_or_null("Entities")
	if entities != null:
		for child in entities.get_children():
			if child.is_in_group("generated_world_prop"):
				child.queue_free()
	terrain = Node2D.new()
	terrain.name = "GeneratedTerrain"
	terrain.z_index = -10
	root.add_child(terrain)
	root.move_child(terrain, 0)

	var ground := _make_layer("Ground", -12)
	var details := _make_layer("Details", -11)
	terrain.add_child(ground)
	terrain.add_child(details)
	return {"ground": ground, "details": details}


static func _make_layer(layer_name: String, z: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = TINY_TOWN_TILESET
	layer.z_index = z
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.collision_enabled = false
	return layer


static func _fill(layer: TileMapLayer, atlas_coords: Vector2i) -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			layer.set_cell(Vector2i(x, y), SOURCE_ID, atlas_coords)


static func _paint_crossroads(layer: TileMapLayer) -> void:
	_paint_rect(layer, Rect2i(57, 0, 6, MAP_H), Tiles.DIRT_CENTER)
	_paint_rect(layer, Rect2i(0, 32, MAP_W, 4), Tiles.DIRT_CENTER)
	_paint_rect(layer, Rect2i(56, 0, 1, MAP_H), Tiles.DIRT_EDGE_L)
	_paint_rect(layer, Rect2i(63, 0, 1, MAP_H), Tiles.DIRT_EDGE_R)
	_paint_rect(layer, Rect2i(0, 31, MAP_W, 1), Tiles.DIRT_TOP)
	_paint_rect(layer, Rect2i(0, 36, MAP_W, 1), Tiles.DIRT_BOTTOM)


static func _paint_flower_field(layer: TileMapLayer, rect: Rect2i, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if rng.randf() < 0.52:
				_stamp(layer, Vector2i(x, y), Tiles.FLOWERS)


static func _paint_dirt_rect(layer: TileMapLayer, rect: Rect2i) -> void:
	_paint_rect(layer, rect, Tiles.DIRT_CENTER)
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		_stamp(layer, Vector2i(x, rect.position.y), Tiles.DIRT_TOP)
		_stamp(layer, Vector2i(x, rect.position.y + rect.size.y - 1), Tiles.DIRT_BOTTOM)
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		_stamp(layer, Vector2i(rect.position.x, y), Tiles.DIRT_EDGE_L)
		_stamp(layer, Vector2i(rect.position.x + rect.size.x - 1, y), Tiles.DIRT_EDGE_R)


static func _paint_path(layer: TileMapLayer, points: Array[Vector2i], radius: int, atlas_coords: Vector2i) -> void:
	for index in range(points.size() - 1):
		_paint_path_segment(layer, points[index], points[index + 1], radius, atlas_coords)


static func _paint_path_segment(layer: TileMapLayer, from_cell: Vector2i, to_cell: Vector2i, radius: int, atlas_coords: Vector2i) -> void:
	var steps: int = maxi(abs(to_cell.x - from_cell.x), abs(to_cell.y - from_cell.y))
	if steps <= 0:
		_stamp_disc(layer, from_cell, radius, atlas_coords)
		return
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var cell := Vector2i(roundi(lerpf(from_cell.x, to_cell.x, t)), roundi(lerpf(from_cell.y, to_cell.y, t)))
		_stamp_disc(layer, cell, radius, atlas_coords)


static func _stamp_disc(layer: TileMapLayer, center: Vector2i, radius: int, atlas_coords: Vector2i) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if center.distance_to(cell) <= radius:
				_stamp(layer, cell, atlas_coords)


static func _paint_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
				continue
			layer.set_cell(Vector2i(x, y), SOURCE_ID, atlas_coords)


static func _scatter(
	layer: TileMapLayer,
	atlas_coords: Vector2i,
	count: int,
	seed: int,
	area: Rect2i,
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for _i in range(count):
		var cell := Vector2i(
			rng.randi_range(area.position.x, area.position.x + area.size.x - 1),
			rng.randi_range(area.position.y, area.position.y + area.size.y - 1)
		)
		layer.set_cell(cell, SOURCE_ID, atlas_coords)


static func _stamp(layer: TileMapLayer, cell: Vector2i, atlas_coords: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_W or cell.y >= MAP_H:
		return
	layer.set_cell(cell, SOURCE_ID, atlas_coords)


static func _spawn_boundary_trees(root: Node2D, seed: int, clusters_per_edge: int, leave_gate_gaps: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var exclusions: Array[Rect2] = []
	if leave_gate_gaps:
		exclusions = [
			Rect2(820, 0, 280, 150),
			Rect2(820, 910, 280, 170),
			Rect2(0, 420, 160, 260),
			Rect2(1760, 420, 160, 260),
			Rect2(760, 350, 420, 360),
		]
	for _i in clusters_per_edge:
		_spawn_tree_cluster(root, Vector2(rng.randf_range(70, 1850), rng.randf_range(30, 115)), rng, exclusions)
		_spawn_tree_cluster(root, Vector2(rng.randf_range(70, 1850), rng.randf_range(965, 1050)), rng, exclusions)
	for _i in clusters_per_edge:
		_spawn_tree_cluster(root, Vector2(rng.randf_range(30, 115), rng.randf_range(120, 950)), rng, exclusions)
		_spawn_tree_cluster(root, Vector2(rng.randf_range(1805, 1890), rng.randf_range(120, 950)), rng, exclusions)


static func _spawn_grove(root: Node2D, center: Vector2, count: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var exclusions: Array[Rect2] = []
	for _i in range(count):
		var pos := center + Vector2(rng.randfn(0, 92), rng.randfn(0, 58))
		_spawn_tree(root, pos, rng, exclusions)


static func _spawn_tree_cluster(root: Node2D, center: Vector2, rng: RandomNumberGenerator, exclusions: Array[Rect2]) -> void:
	for _i in range(rng.randi_range(4, 8)):
		var pos := center + Vector2(rng.randfn(0, 34), rng.randfn(0, 26))
		_spawn_tree(root, pos, rng, exclusions)


static func _spawn_tree(root: Node2D, pos: Vector2, rng: RandomNumberGenerator, exclusions: Array[Rect2]) -> void:
	pos.x = clampf(pos.x, 20, MAP_W * TILE_PX - 20)
	pos.y = clampf(pos.y, 20, MAP_H * TILE_PX - 20)
	for rect in exclusions:
		if rect.has_point(pos):
			return
	var tree := TREE_SCENE.instantiate() as Node2D
	tree.position = pos
	tree.scale = Vector2.ONE * rng.randf_range(0.92, 1.18)
	tree.add_to_group("generated_world_prop")
	var entities := root.get_node_or_null("Entities")
	if entities != null:
		entities.add_child(tree)
	else:
		root.add_child(tree)
