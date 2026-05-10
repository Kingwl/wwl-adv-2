class_name BoardView
extends Node2D

const INVALID_GRID_POSITION := Vector2i(-1, -1)
const START_SCENE_PATH := "res://scenes/start.tscn"

@export var status_label_path: NodePath = NodePath("../Hud/Status")
@export var hint_label_path: NodePath = NodePath("../Hud/Hint")
@export var gold_label_path: NodePath = NodePath("../Hud/Gold")
@export var lives_label_path: NodePath = NodePath("../Hud/Lives")
@export var wave_label_path: NodePath = NodePath("../Hud/Wave")
@export var menu_button_path: NodePath = NodePath("../Hud/MenuButton")
@export var single_tower_button_path: NodePath = NodePath("../Hud/SingleTowerButton")
@export var area_tower_button_path: NodePath = NodePath("../Hud/AreaTowerButton")
@export var slow_tower_button_path: NodePath = NodePath("../Hud/SlowTowerButton")
@export var flame_tower_button_path: NodePath = NodePath("../Hud/FlameTowerButton")
@export var overlay_root_path: NodePath = NodePath("../Overlay/Screen")
@export var overlay_backdrop_path: NodePath = NodePath("../Overlay/Screen/Backdrop")
@export var overlay_panel_path: NodePath = NodePath("../Overlay/Screen/Panel")
@export var overlay_title_path: NodePath = NodePath("../Overlay/Screen/Panel/Title")
@export var overlay_message_path: NodePath = NodePath("../Overlay/Screen/Panel/Message")
@export var overlay_primary_button_path: NodePath = NodePath("../Overlay/Screen/Panel/PrimaryButton")
@export var overlay_secondary_button_path: NodePath = NodePath("../Overlay/Screen/Panel/SecondaryButton")

var hover_grid_position := INVALID_GRID_POSITION
var selected_tower_grid_position := INVALID_GRID_POSITION
var selected_tower_id := ""

var _game_session: BoardGameSession
var _asset_catalog: BoardAssetCatalog
var _layout_service: BoardLayoutService
var _layout_metrics: BoardLayoutMetrics
var _hud_controller: BoardHudController
var _visual_state: BoardVisualState
var _input_adapter: BoardInputAdapter
var _board_renderer: BoardRenderer
var _map_normal_light: DirectionalLight2D


func _ready() -> void:
	_ensure_dependencies()
	_load_assets()
	_initialize_board()
	_initialize_combat()
	_configure_hud()
	_sync_map_normal_light()
	apply_responsive_layout(get_viewport_rect().size)

	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)

	set_status_text("Select a tower, then click an open tile.")
	_update_selected_tower_hint()
	_refresh_hud()
	start_game()
	queue_redraw()


func _process(delta: float) -> void:
	if _game_session.combat_simulation == null or _game_session.gameplay_paused:
		return

	_visual_state.advance(delta)
	var previous_flow_state := _game_session.flow_state
	var tick_results := _game_session.advance_combat(delta)
	_visual_state.advance_attack_feedbacks(delta)
	_visual_state.spawn_enemy_death_animations(tick_results, Callable(self, "_enemy_position_for_id"))
	_visual_state.spawn_attack_feedback(
		tick_results,
		Callable(self, "_grid_space_to_local"),
		Callable(_board_renderer, "impact_feedback_color")
	)
	_sync_flow_overlay_from_transition(previous_flow_state)
	_refresh_hud()
	queue_redraw()


func get_session() -> BoardGameSession:
	_ensure_dependencies()
	return _game_session


func get_asset_catalog() -> BoardAssetCatalog:
	_ensure_dependencies()
	return _asset_catalog


func get_layout_metrics() -> BoardLayoutMetrics:
	_ensure_dependencies()
	if _layout_metrics == null:
		apply_responsive_layout(get_viewport_rect().size)
	return _layout_metrics


func get_visual_state() -> BoardVisualState:
	_ensure_dependencies()
	return _visual_state


func get_renderer() -> BoardRenderer:
	_ensure_dependencies()
	return _board_renderer


func screen_to_grid_position(screen_position: Vector2) -> Vector2i:
	return local_to_grid_position(to_local(screen_position))


func local_to_grid_position(local_position: Vector2) -> Vector2i:
	var metrics := get_layout_metrics()
	return _layout_service.local_to_grid_position(local_position, metrics.board_origin, metrics.cell_size)


