extends GutTest


func test_session_initializes_board_wallet_and_combat_from_level() -> void:
	var session := _new_initialized_session()

	assert_not_null(session.board)
	assert_not_null(session.wallet)
	assert_not_null(session.placement_service)
	assert_not_null(session.combat_simulation)
	assert_not_null(session.kill_reward_service)
	assert_not_null(session.wave_reward_service)
	assert_not_null(session.wave_spawner)
	assert_not_null(session.path_follower)
	assert_eq(session.board.width, 10)
	assert_eq(session.board.height, 8)
	assert_eq(session.wallet.gold, 100)
	assert_eq(session.combat_simulation.player_life.lives, 10)
	assert_eq(session.flow_state, BoardGameSession.FlowState.PLAYING)
	assert_false(session.gameplay_paused)
	assert_eq(session.selected_tower_type, GameTower.Type.SINGLE_TARGET)


func test_try_place_at_grid_spends_gold_and_syncs_combat_towers() -> void:
	var session := _new_initialized_session()

	var result: TowerPlacementResult = session.try_place_at_grid(Vector2i(0, 0))

	assert_true(result.succeeded)
	assert_eq(session.board.get_occupant_id(Vector2i(0, 0)), "tower-1")
	assert_eq(session.wallet.gold, 75)
	assert_eq(session.combat_simulation.towers.size(), 1)
	assert_eq(session.status_text, "Placed tower-1 at (0, 0) for 25 gold.")


func test_apply_tick_rewards_aggregates_multiple_rewards() -> void:
	var session := _new_initialized_session()
	var tick_result := CombatTickResult.new(
		0.1,
		[],
		[],
		[],
		EnemyDamageResult.new(
			[],
			[
				EnemyDeathEvent.new("enemy-1", 5, "tower-1"),
				EnemyDeathEvent.new("enemy-2", 7, "tower-1"),
			],
			[]
		)
	)

	session.apply_tick_rewards([tick_result])

	assert_eq(session.wallet.gold, 112)
	assert_eq(session.last_reward_transaction_results.size(), 2)
	assert_eq(session.status_text, "Earned 12 gold.")


func test_apply_tick_outcome_sets_defeat_flow() -> void:
	var session := _new_initialized_session()
	var tick_result := CombatTickResult.new(
		0.1,
		[],
		[],
		[],
		EnemyDamageResult.new(),
		[],
		[],
		false,
		[EnemyLeakEvent.new("enemy-1")],
		0,
		false,
		true
	)

	session.apply_tick_outcome([tick_result])

	assert_eq(session.flow_state, BoardGameSession.FlowState.LOST)
	assert_true(session.gameplay_paused)
	assert_eq(session.status_text, "Defeat. Enemies breached the path.")


func test_apply_tick_outcome_sets_victory_flow() -> void:
	var session := _new_initialized_session()
	var tick_result := CombatTickResult.new(
		0.1,
		[],
		[],
		[],
		EnemyDamageResult.new(),
		[],
		[],
		true,
		[],
		10,
		true,
		false
	)

	session.apply_tick_outcome([tick_result])

	assert_eq(session.flow_state, BoardGameSession.FlowState.WON)
	assert_true(session.gameplay_paused)
	assert_eq(session.status_text, "Victory. All waves cleared.")


func _new_initialized_session() -> BoardGameSession:
	var session := BoardGameSession.new()
	session.level_definition = LevelDefinition.load_from_path("res://data/levels/level_001.json")
	session.initialize_board()
	session.initialize_combat()
	session.start_game()
	return session
