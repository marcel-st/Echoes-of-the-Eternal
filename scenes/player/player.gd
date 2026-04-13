extends CharacterBody2D

@export var move_speed: float = 140.0

const PLAYER_ANIM_FRAMES := {
	"idle_down": ["res://assets/sprites/world/kenney_tiny-dungeon/player_idle_down.png"],
	"idle_up": ["res://assets/sprites/world/kenney_tiny-dungeon/player_idle_up.png"],
	"idle_side": ["res://assets/sprites/world/kenney_tiny-dungeon/player_idle_side.png"],
	"walk_down": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_down_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_down.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_down_b.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_down.png",
	],
	"walk_up": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_up_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_up.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_up_b.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_up.png",
	],
	"walk_side": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_side_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_side.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_walk_side_b.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_idle_side.png",
	],
}

var _interaction_target: Node = null
var _facing := "down"
var _facing_sign := 1

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("player")
	_build_visual_frames()
	_update_animation(Vector2.DOWN, false)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_update_animation(direction, direction.length() > 0.01)
	if Input.is_action_just_pressed("interact"):
		_interact()


func warp_to_spawn(_spawn_id: StringName, map_root: Node) -> void:
	if map_root == null:
		return

	var spawn_label := String(_spawn_id).strip_edges()
	var spawn_path := "Spawn_%s" % spawn_label
	var spawn_point := map_root.get_node_or_null(spawn_path)
	if spawn_point == null:
		spawn_point = map_root.get_node_or_null("SpawnStart")
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


func _update_animation(direction: Vector2, is_moving: bool) -> void:
	if visual == null:
		return

	if is_moving:
		if absf(direction.x) > absf(direction.y):
			_facing = "side"
			_facing_sign = -1 if direction.x < 0.0 else 1
		elif direction.y < 0.0:
			_facing = "up"
		else:
			_facing = "down"

	var animation_name := "%s_%s" % [("walk" if is_moving else "idle"), _facing]
	if visual.animation != animation_name or not visual.is_playing():
		visual.play(animation_name)
	visual.flip_h = _facing == "side" and _facing_sign < 0


func _build_visual_frames() -> void:
	if visual == null:
		return

	var frames := SpriteFrames.new()
	for animation_name_variant in PLAYER_ANIM_FRAMES.keys():
		var animation_name := String(animation_name_variant)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, 8.0 if animation_name.begins_with("walk") else 2.0)
		var frame_paths_variant := PLAYER_ANIM_FRAMES.get(animation_name, [])
		if typeof(frame_paths_variant) != TYPE_ARRAY:
			continue
		for frame_path_variant in frame_paths_variant as Array:
			var frame_path := String(frame_path_variant)
			var loaded := load(frame_path)
			if loaded is Texture2D:
				frames.add_frame(animation_name, loaded as Texture2D)

	visual.sprite_frames = frames
