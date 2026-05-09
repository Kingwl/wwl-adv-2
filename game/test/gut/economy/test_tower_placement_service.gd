extends GutTest


func test_try_place_basic_tower_with_enough_gold_places_tower_and_spends_gold() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")

	var result := service.try_place_basic_tower(Vector2i(1, 1))

	assert_true(result.succeeded)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "tower-1")
	assert_eq(wallet.gold, 75)
	assert_not_null(result.placement_result)
	assert_not_null(result.transaction_result)
	assert_eq(result.transaction_result.reason, TransactionRecord.Reason.PLACE_TOWER)
	assert_eq(result.transaction_result.reference_id, "tower-1")
	assert_not_null(service.tower_registry.get_tower("tower-1"))
	assert_eq(service.tower_registry.get_tower("tower-1").grid_position, Vector2i(1, 1))
	assert_eq(service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.SINGLE_TARGET)


func test_try_place_basic_tower_with_insufficient_gold_does_not_place_or_spend() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(10)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")

	var result := service.try_place_basic_tower(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerPlacementResult.FailureReason.INSUFFICIENT_FUNDS)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "")
	assert_eq(wallet.gold, 10)
	assert_eq(wallet.transactions.size(), 1)
	assert_eq(service.tower_registry.get_all_towers().size(), 0)


func test_try_place_basic_tower_on_path_does_not_spend_gold() -> void:
	var board := Board.new(3, 2)
	board.set_slot_type(Vector2i(1, 1), BoardSlot.Type.PATH)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")

	var result := service.try_place_basic_tower(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerPlacementResult.FailureReason.PLACEMENT_FAILED)
	assert_eq(result.placement_result.failure_reason, PlacementResult.FailureReason.NOT_BUILDABLE)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "")
	assert_eq(wallet.gold, 100)
	assert_eq(wallet.transactions.size(), 1)
	assert_eq(service.tower_registry.get_all_towers().size(), 0)


func test_try_place_basic_tower_on_occupied_slot_does_not_spend_or_replace_tower() -> void:
	var board := Board.new(3, 2)
	board.place_tower(Vector2i(1, 1), "existing-tower")
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")

	var result := service.try_place_basic_tower(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerPlacementResult.FailureReason.PLACEMENT_FAILED)
	assert_eq(result.placement_result.failure_reason, PlacementResult.FailureReason.OCCUPIED)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "existing-tower")
	assert_eq(wallet.gold, 100)
	assert_eq(wallet.transactions.size(), 1)
	assert_eq(service.tower_registry.get_all_towers().size(), 0)
