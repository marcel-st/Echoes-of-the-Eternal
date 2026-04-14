extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"
const AMBIENCE_BUS := "Ambience"

const TRACKS := {
	"overworld": "res://assets/audio/music/kenney_music-jingles/theme_overworld.ogg",
	"mystic": "res://assets/audio/music/kenney_music-jingles/theme_mystic.ogg",
	"cinder": "res://assets/audio/music/kenney_music-jingles/theme_cinder.ogg",
	"veldt": "res://assets/audio/music/kenney_music-jingles/theme_veldt.ogg",
	"dunes": "res://assets/audio/music/kenney_music-jingles/theme_dunes.ogg",
}

const UI_SOUNDS := {
	"select": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_select.ogg",
	"confirm": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_confirm.ogg",
	"back": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_back.ogg",
	"error": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_error.ogg",
	"open": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_open.ogg",
	"close": "res://assets/audio/sfx/ui/kenney_interface-sounds/ui_close.ogg",
}

const WORLD_SOUNDS := {
	"footstep": "res://assets/audio/sfx/world/kenney_rpg-audio/footstep.ogg",
	"interact": "res://assets/audio/sfx/world/kenney_rpg-audio/interact.ogg",
	"swing": "res://assets/audio/sfx/world/kenney_rpg-audio/swing.ogg",
	"map_transition": "res://assets/audio/sfx/world/kenney_rpg-audio/map_transition.ogg",
	"attack_swing": "res://assets/audio/sfx/world/kenney_rpg-audio/swing.ogg",
	"world_interact": "res://assets/audio/sfx/world/kenney_rpg-audio/interact.ogg",
}

const AMBIENCE_SOUNDS := {
	"creak": "res://assets/audio/ambience/kenney_rpg-audio/ambience_creak.ogg",
}

var _current_music_stream: AudioStream
var _current_music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _fade_tween: Tween
var _ui_player_pool: Array[AudioStreamPlayer] = []
var _sfx_player_pool: Array[AudioStreamPlayer] = []
var _track_cache: Dictionary = {}
var _ui_cache: Dictionary = {}
var _world_cache: Dictionary = {}
var _ambience_cache: Dictionary = {}


func _ready() -> void:
	_create_audio_players()
	prime_default_audio()
	if EventBus.has_signal("sfx_requested") and not EventBus.sfx_requested.is_connected(_on_sfx_requested):
		EventBus.sfx_requested.connect(_on_sfx_requested)


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _current_music_stream == stream and _current_music_player.playing:
		return

	_current_music_stream = stream
	_current_music_player.stream = stream
	_current_music_player.volume_db = volume_db
	_current_music_player.play()


func play_music_track(track_id: String, volume_db: float = -4.0) -> void:
	var stream := _resolve_audio(track_id, TRACKS, _track_cache)
	if stream != null:
		play_music(stream, volume_db)


func play_overworld_theme() -> void:
	play_music_track("overworld", -4.0)


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


func fade_music_to_track(track_id: String, duration: float = 1.5) -> void:
	var stream := _resolve_audio(track_id, TRACKS, _track_cache)
	if stream != null:
		fade_music_to(stream, duration)


func play_ui_sound(sound_id: String, volume_db: float = -6.0) -> void:
	var stream := _resolve_audio(sound_id, UI_SOUNDS, _ui_cache)
	if stream == null:
		return
	var player := _next_idle_player(_ui_player_pool)
	player.bus = UI_BUS
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func play_ui(sound_id: String, volume_db: float = -6.0) -> void:
	play_ui_sound(sound_id, volume_db)


func play_ui_open() -> void:
	play_ui_sound("open", -4.0)


func play_ui_close() -> void:
	play_ui_sound("close", -4.0)


func play_world_sfx(sound_id: String, volume_db: float = -8.0) -> void:
	var stream := _resolve_audio(sound_id, WORLD_SOUNDS, _world_cache)
	if stream == null:
		return
	var player := _next_idle_player(_sfx_player_pool)
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func play_sfx(sound_id: String, volume_db: float = -8.0) -> void:
	play_world_sfx(sound_id, volume_db)


func play_ambience(sound_id: String, volume_db: float = -13.0) -> void:
	var stream := _resolve_audio(sound_id, AMBIENCE_SOUNDS, _ambience_cache)
	if stream == null:
		return
	_ambience_player.stream = stream
	_ambience_player.bus = AMBIENCE_BUS
	_ambience_player.volume_db = volume_db
	if not _ambience_player.playing:
		_ambience_player.play()


func stop_ambience() -> void:
	if _ambience_player.playing:
		_ambience_player.stop()


func prime_default_audio() -> void:
	for track_id in TRACKS.keys():
		_resolve_audio(track_id, TRACKS, _track_cache)
	_resolve_audio("select", UI_SOUNDS, _ui_cache)
	_resolve_audio("footstep", WORLD_SOUNDS, _world_cache)
	_resolve_audio("creak", AMBIENCE_SOUNDS, _ambience_cache)


func _create_audio_players() -> void:
	_current_music_player = AudioStreamPlayer.new()
	_current_music_player.bus = MUSIC_BUS
	add_child(_current_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = AMBIENCE_BUS
	add_child(_ambience_player)

	for _i in range(4):
		var ui_player := AudioStreamPlayer.new()
		ui_player.bus = UI_BUS
		add_child(ui_player)
		_ui_player_pool.append(ui_player)

	for _j in range(8):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = SFX_BUS
		add_child(sfx_player)
		_sfx_player_pool.append(sfx_player)


func _next_idle_player(pool: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player
	return pool[0]


func _resolve_audio(sound_id: String, dictionary: Dictionary, cache: Dictionary) -> AudioStream:
	if cache.has(sound_id):
		return cache[sound_id]
	var path := String(dictionary.get(sound_id, "")).strip_edges()
	if path.is_empty():
		return null
	var loaded := load(path)
	if loaded is AudioStream:
		cache[sound_id] = loaded
		return loaded as AudioStream
	return null


func _on_sfx_requested(sfx_id: StringName, volume_db: float) -> void:
	play_world_sfx(String(sfx_id), volume_db)
