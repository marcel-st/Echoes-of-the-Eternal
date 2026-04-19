extends Node2D

const OVERWORLD := "res://scenes/world/overworld.tscn"
const WHISPERING_VALES := "res://scenes/world/whispering_vales.tscn"
const SUNKEN_LIBRARY := "res://scenes/world/sunken_library_entry.tscn"
const CINDER_PEAKS := "res://scenes/world/cinder_peaks.tscn"
const SINKING_SANDS := "res://scenes/world/sinking_sands.tscn"

@onready var north_gate: Marker2D = $NorthGate
@onready var south_gate: Marker2D = $SouthGate
@onready var west_gate: Marker2D = $WestGate
@onready var east_gate: Marker2D = $EastGate

var _current_region_name := "Starter Plains"
var _last_gate_prompt := ""


func _ready() -> void:
	_current_region_name = "Oakhaven Outskirts"
	EventBus.request_ui_prompt.emit(
		"Explore Oakhaven. Speak to Elara, then use map gates to travel surrounding regions."
	)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not (player is Node2D):
		return

	var player_pos := (player as Node2D).global_position
	if _near_gate(player_pos, north_gate):
		_handle_gate("North", SUNKEN_LIBRARY)
		return
	if _near_gate(player_pos, south_gate):
		_handle_gate("South", SINKING_SANDS)
		return
	if _near_gate(player_pos, west_gate):
		_handle_gate("West", WHISPERING_VALES)
		return
	if _near_gate(player_pos, east_gate):
		_handle_gate("East", CINDER_PEAKS)
		return

	if _last_gate_prompt != "":
		_last_gate_prompt = ""
		EventBus.request_ui_prompt.emit(
			"Region: %s. Meet townsfolk and uncover memory echoes." % _current_region_name
		)


func _near_gate(player_position: Vector2, gate: Marker2D, threshold: float = 72.0) -> bool:
	return player_position.distance_to(gate.global_position) <= threshold


func _handle_gate(direction: String, target_scene: String) -> void:
	var prompt := "Travel %s to %s [Press Confirm]" % [direction, _scene_label(target_scene)]
	if _last_gate_prompt != prompt:
		_last_gate_prompt = prompt
		EventBus.request_ui_prompt.emit(prompt)

	if Input.is_action_just_pressed("confirm"):
		var spawn_id := _spawn_for_target(target_scene)
		SceneRouter.change_map(target_scene, spawn_id)


func _scene_label(scene_path: String) -> String:
	if scene_path == OVERWORLD:
		return "Oakhaven"
	if scene_path == WHISPERING_VALES:
		return "Whispering Vales"
	if scene_path == SUNKEN_LIBRARY:
		return "Sunken Library"
	if scene_path == CINDER_PEAKS:
		return "Cinder Peaks"
	if scene_path == SINKING_SANDS:
		return "Sinking Sands"
	return "Unknown Region"


func _spawn_for_target(scene_path: String) -> StringName:
	if scene_path == OVERWORLD:
		return &"from_starter"
	if scene_path == WHISPERING_VALES:
		return &"from_oakhaven"
	if scene_path == SUNKEN_LIBRARY:
		return &"from_oakhaven"
	if scene_path == CINDER_PEAKS:
		return &"from_oakhaven"
	if scene_path == SINKING_SANDS:
		return &"from_oakhaven"
	return &"start"
