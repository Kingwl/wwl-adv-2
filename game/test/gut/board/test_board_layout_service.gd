extends GutTest


func test_desktop_layout_keeps_board_inside_play_area() -> void:
	var service := BoardLayoutService.new()
	var metrics := service.calculate(Vector2(1280, 720), 10, 8)

	assert_false(metrics.tower_deck_is_bottom)
	assert_false(metrics.compact_messages)
	assert_true(metrics.cell_size > 0.0)
	assert_true(metrics.get_board_rect().position.x >= BoardLayoutService.SCREEN_PADDING)
	assert_true(metrics.get_board_rect().position.y >= metrics.hud_reserved_height)
	assert_true(metrics.get_board_rect().end.x <= metrics.tower_deck_rect.position.x - BoardLayoutService.SIDE_PANEL_GAP)
	assert_eq(
		service.local_to_grid_position(
			service.grid_to_local_rect(Vector2i(2, 3), metrics.board_origin, metrics.cell_size).get_center(),
			metrics.board_origin,
			metrics.cell_size
		),
		Vector2i(2, 3)
	)


func test_compact_square_layout_moves_tower_deck_below_board() -> void:
	var service := BoardLayoutService.new()
	var metrics := service.calculate(Vector2(720, 720), 10, 8)

	assert_true(metrics.tower_deck_is_bottom)
	assert_true(metrics.compact_messages)
	assert_true(metrics.get_board_rect().position.y >= BoardLayoutService.HUD_COMPACT_MESSAGE_RESERVED_HEIGHT)
	assert_true(metrics.hint_label_rect.end.y <= metrics.get_board_rect().position.y)
	assert_true(metrics.get_board_rect().end.y <= metrics.single_tower_button_rect.position.y - BoardLayoutService.BOTTOM_TOWER_DECK_GAP)
	assert_eq(metrics.area_tower_button_rect.position.y, metrics.single_tower_button_rect.position.y)
	assert_eq(metrics.slow_tower_button_rect.position.y, metrics.single_tower_button_rect.position.y)