func grid_to_local_rect(grid_position: Vector2i) -> Rect2:
	var metrics := get_layout_metrics()
	return _layout_service.grid_to_local_rect(grid_position, metrics.board_origin, metrics.cell_size)


func apply_responsive_layout(viewport_size: Vector2) -> void:
	_ensure_dependencies()
	var board_width := BoardGameSession.DEFAULT_BOARD_WIDTH
	var board_height := BoardGameSession.DEFAULT_BOARD_HEIGHT
	if _game_session.board != null:
		board_width = _game_session.board.width
		board_height = _game_session.board.height

	_layout_metrics = _layout_service.calculate(viewport_size, board_width, board_height)
	_hud_controller.apply_layout(_layout_metrics)
	_sync_tower_action_menu()
	_sync_message_labels()


func try_place_at_grid(grid_position: Vector2i) -> TowerPlacementResult:
	_ensure_dependencies()
	var result := _game_session.try_place_at_grid(grid_position)
	_refresh_hud()
	queue_redraw()
	return result


func handle_board_click(grid_position: Vector2i) -> void:
	_ensure_dependencies()
	if _select_tower_if_occupied(grid_position):
		return

	clear_tower_action_menu()
	try_place_at_grid(grid_position)


func get_selected_tower_id() -> String:
	return selected_tower_id


func get_selected_tower_grid_position() -> Vector2i:
	return selected_tower_grid_position


func has_tower_action_menu() -> bool:
	return not selected_tower_id.is_empty()


func select_tower_at_grid(grid_position: Vector2i) -> bool:
	_ensure_dependencies()
	return _select_tower_if_occupied(grid_position)


func clear_tower_action_menu() -> void:
	selected_tower_grid_position = INVALID_GRID_POSITION
	selected_tower_id = ""
	if _hud_controller != null:
		_hud_controller.hide_tower_action_menu()
	if _game_session != null and _game_session.economy_config != null and _hud_controller != null:
		_game_session.set_hint(_hud_controller.update_selected_tower_hint(
			_game_session.selected_tower_type,
			_game_session.economy_config
		))
		_sync_message_labels()
	queue_redraw()


func upgrade_selected_tower() -> TowerUpgradeResult:
	_ensure_dependencies()
	if selected_tower_id.is_empty():
		return null

	var result := _game_session.try_upgrade_tower(selected_tower_id)
	if result.succeeded:
		_sync_combat_tower_selection()
	_sync_tower_action_menu()
	_refresh_hud()
	queue_redraw()
	return result


func remove_selected_tower() -> TowerRemovalResult:
	_ensure_dependencies()
	if selected_tower_grid_position == INVALID_GRID_POSITION:
		return null

	var result := _game_session.try_remove_tower_at(selected_tower_grid_position)
	if result.succeeded:
		clear_tower_action_menu()
	else:
		_sync_tower_action_menu()
	_refresh_hud()
	queue_redraw()
	return result


func start_game() -> void:
	_ensure_dependencies()
	_game_session.start_game()
	_set_overlay_visible(false)
	_update_selected_tower_hint()
	_refresh_hud()
	queue_redraw()


func open_pause_menu() -> void:
	_ensure_dependencies()
	if not _game_session.open_pause_menu():
		return

	clear_tower_action_menu()
	_show_overlay("Paused", "Game paused.", "Resume", "Start")
	_refresh_hud()


func resume_game() -> void:
	_ensure_dependencies()
	if not _game_session.resume_game():
		return

	_set_overlay_visible(false)
	_refresh_hud()
	queue_redraw()


func restart_game() -> void:
	_ensure_dependencies()
	_game_session.restart_game()
	_reset_view_state()
	_update_selected_tower_hint()
	_set_overlay_visible(false)
	_refresh_hud()
	queue_redraw()


func return_to_start_screen() -> void:
	_game_session.gameplay_paused = true
	_sync_tower_button_state()
	get_tree().change_scene_to_file(START_SCENE_PATH)


func show_victory_screen() -> void:
	_ensure_dependencies()
	clear_tower_action_menu()
	_game_session.show_victory_screen()
	_game_session.set_status("Victory. All waves cleared.")
	_show_overlay("Victory", "All waves cleared.", "Restart", "Start")
	_refresh_hud()


