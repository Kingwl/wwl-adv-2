class_name Wallet
extends RefCounted

var gold: int
var transactions: Array[TransactionRecord]


func _init(initial_gold: int = 0) -> void:
	assert(initial_gold >= 0, "Initial gold cannot be negative.")

	gold = 0
	transactions = []

	if initial_gold > 0:
		_record_transaction(TransactionRecord.Reason.STARTING_GOLD, initial_gold, initial_gold, "")
		gold = initial_gold


func can_spend(amount: int) -> bool:
	return amount > 0 and gold >= amount


func spend(amount: int, reason: TransactionRecord.Reason, reference_id: String = "") -> TransactionResult:
	if amount <= 0:
		return TransactionResult.failure(
			TransactionResult.FailureReason.INVALID_AMOUNT,
			reason,
			amount,
			gold,
			reference_id,
			"Amount must be positive."
		)

	if gold < amount:
		return TransactionResult.failure(
			TransactionResult.FailureReason.INSUFFICIENT_FUNDS,
			reason,
			amount,
			gold,
			reference_id,
			"Insufficient gold."
		)

	var balance_before := gold
	gold -= amount
	_record_transaction(reason, amount, gold, reference_id, balance_before)
	return TransactionResult.success(
		reason,
		amount,
		balance_before,
		gold,
		reference_id,
		"Spent %d gold." % amount
	)


func earn(amount: int, reason: TransactionRecord.Reason, reference_id: String = "") -> TransactionResult:
	if amount <= 0:
		return TransactionResult.failure(
			TransactionResult.FailureReason.INVALID_AMOUNT,
			reason,
			amount,
			gold,
			reference_id,
			"Amount must be positive."
		)

	var balance_before := gold
	gold += amount
	_record_transaction(reason, amount, gold, reference_id, balance_before)
	return TransactionResult.success(
		reason,
		amount,
		balance_before,
		gold,
		reference_id,
		"Earned %d gold." % amount
	)


func _record_transaction(
	reason: TransactionRecord.Reason,
	amount: int,
	balance_after: int,
	reference_id: String = "",
	balance_before: int = gold
) -> void:
	transactions.append(TransactionRecord.new(reason, amount, balance_before, balance_after, reference_id))
