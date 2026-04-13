extends Node2D

const OAKHAVEN := "res://scenes/world/oakhaven.tscn"
const SUNKEN_LIBRARY := "res://scenes/world/sunken_library_entry.tscn"

func _ready() -> void:
	EventBus.request_ui_prompt.emit("Whispering Vales: the trees murmur forgotten names.")
	LoreManager.mark_entry_discovered("world_lore_006")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.y >= 1056.0:
		return {
			"map_scene_path": OAKHAVEN,
			"spawn_id": "from_whispering_north",
		}
	if player_position.x >= 1896.0:
		return {
			"map_scene_path": SUNKEN_LIBRARY,
			"spawn_id": "from_vales_west",
		}
	return {}


