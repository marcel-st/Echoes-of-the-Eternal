extends Area2D

@export var npc_id: StringName = &"npc_generic"
@export var display_name: String = "Villager"
@export var default_dialogue_id: StringName = &""
@export var prompt_text: String = "Press E to talk"
@export var interaction_radius: float = 48.0
@export var interaction_cooldown_seconds: float = 0.25

@export var dialogue_by_flag_true: Dictionary = {}
@export var dialogue_by_quest_state: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $NameLabel

var _player_in_range := false
var _cooldown_timer := 0.0


func _ready() -> void:
	_configure_collision_shape()
	name_label.text = display_name
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if not EventBus.dialogue_closed.is_connected(_on_dialogue_closed):
		EventBus.dialogue_closed.connect(_on_dialogue_closed)


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _player_in_range and _cooldown_timer <= 0.0:
		EventBus.request_ui_prompt.emit("%s (%s)" % [prompt_text, display_name])


func interact(_actor: Node = null) -> void:
	if not _player_in_range:
		return
	if _cooldown_timer > 0.0:
		return
	var dialogue_id := _resolve_dialogue_id()
	if dialogue_id.is_empty():
		EventBus.request_ui_prompt.emit("%s has nothing to say right now." % display_name)
		return
	DialogueManager.request_dialogue(
		dialogue_id,
		{
			"speaker_id": String(npc_id),
			"speaker_name": display_name,
		}
	)
	_cooldown_timer = interaction_cooldown_seconds


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	if body.has_method("set_interaction_target"):
		body.call("set_interaction_target", self)
	EventBus.request_ui_prompt.emit("%s (%s)" % [prompt_text, display_name])


func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	if body.has_method("clear_interaction_target"):
		body.call("clear_interaction_target", self)


func _on_dialogue_closed(_dialogue_id: StringName) -> void:
	_cooldown_timer = interaction_cooldown_seconds


func _resolve_dialogue_id() -> StringName:
	for flag_name in dialogue_by_flag_true.keys():
		if WorldFlags.get_flag(StringName(flag_name), false):
			return StringName(dialogue_by_flag_true[flag_name])

	for quest_id in dialogue_by_quest_state.keys():
		var expected_state_map_variant := dialogue_by_quest_state[quest_id]
		if typeof(expected_state_map_variant) != TYPE_DICTIONARY:
			continue
		var expected_state_map := expected_state_map_variant as Dictionary
		var current_state := QuestManager.get_quest_state(StringName(quest_id))
		if expected_state_map.has(current_state):
			return StringName(expected_state_map[current_state])

	return default_dialogue_id


func _configure_collision_shape() -> void:
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	collision_shape.shape = circle
