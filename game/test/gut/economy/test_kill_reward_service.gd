extends GutTest


func test_apply_death_events_earns_gold_for_each_enemy_death() -> void:
	var wallet := Wallet.new(10)
	var service := KillRewardService.new(wallet)

	var results := service.apply_death_events([
		EnemyDeathEvent.new("enemy-1", 5, "tower-a"),
		EnemyDeathEvent.new("enemy-2", 7, "tower-b"),
	])

	assert_eq(results.size(), 2)
	assert_true(results[0].succeeded)
	assert_true(results[1].succeeded)
	assert_eq(wallet.gold, 22)
	assert_eq(wallet.transactions.size(), 3)
	assert_eq(wallet.transactions[1].reason, TransactionRecord.Reason.KILL_ENEMY)
	assert_eq(wallet.transactions[1].amount, 5)
	assert_eq(wallet.transactions[1].reference_id, "enemy-1")
	assert_eq(wallet.transactions[2].amount, 7)
	assert_eq(wallet.transactions[2].reference_id, "enemy-2")


func test_apply_death_events_ignores_non_death_events() -> void:
	var wallet := Wallet.new(10)
	var service := KillRewardService.new(wallet)

	var results := service.apply_death_events([
		null,
		DamageEvent.new("enemy-1", 5.0, "tower-a"),
		EnemyDeathEvent.new("enemy-2", 5, "tower-b"),
	])

	assert_eq(results.size(), 1)
	assert_true(results[0].succeeded)
	assert_eq(wallet.gold, 15)
	assert_eq(wallet.transactions.size(), 2)


func test_zero_reward_death_event_is_skipped_without_wallet_transaction() -> void:
	var wallet := Wallet.new(10)
	var service := KillRewardService.new(wallet)

	var results := service.apply_death_events([
		EnemyDeathEvent.new("enemy-1", 0, "tower-a"),
	])

	assert_eq(results.size(), 0)
	assert_eq(wallet.gold, 10)
	assert_eq(wallet.transactions.size(), 1)
