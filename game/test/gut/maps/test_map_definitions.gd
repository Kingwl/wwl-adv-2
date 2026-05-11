extends GutTest


func test_level_definition_loads_and_applies_to_board() -> void:
	var level := LevelDefinition.load_from_path("res://data/levels/level_001.json")
	assert_not_null(level)
	assert_true(level.is_valid())
	assert_eq(level.grid_width, 10)
	assert_eq(level.grid_height, 8)
	assert_eq(level.style_id, "stormwind_city_v3")
	assert_eq(level.wave_set_id, "level_001_training_gate")

	var board := Board.new(level.grid_width, level.grid_height)
	level.apply_to_board(board)

	assert_eq(board.get_slot_type(Vector2i(0, 3)), BoardSlot.Type.PATH)
	assert_eq(board.get_slot_type(Vector2i(4, 4)), BoardSlot.Type.PATH)
	assert_eq(board.get_slot_type(Vector2i(0, 0)), BoardSlot.Type.BLOCKED)
	assert_eq(board.get_slot_type(Vector2i(1, 1)), BoardSlot.Type.BUILDABLE)
	assert_true(board.validate_path(level.path_cells).succeeded)


func test_mvp_levels_load_referenced_eight_wave_sets() -> void:
	var level_paths := [
		"res://data/levels/level_001.json",
		"res://data/levels/level_002.json",
		"res://data/levels/level_003.json",
		"res://data/levels/level_004.json",
		"res://data/levels/level_005.json",
	]
	var expected_styles := {
		"res://data/levels/level_001.json": "stormwind_city_v3",
		"res://data/levels/level_002.json": "long_road_v1",
		"res://data/levels/level_003.json": "kill_zone_v1",
		"res://data/levels/level_004.json": "armored_column_v1",
		"res://data/levels/level_005.json": "mvp_showcase_v1",
	}
	var expected_path_lengths := {
		"res://data/levels/level_001.json": 11,
		"res://data/levels/level_002.json": 16,
		"res://data/levels/level_003.json": 12,
		"res://data/levels/level_004.json": 12,
		"res://data/levels/level_005.json": 17,
	}
	var expected_blocked_counts := {
		"res://data/levels/level_001.json": 34,
		"res://data/levels/level_002.json": 45,
		"res://data/levels/level_003.json": 48,
		"res://data/levels/level_004.json": 44,
		"res://data/levels/level_005.json": 48,
	}
	var enemy_catalog := EnemyCatalog.new()

	for level_path in level_paths:
		var level := LevelDefinition.load_from_path(level_path)
		assert_not_null(level)
		assert_true(level.is_valid())
		assert_eq(level.style_id, expected_styles[level_path])
		assert_eq(level.path_cells.size(), expected_path_lengths[level_path])
		assert_eq(level.blocked_cells.size(), expected_blocked_counts[level_path])
		assert_eq(level.locked_cells.size(), 0)
		assert_eq(level.path_cells.front(), level.spawn_cell)
		assert_eq(level.path_cells.back(), level.exit_cell)

		var wave_definitions := WaveConfig.load_definitions_for_level(level, enemy_catalog)
		assert_eq(wave_definitions.size(), 8, "%s should reference an 8-wave MVP set." % level_path)
		assert_false(level.wave_set_id.is_empty())


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


func test_map_style_definition_supports_layered_slot_tiles() -> void:
	var style := MapStyleDefinition.from_dictionary({
		"id": "layered_test",
		"display_name": "Layered Test",
		"tile_size": 128,
		"background": "res://assets/tilesets/layered_test/background.png",
		"background_normal": "",
		"grid_layer": "res://assets/tilesets/layered_test/grid_layer.png",
		"lighting": {},
		"tiles": {
			"buildable": "res://assets/tilesets/layered_test/buildable.png",
			"path": "res://assets/tilesets/layered_test/path.png",
			"blocked": "res://assets/tilesets/layered_test/blocked.png",
			"locked": "res://assets/tilesets/layered_test/locked.png",
		},
	})

	assert_true(style.is_valid())
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.BUILDABLE), "res://assets/tilesets/layered_test/buildable.png")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.PATH), "res://assets/tilesets/layered_test/path.png")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.BLOCKED), "res://assets/tilesets/layered_test/blocked.png")
	assert_eq(style.get_slot_tile_path(BoardSlot.Type.LOCKED), "res://assets/tilesets/layered_test/locked.png")

	var tile_paths := style.get_all_tile_paths()
	assert_eq(tile_paths.size(), 6)
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/background.png"))
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/grid_layer.png"))
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/buildable.png"))
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/path.png"))
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/blocked.png"))
	assert_true(tile_paths.has("res://assets/tilesets/layered_test/locked.png"))


