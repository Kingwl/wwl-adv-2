class_name BoardView
extends Node2D

const BOARD_WIDTH := 10
const BOARD_HEIGHT := 8
const CELL_SIZE := 128.0
const BOARD_ORIGIN := Vector2(96, 96)
const INVALID_GRID_POSITION := Vector2i(-1, -1)
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
const TOWER_CARD_HEIGHT := 76.0
const TOWER_CARD_GAP := 8.0
const STAT_ICON_SIZE := 30.0
const HUD_CHROME_MARGIN := 8.0
const BOTTOM_TOWER_DECK_ASPECT_THRESHOLD := 1.45
const BOTTOM_TOWER_DECK_GAP := 12.0
const ENEMY_RADIUS_FACTOR := 0.18
const ENEMY_HEALTH_BAR_WIDTH_FACTOR := 0.54
const ENEMY_HEALTH_BAR_HEIGHT_FACTOR := 0.075
const ENEMY_HEALTH_BAR_OFFSET_FACTOR := 0.08
const TOWER_SPRITE_SIZE_FACTOR := 0.88
const ENEMY_SPRITE_SIZE_FACTOR := 0.64
const PROJECTILE_SPRITE_SIZE_FACTOR := 0.46
const IMPACT_SPRITE_SIZE_FACTOR := 0.90
const ATTACK_FEEDBACK_DURATION_SECONDS := 0.18
const TOWER_ATTACK_ANIMATION_SECONDS := 0.32
const ENEMY_WALK_FRAME_SECONDS := 0.16
const ENEMY_DEATH_ANIMATION_SECONDS := 0.54
const START_SCENE_PATH := "res://scenes/start.tscn"

enum FlowState {
	PLAYING,
	MENU,
	WON,
	LOST,
}

@export var status_label_path: NodePath = NodePath("../Hud/Status")
@export var hint_label_path: NodePath = NodePath("../Hud/Hint")
@export var gold_label_path: NodePath = NodePath("../Hud/Gold")
@export var lives_label_path: NodePath = NodePath("../Hud/Lives")
@export var wave_label_path: NodePath = NodePath("../Hud/Wave")
@export var menu_button_path: NodePath = NodePath("../Hud/MenuButton")
@export var single_tower_button_path: NodePath = NodePath("../Hud/SingleTowerButton")
@export var area_tower_button_path: NodePath = NodePath("../Hud/AreaTowerButton")
@export var slow_tower_button_path: NodePath = NodePath("../Hud/SlowTowerButton")
@export var overlay_root_path: NodePath = NodePath("../Overlay/Screen")
@export var overlay_backdrop_path: NodePath = NodePath("../Overlay/Screen/Backdrop")
@export var overlay_panel_path: NodePath = NodePath("../Overlay/Screen/Panel")
@export var overlay_title_path: NodePath = NodePath("../Overlay/Screen/Panel/Title")
@export var overlay_message_path: NodePath = NodePath("../Overlay/Screen/Panel/Message")
@export var overlay_primary_button_path: NodePath = NodePath("../Overlay/Screen/Panel/PrimaryButton")
@export var overlay_secondary_button_path: NodePath = NodePath("../Overlay/Screen/Panel/SecondaryButton")

var board: Board
var wallet: Wallet
var economy_config: EconomyConfig
var placement_service: TowerPlacementService
var combat_simulation: CombatSimulation
var kill_reward_service: KillRewardService
var wave_reward_service: WaveRewardService
var wave_spawner: WaveSpawner
var path_follower: PathFollower
var level_definition: LevelDefinition
var map_style_definition: MapStyleDefinition
var board_map_renderer: BoardMapRenderer
var last_placement_result: PlacementResult
var last_tick_results: Array
var last_reward_transaction_results: Array
var last_wave_reward_transaction_results: Array
var hover_grid_position := INVALID_GRID_POSITION
var cell_size := CELL_SIZE
var board_origin := BOARD_ORIGIN
var attack_feedbacks: Array
var tower_attack_animations: Dictionary
var enemy_death_animations: Array
var visual_elapsed_seconds := 0.0
var flow_state := FlowState.PLAYING
var gameplay_paused := false
var selected_tower_type: GameTower.Type = GameTower.Type.SINGLE_TARGET
var tower_deck_is_bottom := false
var _compact_messages := false
var _status_text := ""
var _hint_text := ""

var _status_label: Label
var _hint_label: Label
var _gold_label: Label
var _lives_label: Label
var _wave_label: Label
var _menu_button: Button
var _single_tower_button: Button
var _area_tower_button: Button
var _slow_tower_button: Button
var _overlay_root: Control
var _overlay_backdrop: ColorRect
var _overlay_panel: Control
var _overlay_title: Label
var _overlay_message: Label
var _overlay_primary_button: Button
var _overlay_secondary_button: Button
var _hud_frame_panel: Panel
var _tower_deck_panel: Panel
var _gold_icon_rect: TextureRect
var _lives_icon_rect: TextureRect
var _wave_icon_rect: TextureRect
var _map_normal_light: DirectionalLight2D
var _asset_catalog: BoardAssetCatalog
var _gold_icon_texture: Texture2D
var _lives_icon_texture: Texture2D
var _wave_icon_texture: Texture2D
var _menu_icon_texture: Texture2D
var _scene_background_texture: Texture2D
var _single_tower_texture: Texture2D
var _area_tower_texture: Texture2D
var _slow_tower_texture: Texture2D
var _basic_enemy_texture: Texture2D
var _single_tower_attack_textures: Array = []
var _area_tower_attack_textures: Array = []
var _slow_tower_attack_textures: Array = []
var _enemy_walk_textures: Array = []
var _enemy_death_textures: Array = []
var _single_projectile_textures: Array = []
var _area_impact_textures: Array = []
var _slow_impact_textures: Array = []


func _ready() -> void:
	_load_level_definition()
	initialize_board()
	initialize_combat()
	_status_label = get_node_or_null(status_label_path) as Label
	_hint_label = get_node_or_null(hint_label_path) as Label
	_gold_label = get_node_or_null(gold_label_path) as Label
	_lives_label = get_node_or_null(lives_label_path) as Label
	_wave_label = get_node_or_null(wave_label_path) as Label
	_menu_button = get_node_or_null(menu_button_path) as Button
	_single_tower_button = get_node_or_null(single_tower_button_path) as Button
	_area_tower_button = get_node_or_null(area_tower_button_path) as Button
	_slow_tower_button = get_node_or_null(slow_tower_button_path) as Button
	_overlay_root = get_node_or_null(overlay_root_path) as Control
	_overlay_backdrop = get_node_or_null(overlay_backdrop_path) as ColorRect
	_overlay_panel = get_node_or_null(overlay_panel_path) as Control
	_overlay_title = get_node_or_null(overlay_title_path) as Label
	_overlay_message = get_node_or_null(overlay_message_path) as Label
	_overlay_primary_button = get_node_or_null(overlay_primary_button_path) as Button
	_overlay_secondary_button = get_node_or_null(overlay_secondary_button_path) as Button
	_load_sprite_assets()
	_sync_map_normal_light()
	_configure_hud_labels()
	_connect_ui_signals()
	_update_responsive_layout()
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)
	_set_status("Select a tower, then click an open tile.")
	_update_selected_tower_hint()
	_update_gold_label()
	_update_lives_label()
	_update_wave_label()
	_sync_tower_button_state()
	start_game()
	queue_redraw()


