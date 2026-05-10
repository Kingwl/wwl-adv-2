extends GutTest


func test_project_entry_scene_is_start_scene() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/start.tscn")


func test_start_scene_loads_title_and_start_button() -> void:
	var packed_scene: PackedScene = load("res://scenes/start.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var title: Label = scene.get_node("Title") as Label
	var start_button: Button = scene.get_node("StartButton") as Button

	assert_not_null(scene as StartScreen)
	assert_eq(title.text, "WWL 大冒险 2")
	assert_not_null(title.get_theme_font("font"))
	assert_true(title.get_theme_font("font").has_char("大".unicode_at(0)))
	assert_eq(title.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(title.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(start_button.text, "Start")
	assert_eq(start_button.alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_true(start_button.get_theme_stylebox("normal") is StyleBoxTexture)


func test_main_scene_loads_board_view_and_hud() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	assert_not_null(scene.get_node_or_null("BoardView"))
	assert_not_null(scene.get_node_or_null("Hud/Gold"))
	assert_not_null(scene.get_node_or_null("Hud/Lives"))
	assert_not_null(scene.get_node_or_null("Hud/Wave"))
	assert_not_null(scene.get_node_or_null("Hud/MenuButton"))
	assert_not_null(scene.get_node_or_null("Hud/SingleTowerButton"))
	assert_not_null(scene.get_node_or_null("Hud/AreaTowerButton"))
	assert_not_null(scene.get_node_or_null("Hud/SlowTowerButton"))
	assert_not_null(scene.get_node_or_null("Hud/FlameTowerButton"))
	assert_not_null(scene.get_node_or_null("Hud/HudFrame"))
	assert_not_null(scene.get_node_or_null("Hud/TowerDeck"))
	assert_not_null(scene.get_node_or_null("Hud/TowerActionPanel"))
	assert_not_null(scene.get_node_or_null("Hud/TowerActionPanel/Title"))
	assert_not_null(scene.get_node_or_null("Hud/TowerActionPanel/UpgradeButton"))
	assert_not_null(scene.get_node_or_null("Hud/TowerActionPanel/RemoveButton"))
	assert_not_null(scene.get_node_or_null("Hud/GoldIcon"))
	assert_not_null(scene.get_node_or_null("Hud/LivesIcon"))
	assert_not_null(scene.get_node_or_null("Hud/WaveIcon"))
	assert_not_null(scene.get_node_or_null("Hud/Status"))
	assert_not_null(scene.get_node_or_null("Hud/Hint"))
	assert_not_null(scene.get_node_or_null("Overlay/Screen"))
	assert_not_null(scene.get_node_or_null("Overlay/Screen/Panel/Title"))
	assert_not_null(scene.get_node_or_null("Overlay/Screen/Panel/PrimaryButton"))
	assert_not_null(scene.get_node_or_null("Overlay/Screen/Panel/SecondaryButton"))

	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var lives_label: Label = scene.get_node("Hud/Lives") as Label
	var wave_label: Label = scene.get_node("Hud/Wave") as Label
	var overlay_title: Label = scene.get_node("Overlay/Screen/Panel/Title") as Label
	var overlay_message: Label = scene.get_node("Overlay/Screen/Panel/Message") as Label
	assert_eq(single_button.text, "SINGLE\nFocus fire  25g")
	assert_eq(flame_button.text, "FLAME\nBurn DoT  25g")
	assert_eq(single_button.size.x, BoardLayoutService.TOWER_CARD_WIDTH)
	assert_eq(single_button.size.y, BoardLayoutService.TOWER_CARD_HEIGHT)
	assert_not_null(single_button.icon)
	assert_not_null(flame_button.icon)
	assert_eq(status_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(status_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(hint_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(hint_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(gold_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(lives_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(wave_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(overlay_title.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(overlay_title.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(overlay_message.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(overlay_message.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_true(single_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert_true(single_button.get_theme_stylebox("pressed") is StyleBoxTexture)
	assert_true((scene.get_node("Hud/HudFrame") as Panel).get_theme_stylebox("panel") is StyleBoxTexture)
	assert_true(single_button.button_pressed)
	assert_false(tower_action_panel.visible)


func test_board_view_loads_board_sprite_assets() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView

	assert_not_null(board_view.get_asset_catalog().level_definition)
	assert_eq(board_view.get_asset_catalog().level_definition.style_id, "stormwind_city_v3")
	assert_not_null(board_view.get_asset_catalog().map_style_definition)
	assert_eq(board_view.get_asset_catalog().map_style_definition.id, "stormwind_city_v3")
	assert_not_null(board_view.get_asset_catalog().board_map_renderer)
	assert_true(board_view.get_asset_catalog().board_map_renderer.has_texture("res://assets/tilesets/stormwind_city_v3/background_frame.png"))
	assert_true(board_view.get_asset_catalog().board_map_renderer.has_texture("res://assets/tilesets/stormwind_city_v3/background_frame_normal.png"))
	assert_not_null(board_view.get_asset_catalog().gold_icon_texture)
	assert_not_null(board_view.get_asset_catalog().lives_icon_texture)
	assert_not_null(board_view.get_asset_catalog().wave_icon_texture)
	assert_not_null(board_view.get_asset_catalog().menu_icon_texture)
	assert_not_null(board_view.get_asset_catalog().scene_background_texture)
	var map_light := board_view.get_node_or_null("MapNormalLight") as DirectionalLight2D
	assert_not_null(map_light)
	assert_true(map_light.enabled)
	assert_almost_eq(map_light.energy, 0.28, 0.00001)
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(GameTower.Type.SINGLE_TARGET, "", board_view.get_visual_state(), board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(GameTower.Type.AREA, "", board_view.get_visual_state(), board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(GameTower.Type.SLOW, "", board_view.get_visual_state(), board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(GameTower.Type.FLAME, "", board_view.get_visual_state(), board_view.get_asset_catalog()))
	assert_eq(board_view.get_asset_catalog().single_tower_texture.get_size(), Vector2(128.0, 128.0))
	assert_eq(board_view.get_asset_catalog().area_tower_texture.get_size(), Vector2(128.0, 128.0))
	assert_eq(board_view.get_asset_catalog().slow_tower_texture.get_size(), Vector2(128.0, 128.0))
	assert_eq(board_view.get_asset_catalog().flame_tower_texture.get_size(), Vector2(128.0, 128.0))
	assert_not_null(board_view.get_renderer().get_enemy_sprite_texture(null, board_view.get_visual_state(), board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_attack_feedback_texture(GameTower.Type.SINGLE_TARGET, 0.0, board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_attack_feedback_texture(GameTower.Type.AREA, 0.5, board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_attack_feedback_texture(GameTower.Type.SLOW, 0.99, board_view.get_asset_catalog()))
	assert_not_null(board_view.get_renderer().get_attack_feedback_texture(GameTower.Type.FLAME, 0.5, board_view.get_asset_catalog()))
	assert_eq(board_view.get_asset_catalog().enemy_walk_textures.size(), 4)
	assert_eq(board_view.get_asset_catalog().enemy_death_textures.size(), 6)


func test_board_view_level_definition_matches_default_path() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var level_file := FileAccess.open("res://data/levels/level_001.json", FileAccess.READ)
	assert_not_null(level_file)
	if level_file == null:
		return

	var level: Dictionary = JSON.parse_string(level_file.get_as_text()) as Dictionary
	assert_eq(int(level["grid"]["width"]), board_view.get_session().board.width)
	assert_eq(int(level["grid"]["height"]), board_view.get_session().board.height)
	assert_eq(_path_cells_to_vector2i(level["path_cells"]), board_view.get_session().get_default_path())
	assert_eq(level["style_id"], board_view.get_asset_catalog().map_style_definition.id)


func test_board_view_initializes_board_and_default_path() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	assert_not_null(board_view.get_session().board)
	assert_not_null(board_view.get_session().wallet)
	assert_not_null(board_view.get_session().placement_service)
	assert_not_null(board_view.get_session().combat_simulation)
	assert_not_null(board_view.get_session().kill_reward_service)
	assert_not_null(board_view.get_session().wave_reward_service)
	assert_not_null(board_view.get_session().wave_spawner)
	assert_not_null(board_view.get_session().path_follower)
	assert_eq(board_view.get_session().board.width, 10)
	assert_eq(board_view.get_session().board.height, 8)
	assert_eq(board_view.get_session().wallet.gold, 100)
	assert_eq(board_view.get_session().combat_simulation.player_life.lives, 10)
	assert_eq(board_view.get_session().combat_simulation.enemies.size(), 0)
	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(board_view.get_session().gameplay_paused)
	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.SINGLE_TARGET)

	var path_result: PathValidationResult = board_view.get_session().board.validate_path(board_view.get_session().get_default_path())
	assert_true(path_result.succeeded)


func test_board_view_game_scene_starts_playing_without_start_overlay() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var overlay: Control = scene.get_node("Overlay/Screen") as Control
	var menu_button: Button = scene.get_node("Hud/MenuButton") as Button

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(board_view.get_session().gameplay_paused)
	assert_false(overlay.visible)
	assert_false(menu_button.disabled)


func test_board_view_spawns_and_advances_wave_enemy() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var wave_label: Label = scene.get_node("Hud/Wave") as Label
	board_view.start_game()
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0
	board_view.get_session().wave_spawner.current_wave_state.spawn_elapsed_seconds = 0.0

	board_view._process(0.8)

	assert_eq(board_view.get_session().combat_simulation.enemies.size(), 1)
	assert_eq(board_view.get_session().get_visible_enemies().size(), 1)
	assert_eq(board_view.get_session().combat_simulation.enemies[0].id, "wave-1-enemy-1")
	assert_almost_eq(
		board_view.get_session().combat_simulation.enemies[0].path_distance,
		CombatSimulation.DEFAULT_FIXED_STEP_SECONDS,
		0.00001
	)
	assert_eq(wave_label.text, "Wave: 1/3")


func test_board_view_layout_fits_mobile_landscape_viewport() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	var mobile_landscape_size := Vector2(844, 390)

	board_view.apply_responsive_layout(mobile_landscape_size)

	var board_size := Vector2(
		float(board_view.get_session().board.width) * board_view.get_layout_metrics().cell_size,
		float(board_view.get_session().board.height) * board_view.get_layout_metrics().cell_size
	)
	var board_rect := Rect2(board_view.get_layout_metrics().board_origin, board_size)

	assert_true(board_view.get_layout_metrics().cell_size < BoardLayoutService.DEFAULT_CELL_SIZE)
	assert_true(board_view.get_layout_metrics().cell_size >= 38.0)
	assert_true(board_rect.position.x >= 0.0)
	assert_true(board_rect.position.y >= BoardLayoutService.HUD_RESERVED_HEIGHT)
	assert_true(board_rect.end.x <= single_button.position.x - BoardLayoutService.SIDE_PANEL_GAP)
	assert_true(board_rect.end.y <= mobile_landscape_size.y)
	assert_eq(single_button.size.x, BoardLayoutService.TOWER_CARD_WIDTH)
	assert_eq(single_button.size.y, BoardLayoutService.TOWER_CARD_HEIGHT)
	assert_eq(area_button.position.y, single_button.position.y + BoardLayoutService.TOWER_CARD_HEIGHT + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(slow_button.position.y, area_button.position.y + BoardLayoutService.TOWER_CARD_HEIGHT + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(flame_button.position.y, slow_button.position.y + BoardLayoutService.TOWER_CARD_HEIGHT + BoardLayoutService.TOWER_CARD_GAP)
	var button_rects := [
		Rect2(single_button.position, single_button.size),
		Rect2(area_button.position, area_button.size),
		Rect2(slow_button.position, slow_button.size),
		Rect2(flame_button.position, flame_button.size),
	]
	var status_rect := Rect2(status_label.position, status_label.size)
	var hint_rect := Rect2(hint_label.position, hint_label.size)

	assert_true(status_label.position.x >= 0.0)
	assert_true(hint_label.position.x >= 0.0)
	assert_true(status_label.position.x + status_label.size.x <= mobile_landscape_size.x)
	assert_true(hint_label.position.x + hint_label.size.x <= mobile_landscape_size.x)
	assert_true(status_label.position.y >= 0.0)
	assert_true(hint_label.position.y + hint_label.size.y <= mobile_landscape_size.y)
	assert_false(board_rect.intersects(status_rect))
	assert_false(board_rect.intersects(hint_rect))
	for button_rect in button_rects:
		assert_false(status_rect.intersects(button_rect))
		assert_false(hint_rect.intersects(button_rect))


func test_board_view_square_layout_moves_tower_deck_to_bottom_and_expands_board() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var square_size := Vector2(1364, 1242)

	board_view.apply_responsive_layout(square_size)

	var board_size := Vector2(
		float(board_view.get_session().board.width) * board_view.get_layout_metrics().cell_size,
		float(board_view.get_session().board.height) * board_view.get_layout_metrics().cell_size
	)
	var board_rect := Rect2(board_view.get_layout_metrics().board_origin, board_size)

	assert_true(board_view.get_layout_metrics().tower_deck_is_bottom)
	assert_true(board_view.get_layout_metrics().cell_size > BoardLayoutService.DEFAULT_CELL_SIZE)
	assert_eq(area_button.position.x, single_button.position.x + BoardLayoutService.TOWER_CARD_WIDTH + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(slow_button.position.x, area_button.position.x + BoardLayoutService.TOWER_CARD_WIDTH + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(flame_button.position.x, slow_button.position.x + BoardLayoutService.TOWER_CARD_WIDTH + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(area_button.position.y, single_button.position.y)
	assert_eq(slow_button.position.y, single_button.position.y)
	assert_eq(flame_button.position.y, single_button.position.y)
	assert_true(board_rect.end.y <= single_button.position.y - BoardLayoutService.BOTTOM_TOWER_DECK_GAP)
	assert_true(board_rect.end.x <= square_size.x - BoardLayoutService.SCREEN_PADDING)


func test_board_view_compact_square_layout_keeps_messages_above_board() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	var square_size := Vector2(720, 720)

	board_view.apply_responsive_layout(square_size)

	var board_size := Vector2(
		float(board_view.get_session().board.width) * board_view.get_layout_metrics().cell_size,
		float(board_view.get_session().board.height) * board_view.get_layout_metrics().cell_size
	)
	var board_rect := Rect2(board_view.get_layout_metrics().board_origin, board_size)

	assert_true(board_view.get_layout_metrics().tower_deck_is_bottom)
	assert_eq(area_button.position.x, single_button.position.x + BoardLayoutService.TOWER_CARD_WIDTH + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(area_button.position.y, single_button.position.y)
	assert_eq(slow_button.position.x, single_button.position.x)
	assert_eq(slow_button.position.y, single_button.position.y + BoardLayoutService.TOWER_CARD_HEIGHT + BoardLayoutService.TOWER_CARD_GAP)
	assert_eq(flame_button.position.x, area_button.position.x)
	assert_eq(flame_button.position.y, slow_button.position.y)
	assert_true(board_rect.position.y >= BoardLayoutService.HUD_COMPACT_MESSAGE_RESERVED_HEIGHT)
	assert_true(status_label.position.y + status_label.size.y <= hint_label.position.y)
	assert_true(hint_label.position.y + hint_label.size.y <= board_rect.position.y)
	assert_true(board_rect.end.y <= single_button.position.y - BoardLayoutService.BOTTOM_TOWER_DECK_GAP)
	assert_false(board_rect.intersects(Rect2(status_label.position, status_label.size)))
	assert_false(board_rect.intersects(Rect2(hint_label.position, hint_label.size)))


func test_board_view_compact_layout_shortens_reward_status_text() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.apply_responsive_layout(Vector2(896, 414))

	board_view.set_status_text("Defeated enemy-1 for 5 gold.")
	assert_eq(status_label.text, "+5 gold")

	board_view.set_status_text("Cleared wave-1 for 20 gold.")
	assert_eq(status_label.text, "Wave clear +20")

	board_view.set_status_text("Earned 25 gold.")
	assert_eq(status_label.text, "+25 gold")


func test_board_view_scaled_layout_keeps_grid_coordinate_mapping() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	board_view.apply_responsive_layout(Vector2(844, 390))

	var rect := board_view.grid_to_local_rect(Vector2i(2, 3))

	assert_eq(board_view.local_to_grid_position(rect.get_center()), Vector2i(2, 3))


func test_board_view_shows_tower_placement_preview_on_hovered_buildable_cell() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var hover_cell := Vector2i(2, 2)
	var motion_event := InputEventMouseMotion.new()
	board_view.start_game()
	board_view.select_tower_type(GameTower.Type.AREA)

	motion_event.position = board_view.to_global(board_view.grid_to_local_rect(hover_cell).get_center())
	board_view._unhandled_input(motion_event)

	assert_eq(board_view.hover_grid_position, hover_cell)
	assert_true(board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		hover_cell,
		true
	))
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(
		GameTower.Type.AREA,
		"",
		board_view.get_visual_state(),
		board_view.get_asset_catalog()
	))

	var path_cell: Vector2i = board_view.get_session().get_default_path()[0]
	assert_false(board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		path_cell,
		true
	))

	board_view.get_session().wallet.gold = 0
	assert_false(board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		hover_cell,
		true
	))

	board_view.get_session().wallet.gold = 100
	assert_true(board_view.try_place_at_grid(hover_cell).succeeded)
	assert_false(board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		hover_cell,
		true
	))
	assert_false(board_view.get_renderer().should_draw_tower_placement_preview(
		board_view.get_session().board,
		board_view.get_session().placement_service,
		Vector2i(3, 2),
		false
	))


func test_board_view_pause_menu_pauses_and_resumes_game() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var title: Label = scene.get_node("Overlay/Screen/Panel/Title") as Label
	var primary_button: Button = scene.get_node("Overlay/Screen/Panel/PrimaryButton") as Button
	var secondary_button: Button = scene.get_node("Overlay/Screen/Panel/SecondaryButton") as Button
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	board_view.start_game()
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0
	board_view.get_session().wave_spawner.current_wave_state.spawn_elapsed_seconds = 0.0
	board_view._process(0.8)
	var enemy: Enemy = board_view.get_session().combat_simulation.enemies[0]
	var paused_distance := enemy.path_distance

	board_view.open_pause_menu()
	board_view._process(1.0)

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.MENU)
	assert_true(board_view.get_session().gameplay_paused)
	assert_eq(title.text, "Paused")
	assert_true(secondary_button.visible)
	assert_eq(secondary_button.text, "Start")
	assert_true(single_button.disabled)
	assert_almost_eq(enemy.path_distance, paused_distance, 0.00001)

	primary_button.pressed.emit()
	board_view._process(0.1)

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(board_view.get_session().gameplay_paused)
	assert_false(single_button.disabled)
	assert_true(enemy.path_distance > paused_distance)


func test_board_view_restart_resets_game_and_starts_playing() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var overlay: Control = scene.get_node("Overlay/Screen") as Control
	board_view.start_game()
	board_view.select_tower_type(GameTower.Type.AREA)
	assert_true(board_view.try_place_at_grid(Vector2i(0, 0)).succeeded)
	assert_eq(board_view.get_session().wallet.gold, 75)

	board_view.restart_game()

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(board_view.get_session().gameplay_paused)
	assert_false(overlay.visible)
	assert_eq(board_view.get_session().wallet.gold, 100)
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(0, 0)), "")
	assert_eq(board_view.get_session().combat_simulation.enemies.size(), 0)
	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.SINGLE_TARGET)


func test_board_view_places_tower_on_buildable_grid_position() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	board_view.start_game()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var gold_label: Label = scene.get_node("Hud/Gold") as Label

	assert_true(result.succeeded)
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(0, 0)), "tower-1")
	assert_eq(board_view.get_session().wallet.gold, 75)
	assert_eq(status_label.text, "Placed tower-1 at (0, 0) for 25 gold.")
	assert_eq(gold_label.text, "Gold: 75")
	assert_eq(board_view.get_session().combat_simulation.towers.size(), 1)
	assert_eq(board_view.get_session().placement_service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.SINGLE_TARGET)


func test_board_view_selects_area_tower_for_next_placement() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	board_view.start_game()

	area_button.pressed.emit()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))

	assert_true(result.succeeded)
	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.AREA)
	assert_eq(board_view.get_session().placement_service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.AREA)
	assert_eq(area_button.text, "AREA\nSplash hit  25g")
	assert_eq(single_button.text, "SINGLE\nFocus fire  25g")
	assert_not_null(area_button.icon)
	assert_true(area_button.button_pressed)
	assert_false(single_button.button_pressed)
	assert_eq(hint_label.text, "Area tower: 25g. Enemies follow the paved road.")


func test_board_view_selects_slow_tower_for_next_placement() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	board_view.start_game()

	slow_button.pressed.emit()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))

	assert_true(result.succeeded)
	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.SLOW)
	assert_eq(board_view.get_session().placement_service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.SLOW)
	assert_true(slow_button.button_pressed)


func test_board_view_selects_flame_tower_for_next_placement() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	board_view.start_game()

	flame_button.pressed.emit()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))

	assert_true(result.succeeded)
	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.FLAME)
	assert_eq(board_view.get_session().placement_service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.FLAME)
	assert_eq(flame_button.text, "FLAME\nBurn DoT  25g")
	assert_not_null(flame_button.icon)
	assert_true(flame_button.button_pressed)
	assert_false(single_button.button_pressed)
	assert_eq(hint_label.text, "Flame tower: 25g. Enemies follow the paved road.")


func test_board_view_number_keys_select_tower_type_shortcuts() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	board_view.start_game()

	board_view._unhandled_input(_key_event(KEY_2))

	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.AREA)
	assert_true(area_button.button_pressed)
	assert_false(single_button.button_pressed)
	assert_eq(hint_label.text, "Area tower: 25g. Enemies follow the paved road.")

	board_view._unhandled_input(_key_event(KEY_3))

	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.SLOW)
	assert_true(slow_button.button_pressed)
	assert_false(area_button.button_pressed)
	assert_eq(hint_label.text, "Slow tower: 25g. Enemies follow the paved road.")

	board_view._unhandled_input(_key_event(KEY_4))

	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.FLAME)
	assert_true(flame_button.button_pressed)
	assert_false(slow_button.button_pressed)
	assert_eq(hint_label.text, "Flame tower: 25g. Enemies follow the paved road.")

	board_view._unhandled_input(_key_event(KEY_1))

	assert_eq(board_view.get_session().selected_tower_type, GameTower.Type.SINGLE_TARGET)
	assert_true(single_button.button_pressed)
	assert_false(flame_button.button_pressed)
	assert_eq(hint_label.text, "Single tower: 25g. Enemies follow the paved road.")


func test_board_view_rejects_path_and_occupied_grid_positions() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	board_view.start_game()
	var path_result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 3))
	assert_false(path_result.succeeded)
	assert_eq(path_result.failure_reason, TowerPlacementResult.FailureReason.PLACEMENT_FAILED)
	assert_eq(path_result.placement_result.failure_reason, PlacementResult.FailureReason.NOT_BUILDABLE)

	var first_result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))
	var second_result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 0))

	assert_true(first_result.succeeded)
	assert_false(second_result.succeeded)
	assert_eq(second_result.failure_reason, TowerPlacementResult.FailureReason.PLACEMENT_FAILED)
	assert_eq(second_result.placement_result.failure_reason, PlacementResult.FailureReason.OCCUPIED)


