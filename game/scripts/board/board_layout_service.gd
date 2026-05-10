class_name BoardLayoutService
extends RefCounted

const DEFAULT_BOARD_WIDTH := 10
const DEFAULT_BOARD_HEIGHT := 8
const DEFAULT_CELL_SIZE := 128.0
const DEFAULT_BOARD_ORIGIN := Vector2(96, 96)
const SCREEN_PADDING := 16.0
const HUD_RESERVED_HEIGHT := 68.0
const HUD_COMPACT_MESSAGE_RESERVED_HEIGHT := 104.0
const HUD_COMPACT_MESSAGE_MAX_HEIGHT := 820.0
const SIDE_PANEL_GAP := 12.0
const HUD_STAT_ROW_TOP := 18.0
const HUD_MESSAGE_ROW_TOP := 10.0
const HUD_ROW_HEIGHT := 32.0
const HUD_ROW_GAP := 10.0
const HUD_MESSAGE_ROW_HEIGHT := 24.0
const HUD_MESSAGE_ROW_GAP := 2.0
const HUD_INLINE_MESSAGE_MIN_WIDTH := 420.0
const TOWER_CARD_WIDTH := 184.0
const TOWER_CARD_HEIGHT := 68.0
const TOWER_CARD_MIN_HEIGHT := 50.0
const TOWER_CARD_GAP := 8.0
const DEFAULT_TOWER_CARD_COUNT := 4
const STAT_ICON_SIZE := 30.0
const HUD_CHROME_MARGIN := 8.0
const BOTTOM_TOWER_DECK_ASPECT_THRESHOLD := 1.45
const BOTTOM_TOWER_DECK_GAP := 12.0


func calculate(
	viewport_size: Vector2,
	board_width: int,
	board_height: int,
	tower_card_count: int = DEFAULT_TOWER_CARD_COUNT
) -> BoardLayoutMetrics:
	var metrics := BoardLayoutMetrics.new()
	metrics.viewport_size = viewport_size
	metrics.board_width = board_width
	metrics.board_height = board_height
	metrics.tower_deck_is_bottom = should_use_bottom_tower_deck(viewport_size)
	metrics.tower_card_count = maxi(1, tower_card_count)
	metrics.tower_card_height = _tower_card_height(viewport_size, metrics.tower_card_count, metrics.tower_deck_is_bottom)
	metrics.hud_reserved_height = hud_reserved_height(viewport_size)

	var tower_reserved_width := 0.0
	var tower_reserved_height := 0.0
	if metrics.tower_deck_is_bottom:
		tower_reserved_height = _bottom_tower_deck_content_size(viewport_size, metrics.tower_card_count, metrics.tower_card_height).y + HUD_CHROME_MARGIN * 2.0 + BOTTOM_TOWER_DECK_GAP
	else:
		tower_reserved_width = TOWER_CARD_WIDTH + SIDE_PANEL_GAP

	var available_width := maxf(
		1.0,
		viewport_size.x - SCREEN_PADDING * 2.0 - tower_reserved_width
	)
	var available_height := maxf(
		1.0,
		viewport_size.y - metrics.hud_reserved_height - SCREEN_PADDING - tower_reserved_height
	)
	metrics.cell_size = maxf(1.0, floorf(minf(
		available_width / float(board_width),
		available_height / float(board_height)
	)))
	var board_size := Vector2(float(board_width) * metrics.cell_size, float(board_height) * metrics.cell_size)
	metrics.board_origin = Vector2(
		floorf(SCREEN_PADDING + maxf(0.0, (available_width - board_size.x) * 0.5)),
		floorf(metrics.hud_reserved_height + maxf(0.0, (available_height - board_size.y) * 0.5))
	)

	_calculate_hud(metrics)
	_calculate_overlay(metrics)
	return metrics


func should_use_bottom_tower_deck(viewport_size: Vector2) -> bool:
	if viewport_size.y <= 0.0:
		return false

	return viewport_size.x / viewport_size.y < BOTTOM_TOWER_DECK_ASPECT_THRESHOLD