func _process(delta: float) -> void:
	if combat_simulation == null or gameplay_paused:
		return

	_advance_visual_animations(delta)
	var tick_results := combat_simulation.advance(delta)
	last_tick_results = tick_results
	_advance_attack_feedbacks(delta)
	_spawn_tower_attack_animations(tick_results)
	_spawn_enemy_death_animations(tick_results)
	_spawn_attack_feedback(tick_results)
	_apply_tick_rewards(tick_results)
	_apply_tick_outcome(tick_results)
	_update_lives_label()
	_update_wave_label()
	queue_redraw()


func initialize_board() -> void:
	if level_definition == null:
		_load_level_definition()

	if level_definition != null and level_definition.is_valid():
		board = Board.new(level_definition.grid_width, level_definition.grid_height)
		level_definition.apply_to_board(board)
	else:
		board = Board.new(BOARD_WIDTH, BOARD_HEIGHT)
		board.set_path(get_default_path())

	var path_result := board.validate_path(get_default_path())
	assert(path_result.succeeded, "Default path must be valid.")

	economy_config = EconomyConfig.new()
	wallet = Wallet.new(economy_config.initial_gold)
	placement_service = TowerPlacementService.new(board, wallet, economy_config)
	selected_tower_type = GameTower.Type.SINGLE_TARGET
	placement_service.basic_tower_type = selected_tower_type
	kill_reward_service = KillRewardService.new(wallet)
	wave_reward_service = WaveRewardService.new(wallet)
	last_placement_result = null
	last_tick_results = []
	last_reward_transaction_results = []
	last_wave_reward_transaction_results = []
	hover_grid_position = INVALID_GRID_POSITION
	attack_feedbacks = []
	tower_attack_animations = {}
	enemy_death_animations = []
	visual_elapsed_seconds = 0.0


func initialize_combat() -> void:
	path_follower = PathFollower.new(get_default_path())
	wave_spawner = WaveSpawner.new(get_default_wave_definitions())
	combat_simulation = CombatSimulation.new(
		placement_service.tower_registry.get_all_towers(),
		[],
		path_follower,
		CombatSimulation.DEFAULT_FIXED_STEP_SECONDS,
		null,
		null,
		wave_spawner
	)


func get_default_path() -> Array:
	if level_definition != null and not level_definition.path_cells.is_empty():
		return level_definition.path_cells.duplicate()

	return [
		Vector2i(0, 3),
		Vector2i(1, 3),
		Vector2i(2, 3),
		Vector2i(3, 3),
		Vector2i(4, 3),
		Vector2i(4, 4),
		Vector2i(5, 4),
		Vector2i(6, 4),
		Vector2i(7, 4),
		Vector2i(8, 4),
		Vector2i(9, 4),
	]


func get_default_wave_definitions() -> Array:
	return [
		WaveDefinition.new("wave-1", 5, 0.8, 20.0, 1.0, 5, 20),
		WaveDefinition.new("wave-2", 7, 0.7, 24.0, 1.0, 5, 25),
		WaveDefinition.new("wave-3", 10, 0.6, 30.0, 1.1, 6, 35),
	]


func screen_to_grid_position(screen_position: Vector2) -> Vector2i:
	return local_to_grid_position(to_local(screen_position))


func local_to_grid_position(local_position: Vector2) -> Vector2i:
	var offset := local_position - board_origin
	return Vector2i(floori(offset.x / cell_size), floori(offset.y / cell_size))


func grid_to_local_rect(grid_position: Vector2i) -> Rect2:
	return Rect2(
		board_origin + Vector2(float(grid_position.x) * cell_size, float(grid_position.y) * cell_size),
		Vector2(cell_size, cell_size)
	)


func apply_responsive_layout(viewport_size: Vector2) -> void:
	var board_width := BOARD_WIDTH
	var board_height := BOARD_HEIGHT
	if board != null:
		board_width = board.width
		board_height = board.height

	tower_deck_is_bottom = _should_use_bottom_tower_deck(viewport_size)
	var hud_reserved_height := _hud_reserved_height(viewport_size)
	var tower_reserved_width := 0.0
	var tower_reserved_height := 0.0
	if tower_deck_is_bottom:
		tower_reserved_height = TOWER_CARD_HEIGHT + HUD_CHROME_MARGIN * 2.0 + BOTTOM_TOWER_DECK_GAP
	else:
		tower_reserved_width = TOWER_CARD_WIDTH + SIDE_PANEL_GAP

	var available_width := maxf(
		1.0,
		viewport_size.x - SCREEN_PADDING * 2.0 - tower_reserved_width
	)
	var available_height := maxf(
		1.0,
		viewport_size.y - hud_reserved_height - SCREEN_PADDING - tower_reserved_height
	)
	var fit_cell_size := floorf(minf(
		available_width / float(board_width),
		available_height / float(board_height)
	))

	cell_size = maxf(1.0, fit_cell_size)
	var board_size := Vector2(float(board_width) * cell_size, float(board_height) * cell_size)
	board_origin = Vector2(
		floorf(SCREEN_PADDING + maxf(0.0, (available_width - board_size.x) * 0.5)),
		floorf(hud_reserved_height + maxf(0.0, (available_height - board_size.y) * 0.5))
	)
	_layout_hud(viewport_size)


func _should_use_bottom_tower_deck(viewport_size: Vector2) -> bool:
	if viewport_size.y <= 0.0:
		return false

	return viewport_size.x / viewport_size.y < BOTTOM_TOWER_DECK_ASPECT_THRESHOLD


func _hud_reserved_height(viewport_size: Vector2) -> float:
	if _should_use_bottom_tower_deck(viewport_size) and viewport_size.y <= HUD_COMPACT_MESSAGE_MAX_HEIGHT:
		return HUD_COMPACT_MESSAGE_RESERVED_HEIGHT
	return HUD_RESERVED_HEIGHT


func try_place_at_grid(grid_position: Vector2i) -> TowerPlacementResult:
	placement_service.basic_tower_type = selected_tower_type
	var result := placement_service.try_place_basic_tower(grid_position)
	last_placement_result = result.placement_result

	if result.succeeded:
		_sync_combat_towers()
		_set_status("Placed %s at (%d, %d) for %d gold." % [
			result.tower_id,
			grid_position.x,
			grid_position.y,
			economy_config.basic_tower_cost,
		])
	elif result.placement_result != null:
		_set_status("Cannot place at (%d, %d): %s" % [grid_position.x, grid_position.y, result.placement_result.message])
	else:
		_set_status("Cannot place at (%d, %d): %s" % [grid_position.x, grid_position.y, result.message])

	_update_gold_label()
	queue_redraw()
	return result


func start_game() -> void:
	flow_state = FlowState.PLAYING
	gameplay_paused = false
	_set_overlay_visible(false)
	_sync_menu_button_state()
	_sync_tower_button_state()
	_set_status("Click a green slot to place a tower.")
	_update_selected_tower_hint()
	queue_redraw()


func open_pause_menu() -> void:
	if flow_state != FlowState.PLAYING:
		return

	flow_state = FlowState.MENU
	gameplay_paused = true
	_show_overlay("Paused", "Game paused.", "Resume", "Start")
	_sync_menu_button_state()
	_sync_tower_button_state()


func resume_game() -> void:
	if flow_state != FlowState.MENU:
		return

	flow_state = FlowState.PLAYING
	gameplay_paused = false
	_set_overlay_visible(false)
	_sync_menu_button_state()
	_sync_tower_button_state()
	queue_redraw()


