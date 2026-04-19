extends Node

## Global audio: overlapping SFX pool, one looping music stream, one looping ambience bed.
## Kenney `.resources` had many **UI / click** clips (Interface + UI Audio); no files named *wind*
## or *forest* were found — startup ambience uses the soft **Flowing Rocks** music loop as a forest/outdoor bed.

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_AMBIENCE := "Ambience"

const SFX_POOL_SIZE := 16
const DEFAULT_AMBIENCE_DB := -15.0

## Logical names -> `res://kenney_pack/...` (sync from `.resources` via tools script).
const NAMED_SFX_PATHS: Dictionary = {
	"click": KenneyPackPaths.SFX_UI_CLICK,
	"ui_click": KenneyPackPaths.SFX_UI_CLICK,
	"mouse_click": KenneyPackPaths.SFX_UI_MOUSE_CLICK,
	"ui_select": KenneyPackPaths.UI_SELECT,
	"ui_confirm": KenneyPackPaths.UI_CONFIRM,
	"ui_back": KenneyPackPaths.UI_BACK,
	## Kenney Interface short tick — dialogue typewriter / “talk blip” per character.
	"dialogue_blip": KenneyPackPaths.UI_TICK_TYPEWRITER,
	"talk_blip": KenneyPackPaths.UI_TICK_TYPEWRITER,
}

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}


func _ready() -> void:
	_build_players()
	_start_default_ambience()


func _build_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_name_or_master(BUS_MUSIC)
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = _bus_name_or_master(BUS_AMBIENCE)
	add_child(_ambience_player)

	for _i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _bus_name_or_master(BUS_SFX)
		add_child(p)
		_sfx_pool.append(p)


## Short effects; uses a free `AudioStreamPlayer` from the pool so sounds can overlap.
## When `pitch_jitter` is true, applies a small random pitch (good for repeated dialogue ticks).
func play_sfx(sound_name: String, volume_db: float = -6.0, pitch_jitter: bool = false) -> void:
	var path := _resolve_sfx_path(sound_name)
	if path.is_empty():
		push_warning("SoundManager.play_sfx: unknown or empty path for '%s'." % sound_name)
		return
	var stream := _get_cached_stream(path)
	if stream == null:
		push_warning("SoundManager.play_sfx: could not load '%s'." % path)
		return
	var player := _next_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.92, 1.08) if pitch_jitter else 1.0
	player.play()


## Looping background music from a `res://` path (or named resource path).
func play_music(track_path: String, volume_db: float = -4.0) -> void:
	var path := track_path.strip_edges()
	if path.is_empty():
		return
	var stream := _get_cached_stream(path)
	if stream == null:
		push_warning("SoundManager.play_music: could not load '%s'." % path)
		return
	_apply_loop(stream)
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()


func play_ambience_loop(res_path: String, volume_db: float = DEFAULT_AMBIENCE_DB) -> void:
	var path := res_path.strip_edges()
	if path.is_empty():
		return
	var stream := _get_cached_stream(path)
	if stream == null:
		push_warning("SoundManager.play_ambience_loop: could not load '%s'." % path)
		return
	_apply_loop(stream)
	_ambience_player.stream = stream
	_ambience_player.volume_db = volume_db
	_ambience_player.play()


func stop_ambience() -> void:
	if _ambience_player.playing:
		_ambience_player.stop()


func _start_default_ambience() -> void:
	play_ambience_loop(KenneyPackPaths.AMBIENCE_FOREST_BED, DEFAULT_AMBIENCE_DB)


func _resolve_sfx_path(sound_name: String) -> String:
	var key := sound_name.strip_edges()
	if key.is_empty():
		return ""
	if key.begins_with("res://"):
		return key
	if NAMED_SFX_PATHS.has(key):
		return String(NAMED_SFX_PATHS[key])
	return key


func _get_cached_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path] as AudioStream
	var loaded := load(path)
	if loaded is AudioStream:
		_stream_cache[path] = loaded
		return loaded as AudioStream
	return null


func _apply_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _next_sfx_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _bus_name_or_master(bus_name: String) -> StringName:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return StringName(bus_name)
	return &"Master"