func test_board_view_rejects_placement_when_gold_is_insufficient() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var single_button: Button = scene.get_node("Hud/SingleTowerButton") as Button
	var area_button: Button = scene.get_node("Hud/AreaTowerButton") as Button
	var slow_button: Button = scene.get_node("Hud/SlowTowerButton") as Button
	var flame_button: Button = scene.get_node("Hud/FlameTowerButton") as Button
	board_view.start_game()

	assert_true(board_view.try_place_at_grid(Vector2i(0, 0)).succeeded)
	assert_true(board_view.try_place_at_grid(Vector2i(1, 0)).succeeded)
	assert_true(board_view.try_place_at_grid(Vector2i(2, 0)).succeeded)
	assert_true(board_view.try_place_at_grid(Vector2i(3, 0)).succeeded)

	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(4, 0))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerPlacementResult.FailureReason.INSUFFICIENT_FUNDS)
	assert_eq(board_view.get_session().wallet.gold, 0)
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(4, 0)), "")
	assert_eq(gold_label.text, "Gold: 0")
	assert_eq(status_label.text, "Cannot place at (4, 0): Need 25 gold.")
	assert_true(single_button.disabled)
	assert_true(area_button.disabled)
	assert_true(slow_button.disabled)
	assert_true(flame_button.disabled)


