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
	assert_eq(service.tower_registry.get_tower("tower-1").invested_gold, 25)


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


func test_try_place_basic_tower_uses_tower_type_build_cost() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var tower_config := TowerConfig.new({
		GameTower.Type.AREA: {
			"build_cost": 37,
			"tiers": [
				{
					"damage": 6.0,
					"range_cells": 2.0,
					"attack_interval": 1.4,
					"effects": [
						{
							"type": TowerEffect.EffectType.SPLASH_DAMAGE,
							"radius_cells": 0.75,
						},
					],
				},
			],
		},
	})
	var service := TowerPlacementService.new(
		board,
		wallet,
		EconomyConfig.new(),
		func() -> String: return "tower-1",
		null,
		GameTower.Type.AREA,
		tower_config
	)

	var result := service.try_place_basic_tower(Vector2i(1, 1))
	var tower := service.tower_registry.get_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(result.transaction_result.amount, 37)
	assert_eq(wallet.gold, 63)
	assert_eq(tower.tower_type, GameTower.Type.AREA)
	assert_eq(tower.invested_gold, 37)


func test_try_upgrade_tower_spends_configured_cost_and_updates_tier_and_investment() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)

	var result := service.try_upgrade_tower("tower-1")
	var tower := service.tower_registry.get_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(result.previous_tier, 1)
	assert_eq(result.new_tier, 2)
	assert_eq(result.cost, 40)
	assert_eq(result.transaction_result.reason, TransactionRecord.Reason.UPGRADE_TOWER)
	assert_eq(result.transaction_result.reference_id, "tower-1")
	assert_eq(tower.tier, 2)
	assert_eq(tower.invested_gold, 65)
	assert_eq(wallet.gold, 35)


func test_try_upgrade_tower_uses_tower_type_specific_cost() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(
		board,
		wallet,
		EconomyConfig.new(),
		func() -> String: return "tower-1",
		null,
		GameTower.Type.SLOW
	)
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)

	var result := service.try_upgrade_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(result.cost, 35)
	assert_eq(service.tower_registry.get_tower("tower-1").tower_type, GameTower.Type.SLOW)
	assert_eq(service.tower_registry.get_tower("tower-1").tier, 2)
	assert_eq(wallet.gold, 40)


func test_try_upgrade_tower_does_not_clear_existing_cooldown() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)
	var tower := service.tower_registry.get_tower("tower-1")
	tower.cooldown_remaining = 0.4

	var result := service.try_upgrade_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(tower.tier, 2)
	assert_eq(tower.cooldown_remaining, 0.4)


func test_try_upgrade_tower_clamps_cooldown_to_new_attack_interval() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)
	var tower := service.tower_registry.get_tower("tower-1")
	tower.cooldown_remaining = 5.0

	var result := service.try_upgrade_tower("tower-1")

	assert_true(result.succeeded)
	assert_eq(tower.tier, 2)
	assert_eq(tower.cooldown_remaining, 0.9)


func test_try_upgrade_tower_with_insufficient_gold_does_not_change_tower() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(50)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)

	var result := service.try_upgrade_tower("tower-1")
	var tower := service.tower_registry.get_tower("tower-1")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerUpgradeResult.FailureReason.INSUFFICIENT_FUNDS)
	assert_eq(result.cost, 40)
	assert_eq(tower.tier, 1)
	assert_eq(tower.invested_gold, 25)
	assert_eq(wallet.gold, 25)


func test_try_upgrade_missing_tower_returns_structured_failure() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new())

	var result := service.try_upgrade_tower("missing-tower")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerUpgradeResult.FailureReason.TOWER_MISSING)
	assert_eq(result.tower_id, "missing-tower")
	assert_eq(result.message, "Tower does not exist.")
	assert_eq(wallet.gold, 100)
	assert_eq(service.tower_registry.get_all_towers().size(), 0)


func test_try_upgrade_tower_at_max_tier_does_not_spend_gold() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(200)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)
	assert_true(service.try_upgrade_tower("tower-1").succeeded)
	assert_true(service.try_upgrade_tower("tower-1").succeeded)
	var gold_before := wallet.gold

	var result := service.try_upgrade_tower("tower-1")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerUpgradeResult.FailureReason.MAX_TIER)
	assert_eq(service.tower_registry.get_tower("tower-1").tier, 3)
	assert_eq(wallet.gold, gold_before)


func test_try_remove_tower_refunds_half_build_and_upgrade_investment() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new(), func() -> String: return "tower-1")
	assert_true(service.try_place_basic_tower(Vector2i(1, 1)).succeeded)
	assert_true(service.try_upgrade_tower("tower-1").succeeded)

	var result := service.try_remove_tower_at(Vector2i(1, 1))

	assert_true(result.succeeded)
	assert_eq(result.tower_id, "tower-1")
	assert_eq(result.refund_amount, 32)
	assert_not_null(result.refund_transaction_result)
	assert_eq(result.refund_transaction_result.reason, TransactionRecord.Reason.REFUND)
	assert_eq(result.refund_transaction_result.reference_id, "tower-1")
	assert_eq(wallet.gold, 67)
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "")
	assert_null(service.tower_registry.get_tower("tower-1"))


func test_try_remove_tower_missing_from_registry_leaves_board_and_wallet_unchanged() -> void:
	var board := Board.new(3, 2)
	assert_true(board.place_tower(Vector2i(1, 1), "ghost-tower").succeeded)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new())

	var result := service.try_remove_tower_at(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerRemovalResult.FailureReason.TOWER_MISSING)
	assert_eq(result.tower_id, "ghost-tower")
	assert_eq(result.message, "Tower does not exist.")
	assert_eq(board.get_occupant_id(Vector2i(1, 1)), "ghost-tower")
	assert_eq(wallet.gold, 100)


func test_try_remove_tower_from_empty_slot_does_not_refund() -> void:
	var board := Board.new(3, 2)
	var wallet := Wallet.new(100)
	var service := TowerPlacementService.new(board, wallet, EconomyConfig.new())

	var result := service.try_remove_tower_at(Vector2i(1, 1))

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TowerRemovalResult.FailureReason.BOARD_REMOVE_FAILED)
	assert_eq(result.removal_result.failure_reason, RemovalResult.FailureReason.EMPTY)
	assert_eq(wallet.gold, 100)


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
