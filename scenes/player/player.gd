extends CharacterBody2D

@export var move_speed: float = 140.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		DialogueManager.request_dialogue(&"MS_ACT1_01")


func warp_to_spawn(_spawn_id: StringName, map_root: Node) -> void:
	if map_root == null:
		return

	var spawn_point := map_root.get_node_or_null("SpawnStart")
	if spawn_point is Node2D:
		global_position = (spawn_point as Node2D).global_position
