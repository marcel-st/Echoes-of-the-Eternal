extends Node2D

## Small world-space hint (Kenney keyboard glyph). Bob animation while visible.

@export var bob_amplitude_pixels: float = 1.5
@export var bob_speed: float = 5.0
## Keeps bobbing from drifting too far vertically (avoids popping off-screen near UI edges).
@export var bob_max_offset_pixels: float = 2.0

@onready var _glyph: Sprite2D = $Glyph
@onready var _blip_player: AudioStreamPlayer = $BlipPlayer

var _bob_base_y: float = 0.0
var _blip_stream: AudioStream


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and _blip_stream != null and _blip_player != null:
		_blip_player.stream = _blip_stream
		_blip_player.volume_db = -8.0
		_blip_player.pitch_scale = randf_range(0.95, 1.05)
		_blip_player.play()


func _ready() -> void:
	var loaded := load(KenneyPackPaths.UI_TICK_POP)
	if loaded is AudioStream:
		_blip_stream = loaded as AudioStream
	else:
		push_warning("InteractPrompt: missing blip at %s" % KenneyPackPaths.UI_TICK_POP)
	visible = false
	if _glyph != null:
		var path := KenneyPackPaths.resolve_keyboard_e_texture_path()
		var tex := load(path)
		if tex is Texture2D:
			_glyph.texture = tex as Texture2D
		else:
			push_error("InteractPrompt: missing keyboard E texture at %s" % path)
		_bob_base_y = _glyph.position.y


func _process(_delta: float) -> void:
	if not visible or _glyph == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	var bob := sin(t * bob_speed) * bob_amplitude_pixels
	_glyph.position.y = clampf(_bob_base_y + bob, _bob_base_y - bob_max_offset_pixels, _bob_base_y + bob_max_offset_pixels)
