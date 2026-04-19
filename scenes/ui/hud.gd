extends Control

const _InputPromptIcons := preload("res://core/ui/input_prompt_icons.gd")

@onready var prompt_label: Label = $MarginContainer/VBoxContainer/PromptLabel
@onready var hint_hbox: HBoxContainer = $MarginContainer/VBoxContainer/HintHBox
@onready var journal_panel: PanelContainer = $JournalPanel
var _last_prompt := ""
var _prompt_sound_cooldown := 0.0


func _ready() -> void:
	prompt_label.visible = false
	EventBus.request_ui_prompt.connect(_on_ui_prompt)
	if journal_panel:
		journal_panel.visible = false
	_build_control_hint_row()


func _process(delta: float) -> void:
	if _prompt_sound_cooldown > 0.0:
		_prompt_sound_cooldown = maxf(0.0, _prompt_sound_cooldown - delta)


func _on_ui_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text.strip_edges() != ""
	if text.strip_edges().is_empty():
		_last_prompt = text
		return
	if text == _last_prompt and _prompt_sound_cooldown > 0.0:
		return
	_last_prompt = text
	_prompt_sound_cooldown = 0.4
	AudioManager.play_ui("select")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if journal_panel and journal_panel.has_method("toggle_panel"):
			journal_panel.call("toggle_panel")
			get_viewport().set_input_as_handled()


func _build_control_hint_row() -> void:
	if hint_hbox == null:
		return
	for child in hint_hbox.get_children():
		child.queue_free()
	_add_hint_label("WASD / stick — ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_kb_e"))
	_add_hint_label(" / ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_pad_x"))
	_add_hint_label(" interact · ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_kb_j"))
	_add_hint_label(" / ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_pad_a"))
	_add_hint_label(" Attack · ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_kb_esc"))
	_add_hint_label(" / ")
	_add_hint_texture(_InputPromptIcons.get_texture("glyph_pad_start"))
	_add_hint_label(" Journal")


func _add_hint_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.custom_minimum_size = Vector2(32, 32)
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_hbox.add_child(tr)


func _add_hint_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.792157, 0.890196, 0.941176, 1))
	hint_hbox.add_child(label)
