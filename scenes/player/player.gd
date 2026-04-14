extends CharacterBody2D

@export var move_speed: float = 140.0
@export var footstep_interval_seconds: float = 0.24

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
	"interact_down": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_down_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_down_b.png",
	],
	"interact_up": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_up_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_up_b.png",
	],
	"interact_side": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_side_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_action_side_b.png",
	],
	"attack_down": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_down_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_down_b.png",
	],
	"attack_up": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_up_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_up_b.png",
	],
	"attack_side": [
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_side_a.png",
		"res://assets/sprites/world/kenney_tiny-dungeon/player_attack_side_b.png",
	],
}

var _interaction_target: Node = null
var _facing := "down"
var _facing_sign := 1
var _action_lock := false
var _action_animation := ""
var _footstep_timer := 0.0

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("player")
	_build_visual_frames()
	_update_animation(Vector2.DOWN, false)
	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _action_lock:
		direction = Vector2.ZERO
	velocity = direction * move_speed
	move_and_slide()
	if not _action_lock:
		_update_animation(direction, direction.length() > 0.01)
		_process_footsteps(_delta, direction.length() > 0.01)
	else:
		_footstep_timer = 0.0
	if Input.is_action_just_pressed("attack"):
		_play_action_animation("attack")
		EventBus.sfx_requested.emit(&"swing", -8.0)
	if Input.is_action_just_pressed("interact"):
		_play_action_animation("interact")
		AudioManager.play_ui_sound("confirm")
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
	if _action_lock:
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


func _play_action_animation(action_prefix: String) -> void:
	if visual == null:
		return
	if _action_lock:
		return
	var animation_name := "%s_%s" % [action_prefix, _facing]
	if not visual.sprite_frames.has_animation(animation_name):
		return
	_action_lock = true
	_action_animation = animation_name
	visual.flip_h = _facing == "side" and _facing_sign < 0
	visual.play(animation_name)


func _on_visual_animation_finished() -> void:
	if not _action_lock:
		return
	if visual == null:
		_action_lock = false
		_action_animation = ""
		return
	if visual.animation != _action_animation:
		return
	_action_lock = false
	_action_animation = ""
	var idle_animation := "idle_%s" % _facing
	if visual.sprite_frames.has_animation(idle_animation):
		visual.play(idle_animation)
	visual.flip_h = _facing == "side" and _facing_sign < 0


func _process_footsteps(delta: float, is_moving: bool) -> void:
	if not is_moving:
		_footstep_timer = 0.0
		return
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	EventBus.sfx_requested.emit(&"footstep", -8.0)
	_footstep_timer = footstep_interval_seconds


func _build_visual_frames() -> void:
	if visual == null:
		return

	var frames := SpriteFrames.new()
	for animation_name_variant in PLAYER_ANIM_FRAMES.keys():
		var animation_name := String(animation_name_variant)
		frames.add_animation(animation_name)
		var is_walk := animation_name.begins_with("walk")
		var is_action := animation_name.begins_with("attack") or animation_name.begins_with("interact")
		frames.set_animation_loop(animation_name, is_walk)
		if is_walk:
			frames.set_animation_speed(animation_name, 8.0)
		elif is_action:
			frames.set_animation_speed(animation_name, 14.0)
		else:
			frames.set_animation_speed(animation_name, 2.0)
		var frame_paths_variant: Variant = PLAYER_ANIM_FRAMES.get(animation_name, [])
		if typeof(frame_paths_variant) != TYPE_ARRAY:
			continue
		for frame_path_variant in frame_paths_variant as Array:
			var frame_path := String(frame_path_variant)
			var loaded := load(frame_path)
			if loaded is Texture2D:
				frames.add_frame(animation_name, loaded as Texture2D)

	visual.sprite_frames = frames