func test_board_view_clicking_placed_tower_shows_action_menu_near_tower() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var title: Label = scene.get_node("Hud/TowerActionPanel/Title") as Label
	var preview: Label = scene.get_node("Hud/TowerActionPanel/Preview") as Label
	var upgrade_button: Button = scene.get_node("Hud/TowerActionPanel/UpgradeButton") as Button
	var remove_button: Button = scene.get_node("Hud/TowerActionPanel/RemoveButton") as Button
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)

	board_view.handle_board_click(Vector2i(2, 2))

	var tower_rect := board_view.grid_to_local_rect(Vector2i(2, 2))
	assert_true(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "tower-1")
	assert_eq(board_view.get_selected_tower_grid_position(), Vector2i(2, 2))
	assert_eq(title.text, "Single T1")
	assert_eq(preview.text, "Damage +8 / Range +0.25")
	assert_eq(upgrade_button.text, "Upgrade 40g")
	assert_false(upgrade_button.disabled)
	assert_eq(remove_button.text, "Remove +12g")
	assert_false(remove_button.disabled)
	assert_eq(status_label.text, "Single T1 selected.")
	assert_eq(hint_label.text, "Upgrade or remove this tower.")
	assert_true(tower_action_panel.global_position.x >= board_view.to_global(tower_rect.position).x)
	assert_true(tower_action_panel.global_position.y < board_view.to_global(tower_rect.end).y)


