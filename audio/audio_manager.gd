extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"
const AMBIENCE_BUS := "Ambience"

var _current_music_stream: AudioStream
var _current_music_player: AudioStreamPlayer
var _fade_tween: Tween


func _ready() -> void:
	_create_music_player()


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _current_music_stream == stream and _current_music_player.playing:
		return

	_current_music_stream = stream
	_current_music_player.stream = stream
	_current_music_player.volume_db = volume_db
	_current_music_player.play()


func stop_music() -> void:
	if _current_music_player.playing:
		_current_music_player.stop()
	_current_music_stream = null


func fade_music_to(stream: AudioStream, duration: float = 1.5) -> void:
	if stream == null:
		return
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_current_music_player, "volume_db", -40.0, duration * 0.5)
	_fade_tween.tween_callback(func() -> void:
		_current_music_stream = stream
		_current_music_player.stream = stream
		_current_music_player.play()
	)
	_fade_tween.tween_property(_current_music_player, "volume_db", 0.0, duration * 0.5)


func _create_music_player() -> void:
	_current_music_player = AudioStreamPlayer.new()
	_current_music_player.bus = MUSIC_BUS
	add_child(_current_music_player)