func show_defeat_screen() -> void:
	_ensure_dependencies()
	clear_tower_action_menu()
	_game_session.show_defeat_screen()
	_game_session.set_status("Defeat. Enemies breached the path.")
	_show_overlay("Defeat", "Enemies breached the path.", "Restart", "Start")
	_refresh_hud()


func select_tower_type(tower_type: GameTower.Type) -> void:
	_ensure_dependencies()
	_game_session.select_tower_type(tower_type)
	_update_selected_tower_hint()
	_sync_tower_button_state()
	queue_redraw()


func set_status_text(text: String) -> void:
	_ensure_dependencies()
	_game_session.set_status(text)
	_sync_message_labels()


func refresh_hud() -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	_input_adapter.handle_unhandled_input(
		event,
		_game_session.flow_state,
		BoardGameSession.FlowState.PLAYING,
		BoardGameSession.FlowState.MENU,
		Callable(self, "screen_to_grid_position"),
		Callable(self, "_update_hover"),
		Callable(self, "handle_board_click"),
		Callable(self, "open_pause_menu"),
		Callable(self, "resume_game"),
		{
			"select_single_tower": Callable(self, "select_tower_type").bind(GameTower.Type.SINGLE_TARGET),
			"select_area_tower": Callable(self, "select_tower_type").bind(GameTower.Type.AREA),
			"select_slow_tower": Callable(self, "select_tower_type").bind(GameTower.Type.SLOW),
			"select_flame_tower": Callable(self, "select_tower_type").bind(GameTower.Type.FLAME),
			"upgrade_selected_tower": Callable(self, "upgrade_selected_tower"),
			"remove_selected_tower": Callable(self, "remove_selected_tower"),
			"has_tower_action_menu": Callable(self, "has_tower_action_menu"),
			"clear_tower_action_menu": Callable(self, "clear_tower_action_menu"),
		}
	)


func _draw() -> void:
	if _game_session.board == null:
		return

	var metrics := get_layout_metrics()
	_board_renderer.draw(
		self,
		_game_session.board,
		_game_session.get_visible_enemies(),
		_game_session.combat_simulation,
		_game_session.path_follower,
		_game_session.placement_service,
		_asset_catalog.map_style_definition,
		_asset_catalog.board_map_renderer,
		_visual_state,
		_asset_catalog,
		metrics.board_origin,
		metrics.cell_size,
		hover_grid_position,
		_game_session.selected_tower_type,
		_should_draw_tower_placement_preview(),
		selected_tower_grid_position,
		_game_session.last_placement_result
	)


func _ensure_dependencies() -> void:
	if _game_session == null:
		_game_session = BoardGameSession.new(
			BoardGameSession.DEFAULT_BOARD_WIDTH,
			BoardGameSession.DEFAULT_BOARD_HEIGHT
		)
	if _asset_catalog == null:
		_asset_catalog = BoardAssetCatalog.new()
	if _layout_service == null:
		_layout_service = BoardLayoutService.new()
	if _hud_controller == null:
		_hud_controller = BoardHudController.new()
	if _visual_state == null:
		_visual_state = BoardVisualState.new()
	if _input_adapter == null:
		_input_adapter = BoardInputAdapter.new()
	if _board_renderer == null:
		_board_renderer = BoardRenderer.new()


func _load_assets() -> void:
	_asset_catalog.load_all()


func _initialize_board() -> void:
	_ensure_dependencies()
	if _asset_catalog.level_definition == null:
		_asset_catalog.load_level_definition()
	_game_session.level_definition = _asset_catalog.level_definition
	_game_session.initialize_board()
	_reset_view_state()


func _initialize_combat() -> void:
	_ensure_dependencies()
	_game_session.initialize_combat()


