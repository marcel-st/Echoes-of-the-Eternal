extends CharacterBody2D

@export var move_speed: float = 140.0
@export var footstep_interval_seconds: float = 0.24

## Kenney Tiny Dungeon `tilemap_packed.png`: 16×16 cells, 12 columns (no spacing).
## Loose `player_*.png` names are not in the official pack; wrong slices show as chests/tracks.
const PLAYER_ATLAS_PATH := "res://assets/sprites/world/kenney_tiny-dungeon/tilemap_packed.png"
const PLAYER_ATLAS_CELL := 16
const PLAYER_ATLAS_COLS := 12

## Hero tile on `tilemap_packed.png` (16×16 grid, 12 cols). 86 ≈ front villager / overalls (no knight helmet).
## Tile 103 = sword icon — drawn on `SwordSprite` and tweened during attack (body stays on 86).
const PLAYER_HERO_CELL := 86
const PLAYER_ATTACK_SWING_CELL := 103

const PLAYER_ATLAS_FRAMES := {
	"idle_down": [PLAYER_HERO_CELL],
	"idle_up": [PLAYER_HERO_CELL],
	"idle_side": [PLAYER_HERO_CELL],
	"walk_down": [PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL],
	"walk_up": [PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL],
	"walk_side": [PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL, PLAYER_HERO_CELL],
	# Same art each frame: timing only so `animation_finished` runs (no visor swap).
	"interact_down": [PLAYER_HERO_CELL, PLAYER_HERO_CELL],
	"interact_up": [PLAYER_HERO_CELL, PLAYER_HERO_CELL],
	"interact_side": [PLAYER_HERO_CELL, PLAYER_HERO_CELL],
}

var _interaction_target: Node = null
var _facing := "down"
var _facing_sign := 1
var _action_lock := false
var _action_animation := ""
var _footstep_timer := 0.0
var _attack_sword_tween: Tween

@onready var visual: AnimatedSprite2D = $Visual
@onready var sword_pivot: Node2D = $SwordPivot
@onready var sword_sprite: Sprite2D = $SwordPivot/SwordSprite


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
	if action_prefix == "attack":
		_play_attack_sword_swing()


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

	var atlas: Texture2D = null
	var atlas_loaded := load(PLAYER_ATLAS_PATH)
	if atlas_loaded is Texture2D:
		atlas = atlas_loaded as Texture2D
	else:
		var abs_path := ProjectSettings.globalize_path(PLAYER_ATLAS_PATH)
		var img := Image.load_from_file(abs_path)
		if img != null:
			atlas = ImageTexture.create_from_image(img)
	if atlas == null:
		push_error("Player atlas missing or invalid: %s" % PLAYER_ATLAS_PATH)
		return

	var frames := SpriteFrames.new()
	for animation_name_variant in PLAYER_ATLAS_FRAMES.keys():
		var animation_name := String(animation_name_variant)
		frames.add_animation(animation_name)
		var is_walk := animation_name.begins_with("walk")
		var is_action := animation_name.begins_with("attack") or animation_name.begins_with("interact")
		frames.set_animation_loop(animation_name, is_walk)
		if is_walk:
			frames.set_animation_speed(animation_name, 8.0)
		elif is_action:
			frames.set_animation_speed(animation_name, 10.0)
		else:
			frames.set_animation_speed(animation_name, 2.0)
		var cells_variant: Variant = PLAYER_ATLAS_FRAMES.get(animation_name, [])
		if typeof(cells_variant) != TYPE_ARRAY:
			continue
		for cell_variant in cells_variant as Array:
			var cell_idx := int(cell_variant)
			_add_atlas_frame_to_sprite_frames(frames, animation_name, atlas, cell_idx)

	for facing in [&"down", &"up", &"side"]:
		var attack_name := "attack_%s" % String(facing)
		frames.add_animation(attack_name)
		frames.set_animation_loop(attack_name, false)
		frames.set_animation_speed(attack_name, 1.0)
		# Body only; sword is `SwordSprite` + tween in `_play_attack_sword_swing`.
		_add_atlas_frame_to_sprite_frames(frames, attack_name, atlas, PLAYER_HERO_CELL, 0.1)
		_add_atlas_frame_to_sprite_frames(frames, attack_name, atlas, PLAYER_HERO_CELL, 0.16)
		_add_atlas_frame_to_sprite_frames(frames, attack_name, atlas, PLAYER_HERO_CELL, 0.1)

	visual.sprite_frames = frames
	_setup_attack_sword_texture(atlas)