func restart_game() -> void:
	initialize_board()
	initialize_combat()
	_update_gold_label()
	_update_lives_label()
	_update_wave_label()
	_update_selected_tower_hint()
	_sync_tower_button_state()
	start_game()


func return_to_start_screen() -> void:
	gameplay_paused = true
	_sync_tower_button_state()
	get_tree().change_scene_to_file(START_SCENE_PATH)


func show_victory_screen() -> void:
	flow_state = FlowState.WON
	gameplay_paused = true
	_show_overlay("Victory", "All waves cleared.", "Restart", "Start")
	_sync_menu_button_state()
	_sync_tower_button_state()


func show_defeat_screen() -> void:
	flow_state = FlowState.LOST
	gameplay_paused = true
	_show_overlay("Defeat", "Enemies breached the path.", "Restart", "Start")
	_sync_menu_button_state()
	_sync_tower_button_state()


func select_tower_type(tower_type: GameTower.Type) -> void:
	selected_tower_type = tower_type
	if placement_service != null:
		placement_service.basic_tower_type = selected_tower_type

	_update_selected_tower_hint()
	_sync_tower_button_state()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if flow_state == FlowState.PLAYING:
			open_pause_menu()
		elif flow_state == FlowState.MENU:
			resume_game()
		return

	if flow_state != FlowState.PLAYING:
		return

	if event is InputEventMouseMotion:
		_update_hover(screen_to_grid_position(event.position))
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			try_place_at_grid(screen_to_grid_position(mouse_event.position))


func _draw() -> void:
	if board == null:
		return

	_draw_scene_background()
	_draw_board_shadow()
	_draw_board_background()

	for y in range(board.height):
		for x in range(board.width):
			var grid_position := Vector2i(x, y)
			var slot := board.get_slot(grid_position)
			_draw_slot(grid_position, slot)

	_draw_enemies()
	_draw_projectiles()
	_draw_attack_feedbacks()


func _draw_scene_background() -> void:
	var viewport_rect := get_viewport_rect()
	if _scene_background_texture != null:
		draw_texture_rect(_scene_background_texture, viewport_rect, true, Color(0.46, 0.56, 0.66, 1.0))
		draw_rect(viewport_rect, Color(0.006, 0.012, 0.016, 0.42), true)
		return

	draw_rect(viewport_rect, Color(0.035, 0.045, 0.055, 1.0), true)


func _board_rect() -> Rect2:
	return Rect2(
		board_origin,
		Vector2(float(board.width) * cell_size, float(board.height) * cell_size)
	)


func _draw_board_shadow() -> void:
	var shadow_padding := maxf(4.0, cell_size * 0.125)
	var shadow_rect := _board_rect().grow(shadow_padding)
	draw_rect(shadow_rect, Color(0.06, 0.07, 0.08, 1.0), true)


func _draw_board_background() -> void:
	var board_rect := _board_rect()
	if board_map_renderer != null and map_style_definition != null:
		board_map_renderer.draw_board(self, board, map_style_definition, board_origin, cell_size)
		return

	draw_rect(board_rect, Color(0.15, 0.17, 0.16, 1.0), true)


func _draw_slot(grid_position: Vector2i, slot: BoardSlot) -> void:
	var rect := grid_to_local_rect(grid_position)
	var inner_rect := rect.grow(-1)

	if slot.occupant_id != "":
		_draw_tower_sprite(slot.occupant_id, inner_rect)

	if grid_position == hover_grid_position:
		var outline_color := Color(0.85, 0.95, 1.0, 1.0)
		if not board.is_in_bounds(grid_position) or not slot.is_buildable() or not slot.is_empty():
			outline_color = Color(1.0, 0.30, 0.24, 1.0)
		draw_rect(inner_rect.grow(-1), outline_color, false, 3.0)

	if last_placement_result != null and grid_position == last_placement_result.position and not last_placement_result.succeeded:
		draw_rect(inner_rect.grow(-2), Color(1.0, 0.18, 0.15, 1.0), false, 4.0)


func _draw_tower_sprite(tower_id: String, slot_rect: Rect2) -> void:
	var tower := _get_tower_by_id(tower_id)
	var tower_type := GameTower.Type.SINGLE_TARGET
	if tower != null:
		tower_type = tower.tower_type

	var texture := get_tower_sprite_texture(tower_type, tower_id)
	if texture != null:
		draw_circle(slot_rect.get_center() + Vector2(0.0, cell_size * 0.16), cell_size * 0.25, Color(0.04, 0.035, 0.03, 0.45))
		_draw_sprite_texture(texture, slot_rect.get_center(), cell_size * TOWER_SPRITE_SIZE_FACTOR)
		return

	draw_circle(slot_rect.get_center(), cell_size * 0.25, _tower_fill_color(tower_id))
	draw_circle(slot_rect.get_center(), cell_size * 0.14, Color(0.15, 0.25, 0.32, 1.0))


func _draw_enemies() -> void:
	for enemy in get_visible_enemies():
		_draw_enemy(enemy)

	_draw_enemy_death_animations()


func _draw_enemy(enemy: Enemy) -> void:
	if enemy == null or path_follower == null:
		return

	var enemy_position := _enemy_local_position(enemy)
	var radius := _enemy_radius()
	var texture := get_enemy_sprite_texture(enemy)

	if texture != null:
		draw_circle(enemy_position + Vector2(0.0, radius * 0.48), radius * 0.92, Color(0.04, 0.035, 0.03, 0.55))
		_draw_sprite_texture(texture, enemy_position, cell_size * ENEMY_SPRITE_SIZE_FACTOR)
	else:
		draw_circle(enemy_position, radius + 3.0, Color(0.08, 0.07, 0.06, 0.9))
		draw_circle(enemy_position, radius, Color(0.88, 0.20, 0.16, 1.0))
		draw_circle(enemy_position + Vector2(-5, -5), radius * 0.32, Color(1.0, 0.62, 0.38, 1.0))
	_draw_enemy_health_bar(enemy)


func _draw_enemy_death_animations() -> void:
	for animation in enemy_death_animations:
		var death_position: Vector2 = animation.get("position", Vector2.ZERO)
		var elapsed: float = animation.get("elapsed", 0.0)
		var duration: float = animation.get("duration", ENEMY_DEATH_ANIMATION_SECONDS)
		var progress := clampf(elapsed / duration, 0.0, 0.9999)
		var alpha := 1.0
		if progress > 0.74:
			alpha = 1.0 - ((progress - 0.74) / 0.26)

		var texture := _texture_for_progress(_enemy_death_textures, progress)
		if texture != null:
			_draw_sprite_texture(texture, death_position, cell_size * ENEMY_SPRITE_SIZE_FACTOR, Color(1.0, 1.0, 1.0, alpha))


func _draw_enemy_health_bar(enemy: Enemy) -> void:
	var bar_rect := get_enemy_health_bar_rect(enemy)
	if bar_rect.size.x <= 0.0 or bar_rect.size.y <= 0.0:
		return

	var ratio := get_enemy_health_ratio(enemy)
	var inset := maxf(1.0, floorf(cell_size * 0.018))
	var fill_size := Vector2(maxf(0.0, (bar_rect.size.x - inset * 2.0) * ratio), maxf(0.0, bar_rect.size.y - inset * 2.0))
	var fill_rect := Rect2(bar_rect.position + Vector2(inset, inset), fill_size)

	draw_rect(bar_rect, Color(0.04, 0.05, 0.05, 0.92), true)
	draw_rect(fill_rect, _enemy_health_bar_fill_color(ratio), true)
	draw_rect(bar_rect, Color(0.01, 0.015, 0.018, 1.0), false, maxf(1.0, floorf(cell_size * 0.018)))


