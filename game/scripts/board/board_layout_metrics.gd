class_name BoardLayoutMetrics
extends RefCounted

var viewport_size := Vector2.ZERO
var board_width := 0
var board_height := 0
var cell_size := 1.0
var board_origin := Vector2.ZERO
var tower_deck_is_bottom := false
var compact_messages := false
var hud_reserved_height := 0.0
var hud_frame_rect := Rect2()
var tower_deck_rect := Rect2()
var gold_icon_rect := Rect2()
var gold_label_rect := Rect2()
var lives_icon_rect := Rect2()
var lives_label_rect := Rect2()
var wave_icon_rect := Rect2()
var wave_label_rect := Rect2()
var menu_button_rect := Rect2()
var single_tower_button_rect := Rect2()
var area_tower_button_rect := Rect2()
var slow_tower_button_rect := Rect2()
var flame_tower_button_rect := Rect2()
var status_label_rect := Rect2()
var hint_label_rect := Rect2()
var overlay_root_rect := Rect2()
var overlay_backdrop_rect := Rect2()
var overlay_panel_rect := Rect2()
var overlay_title_rect := Rect2()
var overlay_message_rect := Rect2()
var overlay_primary_button_rect := Rect2()
var overlay_secondary_button_rect := Rect2()


func get_board_rect() -> Rect2:
	return Rect2(board_origin, Vector2(float(board_width) * cell_size, float(board_height) * cell_size))
