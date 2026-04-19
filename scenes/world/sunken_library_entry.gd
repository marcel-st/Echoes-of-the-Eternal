extends Node2D

const OVERWORLD := "res://scenes/world/overworld.tscn"
const WHISPERING_VALES := "res://scenes/world/whispering_vales.tscn"


func _ready() -> void:
	EventBus.request_ui_prompt.emit("Sunken Library approach: knowledge sleeps beneath the waterline.")
	LoreManager.mark_entry_discovered("world_lore_009")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.x <= 24.0:
		return {
			"map_scene_path": WHISPERING_VALES,
			"spawn_id": "from_library_east",
		}
	if player_position.y >= 1048.0:
		return {
			"map_scene_path": OVERWORLD,
			"spawn_id": "from_library_north",
		}
	return {}


func get_region_lore_ids() -> Array:
	return [
		"world_lore_009",
		"world_lore_011",
		"world_lore_012",
	]