func _draw_projectiles() -> void:
	if combat_simulation == null:
		return

	for candidate in combat_simulation.projectiles:
		var projectile := candidate as CombatProjectile
		if projectile == null or not projectile.active:
			continue

		_draw_projectile(projectile)


func _draw_projectile(projectile: CombatProjectile) -> void:
	var projectile_position := _grid_space_to_local(projectile.position)
	var texture := get_projectile_texture(projectile)
	if texture != null:
		var direction := _projectile_draw_rotation(projectile)
		_draw_oriented_sprite_texture(texture, projectile_position, cell_size * PROJECTILE_SPRITE_SIZE_FACTOR, direction)


func _draw_attack_feedbacks() -> void:
	for feedback in attack_feedbacks:
		var elapsed: float = feedback.get("elapsed", 0.0)
		var duration: float = feedback.get("duration", ATTACK_FEEDBACK_DURATION_SECONDS)
		var progress := clampf(elapsed / duration, 0.0, 1.0)
		var alpha := 1.0 - progress
		var impact_position: Vector2 = feedback.get("position", Vector2.ZERO)
		var color: Color = feedback.get("color", Color(1.0, 0.86, 0.25, 1.0))
		var tower_type: GameTower.Type = feedback.get("tower_type", GameTower.Type.SINGLE_TARGET)

		var impact_texture := get_attack_feedback_texture(tower_type, progress)
		if impact_texture != null:
			_draw_sprite_texture(impact_texture, impact_position, cell_size * IMPACT_SPRITE_SIZE_FACTOR, Color(1.0, 1.0, 1.0, alpha))
		else:
			draw_circle(impact_position, maxf(2.0, cell_size * 0.08), Color(color.r, color.g, color.b, alpha))


func _slot_fill_color(slot: BoardSlot) -> Color:
	match slot.slot_type:
		BoardSlot.Type.BUILDABLE:
			return Color(0.34, 0.52, 0.34, 0.0)
		BoardSlot.Type.PATH:
			return Color(0.76, 0.76, 0.70, 0.0)
		BoardSlot.Type.BLOCKED:
			return Color(0.16, 0.18, 0.18, 0.0)
		BoardSlot.Type.LOCKED:
			return Color(0.34, 0.30, 0.40, 0.0)

	return Color(0.22, 0.24, 0.24, 0.0)


func _slot_border_color(slot: BoardSlot) -> Color:
	match slot.slot_type:
		BoardSlot.Type.PATH:
			return Color(0.78, 0.78, 0.72, 0.0)
		BoardSlot.Type.BUILDABLE:
			return Color(0.62, 0.72, 0.58, 0.0)
		BoardSlot.Type.BLOCKED:
			return Color(0.08, 0.09, 0.09, 0.0)
		BoardSlot.Type.LOCKED:
			return Color(0.58, 0.50, 0.70, 0.0)

	return Color(0.50, 0.54, 0.54, 0.0)


func _update_hover(grid_position: Vector2i) -> void:
	if hover_grid_position == grid_position:
		return

	hover_grid_position = grid_position
	queue_redraw()


func _on_viewport_size_changed() -> void:
	_update_responsive_layout()
	queue_redraw()


func _update_responsive_layout() -> void:
	apply_responsive_layout(get_viewport_rect().size)


func _configure_hud_labels() -> void:
	_ensure_hud_chrome()
	FrostRtsTheme.apply_hud_panel(_hud_frame_panel)
	FrostRtsTheme.apply_hud_panel(_tower_deck_panel)

	for label in [_gold_label, _lives_label, _wave_label]:
		if label == null:
			continue

		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_stat_label(label)

	for label in [_status_label, _hint_label]:
		if label == null:
			continue

		label.clip_text = true
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_body_label(label, 14, FrostRtsTheme.TEXT_DIM)

	FrostRtsTheme.apply_title_label(_overlay_title, 28)
	FrostRtsTheme.apply_body_label(_overlay_message, 16, FrostRtsTheme.TEXT)
	FrostRtsTheme.apply_backdrop(_overlay_backdrop, 0.78)
	FrostRtsTheme.apply_overlay_panel(_overlay_panel)

	if _overlay_title != null:
		_overlay_title.clip_text = true
		_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_overlay_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _overlay_message != null:
		_overlay_message.clip_text = true
		_overlay_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_overlay_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	FrostRtsTheme.apply_button(_menu_button, 14)
	if _menu_button != null:
		_menu_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_menu_button.icon = _menu_icon_texture
		_menu_button.expand_icon = true
		_menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_menu_button.add_theme_constant_override("icon_max_width", 22)
		_menu_button.add_theme_constant_override("h_separation", 8)

	for button in [_single_tower_button, _area_tower_button, _slow_tower_button]:
		if button == null:
			continue

		button.clip_text = true
		button.toggle_mode = true
		FrostRtsTheme.apply_tower_button(button)

	for button in [_overlay_primary_button, _overlay_secondary_button]:
		FrostRtsTheme.apply_button(button, 15)


func _connect_ui_signals() -> void:
	if _menu_button != null and not _menu_button.pressed.is_connected(_on_menu_button_pressed):
		_menu_button.pressed.connect(_on_menu_button_pressed)

	if _single_tower_button != null and not _single_tower_button.pressed.is_connected(_on_single_tower_button_pressed):
		_single_tower_button.pressed.connect(_on_single_tower_button_pressed)

	if _area_tower_button != null and not _area_tower_button.pressed.is_connected(_on_area_tower_button_pressed):
		_area_tower_button.pressed.connect(_on_area_tower_button_pressed)

	if _slow_tower_button != null and not _slow_tower_button.pressed.is_connected(_on_slow_tower_button_pressed):
		_slow_tower_button.pressed.connect(_on_slow_tower_button_pressed)

	if _overlay_primary_button != null and not _overlay_primary_button.pressed.is_connected(_on_overlay_primary_pressed):
		_overlay_primary_button.pressed.connect(_on_overlay_primary_pressed)

	if _overlay_secondary_button != null and not _overlay_secondary_button.pressed.is_connected(_on_overlay_secondary_pressed):
		_overlay_secondary_button.pressed.connect(_on_overlay_secondary_pressed)


func _ensure_hud_chrome() -> void:
	var hud_parent: Node = null
	if _gold_label != null:
		hud_parent = _gold_label.get_parent()
	if hud_parent == null:
		return

	_hud_frame_panel = _ensure_hud_panel(hud_parent, "HudFrame")
	_tower_deck_panel = _ensure_hud_panel(hud_parent, "TowerDeck")
	_gold_icon_rect = _ensure_hud_icon(hud_parent, "GoldIcon", _gold_icon_texture)
	_lives_icon_rect = _ensure_hud_icon(hud_parent, "LivesIcon", _lives_icon_texture)
	_wave_icon_rect = _ensure_hud_icon(hud_parent, "WaveIcon", _wave_icon_texture)


func _ensure_hud_panel(parent: Node, node_name: String) -> Panel:
	var panel := parent.get_node_or_null(node_name) as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = node_name
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		parent.move_child(panel, 0)

	return panel


func _ensure_hud_icon(parent: Node, node_name: String, texture: Texture2D) -> TextureRect:
	var icon := parent.get_node_or_null(node_name) as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parent.add_child(icon)

	icon.texture = texture
	return icon


