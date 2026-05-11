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
	assert_eq(session.wave_spawner.wave_definitions.size(), 3)
	assert_eq(session.wave_spawner.wave_definitions[0].enemy_type_id, "grunt")
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


func test_try_upgrade_tower_spends_gold_updates_status_and_syncs_combat_towers() -> void:
	var session := _new_initialized_session()
	assert_true(session.try_place_at_grid(Vector2i(0, 0)).succeeded)

	var result := session.try_upgrade_tower("tower-1")
	var tower := session.placement_service.tower_registry.get_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(session.last_upgrade_result, result)
	assert_eq(session.wallet.gold, 35)
	assert_eq(tower.tier, 2)
	assert_eq(session.combat_simulation.towers.size(), 1)
	assert_eq((session.combat_simulation.towers[0] as GameTower).tier, 2)
	assert_eq(session.status_text, "Upgraded tower-1 to Single T2 for 40 gold.")


func test_try_remove_tower_refunds_gold_updates_status_and_syncs_combat_towers() -> void:
	var session := _new_initialized_session()
	assert_true(session.try_place_at_grid(Vector2i(0, 0)).succeeded)
	assert_true(session.try_upgrade_tower("tower-1").succeeded)

	var result := session.try_remove_tower_at(Vector2i(0, 0))

	assert_true(result.succeeded)
	assert_eq(session.last_removal_result, result)
	assert_eq(result.refund_amount, 32)
	assert_eq(session.wallet.gold, 67)
	assert_eq(session.board.get_occupant_id(Vector2i(0, 0)), "")
	assert_null(session.placement_service.tower_registry.get_tower("tower-1"))
	assert_eq(session.combat_simulation.towers.size(), 0)
	assert_eq(session.status_text, "Removed tower-1 for 32 gold refund.")


func test_select_tower_id_maps_config_id_to_placement_type() -> void:
	var session := _new_initialized_session()

	assert_true(session.select_tower_id("poison"))
	assert_eq(session.selected_tower_type, GameTower.Type.POISON)
	assert_eq(session.placement_service.basic_tower_type, GameTower.Type.POISON)
	assert_false(session.select_tower_id("missing"))
	assert_eq(session.selected_tower_type, GameTower.Type.POISON)


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