func test_board_view_upgrade_button_uses_configured_cost_and_keeps_menu_synced() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var title: Label = scene.get_node("Hud/TowerActionPanel/Title") as Label
	var preview: Label = scene.get_node("Hud/TowerActionPanel/Preview") as Label
	var upgrade_button: Button = scene.get_node("Hud/TowerActionPanel/UpgradeButton") as Button
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)
	board_view.handle_board_click(Vector2i(2, 2))

	upgrade_button.pressed.emit()
	var tower := board_view.get_session().placement_service.tower_registry.get_tower("tower-1")
	var stats := board_view.get_session().placement_service.tower_config.get_stats(tower.tower_type, tower.tier)

	assert_true(tower_action_panel.visible)
	assert_eq(tower.tier, 2)
	assert_eq(tower.invested_gold, 65)
	assert_eq(board_view.get_session().wallet.gold, 35)
	assert_eq(gold_label.text, "Gold: 35")
	assert_eq(status_label.text, "Upgraded tower-1 to Single T2 for 40 gold.")
	assert_eq(title.text, "Single T2")
	assert_eq(preview.text, "Damage +12 / Range +0.25")
	assert_eq(upgrade_button.text, "Upgrade 70g")
	assert_true(upgrade_button.disabled)
	assert_eq(board_view.get_session().combat_simulation.towers[0].tier, 2)
	assert_eq(stats.damage, 18.0)
	assert_eq(stats.attack_interval, 0.9)