func _load_level_definition() -> void:
	_ensure_asset_catalog()
	_asset_catalog.load_level_definition()
	_sync_asset_catalog()


func _load_map_style_assets() -> void:
	_ensure_asset_catalog()
	_asset_catalog.load_map_style_assets()
	_sync_asset_catalog()


func _load_sprite_assets() -> void:
	_ensure_asset_catalog()
	_asset_catalog.load_all()
	_sync_asset_catalog()


func _ensure_asset_catalog() -> void:
	if _asset_catalog == null:
		_asset_catalog = BoardAssetCatalog.new()


func _sync_asset_catalog() -> void:
	if _asset_catalog == null:
		return

	level_definition = _asset_catalog.level_definition
	map_style_definition = _asset_catalog.map_style_definition
	board_map_renderer = _asset_catalog.board_map_renderer
	_gold_icon_texture = _asset_catalog.gold_icon_texture
	_lives_icon_texture = _asset_catalog.lives_icon_texture
	_wave_icon_texture = _asset_catalog.wave_icon_texture
	_menu_icon_texture = _asset_catalog.menu_icon_texture
	_scene_background_texture = _asset_catalog.scene_background_texture
	_single_tower_texture = _asset_catalog.single_tower_texture
	_area_tower_texture = _asset_catalog.area_tower_texture
	_slow_tower_texture = _asset_catalog.slow_tower_texture
	_basic_enemy_texture = _asset_catalog.basic_enemy_texture
	_single_tower_attack_textures = _asset_catalog.single_tower_attack_textures
	_area_tower_attack_textures = _asset_catalog.area_tower_attack_textures
	_slow_tower_attack_textures = _asset_catalog.slow_tower_attack_textures
	_enemy_walk_textures = _asset_catalog.enemy_walk_textures
	_enemy_death_textures = _asset_catalog.enemy_death_textures
	_single_projectile_textures = _asset_catalog.single_projectile_textures
	_area_impact_textures = _asset_catalog.area_impact_textures
	_slow_impact_textures = _asset_catalog.slow_impact_textures


func _sync_map_normal_light() -> void:
	var should_enable := (
		map_style_definition != null
		and map_style_definition.normal_light_enabled
		and not map_style_definition.background_normal_tile_path.is_empty()
	)

	if _map_normal_light == null:
		_map_normal_light = DirectionalLight2D.new()
		_map_normal_light.name = "MapNormalLight"
		add_child(_map_normal_light)

	_map_normal_light.enabled = should_enable
	if not should_enable:
		return

	_map_normal_light.energy = map_style_definition.normal_light_energy
	_map_normal_light.height = map_style_definition.normal_light_height
	_map_normal_light.rotation_degrees = map_style_definition.normal_light_rotation_degrees
	_map_normal_light.color = map_style_definition.normal_light_color


func _layout_hud(viewport_size: Vector2) -> void:
	var stat_top := HUD_STAT_ROW_TOP
	var message_top := HUD_MESSAGE_ROW_TOP
	var left := SCREEN_PADDING
	var gap := HUD_ROW_GAP
	var hud_reserved_height := _hud_reserved_height(viewport_size)
	var menu_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
	var content_right := menu_left - SIDE_PANEL_GAP
	var stat_width := minf(124.0, maxf(104.0, (content_right - left) / 5.4))

	_set_control_rect(
		_hud_frame_panel,
		Rect2(
			HUD_CHROME_MARGIN,
			HUD_CHROME_MARGIN,
			maxf(1.0, viewport_size.x - HUD_CHROME_MARGIN * 2.0),
			hud_reserved_height - HUD_CHROME_MARGIN
		)
	)

	_layout_stat(_gold_icon_rect, _gold_label, Vector2(left, stat_top), stat_width)
	_layout_stat(_lives_icon_rect, _lives_label, Vector2(left + stat_width + gap, stat_top), stat_width)
	_layout_stat(_wave_icon_rect, _wave_label, Vector2(left + (stat_width + gap) * 2.0, stat_top), stat_width + 22.0)
	_set_label_rect(_menu_button, Rect2(menu_left, stat_top, TOWER_CARD_WIDTH, HUD_ROW_HEIGHT))
	_layout_tower_deck(viewport_size)

	var message_left := left + (stat_width + gap) * 3.0 + gap
	var message_width := content_right - message_left
	_compact_messages = message_width < HUD_INLINE_MESSAGE_MIN_WIDTH
	if message_width >= HUD_INLINE_MESSAGE_MIN_WIDTH:
		_set_message_label_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		_set_label_rect(_status_label, Rect2(message_left, message_top, message_width, HUD_MESSAGE_ROW_HEIGHT))
		_set_label_rect(_hint_label, Rect2(message_left, message_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, message_width, HUD_MESSAGE_ROW_HEIGHT))
	elif tower_deck_is_bottom:
		_set_message_label_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		var compact_message_width := viewport_size.x - SCREEN_PADDING * 2.0
		var compact_status_top := message_top + HUD_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP
		_set_label_rect(_status_label, Rect2(left, compact_status_top, compact_message_width, HUD_MESSAGE_ROW_HEIGHT))
		_set_label_rect(_hint_label, Rect2(left, compact_status_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, compact_message_width, HUD_MESSAGE_ROW_HEIGHT))
	else:
		_set_message_label_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		var side_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
		var tower_buttons_bottom := HUD_RESERVED_HEIGHT + TOWER_CARD_HEIGHT * 3.0 + TOWER_CARD_GAP * 2.0
		var side_message_top := minf(
			tower_buttons_bottom + HUD_CHROME_MARGIN + 4.0,
			viewport_size.y - SCREEN_PADDING - HUD_MESSAGE_ROW_HEIGHT * 2.0 - HUD_MESSAGE_ROW_GAP
		)
		_set_label_rect(_status_label, Rect2(side_left, side_message_top, TOWER_CARD_WIDTH, HUD_MESSAGE_ROW_HEIGHT))
		_set_label_rect(_hint_label, Rect2(side_left, side_message_top + HUD_MESSAGE_ROW_HEIGHT + HUD_MESSAGE_ROW_GAP, TOWER_CARD_WIDTH, HUD_MESSAGE_ROW_HEIGHT))

	_sync_message_labels()
	_layout_overlay(viewport_size)


func _layout_tower_deck(viewport_size: Vector2) -> void:
	if tower_deck_is_bottom:
		var total_width := TOWER_CARD_WIDTH * 3.0 + TOWER_CARD_GAP * 2.0
		var deck_left := floorf((viewport_size.x - total_width) * 0.5)
		var deck_top := viewport_size.y - SCREEN_PADDING - TOWER_CARD_HEIGHT
		_set_control_rect(
			_tower_deck_panel,
			Rect2(
				deck_left - HUD_CHROME_MARGIN,
				deck_top - HUD_CHROME_MARGIN,
				total_width + HUD_CHROME_MARGIN * 2.0,
				TOWER_CARD_HEIGHT + HUD_CHROME_MARGIN * 2.0
			)
		)
		_set_label_rect(_single_tower_button, Rect2(deck_left, deck_top, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))
		_set_label_rect(_area_tower_button, Rect2(deck_left + TOWER_CARD_WIDTH + TOWER_CARD_GAP, deck_top, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))
		_set_label_rect(_slow_tower_button, Rect2(deck_left + (TOWER_CARD_WIDTH + TOWER_CARD_GAP) * 2.0, deck_top, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))
		return

	var panel_left := viewport_size.x - SCREEN_PADDING - TOWER_CARD_WIDTH
	var tower_top := _hud_reserved_height(viewport_size)
	_set_control_rect(
		_tower_deck_panel,
		Rect2(
			panel_left - HUD_CHROME_MARGIN,
			tower_top - HUD_CHROME_MARGIN,
			TOWER_CARD_WIDTH + HUD_CHROME_MARGIN * 2.0,
			TOWER_CARD_HEIGHT * 3.0 + TOWER_CARD_GAP * 2.0 + HUD_CHROME_MARGIN * 2.0
		)
	)
	_set_label_rect(_single_tower_button, Rect2(panel_left, tower_top, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))
	_set_label_rect(_area_tower_button, Rect2(panel_left, tower_top + TOWER_CARD_HEIGHT + TOWER_CARD_GAP, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))
	_set_label_rect(_slow_tower_button, Rect2(panel_left, tower_top + (TOWER_CARD_HEIGHT + TOWER_CARD_GAP) * 2.0, TOWER_CARD_WIDTH, TOWER_CARD_HEIGHT))


