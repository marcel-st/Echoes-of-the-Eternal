extends Control

const WORLD_SIZE := Vector2(1920.0, 1088.0)
const OVERWORLD := "res://scenes/world/overworld.tscn"
const VALES := "res://scenes/world/whispering_vales.tscn"
const LIBRARY := "res://scenes/world/sunken_library_entry.tscn"
const SANDS := "res://scenes/world/sinking_sands.tscn"
const CINDER := "res://scenes/world/cinder_peaks.tscn"

const REGION_POS := {
	OVERWORLD: Vector2(0.50, 0.50),
	VALES: Vector2(0.50, 0.18),
	LIBRARY: Vector2(0.50, 0.82),
	SANDS: Vector2(0.18, 0.52),
	CINDER: Vector2(0.82, 0.52),
}
const REGION_LABELS := {
	OVERWORLD: "Oakhaven",
	VALES: "Vales",
	LIBRARY: "Library",
	SANDS: "Sands",
	CINDER: "Cinder",
}
const CONNECTIONS := [
	[OVERWORLD, VALES],
	[OVERWORLD, LIBRARY],
	[OVERWORLD, SANDS],
	[OVERWORLD, CINDER],
]

var _redraw_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(124, 100)
	if not EventBus.map_changed.is_connected(_on_runtime_map_changed):
		EventBus.map_changed.connect(_on_runtime_map_changed)
	if not EventBus.quest_state_changed.is_connected(_on_quest_state_changed):
		EventBus.quest_state_changed.connect(_on_quest_state_changed)
	if not EventBus.world_flag_changed.is_connected(_on_world_flag_changed):
		EventBus.world_flag_changed.connect(_on_world_flag_changed)


func _process(delta: float) -> void:
	_redraw_timer -= delta
	if _redraw_timer <= 0.0:
		_redraw_timer = 0.18
		queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var panel := Rect2(Vector2.ZERO, size)
	var map_rect := Rect2(Vector2(12.0, 10.0), Vector2(size.x - 24.0, size.y - 44.0))
	var current_scene := _current_scene_path()
	var goal_scene := _goal_scene_path()
	var goal_label := _goal_label()

	draw_rect(panel, Color(0.035, 0.05, 0.06, 0.74), true)
	draw_rect(panel, Color(0.60, 0.70, 0.62, 0.82), false, 1.5)
	draw_rect(map_rect, Color(0.10, 0.15, 0.14, 0.70), true)

	for connection in CONNECTIONS:
		var a := _region_point(map_rect, String(connection[0]))
		var b := _region_point(map_rect, String(connection[1]))
		draw_line(a, b, Color(0.65, 0.57, 0.36, 0.76), 4.0)
		draw_line(a, b, Color(0.19, 0.16, 0.10, 0.52), 1.0)

	for scene_path in REGION_POS.keys():
		var point := _region_point(map_rect, String(scene_path))
		var is_current := String(scene_path) == current_scene
		var is_goal := String(scene_path) == goal_scene
		var fill := Color(0.33, 0.55, 0.38, 1.0)
		var outline := Color(0.13, 0.20, 0.16, 1.0)
		var radius := 8.0
		if is_goal:
			draw_circle(point, 13.0, Color(0.95, 0.78, 0.28, 0.32))
			outline = Color(0.96, 0.81, 0.33, 1.0)
		if is_current:
			fill = Color(0.83, 0.92, 0.66, 1.0)
			radius = 9.5
		draw_circle(point, radius, fill)
		draw_arc(point, radius + 1.5, 0.0, TAU, 24, outline, 2.0)

	_draw_player_marker(map_rect, current_scene)
	_draw_local_goal_marker(map_rect, current_scene, goal_scene)
	_draw_goal_direction(map_rect, current_scene, goal_scene)
	_draw_caption(current_scene, goal_label)


func _draw_player_marker(map_rect: Rect2, current_scene: String) -> void:
	if not REGION_POS.has(current_scene):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var region_point := _region_point(map_rect, current_scene)
	var local := Vector2(
		clampf(player.global_position.x / WORLD_SIZE.x, 0.0, 1.0),
		clampf(player.global_position.y / WORLD_SIZE.y, 0.0, 1.0)
	)
	var marker := region_point + (local - Vector2(0.5, 0.5)) * 28.0
	draw_circle(marker, 3.5, Color(0.38, 0.86, 1.0, 1.0))
	draw_arc(marker, 5.5, 0.0, TAU, 16, Color(0.02, 0.08, 0.12, 0.9), 1.4)


