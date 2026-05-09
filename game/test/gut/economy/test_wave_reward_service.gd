extends GutTest


func test_apply_clear_events_earns_gold_for_each_wave_clear() -> void:
	var wallet := Wallet.new(10)
	var service := WaveRewardService.new(wallet)

	var results := service.apply_clear_events([
		WaveClearEvent.new("wave-1", 20),
		WaveClearEvent.new("wave-2", 25),
	])

	assert_eq(results.size(), 2)
	assert_true(results[0].succeeded)
	assert_true(results[1].succeeded)
	assert_eq(wallet.gold, 55)
	assert_eq(wallet.transactions.size(), 3)
	assert_eq(wallet.transactions[1].reason, TransactionRecord.Reason.CLEAR_WAVE)
	assert_eq(wallet.transactions[1].amount, 20)
	assert_eq(wallet.transactions[1].reference_id, "wave-1")
	assert_eq(wallet.transactions[2].amount, 25)
	assert_eq(wallet.transactions[2].reference_id, "wave-2")


func test_apply_clear_events_ignores_non_wave_clear_events() -> void:
	var wallet := Wallet.new(10)
	var service := WaveRewardService.new(wallet)

	var results := service.apply_clear_events([
		null,
		EnemyDeathEvent.new("enemy-1", 5, "tower-a"),
		WaveClearEvent.new("wave-1", 20),
	])

	assert_eq(results.size(), 1)
	assert_true(results[0].succeeded)
	assert_eq(wallet.gold, 30)
	assert_eq(wallet.transactions.size(), 2)


func test_zero_reward_wave_clear_event_is_skipped_without_wallet_transaction() -> void:
	var wallet := Wallet.new(10)
	var service := WaveRewardService.new(wallet)

	var results := service.apply_clear_events([
		WaveClearEvent.new("wave-1", 0),
	])

	assert_eq(results.size(), 0)
	assert_eq(wallet.gold, 10)
	assert_eq(wallet.transactions.size(), 1)