func _set_message_label_alignment(alignment: HorizontalAlignment) -> void:
	for label in [_status_label, _hint_label]:
		if label != null:
			label.horizontal_alignment = alignment


func _layout_stat(icon: TextureRect, label: Label, stat_position: Vector2, width: float) -> void:
	var icon_top := stat_position.y + floorf((HUD_ROW_HEIGHT - STAT_ICON_SIZE) * 0.5)
	_set_control_rect(icon, Rect2(stat_position.x, icon_top, STAT_ICON_SIZE, STAT_ICON_SIZE))
	_set_label_rect(label, Rect2(stat_position.x + STAT_ICON_SIZE + 6.0, stat_position.y, width - STAT_ICON_SIZE - 6.0, HUD_ROW_HEIGHT))


func _set_label_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return

	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return

	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _layout_overlay(viewport_size: Vector2) -> void:
	_set_control_rect(_overlay_root, Rect2(Vector2.ZERO, viewport_size))
	_set_control_rect(_overlay_backdrop, Rect2(Vector2.ZERO, viewport_size))

	var panel_width := minf(500.0, viewport_size.x - SCREEN_PADDING * 2.0)
	var panel_height := minf(244.0, viewport_size.y - SCREEN_PADDING * 2.0)
	var panel_position := Vector2(
		floorf((viewport_size.x - panel_width) * 0.5),
		floorf((viewport_size.y - panel_height) * 0.5)
	)
	_set_control_rect(_overlay_panel, Rect2(panel_position, Vector2(panel_width, panel_height)))

	var inner_left := 28.0
	var inner_width := panel_width - inner_left * 2.0
	_set_label_rect(_overlay_title, Rect2(inner_left, 26.0, inner_width, 38.0))
	_set_label_rect(_overlay_message, Rect2(inner_left, 76.0, inner_width, 64.0))

	var button_width := minf(150.0, inner_width)
	var button_height := 36.0
	var button_gap := 12.0
	var total_button_width := button_width
	if _overlay_secondary_button != null and _overlay_secondary_button.visible:
		total_button_width = button_width * 2.0 + button_gap

	var button_left := floorf((panel_width - total_button_width) * 0.5)
	var button_top := panel_height - 62.0
	_set_label_rect(_overlay_primary_button, Rect2(button_left, button_top, button_width, button_height))

	if _overlay_secondary_button != null and _overlay_secondary_button.visible:
		_set_label_rect(
			_overlay_secondary_button,
			Rect2(button_left + button_width + button_gap, button_top, button_width, button_height)
		)


func _advance_visual_animations(delta_seconds: float) -> void:
	visual_elapsed_seconds += delta_seconds
	_advance_tower_attack_animations(delta_seconds)
	_advance_enemy_death_animations(delta_seconds)


func _advance_tower_attack_animations(delta_seconds: float) -> void:
	if tower_attack_animations.is_empty():
		return

	for tower_id in tower_attack_animations.keys():
		var animation: Dictionary = tower_attack_animations.get(tower_id, {})
		var elapsed: float = animation.get("elapsed", 0.0) + delta_seconds
		var duration: float = animation.get("duration", TOWER_ATTACK_ANIMATION_SECONDS)
		if elapsed >= duration:
			tower_attack_animations.erase(tower_id)
			continue

		animation["elapsed"] = elapsed
		tower_attack_animations[tower_id] = animation


func _advance_enemy_death_animations(delta_seconds: float) -> void:
	if enemy_death_animations.is_empty():
		return

	var active_animations := []
	for animation in enemy_death_animations:
		var elapsed: float = animation.get("elapsed", 0.0) + delta_seconds
		var duration: float = animation.get("duration", ENEMY_DEATH_ANIMATION_SECONDS)
		if elapsed >= duration:
			continue

		animation["elapsed"] = elapsed
		active_animations.append(animation)

	enemy_death_animations = active_animations


func _spawn_tower_attack_animations(tick_results: Array) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		for attack_candidate in tick_result.attack_results:
			var attack_result := attack_candidate as AttackResult
			if attack_result == null or not attack_result.succeeded or attack_result.tower_id.is_empty():
				continue

			tower_attack_animations[attack_result.tower_id] = {
				"elapsed": 0.0,
				"duration": TOWER_ATTACK_ANIMATION_SECONDS,
			}


func _spawn_enemy_death_animations(tick_results: Array) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null or tick_result.damage_result == null:
			continue

		for death_candidate in tick_result.damage_result.death_events:
			var death_event := death_candidate as EnemyDeathEvent
			if death_event == null:
				continue

			var enemy := _get_enemy_by_id(death_event.enemy_id)
			if enemy == null:
				continue

			enemy_death_animations.append({
				"position": _enemy_local_position(enemy),
				"elapsed": 0.0,
				"duration": ENEMY_DEATH_ANIMATION_SECONDS,
			})


func _spawn_attack_feedback(tick_results: Array) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		for impact_candidate in tick_result.projectile_impact_events:
			var impact_event := impact_candidate as ProjectileImpactEvent
			if impact_event == null or not impact_event.hit:
				continue

			attack_feedbacks.append({
				"position": _grid_space_to_local(impact_event.position),
				"elapsed": 0.0,
				"duration": ATTACK_FEEDBACK_DURATION_SECONDS,
				"color": _impact_feedback_color(impact_event.tower_type),
				"tower_type": impact_event.tower_type,
			})


func _advance_attack_feedbacks(delta_seconds: float) -> void:
	if attack_feedbacks.is_empty():
		return

	var active_feedbacks := []
	for feedback in attack_feedbacks:
		var elapsed: float = feedback.get("elapsed", 0.0) + delta_seconds
		var duration: float = feedback.get("duration", ATTACK_FEEDBACK_DURATION_SECONDS)
		if elapsed >= duration:
			continue

		feedback["elapsed"] = elapsed
		active_feedbacks.append(feedback)

	attack_feedbacks = active_feedbacks


func _advance_attack_feedback(delta_seconds: float) -> void:
	_advance_attack_feedbacks(delta_seconds)


func _get_tower_by_id(tower_id: String) -> GameTower:
	if placement_service != null and placement_service.tower_registry != null:
		var placed_tower := placement_service.tower_registry.get_tower(tower_id)
		if placed_tower != null:
			return placed_tower

	if combat_simulation != null:
		for candidate in combat_simulation.towers:
			var tower := candidate as GameTower
			if tower != null and tower.id == tower_id:
				return tower

	return null