func _draw_goal_direction(map_rect: Rect2, current_scene: String, goal_scene: String) -> void:
	if current_scene == goal_scene:
		return
	if not REGION_POS.has(current_scene) or not REGION_POS.has(goal_scene):
		return
	var from_point := _region_point(map_rect, current_scene)
	var to_point := _region_point(map_rect, goal_scene)
	var direction := (to_point - from_point).normalized()
	var tip := from_point + direction * 24.0
	var side := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		tip,
		tip - direction * 9.0 + side * 5.0,
		tip - direction * 9.0 - side * 5.0,
	])
	draw_colored_polygon(points, Color(0.96, 0.78, 0.26, 0.95))


func _draw_local_goal_marker(map_rect: Rect2, current_scene: String, goal_scene: String) -> void:
	if current_scene != goal_scene and not (current_scene == OVERWORLD and goal_scene == LIBRARY):
		return
	var world_goal := _goal_world_position()
	if world_goal == Vector2.INF:
		return
	var region_point := _region_point(map_rect, current_scene)
	var local := Vector2(
		clampf(world_goal.x / WORLD_SIZE.x, 0.0, 1.0),
		clampf(world_goal.y / WORLD_SIZE.y, 0.0, 1.0)
	)
	var marker := region_point + (local - Vector2(0.5, 0.5)) * 28.0
	draw_circle(marker, 5.5, Color(0.96, 0.78, 0.26, 0.95))
	draw_arc(marker, 7.0, 0.0, TAU, 16, Color(0.08, 0.05, 0.02, 0.9), 1.4)


func _draw_caption(current_scene: String, goal_label: String) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := 11
	var current_label := String(REGION_LABELS.get(current_scene, "Unknown"))
	draw_string(
		font,
		Vector2(12.0, size.y - 24.0),
		current_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 24.0,
		font_size,
		Color(0.89, 0.95, 0.84, 1.0)
	)
	draw_string(
		font,
		Vector2(12.0, size.y - 9.0),
		goal_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 24.0,
		font_size,
		Color(0.96, 0.81, 0.38, 1.0)
	)


func _region_point(rect: Rect2, scene_path: String) -> Vector2:
	var normalized: Vector2 = REGION_POS.get(scene_path, Vector2(0.5, 0.5))
	return rect.position + normalized * rect.size


func _current_scene_path() -> String:
	var current := SceneRouter.get_current_map_path()
	if current.is_empty():
		return OVERWORLD
	return current


func _goal_scene_path() -> String:
	if QuestManager.get_quest_state(&"MQ_01_AWAKENING") == "active":
		return LIBRARY
	if bool(WorldFlags.get_flag(&"map_marker_library", false)):
		return LIBRARY
	if bool(WorldFlags.get_flag(&"npc_corwin_met", false)):
		return LIBRARY
	return OVERWORLD


func _goal_label() -> String:
	if QuestManager.get_quest_state(&"MQ_01_AWAKENING") == "active":
		if _current_scene_path() == OVERWORLD:
			return "Goal: South gate"
		return "Goal: Library"
	if bool(WorldFlags.get_flag(&"map_marker_library", false)):
		if _current_scene_path() == OVERWORLD:
			return "Goal: South gate"
		return "Goal: Library"
	if bool(WorldFlags.get_flag(&"npc_corwin_met", false)):
		if _current_scene_path() == OVERWORLD:
			return "Goal: South gate"
		return "Goal: Library"
	if _current_scene_path() == OVERWORLD:
		return "Goal: Herald"
	return "Goal: Oakhaven"


func _goal_world_position() -> Vector2:
	if _current_scene_path() == OVERWORLD and _goal_scene_path() == LIBRARY:
		return Vector2(960.0, 1040.0)
	if _goal_scene_path() != OVERWORLD:
		return Vector2.INF
	return Vector2(992.0, 544.0)


func _on_runtime_map_changed(_map_scene_path: String) -> void:
	queue_redraw()


func _on_quest_state_changed(_quest_id: String, _new_state: String) -> void:
	queue_redraw()


func _on_world_flag_changed(_flag_key: String, _value: Variant) -> void:
	queue_redraw()
