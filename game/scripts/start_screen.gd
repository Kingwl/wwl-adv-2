class_name StartScreen
extends Control

const GAME_SCENE_PATH := "res://scenes/main.tscn"
const SCREEN_PADDING := 24.0
const CREST_ICON_PATH := "res://assets/ui/frost_rts/wave_icon.png"

@export var title_label_path: NodePath = NodePath("Title")
@export var start_button_path: NodePath = NodePath("StartButton")
@export var backdrop_path: NodePath = NodePath("Backdrop")

var _title_label: Label
var _start_button: Button
var _backdrop: ColorRect
var _frame_panel: Panel
var _crest_icon: TextureRect
var _level_select_panel: VBoxContainer
var _level_prompt_label: Label
var _level_buttons: Array = []
var _level_back_button: Button
var _showing_level_select := false


func _ready() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_start_button = get_node_or_null(start_button_path) as Button
	_backdrop = get_node_or_null(backdrop_path) as ColorRect
	_frame_panel = _ensure_frame_panel()
	_crest_icon = _ensure_crest_icon()
	_level_select_panel = _ensure_level_select_panel()

	if _title_label != null:
		_title_label.text = "WWL 大冒险 2"
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_title_label(_title_label, 46)

	if _start_button != null:
		_start_button.text = "Start"
		_start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_button(_start_button, 17)
		if not _start_button.pressed.is_connected(_on_start_button_pressed):
			_start_button.pressed.connect(_on_start_button_pressed)

	FrostRtsTheme.apply_backdrop(_backdrop, 1.0)
	FrostRtsTheme.apply_overlay_panel(_frame_panel)
	if _should_start_in_level_select():
		show_level_select()
	else:
		show_start_prompt()
	_layout(get_viewport_rect().size)
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_layout(get_viewport_rect().size)


func _layout(viewport_size: Vector2) -> void:
	var frame_width_limit := 720.0 if _showing_level_select else 620.0
	var frame_height_limit := 500.0 if _showing_level_select else 280.0
	var frame_width := minf(frame_width_limit, viewport_size.x - SCREEN_PADDING * 2.0)
	var frame_height := minf(frame_height_limit, viewport_size.y - SCREEN_PADDING * 2.0)
	var frame_left := floorf((viewport_size.x - frame_width) * 0.5)
	var frame_top := floorf(maxf(SCREEN_PADDING, viewport_size.y * 0.28))
	if _showing_level_select:
		frame_top = floorf(maxf(SCREEN_PADDING, (viewport_size.y - frame_height) * 0.5 + 10.0))
	_set_control_rect(_frame_panel, Rect2(frame_left, frame_top, frame_width, frame_height))

	var crest_size := minf(116.0, frame_height * (0.18 if _showing_level_select else 0.42))
	_set_control_rect(
		_crest_icon,
		Rect2(
			floorf((viewport_size.x - crest_size) * 0.5),
			maxf(4.0, frame_top - crest_size * (0.52 if _showing_level_select else 0.45)),
			crest_size,
			crest_size
		)
	)

	var title_width := maxf(1.0, frame_width - 48.0)
	var title_height := 52.0 if _showing_level_select else 64.0
	var title_top := frame_top + (38.0 if _showing_level_select else 58.0)
	if _title_label != null:
		FrostRtsTheme.apply_title_label(_title_label, 40 if _showing_level_select else 46)
	_set_control_rect(_title_label, Rect2(frame_left + 24.0, title_top, title_width, title_height))

	var button_width := 210.0
	var button_height := 46.0
	var button_left := floorf((viewport_size.x - button_width) * 0.5)
	var button_top := title_top + title_height + 46.0
	_set_control_rect(_start_button, Rect2(button_left, button_top, button_width, button_height))

	var panel_left := frame_left + maxf(20.0, frame_width * 0.08)
	var panel_top := title_top + title_height + 14.0
	var panel_width := frame_width - (panel_left - frame_left) * 2.0
	var panel_height := maxf(1.0, frame_top + frame_height - panel_top - 22.0)
	_set_control_rect(_level_select_panel, Rect2(panel_left, panel_top, panel_width, panel_height))
	_sync_level_select_compact_style(frame_height < 420.0)


func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return

	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _ensure_frame_panel() -> Panel:
	var panel := get_node_or_null("MenuFrame") as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = "MenuFrame"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		move_child(panel, 1)

	return panel