func test_board_view_remove_button_refunds_half_total_investment_and_hides_menu() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var upgrade_button: Button = scene.get_node("Hud/TowerActionPanel/UpgradeButton") as Button
	var remove_button: Button = scene.get_node("Hud/TowerActionPanel/RemoveButton") as Button
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)
	board_view.handle_board_click(Vector2i(2, 2))
	upgrade_button.pressed.emit()

	remove_button.pressed.emit()

	assert_false(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "")
	assert_eq(board_view.get_session().wallet.gold, 67)
	assert_eq(gold_label.text, "Gold: 67")
	assert_eq(status_label.text, "Removed tower-1 for 32 gold refund.")
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(2, 2)), "")
	assert_null(board_view.get_session().placement_service.tower_registry.get_tower("tower-1"))
	assert_eq(board_view.get_session().combat_simulation.towers.size(), 0)


func test_board_view_action_menu_closes_on_empty_click_and_pause() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var hint_label: Label = scene.get_node("Hud/Hint") as Label
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)
	board_view.handle_board_click(Vector2i(2, 2))
	assert_true(tower_action_panel.visible)

	board_view.handle_board_click(Vector2i(3, 2))

	assert_false(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "")
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(3, 2)), "tower-2")
	assert_eq(hint_label.text, "Single tower: 25g. Enemies follow the paved road.")

	board_view.handle_board_click(Vector2i(2, 2))
	assert_true(tower_action_panel.visible)
	board_view.open_pause_menu()

	assert_false(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "")