func _configure_hud() -> void:
	_hud_controller.bind(
		self,
		status_label_path,
		hint_label_path,
		gold_label_path,
		lives_label_path,
		wave_label_path,
		menu_button_path,
		single_tower_button_path,
		area_tower_button_path,
		slow_tower_button_path,
		flame_tower_button_path,
		overlay_root_path,
		overlay_backdrop_path,
		overlay_panel_path,
		overlay_title_path,
		overlay_message_path,
		overlay_primary_button_path,
		overlay_secondary_button_path
	)
	_hud_controller.ensure_chrome(
		_asset_catalog.gold_icon_texture,
		_asset_catalog.lives_icon_texture,
		_asset_catalog.wave_icon_texture
	)
	FrostRtsTheme.apply_hud_panel(_hud_controller.hud_frame_panel)
	FrostRtsTheme.apply_hud_panel(_hud_controller.tower_deck_panel)
	_hud_controller.configure(_asset_catalog.menu_icon_texture)
	_hud_controller.connect_signals(
		Callable(self, "open_pause_menu"),
		Callable(self, "select_tower_type").bind(GameTower.Type.SINGLE_TARGET),
		Callable(self, "select_tower_type").bind(GameTower.Type.AREA),
		Callable(self, "select_tower_type").bind(GameTower.Type.SLOW),
		Callable(self, "select_tower_type").bind(GameTower.Type.FLAME),
		Callable(self, "_on_overlay_primary_pressed"),
		Callable(self, "_on_overlay_secondary_pressed"),
		Callable(self, "upgrade_selected_tower"),
		Callable(self, "remove_selected_tower")
	)


func _reset_view_state() -> void:
	hover_grid_position = INVALID_GRID_POSITION
	clear_tower_action_menu()
	_visual_state.reset()


func _sync_flow_overlay_from_transition(previous_flow_state: int) -> void:
	if previous_flow_state == _game_session.flow_state:
		return

	match _game_session.flow_state:
		BoardGameSession.FlowState.WON:
			_show_overlay("Victory", "All waves cleared.", "Restart", "Start")
		BoardGameSession.FlowState.LOST:
			_show_overlay("Defeat", "Enemies breached the path.", "Restart", "Start")
		BoardGameSession.FlowState.MENU:
			_show_overlay("Paused", "Game paused.", "Resume", "Start")
		BoardGameSession.FlowState.PLAYING:
			_set_overlay_visible(false)


func _sync_map_normal_light() -> void:
	var map_style := _asset_catalog.map_style_definition
	var should_enable := (
		map_style != null
		and map_style.normal_light_enabled
		and not map_style.background_normal_tile_path.is_empty()
	)

	if _map_normal_light == null:
		_map_normal_light = DirectionalLight2D.new()
		_map_normal_light.name = "MapNormalLight"
		add_child(_map_normal_light)

	_map_normal_light.enabled = should_enable
	if not should_enable:
		return

	_map_normal_light.energy = map_style.normal_light_energy
	_map_normal_light.height = map_style.normal_light_height
	_map_normal_light.rotation_degrees = map_style.normal_light_rotation_degrees
	_map_normal_light.color = map_style.normal_light_color


func _enemy_position_for_id(enemy_id: String):
	var enemy := _game_session.get_enemy_by_id(enemy_id)
	if enemy == null:
		return null

	return _board_renderer.enemy_local_position(
		_game_session.path_follower,
		get_layout_metrics().board_origin,
		get_layout_metrics().cell_size,
		enemy
	)


func _grid_space_to_local(grid_space_position: Vector2) -> Vector2:
	var metrics := get_layout_metrics()
	return _board_renderer.grid_space_to_local(metrics.board_origin, metrics.cell_size, grid_space_position)


func _get_tower_sprite_texture(tower_type: GameTower.Type, tower_id: String = "") -> Texture2D:
	return _board_renderer.get_tower_sprite_texture(tower_type, tower_id, _visual_state, _asset_catalog)


func _show_overlay(title: String, message: String, primary_text: String, secondary_text: String) -> void:
	_hud_controller.show_overlay(title, message, primary_text, secondary_text, get_layout_metrics())


func _set_overlay_visible(should_be_visible: bool) -> void:
	_hud_controller.set_overlay_visible(should_be_visible)


func _on_overlay_primary_pressed() -> void:
	match _game_session.flow_state:
		BoardGameSession.FlowState.MENU:
			resume_game()
		BoardGameSession.FlowState.WON, BoardGameSession.FlowState.LOST:
			restart_game()


func _on_overlay_secondary_pressed() -> void:
	if (
		_game_session.flow_state == BoardGameSession.FlowState.MENU
		or _game_session.flow_state == BoardGameSession.FlowState.WON
		or _game_session.flow_state == BoardGameSession.FlowState.LOST
	):
		return_to_start_screen()


func _set_hint(text: String) -> void:
	_game_session.set_hint(text)
	_sync_message_labels()


