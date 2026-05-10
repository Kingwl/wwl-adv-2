class_name FrostRtsTheme
extends RefCounted

const INK := Color(0.045, 0.052, 0.062, 1.0)
const STONE := Color(0.105, 0.125, 0.145, 0.94)
const STONE_DARK := Color(0.045, 0.052, 0.064, 0.96)
const STONE_HOVER := Color(0.155, 0.185, 0.215, 0.98)
const STONE_PRESSED := Color(0.075, 0.098, 0.125, 1.0)
const FROST := Color(0.54, 0.80, 1.0, 1.0)
const FROST_DIM := Color(0.27, 0.43, 0.56, 1.0)
const GOLD := Color(1.0, 0.78, 0.34, 1.0)
const BLOOD := Color(0.95, 0.23, 0.20, 1.0)
const TEXT := Color(0.90, 0.95, 1.0, 1.0)
const TEXT_DIM := Color(0.62, 0.72, 0.82, 1.0)
const HUD_PANEL_FRAME := "res://assets/ui/frost_rts/frames/hud_panel_frame.png"
const BUTTON_FRAME := "res://assets/ui/frost_rts/frames/button_normal.png"
const BUTTON_PRESSED_FRAME := "res://assets/ui/frost_rts/frames/button_pressed.png"
const TOWER_CARD_FRAME := "res://assets/ui/frost_rts/frames/tower_card_normal.png"
const TOWER_CARD_SELECTED_FRAME := "res://assets/ui/frost_rts/frames/tower_card_selected.png"
const TOWER_CARD_DISABLED_FRAME := "res://assets/ui/frost_rts/frames/tower_card_disabled.png"
const MENU_PANEL_FRAME := "res://assets/ui/frost_rts/frames/menu_panel_frame.png"
const TITLE_FONT_PATH := "res://assets/fonts/wwl-title-noto-sans-sc-subset.ttf"

static var _title_font_cache: Font


static func apply_title_label(label: Label, font_size: int = 42) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04, 1.0))
	label.add_theme_constant_override("outline_size", 7)
	var title_font := _load_title_font()
	if title_font != null:
		label.add_theme_font_override("font", title_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


static func _load_title_font() -> Font:
	if _title_font_cache == null:
		_title_font_cache = load(TITLE_FONT_PATH) as Font
	return _title_font_cache


static func apply_body_label(label: Label, font_size: int = 16, color: Color = TEXT) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.015, 0.025, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", font_size)


static func apply_stat_label(label: Label) -> void:
	apply_body_label(label, 17, Color(0.96, 0.98, 1.0, 1.0))


static func apply_button(button: Button, font_size: int = 15) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", texture_style(BUTTON_FRAME, 42, 14, 42, 14, 15, 5, 15, 5))
	button.add_theme_stylebox_override("hover", texture_style(BUTTON_FRAME, 42, 14, 42, 14, 15, 5, 15, 5))
	button.add_theme_stylebox_override("pressed", texture_style(BUTTON_PRESSED_FRAME, 42, 14, 42, 14, 15, 5, 15, 5))
	button.add_theme_stylebox_override("disabled", texture_style(BUTTON_FRAME, 42, 14, 42, 14, 15, 5, 15, 5))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.50, 0.56, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.02, 1.0))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_NONE


static func apply_tower_button(button: Button) -> void:
	apply_button(button, 11)
	if button == null:
		return

	button.add_theme_stylebox_override("normal", texture_style(TOWER_CARD_FRAME, 46, 32, 46, 32, 10, 8, 10, 8))
	button.add_theme_stylebox_override("hover", texture_style(TOWER_CARD_FRAME, 46, 32, 46, 32, 10, 8, 10, 8))
	button.add_theme_stylebox_override("pressed", texture_style(TOWER_CARD_SELECTED_FRAME, 46, 32, 46, 32, 10, 8, 10, 8))
	button.add_theme_stylebox_override("disabled", texture_style(TOWER_CARD_DISABLED_FRAME, 46, 32, 46, 32, 10, 8, 10, 8))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 38)
	button.add_theme_constant_override("h_separation", 6)
	button.add_theme_constant_override("outline_size", 1)


static func apply_panel(panel: Panel) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", texture_style(HUD_PANEL_FRAME, 58, 22, 58, 22, 14, 8, 14, 8))


static func apply_hud_panel(panel: Panel) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", texture_style(HUD_PANEL_FRAME, 58, 22, 58, 22, 14, 8, 14, 8))


static func apply_overlay_panel(panel: Panel) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", texture_style(MENU_PANEL_FRAME, 48, 48, 48, 48, 26, 20, 26, 20))


static func apply_backdrop(rect: ColorRect, alpha: float = 0.88) -> void:
	if rect == null:
		return

	rect.color = Color(0.018, 0.025, 0.034, alpha)


static func button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


static func texture_style(
	resource_path: String,
	margin_left: float,
	margin_top: float,
	margin_right: float,
	margin_bottom: float,
	content_left: float,
	content_top: float,
	content_right: float,
	content_bottom: float
) -> StyleBox:
	var texture := load(resource_path) as Texture2D
	if texture == null:
		return button_style(STONE, FROST_DIM)

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, margin_left)
	style.set_texture_margin(SIDE_TOP, margin_top)
	style.set_texture_margin(SIDE_RIGHT, margin_right)
	style.set_texture_margin(SIDE_BOTTOM, margin_bottom)
	style.content_margin_left = content_left
	style.content_margin_top = content_top
	style.content_margin_right = content_right
	style.content_margin_bottom = content_bottom
	return style


static func panel_style(fill: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style