func test_board_view_keyboard_shortcuts_upgrade_and_remove_selected_tower() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)
	assert_true(board_view.select_tower_at_grid(Vector2i(2, 2)))

	board_view._unhandled_input(_key_event(KEY_U))
	var tower := board_view.get_session().placement_service.tower_registry.get_tower("tower-1")

	assert_true(tower_action_panel.visible)
	assert_eq(tower.tier, 2)
	assert_eq(board_view.get_session().wallet.gold, 35)
	assert_eq(gold_label.text, "Gold: 35")
	assert_eq(status_label.text, "Upgraded tower-1 to Single T2 for 40 gold.")

	board_view._unhandled_input(_key_event(KEY_X))

	assert_false(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "")
	assert_eq(board_view.get_session().wallet.gold, 67)
	assert_eq(gold_label.text, "Gold: 67")
	assert_eq(status_label.text, "Removed tower-1 for 32 gold refund.")
	assert_eq(board_view.get_session().board.get_occupant_id(Vector2i(2, 2)), "")
	assert_eq(board_view.get_session().combat_simulation.towers.size(), 0)


func test_board_view_escape_closes_action_menu_before_opening_pause() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var tower_action_panel: Panel = scene.get_node("Hud/TowerActionPanel") as Panel
	var overlay: Control = scene.get_node("Overlay/Screen") as Control
	board_view.start_game()
	assert_true(board_view.try_place_at_grid(Vector2i(2, 2)).succeeded)
	assert_true(board_view.select_tower_at_grid(Vector2i(2, 2)))
	assert_true(tower_action_panel.visible)

	board_view._unhandled_input(_key_event(KEY_ESCAPE))

	assert_false(tower_action_panel.visible)
	assert_eq(board_view.get_selected_tower_id(), "")
	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(overlay.visible)

	board_view._unhandled_input(_key_event(KEY_ESCAPE))

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.MENU)
	assert_true(overlay.visible)

	board_view._unhandled_input(_key_event(KEY_ESCAPE))

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(overlay.visible)