func _get_enemy_by_id(enemy_id: String) -> Enemy:
	if combat_simulation == null:
		return null

	for candidate in combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy != null and enemy.id == enemy_id:
			return enemy

	return null


func _enemy_local_position(enemy: Enemy) -> Vector2:
	return _grid_space_to_local(path_follower.get_grid_space_position(enemy))


func _grid_space_to_local(grid_space_position: Vector2) -> Vector2:
	return board_origin + grid_space_position * cell_size


func get_tower_sprite_texture(tower_type: GameTower.Type, tower_id: String = "") -> Texture2D:
	if not tower_id.is_empty() and tower_attack_animations.has(tower_id):
		var animation: Dictionary = tower_attack_animations.get(tower_id, {})
		var elapsed: float = animation.get("elapsed", 0.0)
		var duration: float = animation.get("duration", TOWER_ATTACK_ANIMATION_SECONDS)
		var progress := clampf(elapsed / duration, 0.0, 0.9999)
		var attack_texture := _texture_for_progress(_tower_attack_textures_for_type(tower_type), progress)
		if attack_texture != null:
			return attack_texture

	match tower_type:
		GameTower.Type.AREA:
			return _area_tower_texture
		GameTower.Type.SLOW:
			return _slow_tower_texture

	return _single_tower_texture


func get_enemy_sprite_texture(enemy: Enemy = null) -> Texture2D:
	if not _enemy_walk_textures.is_empty():
		var animation_position := visual_elapsed_seconds
		if enemy != null:
			animation_position += enemy.path_distance * 0.08
		var frame_index := floori(fmod(animation_position / ENEMY_WALK_FRAME_SECONDS, float(_enemy_walk_textures.size())))
		return _enemy_walk_textures[frame_index] as Texture2D

	return _basic_enemy_texture


func get_level_definition() -> LevelDefinition:
	return level_definition


func get_map_style_definition() -> MapStyleDefinition:
	return map_style_definition


func _tower_attack_textures_for_type(tower_type: GameTower.Type) -> Array:
	match tower_type:
		GameTower.Type.AREA:
			return _area_tower_attack_textures
		GameTower.Type.SLOW:
			return _slow_tower_attack_textures

	return _single_tower_attack_textures


func get_attack_feedback_texture(tower_type: GameTower.Type, progress: float) -> Texture2D:
	match tower_type:
		GameTower.Type.AREA:
			return _texture_for_progress(_area_impact_textures, progress)
		GameTower.Type.SLOW:
			return _texture_for_progress(_slow_impact_textures, progress)

	return _texture_for_progress(_single_projectile_textures, progress)


func get_projectile_texture(projectile: CombatProjectile) -> Texture2D:
	if projectile == null:
		return null

	var progress := fmod(projectile.elapsed_seconds / 0.24, 1.0)
	return get_attack_feedback_texture(projectile.tower_type, progress)


func _projectile_draw_rotation(projectile: CombatProjectile) -> float:
	if projectile == null or path_follower == null:
		return 0.0

	var target := _get_enemy_by_id(projectile.target_enemy_id)
	if target == null:
		return 0.0

	var target_position := path_follower.get_grid_space_position(target)
	return projectile.position.angle_to_point(target_position)


func _texture_for_progress(textures: Array, progress: float) -> Texture2D:
	if textures.is_empty():
		return null

	var index := clampi(floori(clampf(progress, 0.0, 0.9999) * float(textures.size())), 0, textures.size() - 1)
	return textures[index] as Texture2D


