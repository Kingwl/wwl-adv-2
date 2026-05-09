extends GutTest


func test_wallet_starts_with_initial_gold_and_records_starting_transaction() -> void:
	var wallet := Wallet.new(100)

	assert_eq(wallet.gold, 100)
	assert_eq(wallet.transactions.size(), 1)
	assert_eq(wallet.transactions[0].reason, TransactionRecord.Reason.STARTING_GOLD)
	assert_eq(wallet.transactions[0].amount, 100)
	assert_eq(wallet.transactions[0].balance_before, 0)
	assert_eq(wallet.transactions[0].balance_after, 100)


func test_earn_increases_gold_and_records_transaction() -> void:
	var wallet := Wallet.new(50)

	var result := wallet.earn(5, TransactionRecord.Reason.KILL_ENEMY, "enemy-1")

	assert_true(result.succeeded)
	assert_eq(result.failure_reason, TransactionResult.FailureReason.NONE)
	assert_eq(wallet.gold, 55)
	assert_eq(result.balance_before, 50)
	assert_eq(result.balance_after, 55)
	assert_eq(result.reference_id, "enemy-1")
	assert_eq(wallet.transactions.size(), 2)
	assert_eq(wallet.transactions[1].reason, TransactionRecord.Reason.KILL_ENEMY)


func test_spend_decreases_gold_and_records_transaction() -> void:
	var wallet := Wallet.new(100)

	var result := wallet.spend(25, TransactionRecord.Reason.PLACE_TOWER, "tower-1")

	assert_true(result.succeeded)
	assert_eq(wallet.gold, 75)
	assert_eq(result.balance_before, 100)
	assert_eq(result.balance_after, 75)
	assert_eq(wallet.transactions.size(), 2)
	assert_eq(wallet.transactions[1].reason, TransactionRecord.Reason.PLACE_TOWER)
	assert_eq(wallet.transactions[1].reference_id, "tower-1")


func test_spend_with_insufficient_funds_fails_without_changing_gold() -> void:
	var wallet := Wallet.new(10)

	var result := wallet.spend(25, TransactionRecord.Reason.PLACE_TOWER, "tower-1")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TransactionResult.FailureReason.INSUFFICIENT_FUNDS)
	assert_eq(wallet.gold, 10)
	assert_eq(result.balance_before, 10)
	assert_eq(result.balance_after, 10)
	assert_eq(wallet.transactions.size(), 1)


func test_earn_with_invalid_amount_fails_without_recording_transaction() -> void:
	var wallet := Wallet.new(10)

	var result := wallet.earn(0, TransactionRecord.Reason.KILL_ENEMY, "enemy-1")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TransactionResult.FailureReason.INVALID_AMOUNT)
	assert_eq(wallet.gold, 10)
	assert_eq(wallet.transactions.size(), 1)


func test_spend_with_invalid_amount_fails_without_recording_transaction() -> void:
	var wallet := Wallet.new(10)

	var result := wallet.spend(-1, TransactionRecord.Reason.PLACE_TOWER, "tower-1")

	assert_false(result.succeeded)
	assert_eq(result.failure_reason, TransactionResult.FailureReason.INVALID_AMOUNT)
	assert_eq(wallet.gold, 10)
	assert_eq(wallet.transactions.size(), 1)
