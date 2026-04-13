extends Node

signal map_change_requested(map_scene_path: String, spawn_id: StringName)
signal map_changed(map_scene_path: String)

signal dialogue_requested(dialogue_id: StringName, context: Dictionary)
signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)
signal dialogue_closed(dialogue_id: StringName)

signal quest_started(quest_id: StringName)
signal quest_updated(quest_id: StringName, objective_id: StringName, progress: int)
signal quest_completed(quest_id: StringName)
signal quest_state_changed(quest_id: String, new_state: String)
signal quests_reloaded

signal item_received(item_id: StringName, amount: int)
signal world_flag_changed(flag_key: String, value: Variant)
signal request_ui_prompt(text: String)
signal player_died
