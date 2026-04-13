extends CharacterBody2D

@export var move_speed: float = 140.0

var _interaction_target: Node = null


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_interact()


func warp_to_spawn(_spawn_id: StringName, map_root: Node) -> void:
	if map_root == null:
		return

	var spawn_point := map_root.get_node_or_null("SpawnStart")
	if spawn_point is Node2D:
		global_position = (spawn_point as Node2D).global_position


func set_interaction_target(target: Node) -> void:
	_interaction_target = target


func clear_interaction_target(target: Node) -> void:
	if _interaction_target == target:
		_interaction_target = null


func _interact() -> void:
	if _interaction_target != null and _interaction_target.has_method("interact"):
		_interaction_target.call("interact", self)
		return
	EventBus.request_ui_prompt.emit("No one is close enough to interact.")
