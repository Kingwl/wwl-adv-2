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
var level_definition: LevelDefinition
var last_placement_result: PlacementResult
var last_upgrade_result: TowerUpgradeResult
var last_removal_result: TowerRemovalResult
var last_tick_results: Array
var last_reward_transaction_results: Array
var last_wave_reward_transaction_results: Array
var flow_state: int = FlowState.PLAYING
var gameplay_paused := false
var selected_tower_type: GameTower.Type = GameTower.Type.SINGLE_TARGET
var status_text := ""
var hint_text := ""


func _init(default_board_width: int = DEFAULT_BOARD_WIDTH, default_board_height: int = DEFAULT_BOARD_HEIGHT) -> void:
	fallback_board_width = default_board_width
	fallback_board_height = default_board_height
	last_tick_results = []
	last_reward_transaction_results = []
	last_wave_reward_transaction_results = []


func initialize_board() -> void:
	if level_definition != null and level_definition.is_valid():
		board = Board.new(level_definition.grid_width, level_definition.grid_height)
		level_definition.apply_to_board(board)
	else:
		board = Board.new(fallback_board_width, fallback_board_height)
		board.set_path(get_default_path())

	var path_result := board.validate_path(get_default_path())
	assert(path_result.succeeded, "Default path must be valid.")

	economy_config = EconomyConfig.new()
	wallet = Wallet.new(economy_config.initial_gold)
	placement_service = TowerPlacementService.new(board, wallet, economy_config)
	selected_tower_type = _default_tower_type()
	placement_service.basic_tower_type = selected_tower_type
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


func advance_combat(delta: float) -> Array:
	if combat_simulation == null or gameplay_paused:
		return []

	var tick_results := combat_simulation.advance(delta)
	last_tick_results = tick_results
	apply_tick_rewards(tick_results)
	apply_tick_outcome(tick_results)
	return tick_results


func try_place_at_grid(grid_position: Vector2i) -> TowerPlacementResult:
	placement_service.basic_tower_type = selected_tower_type
	var result := placement_service.try_place_basic_tower(grid_position)
	last_placement_result = result.placement_result

	if result.succeeded:
		sync_combat_towers()
		set_status("Placed %s at (%d, %d) for %d gold." % [
			result.tower_id,
			grid_position.x,
			grid_position.y,
			economy_config.basic_tower_cost,
		])
	elif result.placement_result != null:
		set_status("Cannot place at (%d, %d): %s" % [grid_position.x, grid_position.y, result.placement_result.message])
	else:
		set_status("Cannot place at (%d, %d): %s" % [grid_position.x, grid_position.y, result.message])

	return result


func try_upgrade_tower(tower_id: String) -> TowerUpgradeResult:
	var result := placement_service.try_upgrade_tower(tower_id)
	last_upgrade_result = result

	if result.succeeded:
		sync_combat_towers()
		var tower := get_tower_by_id(tower_id)
		set_status("Upgraded %s to %s T%d for %d gold." % [
			tower_id,
			_tower_type_label(tower.tower_type),
			result.new_tier,
			result.cost,
		])
	elif result.failure_reason == TowerUpgradeResult.FailureReason.MAX_TIER:
		set_status("%s is fully upgraded." % tower_id)
	elif result.transaction_result != null:
		set_status("Cannot upgrade %s: %s" % [tower_id, result.transaction_result.message])
	else:
		set_status("Cannot upgrade %s: %s" % [tower_id, result.message])

	return result


func try_remove_tower_at(grid_position: Vector2i) -> TowerRemovalResult:
	var result := placement_service.try_remove_tower_at(grid_position)
	last_removal_result = result

	if result.succeeded:
		sync_combat_towers()
		set_status("Removed %s for %d gold refund." % [result.tower_id, result.refund_amount])
	elif result.removal_result != null:
		set_status("Cannot remove at (%d, %d): %s" % [
			grid_position.x,
			grid_position.y,
			result.removal_result.message,
		])
	else:
		set_status("Cannot remove %s: %s" % [result.tower_id, result.message])

	return result


func start_game() -> void:
	flow_state = FlowState.PLAYING
	gameplay_paused = false
	set_status("Click a green slot to place a tower.")


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


func select_tower_type(tower_type: GameTower.Type) -> void:
	selected_tower_type = tower_type
	if placement_service != null:
		placement_service.basic_tower_type = selected_tower_type


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
		set_status("Defeated %s for %d gold." % [defeated_enemy_id, earned_gold])
	elif last_reward_transaction_results.is_empty() and last_wave_reward_transaction_results.size() == 1:
		set_status("Cleared %s for %d gold." % [cleared_wave_id, earned_gold])
	else:
		set_status("Earned %d gold." % earned_gold)


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
			set_status("Defeat. Enemies breached the path.")
			show_defeat_screen()
			return

		if tick_result.game_won:
			set_status("Victory. All waves cleared.")
			show_victory_screen()
			return

	if leak_count > 0:
		set_status("Enemy leaked. Lives: %d" % latest_lives)


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
	status_text = text


func set_hint(text: String) -> void:
	hint_text = text


func _tower_type_label(tower_type: GameTower.Type) -> String:
	if placement_service != null and placement_service.tower_config != null:
		return placement_service.tower_config.get_display_name(tower_type)

	return "Single"


func _default_tower_type() -> GameTower.Type:
	if placement_service == null or placement_service.tower_config == null:
		return GameTower.Type.SINGLE_TARGET

	var tower_types := placement_service.tower_config.get_tower_types()
	if tower_types.is_empty():
		return GameTower.Type.SINGLE_TARGET

	return tower_types[0] as GameTower.Type
