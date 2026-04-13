extends Resource
class_name SaveData

@export var save_version: int = 1
@export var map_scene_path: String = "res://scenes/world/starter_map.tscn"
@export var spawn_id: String = "start"
@export var player_position: Vector2 = Vector2(960, 540)
@export var playtime_seconds: int = 0
@export var world_flags: Dictionary = {}
@export var active_quests: Dictionary = {}
@export var quest_progress: Dictionary = {}
@export var completed_quests: PackedStringArray = []