func test_board_view_combat_simulation_rewards_gold_when_enemy_is_defeated() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 2))
	assert_true(result.succeeded)

	board_view.get_session().combat_simulation.wave_spawner = null
	var enemy := Enemy.new("enemy-1", 1.0, 10.0, 5)
	board_view.get_session().combat_simulation.enemies = [enemy]
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0
	board_view._process(0.3)

	assert_true(enemy.defeated)
	assert_eq(board_view.get_session().wallet.gold, 80)
	assert_eq(gold_label.text, "Gold: 80")
	assert_eq(status_label.text, "Defeated enemy-1 for 5 gold.")
	assert_eq(board_view.get_session().last_reward_transaction_results.size(), 1)
	assert_eq(board_view.get_session().last_reward_transaction_results[0].reason, TransactionRecord.Reason.KILL_ENEMY)
	assert_eq(board_view.get_visual_state().enemy_death_animations.size(), 1)


func test_board_view_spawns_attack_feedback_when_tower_attacks() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	board_view.start_game()
	var result: TowerPlacementResult = board_view.try_place_at_grid(Vector2i(0, 2))
	assert_true(result.succeeded)

	board_view.get_session().combat_simulation.wave_spawner = null
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	board_view.get_session().combat_simulation.enemies = [enemy]
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0

	board_view._process(0.1)

	assert_eq(board_view.get_session().combat_simulation.projectiles.size(), 1)
	assert_eq(board_view.get_visual_state().attack_feedbacks.size(), 0)
	var tower := board_view.get_session().placement_service.tower_registry.get_tower(result.tower_id)
	var tower_rotation := board_view.get_renderer().tower_draw_rotation(
		tower,
		board_view.get_session().combat_simulation,
		board_view.get_session().path_follower
	)
	assert_true(tower_rotation > 1.0)
	assert_true(tower_rotation < 2.0)
	assert_not_null(board_view.get_renderer().get_tower_sprite_texture(GameTower.Type.SINGLE_TARGET, result.tower_id, board_view.get_visual_state(), board_view.get_asset_catalog()))

	board_view._process(0.2)

	assert_eq(board_view.get_visual_state().attack_feedbacks.size(), 1)
	assert_true(board_view.get_visual_state().attack_feedbacks[0]["position"] is Vector2)
	assert_eq(board_view.get_visual_state().attack_feedbacks[0]["tower_type"], GameTower.Type.SINGLE_TARGET)
	assert_not_null(board_view.get_renderer().get_attack_feedback_texture(board_view.get_visual_state().attack_feedbacks[0]["tower_type"], 0.0, board_view.get_asset_catalog()))

	board_view.get_visual_state().advance_attack_feedbacks(BoardVisualState.ATTACK_FEEDBACK_DURATION_SECONDS)

	assert_eq(board_view.get_visual_state().attack_feedbacks.size(), 0)


