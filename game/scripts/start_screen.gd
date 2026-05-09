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


func _ready() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_start_button = get_node_or_null(start_button_path) as Button
	_backdrop = get_node_or_null(backdrop_path) as ColorRect
	_frame_panel = _ensure_frame_panel()
	_crest_icon = _ensure_crest_icon()

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
	_layout(get_viewport_rect().size)
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_layout(get_viewport_rect().size)


func _layout(viewport_size: Vector2) -> void:
	var frame_width := minf(620.0, viewport_size.x - SCREEN_PADDING * 2.0)
	var frame_height := minf(280.0, viewport_size.y - SCREEN_PADDING * 2.0)
	var frame_left := floorf((viewport_size.x - frame_width) * 0.5)
	var frame_top := floorf(maxf(SCREEN_PADDING, viewport_size.y * 0.28))
	_set_control_rect(_frame_panel, Rect2(frame_left, frame_top, frame_width, frame_height))

	var crest_size := minf(116.0, frame_height * 0.42)
	_set_control_rect(
		_crest_icon,
		Rect2(
			floorf((viewport_size.x - crest_size) * 0.5),
			frame_top - crest_size * 0.45,
			crest_size,
			crest_size
		)
	)

	var title_width := maxf(1.0, frame_width - 48.0)
	var title_height := 64.0
	var title_top := frame_top + 58.0
	_set_control_rect(_title_label, Rect2(frame_left + 24.0, title_top, title_width, title_height))

	var button_width := 210.0
	var button_height := 46.0
	var button_left := floorf((viewport_size.x - button_width) * 0.5)
	var button_top := title_top + title_height + 46.0
	_set_control_rect(_start_button, Rect2(button_left, button_top, button_width, button_height))


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


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
