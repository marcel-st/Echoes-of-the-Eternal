extends Node
class_name WorldFlags

var _flags: Dictionary = {}


func get_flag(key: StringName, fallback: Variant = false) -> Variant:
	return _flags.get(String(key), fallback)


func set_flag(key: StringName, value: Variant) -> void:
	_flags[String(key)] = value
	EventBus.world_flag_changed.emit(String(key), value)


func export_flags() -> Dictionary:
	return _flags.duplicate(true)


func import_flags(flags: Dictionary) -> void:
	_flags = flags.duplicate(true)
