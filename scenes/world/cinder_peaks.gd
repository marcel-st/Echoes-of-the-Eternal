extends Node2D

const WorldPainter := preload("res://world/world_painter.gd")
const OVERWORLD := "res://scenes/world/overworld.tscn"
const SINKING_SANDS := "res://scenes/world/sinking_sands.tscn"


func _ready() -> void:
	WorldPainter.paint_cinder(self)
	EventBus.request_ui_prompt.emit("Cinder Peaks: the air burns with old battles.")
	LoreManager.mark_entry_discovered("world_lore_008")


func resolve_transition(player_position: Vector2) -> Dictionary:
	if player_position.x <= 24.0:
		return {
			"map_scene_path": OVERWORLD,
			"spawn_id": "from_cinder_west",
		}
	if player_position.y >= 1056.0:
		return {
			"map_scene_path": SINKING_SANDS,
			"spawn_id": "from_cinder_south",
		}
	return {}