func _ensure_crest_icon() -> TextureRect:
	var icon := get_node_or_null("CrestIcon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "CrestIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon)

	icon.texture = load(CREST_ICON_PATH) as Texture2D
	return icon


func _ensure_level_select_panel() -> VBoxContainer:
	var panel := get_node_or_null("LevelSelectPanel") as VBoxContainer
	if panel == null:
		panel = VBoxContainer.new()
		panel.name = "LevelSelectPanel"
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(panel)

	panel.add_theme_constant_override("separation", 6)
	_level_prompt_label = panel.get_node_or_null("LevelPrompt") as Label
	if _level_prompt_label == null:
		_level_prompt_label = Label.new()
		_level_prompt_label.name = "LevelPrompt"
		_level_prompt_label.text = "Select Level"
		_level_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_level_prompt_label.clip_text = true
		panel.add_child(_level_prompt_label)
	FrostRtsTheme.apply_body_label(_level_prompt_label, 16, FrostRtsTheme.TEXT)

	_level_buttons = []
	for summary in LevelCatalog.get_level_summaries():
		var level_index := int(summary["index"])
		var button_name := "LevelButton%d" % (level_index + 1)
		var button := panel.get_node_or_null(button_name) as Button
		if button == null:
			button = Button.new()
			button.name = button_name
			panel.add_child(button)

		var level_path := String(summary["path"])
		button.text = "%d. %s" % [level_index + 1, String(summary["display_name"])]
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		FrostRtsTheme.apply_button(button, 15)
		if not button.pressed.is_connected(_on_level_button_pressed.bind(level_path)):
			button.pressed.connect(_on_level_button_pressed.bind(level_path))
		_level_buttons.append(button)

	_level_back_button = panel.get_node_or_null("LevelBackButton") as Button
	if _level_back_button == null:
		_level_back_button = Button.new()
		_level_back_button.name = "LevelBackButton"
		panel.add_child(_level_back_button)
	_level_back_button.text = "Back"
	_level_back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_back_button.clip_text = true
	_level_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_back_button.focus_mode = Control.FOCUS_NONE
	FrostRtsTheme.apply_button(_level_back_button, 14)
	if not _level_back_button.pressed.is_connected(_on_level_back_button_pressed):
		_level_back_button.pressed.connect(_on_level_back_button_pressed)

	return panel


func _sync_level_select_compact_style(compact: bool) -> void:
	if _level_prompt_label != null:
		_level_prompt_label.custom_minimum_size = Vector2(0.0, 22.0 if compact else 28.0)
		FrostRtsTheme.apply_body_label(_level_prompt_label, 14 if compact else 16, FrostRtsTheme.TEXT)

	for button in _level_buttons:
		if button == null:
			continue
		button.custom_minimum_size = Vector2(0.0, 31.0 if compact else 39.0)
		FrostRtsTheme.apply_button(button, 13 if compact else 15)

	if _level_back_button != null:
		_level_back_button.custom_minimum_size = Vector2(0.0, 30.0 if compact else 36.0)
		FrostRtsTheme.apply_button(_level_back_button, 12 if compact else 14)


func show_start_prompt() -> void:
	_showing_level_select = false
	if _start_button != null:
		_start_button.visible = true
	if _level_select_panel != null:
		_level_select_panel.visible = false


func show_level_select() -> void:
	_showing_level_select = true
	if _start_button != null:
		_start_button.visible = false
	if _level_select_panel != null:
		_level_select_panel.visible = true


func is_showing_level_select() -> bool:
	return _showing_level_select


func get_level_buttons() -> Array:
	return _level_buttons.duplicate()


func _on_start_button_pressed() -> void:
	show_level_select()
	_layout(get_viewport_rect().size)


func _on_level_button_pressed(level_path: String) -> void:
	get_tree().set_meta(LevelCatalog.SELECTED_LEVEL_META_KEY, level_path)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_level_back_button_pressed() -> void:
	show_start_prompt()
	_layout(get_viewport_rect().size)


func _should_start_in_level_select() -> bool:
	var tree := get_tree()
	if tree == null or not tree.has_meta(LevelCatalog.START_IN_LEVEL_SELECT_META_KEY):
		return false

	var should_show := bool(tree.get_meta(LevelCatalog.START_IN_LEVEL_SELECT_META_KEY))
	tree.remove_meta(LevelCatalog.START_IN_LEVEL_SELECT_META_KEY)
	return should_show