func hud_reserved_height(viewport_size: Vector2) -> float:
	if should_use_bottom_tower_deck(viewport_size) and viewport_size.y <= HUD_COMPACT_MESSAGE_MAX_HEIGHT:
		return HUD_COMPACT_MESSAGE_RESERVED_HEIGHT
	return HUD_RESERVED_HEIGHT


func local_to_grid_position(local_position: Vector2, board_origin: Vector2, cell_size: float) -> Vector2i:
	var offset := local_position - board_origin
	return Vector2i(floori(offset.x / cell_size), floori(offset.y / cell_size))


func grid_to_local_rect(grid_position: Vector2i, board_origin: Vector2, cell_size: float) -> Rect2:
	return Rect2(
		board_origin + Vector2(float(grid_position.x) * cell_size, float(grid_position.y) * cell_size),
		Vector2(cell_size, cell_size)
	)


func _calculate_hud(metrics: BoardLayoutMetrics) -> void:
	var viewport_size := metrics.viewport_size
	var stat_top := HUD_STAT_ROW_TOP
	var message_top := HUD_MESSAGE_ROW_TOP
	var left := SCREEN_PADDING
	var gap := HUD_ROW_GAP
	var menu_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
	var content_right := menu_left - SIDE_PANEL_GAP
	var stat_width := minf(124.0, maxf(104.0, (content_right - left) / 5.4))

	metrics.hud_frame_rect = Rect2(
		HUD_CHROME_MARGIN,
		HUD_CHROME_MARGIN,
		maxf(1.0, viewport_size.x - HUD_CHROME_MARGIN * 2.0),
		metrics.hud_reserved_height - HUD_CHROME_MARGIN
	)

	metrics.gold_icon_rect = _stat_icon_rect(Vector2(left, stat_top))
	metrics.gold_label_rect = _stat_label_rect(Vector2(left, stat_top), stat_width)
	metrics.lives_icon_rect = _stat_icon_rect(Vector2(left + stat_width + gap, stat_top))
	metrics.lives_label_rect = _stat_label_rect(Vector2(left + stat_width + gap, stat_top), stat_width)
	metrics.wave_icon_rect = _stat_icon_rect(Vector2(left + (stat_width + gap) * 2.0, stat_top))
	metrics.wave_label_rect = _stat_label_rect(Vector2(left + (stat_width + gap) * 2.0, stat_top), stat_width + 22.0)
	metrics.menu_button_rect = Rect2(menu_left, stat_top, TOWER_CARD_WIDTH, HUD_ROW_HEIGHT)

	_calculate_tower_deck(metrics)

	var message_left := left + (stat_width + gap) * 3.0 + gap
	var message_width := content_right - message_left
	metrics.compact_messages = message_width < HUD_INLINE_MESSAGE_MIN_WIDTH
	if message_width >= HUD_INLINE_MESSAGE_MIN_WIDTH:
		metrics.status_label_rect = Rect2(message_left, message_top, message_width, HUD_MESSAGE_ROW_HEIGHT)
		metrics.hint_label_rect = Rect2(message_left, message_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, message_width, HUD_MESSAGE_ROW_HEIGHT)
	elif metrics.tower_deck_is_bottom:
		var compact_message_width := viewport_size.x - SCREEN_PADDING * 2.0
		var compact_status_top := message_top + HUD_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP
		metrics.status_label_rect = Rect2(left, compact_status_top, compact_message_width, HUD_MESSAGE_ROW_HEIGHT)
		metrics.hint_label_rect = Rect2(left, compact_status_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, compact_message_width, HUD_MESSAGE_ROW_HEIGHT)
	else:
		var side_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
		var tower_buttons_bottom := HUD_RESERVED_HEIGHT + metrics.tower_card_height * metrics.tower_card_count + TOWER_CARD_GAP * (metrics.tower_card_count - 1)
		var side_message_height := HUD_MESSAGE_ROW_HEIGHT * 2.0 + HUD_MESSAGE_ROW_GAP
		var side_messages_fit_below := tower_buttons_bottom + HUD_CHROME_MARGIN + 4.0 + side_message_height <= viewport_size.y - SCREEN_PADDING
		if not side_messages_fit_below:
			metrics.status_label_rect = Rect2(message_left, message_top, message_width, HUD_MESSAGE_ROW_HEIGHT)
			metrics.hint_label_rect = Rect2(message_left, message_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, message_width, HUD_MESSAGE_ROW_HEIGHT)
			return

		var side_message_top := minf(
			tower_buttons_bottom + HUD_CHROME_MARGIN + 4.0,
			viewport_size.y - SCREEN_PADDING - side_message_height
		)
		metrics.status_label_rect = Rect2(side_left, side_message_top, TOWER_CARD_WIDTH, HUD_MESSAGE_ROW_HEIGHT)
		metrics.hint_label_rect = Rect2(side_left, side_message_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, TOWER_CARD_WIDTH, HUD_MESSAGE_ROW_HEIGHT)


