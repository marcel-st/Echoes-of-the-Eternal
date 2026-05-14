extends Node2D

## Hub overworld: Oakhaven village and region gates.

const WorldPainter := preload("res://world/world_painter.gd")
const NORTH_MAP := "res://scenes/world/whispering_vales.tscn"
const SOUTH_MAP := "res://scenes/world/sunken_library_entry.tscn"
const EAST_MAP := "res://scenes/world/cinder_peaks.tscn"
const WEST_MAP := "res://scenes/world/sinking_sands.tscn"

func _ready() -> void:
	WorldPainter.paint_oakhaven(self)
	if QuestManager.get_quest_state(&"MQ_01_AWAKENING") == "active":
		EventBus.request_ui_prompt.emit("Follow the southern road toward the Sunken Library.")
	elif bool(WorldFlags.get_flag(&"npc_corwin_met", false)):
		EventBus.request_ui_prompt.emit("The library marker is on your map. Head south when ready.")
	else:
		EventBus.request_ui_prompt.emit("Talk with Herald Corwin in Oakhaven's village green.")
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
