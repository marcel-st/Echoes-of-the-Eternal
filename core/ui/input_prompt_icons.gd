extends RefCounted
class_name InputPromptIcons

const _DIR := "res://assets/sprites/ui/kenney_input-prompts-pixel/"

static func get_texture(file_stem: String) -> Texture2D:
	var path := _DIR.path_join("%s.png" % file_stem)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
