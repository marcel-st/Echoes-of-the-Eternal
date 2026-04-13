extends Node2D

const NORTH_MAP := "res://scenes/world/whispering_vales.tscn"
const SOUTH_MAP := "res://scenes/world/sunken_library_entry.tscn"
const EAST_MAP := "res://scenes/world/cinder_peaks.tscn"
const WEST_MAP := "res://scenes/world/sinking_sands.tscn"


func _ready() -> void:
	EventBus.request_ui_prompt.emit("Oakhaven: the last warm hearth in a fading world.")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.y <= 24.0:
		return {
			"map_scene_path": NORTH_MAP,
			"spawn_id": "from_oakhaven_south",
		}
	if player_position.y >= 1056.0:
		return {
			"map_scene_path": SOUTH_MAP,
			"spawn_id": "from_oakhaven_north",
		}
	if player_position.x >= 1896.0:
		return {
			"map_scene_path": EAST_MAP,
			"spawn_id": "from_oakhaven_west",
		}
	if player_position.x <= 24.0:
		return {
			"map_scene_path": WEST_MAP,
			"spawn_id": "from_oakhaven_east",
		}
	return {}