func test_board_view_enemy_health_bar_tracks_current_health() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	board_view.start_game()
	var enemy := Enemy.new("enemy-1", 1.0, 20.0, 5)
	enemy.path_distance = 1.0
	enemy.apply_damage(5.0)
	board_view.get_session().combat_simulation.enemies = [enemy]

	var health_ratio := board_view.get_renderer().get_enemy_health_ratio(enemy)
	var bar_rect := board_view.get_renderer().get_enemy_health_bar_rect(
		board_view.get_session().path_follower,
		board_view.get_layout_metrics().board_origin,
		board_view.get_layout_metrics().cell_size,
		enemy
	)
	var enemy_position := board_view.get_renderer().enemy_local_position(
		board_view.get_session().path_follower,
		board_view.get_layout_metrics().board_origin,
		board_view.get_layout_metrics().cell_size,
		enemy
	)

	assert_almost_eq(health_ratio, 0.75, 0.00001)
	assert_almost_eq(bar_rect.get_center().x, enemy_position.x, 0.00001)
	assert_true(bar_rect.position.y < enemy_position.y)
	assert_true(bar_rect.size.x > 0.0)
	assert_true(bar_rect.size.y > 0.0)


func _path_cells_to_vector2i(path_cells: Array) -> Array:
	var result := []
	for cell in path_cells:
		result.append(Vector2i(int(cell[0]), int(cell[1])))

	return result


func test_board_view_rewards_gold_when_wave_is_cleared() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var gold_label: Label = scene.get_node("Hud/Gold") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	var tick_result := CombatTickResult.new(
		0.1,
		[],
		[],
		[],
		EnemyDamageResult.new(),
		[],
		[WaveClearEvent.new("wave-1", 20)],
		false
	)

	board_view.get_session().apply_tick_rewards([tick_result])
	board_view.refresh_hud()

	assert_eq(board_view.get_session().wallet.gold, 120)
	assert_eq(gold_label.text, "Gold: 120")
	assert_eq(status_label.text, "Cleared wave-1 for 20 gold.")
	assert_eq(board_view.get_session().last_wave_reward_transaction_results.size(), 1)
	assert_eq(board_view.get_session().last_wave_reward_transaction_results[0].reason, TransactionRecord.Reason.CLEAR_WAVE)


func test_board_view_updates_lives_when_enemy_leaks() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var lives_label: Label = scene.get_node("Hud/Lives") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	board_view.start_game()
	board_view.get_session().combat_simulation.wave_spawner = null
	var enemy := Enemy.new("enemy-1", 1.0)
	enemy.path_distance = board_view.get_session().path_follower.total_distance - 0.05
	board_view.get_session().combat_simulation.enemies = [enemy]
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0

	board_view._process(0.1)

	assert_eq(board_view.get_session().combat_simulation.player_life.lives, 9)
	assert_eq(lives_label.text, "Lives: 9")
	assert_eq(status_label.text, "Enemy leaked. Lives: 9")


func test_board_view_shows_defeat_when_lives_reach_zero() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var lives_label: Label = scene.get_node("Hud/Lives") as Label
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var overlay: Control = scene.get_node("Overlay/Screen") as Control
	var title: Label = scene.get_node("Overlay/Screen/Panel/Title") as Label
	var primary_button: Button = scene.get_node("Overlay/Screen/Panel/PrimaryButton") as Button
	var secondary_button: Button = scene.get_node("Overlay/Screen/Panel/SecondaryButton") as Button
	board_view.start_game()
	board_view.get_session().combat_simulation.wave_spawner = null
	board_view.get_session().combat_simulation.player_life = PlayerLife.new(1)
	var enemy := Enemy.new("enemy-1", 1.0)
	enemy.path_distance = board_view.get_session().path_follower.total_distance - 0.05
	board_view.get_session().combat_simulation.enemies = [enemy]
	board_view.get_session().combat_simulation.accumulator_seconds = 0.0

	board_view._process(0.1)

	assert_true(board_view.get_session().combat_simulation.game_failed)
	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.LOST)
	assert_true(board_view.get_session().gameplay_paused)
	assert_true(overlay.visible)
	assert_eq(title.text, "Defeat")
	assert_eq(primary_button.text, "Restart")
	assert_true(secondary_button.visible)
	assert_eq(secondary_button.text, "Start")
	assert_eq(lives_label.text, "Lives: 0")
	assert_eq(status_label.text, "Defeat. Enemies breached the path.")


func test_board_view_shows_victory_when_all_waves_are_cleared() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child_autoqfree(scene)
	await get_tree().process_frame

	var board_view: BoardView = scene.get_node("BoardView") as BoardView
	var status_label: Label = scene.get_node("Hud/Status") as Label
	var overlay: Control = scene.get_node("Overlay/Screen") as Control
	var title: Label = scene.get_node("Overlay/Screen/Panel/Title") as Label
	var secondary_button: Button = scene.get_node("Overlay/Screen/Panel/SecondaryButton") as Button
	board_view.start_game()
	board_view.show_victory_screen()

	assert_eq(board_view.get_session().flow_state, BoardGameSession.FlowState.WON)
	assert_true(board_view.get_session().gameplay_paused)
	assert_true(overlay.visible)
	assert_eq(title.text, "Victory")
	assert_true(secondary_button.visible)
	assert_eq(secondary_button.text, "Start")
	assert_eq(status_label.text, "Victory. All waves cleared.")


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event