func _setup_attack_sword_texture(atlas: Texture2D) -> void:
	if sword_sprite == null:
		return
	var col := PLAYER_ATTACK_SWING_CELL % PLAYER_ATLAS_COLS
	var row: int = PLAYER_ATTACK_SWING_CELL / PLAYER_ATLAS_COLS
	var region := Rect2i(col * PLAYER_ATLAS_CELL, row * PLAYER_ATLAS_CELL, PLAYER_ATLAS_CELL, PLAYER_ATLAS_CELL)
	var slice := AtlasTexture.new()
	slice.atlas = atlas
	slice.region = region
	slice.filter_clip = true
	sword_sprite.texture = slice
	sword_pivot.visible = false


func _attack_facing_dir() -> Vector2:
	match _facing:
		"up":
			return Vector2.UP
		"side":
			return Vector2.RIGHT * float(_facing_sign)
		_:
			return Vector2.DOWN


func _play_attack_sword_swing() -> void:
	if sword_pivot == null or sword_sprite == null:
		return
	if _attack_sword_tween != null:
		_attack_sword_tween.kill()
	var dir := _attack_facing_dir().normalized()
	# Orbit in front of the sprite (same space as Player; Visual is offset + scaled).
	const ORBIT := 20.0
	sword_pivot.position = visual.position + dir * ORBIT
	sword_pivot.scale = visual.scale
	# Atlas sword points “up” in its cell; align pivot so swing reads in facing plane.
	sword_pivot.rotation = dir.angle() + PI * 0.5
	sword_pivot.visible = true
	var start_r: float
	var mid_r: float
	var end_r: float
	match _facing:
		"up":
			start_r = 1.05
			mid_r = -1.0
			end_r = 0.35
		"side":
			start_r = -0.35
			mid_r = 1.25
			end_r = -0.2
		_:
			start_r = -0.95
			mid_r = 1.05
			end_r = -0.35
	sword_sprite.rotation = start_r
	_attack_sword_tween = create_tween()
	_attack_sword_tween.set_trans(Tween.TRANS_QUAD)
	_attack_sword_tween.set_ease(Tween.EASE_OUT)
	_attack_sword_tween.tween_property(sword_sprite, "rotation", mid_r, 0.11)
	_attack_sword_tween.set_ease(Tween.EASE_IN_OUT)
	_attack_sword_tween.tween_property(sword_sprite, "rotation", end_r, 0.13)
	_attack_sword_tween.tween_callback(
		func() -> void:
			if sword_pivot != null:
				sword_pivot.visible = false
	)


func _add_atlas_frame_to_sprite_frames(
	frames: SpriteFrames,
	animation_name: String,
	atlas: Texture2D,
	cell_idx: int,
	frame_duration: float = 1.0,
) -> void:
	var col := cell_idx % PLAYER_ATLAS_COLS
	var row: int = cell_idx / PLAYER_ATLAS_COLS
	var region := Rect2i(col * PLAYER_ATLAS_CELL, row * PLAYER_ATLAS_CELL, PLAYER_ATLAS_CELL, PLAYER_ATLAS_CELL)
	var slice := AtlasTexture.new()
	slice.atlas = atlas
	slice.region = region
	slice.filter_clip = true
	frames.add_frame(animation_name, slice, frame_duration)
