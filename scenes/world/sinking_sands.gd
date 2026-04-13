extends Node2D

const OAKHAVEN := "res://scenes/world/oakhaven.tscn"
const CINDER_PEAKS := "res://scenes/world/cinder_peaks.tscn"

func _ready() -> void:
	EventBus.request_ui_prompt.emit("Sinking Sands: time feels thinner here.")
	LoreManager.mark_entry_discovered("world_lore_007")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.y <= 24.0:
		return {
			"map_scene_path": OAKHAVEN,
			"spawn_id": "from_sands_south",
		}
	if player_position.x <= 24.0:
		return {
			"map_scene_path": CINDER_PEAKS,
			"spawn_id": "from_sands_east",
		}
	return {}