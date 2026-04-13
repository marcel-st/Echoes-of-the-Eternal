extends Node

const DEFAULT_INPUTS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"attack": [KEY_J],
	"interact": [KEY_E],
	"dodge": [KEY_SPACE],
	"pause": [KEY_ESCAPE],
	"confirm": [KEY_ENTER, KEY_SPACE],
	"cancel": [KEY_BACKSPACE]
}

const GAMEPAD_DEFAULTS := {
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"attack": [JOY_BUTTON_A],
	"interact": [JOY_BUTTON_X],
	"dodge": [JOY_BUTTON_B],
	"pause": [JOY_BUTTON_START],
	"confirm": [JOY_BUTTON_A],
	"cancel": [JOY_BUTTON_B]
}


func _ready() -> void:
	_register_default_actions()


func _register_default_actions() -> void:
	for action in DEFAULT_INPUTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)

		for keycode in DEFAULT_INPUTS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			_add_event_if_missing(action, key_event)

	for action in GAMEPAD_DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)

		for button in GAMEPAD_DEFAULTS[action]:
			var joypad_event := InputEventJoypadButton.new()
			joypad_event.button_index = button
			_add_event_if_missing(action, joypad_event)


func _add_event_if_missing(action: StringName, input_event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == input_event.as_text():
			return
	InputMap.action_add_event(action, input_event)