func test_mvp_generated_map_styles_load_baked_backgrounds_and_optional_grid_layers() -> void:
	var expected_backgrounds := {
		"long_road_v1": "res://assets/tilesets/long_road_v1/background_frame_clean.png",
		"kill_zone_v1": "res://assets/tilesets/kill_zone_v1/background_frame_clean.png",
		"armored_column_v1": "res://assets/tilesets/armored_column_v1/background_frame_clean.png",
		"mvp_showcase_v1": "res://assets/tilesets/mvp_showcase_v1/background_frame_clean.png",
	}
	var expected_grid_layers := {
		"long_road_v1": "res://assets/tilesets/long_road_v1/grid_layer_composed.png",
		"kill_zone_v1": "res://assets/tilesets/kill_zone_v1/grid_layer_composed.png",
		"armored_column_v1": "res://assets/tilesets/armored_column_v1/grid_layer_composed.png",
		"mvp_showcase_v1": "res://assets/tilesets/mvp_showcase_v1/grid_layer_composed.png",
	}

	for style_id in expected_backgrounds:
		var background_path: String = expected_backgrounds[style_id]
		var grid_layer_path: String = expected_grid_layers[style_id]
		var style := MapStyleDefinition.load_from_path("res://data/map_styles/%s.json" % style_id)
		assert_not_null(style)
		assert_true(style.is_valid())
		assert_eq(style.background_tile_path, background_path)
		assert_eq(style.background_normal_tile_path, "")
		assert_eq(style.grid_layer_path, grid_layer_path)
		assert_false(style.normal_light_enabled)
		assert_eq(style.get_slot_tile_path(BoardSlot.Type.BLOCKED), "")
		assert_eq(style.get_slot_tile_path(BoardSlot.Type.LOCKED), "")

		var tile_paths := style.get_all_tile_paths()
		assert_eq(tile_paths.size(), 1 if grid_layer_path.is_empty() else 2)
		assert_true(tile_paths.has(background_path))
		if not grid_layer_path.is_empty():
			assert_true(tile_paths.has(grid_layer_path))

		var renderer := BoardMapRenderer.new()
		renderer.load_style(style)
		assert_true(renderer.has_texture(background_path))
		if not grid_layer_path.is_empty():
			assert_true(renderer.has_texture(grid_layer_path))


func test_board_asset_catalog_loads_requested_level_definition() -> void:
	var catalog := BoardAssetCatalog.new()
	catalog.load_level_definition("res://data/levels/level_003.json")
	catalog.load_map_style_assets()

	assert_not_null(catalog.level_definition)
	assert_eq(catalog.level_definition.id, "level_003")
	assert_eq(catalog.level_definition.style_id, "kill_zone_v1")
	assert_not_null(catalog.map_style_definition)
	assert_eq(catalog.map_style_definition.id, "kill_zone_v1")
	assert_true(catalog.board_map_renderer.has_texture("res://assets/tilesets/kill_zone_v1/background_frame_clean.png"))
	assert_true(catalog.board_map_renderer.has_texture("res://assets/tilesets/kill_zone_v1/grid_layer_composed.png"))


func test_board_map_renderer_uses_plain_cell_rects_without_path_padding() -> void:
	var renderer := BoardMapRenderer.new()
	var origin := Vector2(10.0, 20.0)
	var cell_size := 64.0

	var rect := renderer.get_slot_draw_rect(Vector2i(2, 3), origin, cell_size)
	assert_almost_eq(rect.position.x, origin.x + 2.0 * cell_size, 0.00001)
	assert_almost_eq(rect.position.y, origin.y + 3.0 * cell_size, 0.00001)
	assert_almost_eq(rect.size.x, cell_size, 0.00001)
	assert_almost_eq(rect.size.y, cell_size, 0.00001)
