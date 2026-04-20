extends RefCounted
class_name InputPromptIcons

## Maps HUD hint stems to loose PNGs under `kenney_pack/` (see KenneyPackPaths).

const _GLYPH_PATHS := {
	"glyph_kb_j": KenneyPackPaths.INPUT_KB_DOUBLE + "keyboard_j.png",
	"glyph_kb_esc": KenneyPackPaths.INPUT_KB_DOUBLE + "keyboard_escape.png",
	"glyph_pad_x": KenneyPackPaths.INPUT_XBOX_DOUBLE + "xbox_button_color_x.png",
	"glyph_pad_a": KenneyPackPaths.INPUT_XBOX_DOUBLE + "xbox_button_color_a.png",
	"glyph_pad_start": KenneyPackPaths.INPUT_XBOX_DOUBLE + "xbox_button_start.png",
}


static func get_texture(file_stem: String) -> Texture2D:
	var path: String
	if file_stem == "glyph_kb_e":
		path = KenneyPackPaths.resolve_keyboard_e_texture_path()
	else:
		path = _GLYPH_PATHS.get(file_stem, "") as String
	if path.is_empty():
		push_warning("InputPromptIcons: unknown glyph stem: %s" % file_stem)
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
