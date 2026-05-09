extends GutTest


func test_level_definition_loads_and_applies_to_board() -> void:
	var level := LevelDefinition.load_from_path("res://data/levels/level_001.json")
	assert_not_null(level)
	assert_true(level.is_valid())
	assert_eq(level.grid_width, 10)
	assert_eq(level.grid_height, 8)
	assert_eq(level.style_id, "stormwind_city_v3")

	var board := Board.new(level.grid_width, level.grid_height)
	level.apply_to_board(board)

	assert_eq(board.get_slot_type(Vector2i(0, 3)), BoardSlot.Type.PATH)
	assert_eq(board.get_slot_type(Vector2i(4, 4)), BoardSlot.Type.PATH)
	assert_eq(board.get_slot_type(Vector2i(0, 0)), BoardSlot.Type.BUILDABLE)
	assert_true(board.validate_path(level.path_cells).succeeded)


func test_stormwind_city_v3_uses_baked_background_without_overlay_tiles() -> void:
	var style := MapStyleDefinition.load_from_path("res://data/map_styles/stormwind_city_v3.json")
	assert_not_null(style)
	assert_true(style.is_valid())
	assert_eq(
		style.background_tile_path,
		"res://assets/tilesets/stormwind_city_v3/background_frame.png"
	)
	assert_eq(
		style.background_normal_tile_path,
		"res://assets/tilesets/stormwind_city_v3/background_frame_normal.png"
	)
	assert_true(style.normal_light_enabled)
	assert_almost_eq(style.normal_light_energy, 0.28, 0.00001)
	assert_almost_eq(style.normal_light_height, 0.38, 0.00001)
	assert_almost_eq(style.normal_light_rotation_degrees, -42.0, 0.00001)
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.BUILDABLE), "")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.PATH), "")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.BLOCKED), "")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.LOCKED), "")

	var tile_paths := style.get_all_tile_paths()
	assert_eq(tile_paths.size(), 2)
	assert_true(tile_paths.has("res://assets/tilesets/stormwind_city_v3/background_frame.png"))
	assert_true(tile_paths.has("res://assets/tilesets/stormwind_city_v3/background_frame_normal.png"))


func test_board_map_renderer_loads_stormwind_city_v3_background_textures() -> void:
	var style := MapStyleDefinition.load_from_path("res://data/map_styles/stormwind_city_v3.json")
	var renderer := BoardMapRenderer.new()
	renderer.load_style(style)

	assert_true(renderer.has_texture("res://assets/tilesets/stormwind_city_v3/background_frame.png"))
	assert_true(renderer.has_texture("res://assets/tilesets/stormwind_city_v3/background_frame_normal.png"))


func test_board_map_renderer_uses_plain_cell_rects_without_path_padding() -> void:
	var renderer := BoardMapRenderer.new()
	var origin := Vector2(10.0, 20.0)
	var cell_size := 64.0

	var rect := renderer.get_slot_draw_rect(Vector2i(2, 3), origin, cell_size)
	assert_almost_eq(rect.position.x, origin.x + 2.0 * cell_size, 0.00001)
	assert_almost_eq(rect.position.y, origin.y + 3.0 * cell_size, 0.00001)
	assert_almost_eq(rect.size.x, cell_size, 0.00001)
	assert_almost_eq(rect.size.y, cell_size, 0.00001)