func _sync_message_labels() -> void:
	_hud_controller.sync_message_labels(_game_session.status_text, _game_session.hint_text)


func _update_selected_tower_hint() -> void:
	_set_hint(_hud_controller.update_selected_tower_hint(
		_game_session.selected_tower_type,
		_game_session.economy_config
	))


func _sync_tower_button_state() -> void:
	_hud_controller.sync_tower_button_state(
		_game_session.flow_state,
		_game_session.selected_tower_type,
		_game_session.wallet,
		_game_session.economy_config,
		Callable(self, "_get_tower_sprite_texture")
	)


func _sync_tower_action_menu() -> void:
	if selected_tower_id.is_empty() or selected_tower_grid_position == INVALID_GRID_POSITION:
		if _hud_controller != null:
			_hud_controller.hide_tower_action_menu()
		return

	var tower := _game_session.get_tower_by_id(selected_tower_id)
	if tower == null:
		clear_tower_action_menu()
		return

	var refund_amount := _game_session.placement_service.removal_refund_amount(tower)
	_hud_controller.show_tower_action_menu(
		tower,
		_game_session.placement_service.tower_config,
		_game_session.wallet,
		refund_amount,
		_tower_action_menu_rect(selected_tower_grid_position),
		_game_session.flow_state
	)


func _sync_menu_button_state() -> void:
	_hud_controller.sync_menu_button_state(_game_session.flow_state)


func _refresh_hud() -> void:
	_hud_controller.update_gold_label(_game_session.wallet)
	_hud_controller.update_lives_label(_game_session.combat_simulation)
	_hud_controller.update_wave_label(_game_session.wave_spawner)
	_sync_menu_button_state()
	_sync_tower_button_state()
	_sync_tower_action_menu()
	_sync_message_labels()


func _update_hover(grid_position: Vector2i) -> void:
	if hover_grid_position == grid_position:
		return

	hover_grid_position = grid_position
	queue_redraw()


func _should_draw_tower_placement_preview() -> bool:
	return (
		_game_session != null
		and _game_session.flow_state == BoardGameSession.FlowState.PLAYING
		and not _game_session.gameplay_paused
	)


func _on_viewport_size_changed() -> void:
	apply_responsive_layout(get_viewport_rect().size)
	queue_redraw()


func _select_tower_if_occupied(grid_position: Vector2i) -> bool:
	if _game_session.board == null or not _game_session.board.is_in_bounds(grid_position):
		return false

	var tower_id := _game_session.board.get_occupant_id(grid_position)
	if tower_id.is_empty():
		return false

	var tower := _game_session.get_tower_by_id(tower_id)
	if tower == null:
		return false

	selected_tower_grid_position = grid_position
	selected_tower_id = tower_id
	_game_session.set_status("%s T%d selected." % [
		_hud_controller.tower_type_label(tower.tower_type),
		tower.tier,
	])
	_game_session.set_hint("Upgrade or remove this tower.")
	_sync_tower_action_menu()
	_sync_message_labels()
	queue_redraw()
	return true


func _sync_combat_tower_selection() -> void:
	var tower := _game_session.get_tower_by_id(selected_tower_id)
	if tower == null:
		clear_tower_action_menu()
		return
	selected_tower_grid_position = tower.grid_position


func _tower_action_menu_rect(grid_position: Vector2i) -> Rect2:
	var metrics := get_layout_metrics()
	var cell_rect := grid_to_local_rect(grid_position)
	var viewport_size := metrics.viewport_size
	var menu_size := BoardHudController.TOWER_ACTION_MENU_SIZE
	var gap := maxf(6.0, metrics.cell_size * 0.08)
	var anchor := to_global(cell_rect.position + Vector2(metrics.cell_size * 0.72, -gap - menu_size.y))
	var min_y := metrics.hud_reserved_height + 4.0
	var max_x := viewport_size.x - menu_size.x - BoardLayoutService.SCREEN_PADDING
	var max_y := viewport_size.y - menu_size.y - BoardLayoutService.SCREEN_PADDING
	var menu_position := Vector2(
		clampf(anchor.x, BoardLayoutService.SCREEN_PADDING, maxf(BoardLayoutService.SCREEN_PADDING, max_x)),
		clampf(anchor.y, min_y, maxf(min_y, max_y))
	)

	return Rect2(menu_position, menu_size)
