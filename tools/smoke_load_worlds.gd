extends SceneTree

const WORLD_SCENES: PackedStringArray = [
	"res://scenes/world/overworld.tscn",
	"res://scenes/world/whispering_vales.tscn",
	"res://scenes/world/sunken_library_entry.tscn",
	"res://scenes/world/sinking_sands.tscn",
	"res://scenes/world/cinder_peaks.tscn",
]

var _exit_code := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in WORLD_SCENES:
		var packed := load(scene_path)
		if not (packed is PackedScene):
			push_error("Could not load world scene: %s" % scene_path)
			_exit_code = 1
			break
		var node := (packed as PackedScene).instantiate()
		root.add_child(node)
		await process_frame
		node.queue_free()
		await process_frame
	quit(_exit_code)
