extends Node

const SETTINGS_PATH := "user://settings.cfg"

var master_volume_db := 0.0
var music_volume_db := -2.0
var sfx_volume_db := -4.0
var fullscreen := false


func _ready() -> void:
	load_settings()
	_apply_video_settings()
	_apply_audio_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_video_settings()
	save_settings()


func set_audio_levels(master_db: float, music_db: float, sfx_db: float) -> void:
	master_volume_db = master_db
	music_volume_db = music_db
	sfx_volume_db = sfx_db
	_apply_audio_settings()
	save_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("audio", "master_db", master_volume_db)
	config.set_value("audio", "music_db", music_volume_db)
	config.set_value("audio", "sfx_db", sfx_volume_db)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(SETTINGS_PATH)
	if result != OK:
		return
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	master_volume_db = float(config.get_value("audio", "master_db", master_volume_db))
	music_volume_db = float(config.get_value("audio", "music_db", music_volume_db))
	sfx_volume_db = float(config.get_value("audio", "sfx_db", sfx_volume_db))


func _apply_video_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume_db)
	_set_bus_volume("Music", music_volume_db)
	_set_bus_volume("SFX", sfx_volume_db)


func _set_bus_volume(bus_name: String, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)
