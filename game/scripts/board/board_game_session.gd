class_name BoardGameSession
extends RefCounted

const DEFAULT_BOARD_WIDTH := 10
const DEFAULT_BOARD_HEIGHT := 8

enum FlowState {
	PLAYING,
	MENU,
	WON,
	LOST,
}

var fallback_board_width: int
var fallback_board_height: int
var board: Board
var wallet: Wallet
var economy_config: EconomyConfig
var placement_service: TowerPlacementService
var combat_simulation: CombatSimulation
var kill_reward_service: KillRewardService
var wave_reward_service: WaveRewardService
var wave_spawner: WaveSpawner
var path_follower: PathFollower
var enemy_catalog: EnemyCatalog
var level_definition: LevelDefinition
var last_placement_result: PlacementResult
var last_upgrade_result: TowerUpgradeResult
var last_removal_result: TowerRemovalResult
var last_tick_results: Array
var last_reward_transaction_results: Array
var last_wave_reward_transaction_results: Array
var flow_state: int = FlowState.PLAYING
var gameplay_paused := false
var selected_tower_type: int = GameTower.Type.SINGLE_TARGET
var selected_tower_definition_id := "single"
var status_message: BoardMessage
var hint_message: BoardMessage
var status_text := ""
var hint_text := ""


func _init(default_board_width: int = DEFAULT_BOARD_WIDTH, default_board_height: int = DEFAULT_BOARD_HEIGHT) -> void:
	fallback_board_width = default_board_width
	fallback_board_height = default_board_height
	last_tick_results = []
	last_reward_transaction_results = []
	last_wave_reward_transaction_results = []
	status_message = BoardMessage.empty()
	hint_message = BoardMessage.empty()


func initialize_board() -> void:
	if level_definition != null and level_definition.is_valid():
		board = Board.new(level_definition.grid_width, level_definition.grid_height)
		level_definition.apply_to_board(board)
	else:
		board = Board.new(fallback_board_width, fallback_board_height)
		board.set_path(get_default_path())

	var path_result := board.validate_path(get_default_path())
	assert(path_result.succeeded, "Default path must be valid.")

	economy_config = EconomyConfig.load_from_path(EconomyConfig.DEFAULT_ECONOMY_CONFIG_PATH)
	wallet = Wallet.new(economy_config.initial_gold)
	placement_service = TowerPlacementService.new(board, wallet, economy_config)
	selected_tower_definition_id = _default_tower_definition_id()
	placement_service.select_basic_tower_id(selected_tower_definition_id)
	selected_tower_type = placement_service.basic_tower_type
	kill_reward_service = KillRewardService.new(wallet)
	wave_reward_service = WaveRewardService.new(wallet)
	last_placement_result = null
	last_upgrade_result = null
	last_removal_result = null
	last_tick_results = []
	last_reward_transaction_results = []
	last_wave_reward_transaction_results = []


func initialize_combat() -> void:
	path_follower = PathFollower.new(get_default_path())
	enemy_catalog = EnemyCatalog.new()
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
	if enemy_catalog == null:
		enemy_catalog = EnemyCatalog.new()

	var wave_definitions := WaveConfig.load_definitions_for_level(level_definition, enemy_catalog)
	assert(not wave_definitions.is_empty(), "Default wave definitions must be configured.")
	return wave_definitions


func advance_combat(delta: float) -> Array:
	if combat_simulation == null or gameplay_paused:
		return []

	var tick_results := combat_simulation.advance(delta)
	last_tick_results = tick_results
	apply_tick_rewards(tick_results)
	apply_tick_outcome(tick_results)
	return tick_results


func try_place_at_grid(grid_position: Vector2i) -> TowerPlacementResult:
	placement_service.select_basic_tower_id(selected_tower_definition_id)
	var result := placement_service.try_place_basic_tower(grid_position)
	last_placement_result = result.placement_result

	if result.succeeded:
		sync_combat_towers()
		set_status_message(BoardMessage.tower_placed(
			result.tower_id,
			grid_position,
			result.transaction_result.amount
		))
	elif result.placement_result != null:
		set_status_message(BoardMessage.tower_place_failed(
			grid_position,
			result.placement_result.message,
			_placement_failure_compact_text(result.placement_result)
		))
	else:
		set_status_message(BoardMessage.tower_place_failed(
			grid_position,
			result.message,
			_placement_transaction_failure_compact_text(result)
		))

	return result


func try_upgrade_tower(tower_id: String) -> TowerUpgradeResult:
	var result := placement_service.try_upgrade_tower(tower_id)
	last_upgrade_result = result

	if result.succeeded:
		sync_combat_towers()
		var tower := get_tower_by_id(tower_id)
		set_status_message(BoardMessage.tower_upgraded(
			tower_id,
			_tower_label(tower),
			result.new_tier,
			result.cost
		))
	elif result.failure_reason == TowerUpgradeResult.FailureReason.MAX_TIER:
		set_status_message(BoardMessage.tower_max_tier(tower_id))
	elif result.transaction_result != null:
		set_status_message(BoardMessage.tower_upgrade_failed(
			tower_id,
			result.transaction_result.message,
			result.transaction_result.message
		))
	else:
		set_status_message(BoardMessage.tower_upgrade_failed(tower_id, result.message, result.message))

	return result


func try_remove_tower_at(grid_position: Vector2i) -> TowerRemovalResult:
	var result := placement_service.try_remove_tower_at(grid_position)
	last_removal_result = result

	if result.succeeded:
		sync_combat_towers()
		set_status_message(BoardMessage.tower_removed(result.tower_id, result.refund_amount))
	elif result.removal_result != null:
		set_status_message(BoardMessage.tower_remove_failed_at(
			grid_position,
			result.removal_result.message,
			_removal_failure_compact_text(result.removal_result)
		))
	else:
		set_status_message(BoardMessage.tower_remove_failed(result.tower_id, result.message, result.message))

	return result