func _draw_sprite_texture(texture: Texture2D, center: Vector2, max_size: float, draw_modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return

	draw_texture_rect(texture, _sprite_draw_rect(texture, center, max_size), false, draw_modulate)


func _draw_oriented_sprite_texture(texture: Texture2D, center: Vector2, max_size: float, draw_rotation: float, draw_modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return

	var rect := _sprite_draw_rect(texture, Vector2.ZERO, max_size)
	draw_set_transform(center, draw_rotation, Vector2.ONE)
	draw_texture_rect(texture, rect, false, draw_modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sprite_draw_rect(texture: Texture2D, center: Vector2, max_size: float) -> Rect2:
	if texture == null:
		return Rect2(center, Vector2.ZERO)

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or max_size <= 0.0:
		return Rect2(center, Vector2.ZERO)

	var draw_scale := minf(max_size / texture_size.x, max_size / texture_size.y)
	var draw_size := texture_size * draw_scale
	return Rect2(center - draw_size * 0.5, draw_size)


func get_enemy_health_ratio(enemy: Enemy) -> float:
	if enemy == null or enemy.max_health <= 0.0:
		return 0.0

	return clampf(enemy.health / enemy.max_health, 0.0, 1.0)


func get_enemy_health_bar_rect(enemy: Enemy) -> Rect2:
	if enemy == null or path_follower == null:
		return Rect2()

	var enemy_position := _enemy_local_position(enemy)
	var bar_width := maxf(18.0, cell_size * ENEMY_HEALTH_BAR_WIDTH_FACTOR)
	var bar_height := maxf(4.0, cell_size * ENEMY_HEALTH_BAR_HEIGHT_FACTOR)
	var bar_offset := maxf(4.0, cell_size * ENEMY_HEALTH_BAR_OFFSET_FACTOR)
	var bar_position := Vector2(
		enemy_position.x - bar_width * 0.5,
		enemy_position.y - _enemy_radius() - bar_offset - bar_height
	)

	return Rect2(bar_position, Vector2(bar_width, bar_height))


func _enemy_radius() -> float:
	return cell_size * ENEMY_RADIUS_FACTOR


func _enemy_health_bar_fill_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.22, 0.82, 0.30, 1.0)
	if ratio > 0.25:
		return Color(1.0, 0.78, 0.22, 1.0)

	return Color(0.92, 0.18, 0.15, 1.0)


func _impact_feedback_color(tower_type: GameTower.Type) -> Color:
	match tower_type:
		GameTower.Type.AREA:
			return Color(1.0, 0.48, 0.18, 1.0)
		GameTower.Type.SLOW:
			return Color(0.35, 0.70, 1.0, 1.0)

	return Color(1.0, 0.86, 0.25, 1.0)


func _tower_fill_color(tower_id: String) -> Color:
	var tower := _get_tower_by_id(tower_id)
	if tower == null:
		return Color(0.95, 0.75, 0.30, 1.0)

	match tower.tower_type:
		GameTower.Type.AREA:
			return Color(1.0, 0.52, 0.24, 1.0)
		GameTower.Type.SLOW:
			return Color(0.38, 0.70, 1.0, 1.0)

	return Color(0.95, 0.75, 0.30, 1.0)


func _show_overlay(title: String, message: String, primary_text: String, secondary_text: String) -> void:
	if _overlay_title != null:
		_overlay_title.text = title

	if _overlay_message != null:
		_overlay_message.text = message

	if _overlay_primary_button != null:
		_overlay_primary_button.text = primary_text
		_overlay_primary_button.visible = not primary_text.is_empty()

	if _overlay_secondary_button != null:
		_overlay_secondary_button.text = secondary_text
		_overlay_secondary_button.visible = not secondary_text.is_empty()

	_layout_overlay(get_viewport_rect().size)
	_set_overlay_visible(true)


func _set_overlay_visible(should_be_visible: bool) -> void:
	if _overlay_root != null:
		_overlay_root.visible = should_be_visible


func _sync_menu_button_state() -> void:
	if _menu_button == null:
		return

	_menu_button.disabled = flow_state != FlowState.PLAYING


func _on_menu_button_pressed() -> void:
	open_pause_menu()


func _on_single_tower_button_pressed() -> void:
	select_tower_type(GameTower.Type.SINGLE_TARGET)


func _on_area_tower_button_pressed() -> void:
	select_tower_type(GameTower.Type.AREA)


func _on_slow_tower_button_pressed() -> void:
	select_tower_type(GameTower.Type.SLOW)


func _on_overlay_primary_pressed() -> void:
	match flow_state:
		FlowState.MENU:
			resume_game()
		FlowState.WON, FlowState.LOST:
			restart_game()


func _on_overlay_secondary_pressed() -> void:
	if flow_state == FlowState.MENU or flow_state == FlowState.WON or flow_state == FlowState.LOST:
		return_to_start_screen()


func _set_status(text: String) -> void:
	_status_text = text
	_sync_message_labels()


func _set_hint(text: String) -> void:
	_hint_text = text
	_sync_message_labels()


func _sync_message_labels() -> void:
	if _status_label != null:
		_status_label.text = _compact_status_text(_status_text) if _compact_messages else _status_text
	if _hint_label != null:
		_hint_label.text = _compact_hint_text(_hint_text) if _compact_messages else _hint_text


func _compact_status_text(text: String) -> String:
	if text.begins_with("Cannot place"):
		if text.find("buildable") != -1:
			return "Road tile blocked."
		if text.find("Need") != -1:
			return text.get_slice(": ", 1)
		return "Cannot place."
	if text.begins_with("Placed"):
		return "Tower placed."
	if text.begins_with("Click a green"):
		return "Place on green tile."
	if text.begins_with("Select a tower"):
		return "Select tower."
	if text.begins_with("Defeated"):
		return "+%s gold" % text.get_slice(" for ", 1).get_slice(" gold", 0)
	if text.begins_with("Cleared"):
		return "Wave clear +%s" % text.get_slice(" for ", 1).get_slice(" gold", 0)
	if text.begins_with("Earned"):
		return "+%s gold" % text.get_slice("Earned ", 1).get_slice(" gold", 0)
	return text


func _compact_hint_text(text: String) -> String:
	var first_sentence := text.get_slice(".", 0)
	if not first_sentence.is_empty():
		return first_sentence
	return text


func _update_selected_tower_hint() -> void:
	_set_hint("%s tower: %dg. Enemies follow the paved road." % [
		_tower_type_label(selected_tower_type),
		economy_config.basic_tower_cost,
	])


func _sync_tower_button_state() -> void:
	_set_tower_button_text(_single_tower_button, GameTower.Type.SINGLE_TARGET, "Single")
	_set_tower_button_text(_area_tower_button, GameTower.Type.AREA, "Area")
	_set_tower_button_text(_slow_tower_button, GameTower.Type.SLOW, "Slow")


func _set_tower_button_text(button: Button, tower_type: GameTower.Type, label: String) -> void:
	if button == null:
		return

	var cost := 0
	if economy_config != null:
		cost = economy_config.basic_tower_cost

	var can_afford := wallet != null and wallet.gold >= cost
	var is_selected := selected_tower_type == tower_type
	button.disabled = flow_state != FlowState.PLAYING or not can_afford
	button.tooltip_text = "%s tower: %s, %d gold" % [label, _tower_type_description(tower_type), cost]
	button.button_pressed = is_selected
	button.modulate = _tower_button_modulate(tower_type, is_selected, button.disabled)
	button.icon = get_tower_sprite_texture(tower_type)

	button.text = "%s\n%s  %dg" % [
		label.to_upper(),
		_tower_type_description(tower_type),
		cost,
	]


func _tower_button_modulate(_tower_type: GameTower.Type, is_selected: bool, is_disabled: bool) -> Color:
	if is_disabled:
		return Color(0.55, 0.58, 0.60, 0.85)

	if is_selected:
		return Color.WHITE

	return Color(0.88, 0.92, 0.94, 1.0)


func _tower_type_label(tower_type: GameTower.Type) -> String:
	match tower_type:
		GameTower.Type.AREA:
			return "Area"
		GameTower.Type.SLOW:
			return "Slow"

	return "Single"


func _tower_type_description(tower_type: GameTower.Type) -> String:
	match tower_type:
		GameTower.Type.AREA:
			return "Splash hit"
		GameTower.Type.SLOW:
			return "Frost slow"

	return "Focus fire"


func _update_gold_label() -> void:
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % wallet.gold

	_sync_tower_button_state()


func _update_lives_label() -> void:
	if _lives_label != null and combat_simulation != null:
		_lives_label.text = "Lives: %d" % combat_simulation.player_life.lives


func _update_wave_label() -> void:
	if _wave_label == null or wave_spawner == null:
		return

	if wave_spawner.all_waves_cleared:
		_wave_label.text = "Wave: Complete"
		return

	_wave_label.text = "Wave: %d/%d" % [
		wave_spawner.current_wave_index + 1,
		wave_spawner.wave_definitions.size(),
	]


func get_visible_enemies() -> Array:
	if combat_simulation == null:
		return []

	var visible_enemies := []
	for candidate in combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.defeated or enemy.completed:
			continue

		visible_enemies.append(enemy)

	return visible_enemies


func _sync_combat_towers() -> void:
	if combat_simulation == null or placement_service == null:
		return

	combat_simulation.towers = placement_service.tower_registry.get_all_towers()


func _apply_tick_rewards(tick_results: Array) -> void:
	if kill_reward_service == null or wave_reward_service == null:
		return

	var earned_gold := 0
	var defeated_enemy_id := ""
	var cleared_wave_id := ""
	last_reward_transaction_results = []
	last_wave_reward_transaction_results = []

	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null or tick_result.damage_result == null:
			continue

		var transaction_results := kill_reward_service.apply_death_events(tick_result.damage_result.death_events)
		last_reward_transaction_results.append_array(transaction_results)
		var wave_transaction_results := wave_reward_service.apply_clear_events(tick_result.wave_clear_events)
		last_wave_reward_transaction_results.append_array(wave_transaction_results)

		for transaction_result in transaction_results:
			if transaction_result.succeeded:
				earned_gold += transaction_result.amount
				defeated_enemy_id = transaction_result.reference_id

		for transaction_result in wave_transaction_results:
			if transaction_result.succeeded:
				earned_gold += transaction_result.amount
				cleared_wave_id = transaction_result.reference_id

	if earned_gold <= 0:
		return

	if last_reward_transaction_results.size() == 1 and last_wave_reward_transaction_results.is_empty():
		_set_status("Defeated %s for %d gold." % [defeated_enemy_id, earned_gold])
	elif last_reward_transaction_results.is_empty() and last_wave_reward_transaction_results.size() == 1:
		_set_status("Cleared %s for %d gold." % [cleared_wave_id, earned_gold])
	else:
		_set_status("Earned %d gold." % earned_gold)

	_update_gold_label()


func _apply_tick_outcome(tick_results: Array) -> void:
	var leak_count := 0
	var latest_lives := combat_simulation.player_life.lives

	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		leak_count += tick_result.enemy_leak_events.size()
		latest_lives = tick_result.lives_remaining

		if tick_result.game_failed:
			_set_status("Defeat. Enemies breached the path.")
			show_defeat_screen()
			return

		if tick_result.game_won:
			_set_status("Victory. All waves cleared.")
			show_victory_screen()
			return

	if leak_count > 0:
		_set_status("Enemy leaked. Lives: %d" % latest_lives)