func _calculate_tower_deck(metrics: BoardLayoutMetrics) -> void:
	var viewport_size := metrics.viewport_size
	if metrics.tower_deck_is_bottom:
		var columns := _bottom_tower_deck_columns(viewport_size, metrics.tower_card_count)
		var content_size := _bottom_tower_deck_content_size(viewport_size, metrics.tower_card_count, metrics.tower_card_height)
		var deck_left := floorf((viewport_size.x - content_size.x) * 0.5)
		var deck_top := viewport_size.y - SCREEN_PADDING - content_size.y
		metrics.tower_deck_rect = Rect2(
			deck_left - HUD_CHROME_MARGIN,
			deck_top - HUD_CHROME_MARGIN,
			content_size.x + HUD_CHROME_MARGIN * 2.0,
			content_size.y + HUD_CHROME_MARGIN * 2.0
		)
		for index in range(metrics.tower_card_count):
			metrics.tower_button_rects.append(_bottom_tower_button_rect(deck_left, deck_top, columns, index, metrics.tower_card_height))
		_assign_legacy_tower_button_rects(metrics)
		return

	var panel_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
	var tower_top := metrics.hud_reserved_height
	var content_height := metrics.tower_card_height * metrics.tower_card_count + TOWER_CARD_GAP * (metrics.tower_card_count - 1)
	metrics.tower_deck_rect = Rect2(
		panel_left - HUD_CHROME_MARGIN,
		tower_top - HUD_CHROME_MARGIN,
		TOWER_CARD_WIDTH + HUD_CHROME_MARGIN * 2.0,
		content_height + HUD_CHROME_MARGIN * 2.0
	)
	for index in range(metrics.tower_card_count):
		metrics.tower_button_rects.append(Rect2(
			panel_left,
			tower_top + (metrics.tower_card_height + TOWER_CARD_GAP) * float(index),
			TOWER_CARD_WIDTH,
			metrics.tower_card_height
		))
	_assign_legacy_tower_button_rects(metrics)


func _bottom_tower_deck_columns(viewport_size: Vector2, tower_card_count: int) -> int:
	var available_width := viewport_size.x - SCREEN_PADDING * 2.0
	var max_columns := maxi(1, floori((available_width + TOWER_CARD_GAP) / (TOWER_CARD_WIDTH + TOWER_CARD_GAP)))
	return clampi(mini(tower_card_count, max_columns), 1, tower_card_count)


func _bottom_tower_deck_content_size(viewport_size: Vector2, tower_card_count: int, tower_card_height: float) -> Vector2:
	var columns := _bottom_tower_deck_columns(viewport_size, tower_card_count)
	var rows := ceili(float(tower_card_count) / float(columns))
	return Vector2(
		TOWER_CARD_WIDTH * columns + TOWER_CARD_GAP * (columns - 1),
		tower_card_height * rows + TOWER_CARD_GAP * (rows - 1)
	)