func start_game() -> void:
	flow_state = FlowState.PLAYING
	gameplay_paused = false
	set_status_message(BoardMessage.place_tower_hint())


func open_pause_menu() -> bool:
	if flow_state != FlowState.PLAYING:
		return false

	flow_state = FlowState.MENU
	gameplay_paused = true
	return true


func resume_game() -> bool:
	if flow_state != FlowState.MENU:
		return false

	flow_state = FlowState.PLAYING
	gameplay_paused = false
	return true


func restart_game() -> void:
	initialize_board()
	initialize_combat()
	start_game()


func show_victory_screen() -> void:
	flow_state = FlowState.WON
	gameplay_paused = true


func show_defeat_screen() -> void:
	flow_state = FlowState.LOST
	gameplay_paused = true


func select_tower_type(tower_type: int) -> void:
	selected_tower_type = tower_type
	if placement_service != null:
		selected_tower_definition_id = placement_service.tower_config.get_tower_id(tower_type)
		placement_service.select_basic_tower_id(selected_tower_definition_id)


func select_tower_id(tower_id: String) -> bool:
	if placement_service == null or placement_service.tower_config == null:
		return false

	if not placement_service.select_basic_tower_id(tower_id):
		return false

	selected_tower_definition_id = tower_id
	selected_tower_type = placement_service.basic_tower_type
	return true


func get_visible_enemies() -> Array:
	if combat_simulation == null:
		return []

	var visible_enemies := []
	for candidate in combat_simulation.enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.defeated:
			continue
		if enemy.completed:
			continue
		visible_enemies.append(enemy)

	return visible_enemies


func sync_combat_towers() -> void:
	if combat_simulation == null or placement_service == null:
		return

	combat_simulation.towers = placement_service.tower_registry.get_all_towers()


func apply_tick_rewards(tick_results: Array) -> void:
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
		set_status_message(BoardMessage.kill_reward(defeated_enemy_id, earned_gold))
	elif last_reward_transaction_results.is_empty() and last_wave_reward_transaction_results.size() == 1:
		set_status_message(BoardMessage.wave_clear_reward(cleared_wave_id, earned_gold))
	else:
		set_status_message(BoardMessage.gold_earned(earned_gold))


func apply_tick_outcome(tick_results: Array) -> void:
	if combat_simulation == null:
		return

	var leak_count := 0
	var latest_lives := combat_simulation.player_life.lives

	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		leak_count += tick_result.enemy_leak_events.size()
		latest_lives = tick_result.lives_remaining

		if tick_result.game_failed:
			set_status_message(BoardMessage.defeat())
			show_defeat_screen()
			return

		if tick_result.game_won:
			set_status_message(BoardMessage.victory())
			show_victory_screen()
			return

	if leak_count > 0:
		set_status_message(BoardMessage.enemy_leaked(latest_lives))


func get_tower_by_id(tower_id: String) -> GameTower:
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


func get_enemy_by_id(enemy_id: String) -> Enemy:
	if combat_simulation == null:
		return null

	for enemy in combat_simulation.enemies:
		if enemy != null and enemy.id == enemy_id:
			return enemy

	return null


func set_status(text: String) -> void:
	set_status_message(BoardMessage.text(text))


func set_hint(text: String) -> void:
	set_hint_message(BoardMessage.text(text))


func set_status_message(message: BoardMessage) -> void:
	status_message = message if message != null else BoardMessage.empty()
	status_text = status_message.full_text


func set_hint_message(message: BoardMessage) -> void:
	hint_message = message if message != null else BoardMessage.empty()
	hint_text = hint_message.full_text


func _placement_failure_compact_text(result: PlacementResult) -> String:
	if result == null:
		return "Cannot place."

	match result.failure_reason:
		PlacementResult.FailureReason.OUT_OF_BOUNDS:
			return "Out of bounds."
		PlacementResult.FailureReason.NOT_BUILDABLE:
			return "Road tile blocked."
		PlacementResult.FailureReason.OCCUPIED:
			return "Tile occupied."
		PlacementResult.FailureReason.RESERVED:
			return "Tile reserved."

	return "Cannot place."


func _placement_transaction_failure_compact_text(result: TowerPlacementResult) -> String:
	if result != null and result.transaction_result != null and not result.transaction_result.message.is_empty():
		return result.transaction_result.message
	if result != null and not result.message.is_empty():
		return result.message
	return "Cannot place."


func _removal_failure_compact_text(result: RemovalResult) -> String:
	if result == null:
		return "Cannot remove."

	match result.failure_reason:
		RemovalResult.FailureReason.OUT_OF_BOUNDS:
			return "Out of bounds."
		RemovalResult.FailureReason.EMPTY:
			return "No tower there."
		RemovalResult.FailureReason.OCCUPANT_MISMATCH:
			return "Different tower selected."

	return "Cannot remove."


func _tower_label(tower: GameTower) -> String:
	if placement_service != null and placement_service.tower_config != null:
		return placement_service.tower_config.get_display_name_for_id(
			placement_service.tower_config.get_tower_id_for_runtime_tower(tower)
		)

	return "Single"


func _default_tower_definition_id() -> String:
	if placement_service == null or placement_service.tower_config == null:
		return "single"

	var tower_ids := placement_service.tower_config.get_tower_ids()
	if tower_ids.is_empty():
		return "single"

	return String(tower_ids[0])
