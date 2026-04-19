extends Area2D

@export var lore_entry_id: String = ""
@export var prompt_text: String = "Inspect [E]"
@export var display_name: String = "Lore Plinth"
@export var interaction_radius: float = 52.0
@export var lore_title: String = ""

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interact_prompt: Node2D = $InteractPrompt
@onready var _magic_hum: AudioStreamPlayer2D = $MagicHum

var _player_in_range := false
var _cooldown := 0.0


func _ready() -> void:
	_ensure_magic_hum_loops()
	_configure_collision()
	if interact_prompt != null:
		interact_prompt.visible = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if not EventBus.dialogue_closed.is_connected(_on_dialogue_closed):
		EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)


func interact(_actor: Node = null) -> void:
	if not _player_in_range:
		return
	if _cooldown > 0.0:
		return
	if lore_entry_id.strip_edges().is_empty():
		EventBus.request_ui_prompt.emit("This plinth is blank.")
		return

	var dialogue_id := LoreManager.get_or_create_dialogue_for_lore(lore_entry_id)
	if dialogue_id.is_empty():
		EventBus.request_ui_prompt.emit("The inscription is too faded to read.")
		return
	DialogueManager.request_dialogue(StringName(dialogue_id), {"lore_entry_id": lore_entry_id})
	EventBus.sfx_requested.emit(&"interact", -8.0)
	_cooldown = 0.3


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_player_in_range = true
	if body.has_method("set_interaction_target"):
		body.call("set_interaction_target", self)
	if interact_prompt != null:
		interact_prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_player_in_range = false
	if body.has_method("clear_interaction_target"):
		body.call("clear_interaction_target", self)
	if interact_prompt != null:
		interact_prompt.visible = false


func _on_dialogue_closed(_dialogue_id: StringName) -> void:
	_cooldown = 0.25


func _configure_collision() -> void:
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	collision_shape.shape = circle


## Child `MagicHum` may start via autoplay before loop is applied; duplicate stream so looping is reliable.
func _ensure_magic_hum_loops() -> void:
	if _magic_hum == null or _magic_hum.stream == null:
		return
	var base: AudioStream = _magic_hum.stream
	var dup: AudioStream = base.duplicate()
	if dup is AudioStreamOggVorbis:
		(dup as AudioStreamOggVorbis).loop = true
	_magic_hum.stream = dup
	_magic_hum.bus = _audio_bus_or_master("Ambience")
	if _magic_hum.autoplay:
		_magic_hum.stop()
		_magic_hum.play()


func _audio_bus_or_master(bus_name: String) -> StringName:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return StringName(bus_name)
	return &"Master"