func _bottom_tower_button_rect(deck_left: float, deck_top: float, columns: int, index: int, tower_card_height: float) -> Rect2:
	var column := index % columns
	var row := floori(float(index) / float(columns))
	return Rect2(
		deck_left + float(column) * (TOWER_CARD_WIDTH + TOWER_CARD_GAP),
		deck_top + float(row) * (tower_card_height + TOWER_CARD_GAP),
		TOWER_CARD_WIDTH,
		tower_card_height
	)


func _tower_card_height(viewport_size: Vector2, tower_card_count: int, tower_deck_is_bottom: bool) -> float:
	if tower_deck_is_bottom:
		return TOWER_CARD_HEIGHT

	var available_height := viewport_size.y - HUD_RESERVED_HEIGHT - SCREEN_PADDING - HUD_CHROME_MARGIN * 2.0
	var gap_height := TOWER_CARD_GAP * maxi(0, tower_card_count - 1)
	var fit_height := floorf((available_height - gap_height) / float(maxi(1, tower_card_count)))
	return clampf(fit_height, TOWER_CARD_MIN_HEIGHT, TOWER_CARD_HEIGHT)


func _assign_legacy_tower_button_rects(metrics: BoardLayoutMetrics) -> void:
	metrics.single_tower_button_rect = metrics.tower_button_rects[0] if metrics.tower_button_rects.size() > 0 else Rect2()
	metrics.area_tower_button_rect = metrics.tower_button_rects[1] if metrics.tower_button_rects.size() > 1 else Rect2()
	metrics.slow_tower_button_rect = metrics.tower_button_rects[2] if metrics.tower_button_rects.size() > 2 else Rect2()
	metrics.flame_tower_button_rect = metrics.tower_button_rects[3] if metrics.tower_button_rects.size() > 3 else Rect2()
	metrics.poison_tower_button_rect = metrics.tower_button_rects[4] if metrics.tower_button_rects.size() > 4 else Rect2()


func _calculate_overlay(metrics: BoardLayoutMetrics) -> void:
	var viewport_size := metrics.viewport_size
	metrics.overlay_root_rect = Rect2(Vector2.ZERO, viewport_size)
	metrics.overlay_backdrop_rect = Rect2(Vector2.ZERO, viewport_size)

	var panel_width := minf(500.0, viewport_size.x - SCREEN_PADDING * 2.0)
	var panel_height := minf(244.0, viewport_size.y - SCREEN_PADDING * 2.0)
	var panel_position := Vector2(
		floorf((viewport_size.x - panel_width) * 0.5),
		floorf((viewport_size.y - panel_height) * 0.5)
	)
	metrics.overlay_panel_rect = Rect2(panel_position, Vector2(panel_width, panel_height))

	var inner_left := 28.0
	var inner_width := panel_width - inner_left * 2.0
	metrics.overlay_title_rect = Rect2(inner_left, 26.0, inner_width, 38.0)
	metrics.overlay_message_rect = Rect2(inner_left, 76.0, inner_width, 64.0)

	var button_width := minf(150.0, inner_width)
	var button_height := 36.0
	var button_gap := 12.0
	var total_button_width := button_width * 2.0 + button_gap
	var button_left := floorf((panel_width - total_button_width) * 0.5)
	var button_top := panel_height - 62.0
	metrics.overlay_primary_button_rect = Rect2(button_left, button_top, button_width, button_height)
	metrics.overlay_secondary_button_rect = Rect2(button_left + button_width + button_gap, button_top, button_width, button_height)


func _stat_icon_rect(stat_position: Vector2) -> Rect2:
	var icon_top := stat_position.y + floorf((HUD_ROW_HEIGHT - STAT_ICON_SIZE) * 0.5)
	return Rect2(stat_position.x, icon_top, STAT_ICON_SIZE, STAT_ICON_SIZE)


func _stat_label_rect(stat_position: Vector2, width: float) -> Rect2:
	return Rect2(stat_position.x + STAT_ICON_SIZE + 6.0, stat_position.y, width - STAT_ICON_SIZE - 6.0, HUD_ROW_HEIGHT)
