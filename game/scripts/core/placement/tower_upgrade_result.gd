class_name TowerUpgradeResult
extends RefCounted

enum FailureReason {
	NONE,
	TOWER_MISSING,
	MAX_TIER,
	INSUFFICIENT_FUNDS,
	TRANSACTION_FAILED,
}

var succeeded: bool
var failure_reason: FailureReason
var transaction_result: TransactionResult
var tower_id: String
var previous_tier: int
var new_tier: int
var cost: int
var message: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_transaction_result: TransactionResult,
	new_tower_id: String,
	new_previous_tier: int,
	new_new_tier: int,
	new_cost: int,
	new_message: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	transaction_result = new_transaction_result
	tower_id = new_tower_id
	previous_tier = new_previous_tier
	new_tier = new_new_tier
	cost = new_cost
	message = new_message


static func success(
	tower: GameTower,
	old_tier: int,
	new_transaction_result: TransactionResult
) -> TowerUpgradeResult:
	return TowerUpgradeResult.new(
		true,
		FailureReason.NONE,
		new_transaction_result,
		tower.id,
		old_tier,
		tower.tier,
		new_transaction_result.amount,
		"Upgraded %s to tier %d." % [tower.id, tower.tier]
	)


static func tower_missing(missing_tower_id: String) -> TowerUpgradeResult:
	return TowerUpgradeResult.new(
		false,
		FailureReason.TOWER_MISSING,
		null,
		missing_tower_id,
		0,
		0,
		0,
		"Tower does not exist."
	)


static func max_tier(tower: GameTower) -> TowerUpgradeResult:
	return TowerUpgradeResult.new(
		false,
		FailureReason.MAX_TIER,
		null,
		tower.id,
		tower.tier,
		tower.tier,
		0,
		"Tower is already fully upgraded."
	)


static func transaction_failure(
	reason: FailureReason,
	new_transaction_result: TransactionResult,
	tower: GameTower,
	next_tier: int,
	upgrade_cost: int
) -> TowerUpgradeResult:
	return TowerUpgradeResult.new(
		false,
		reason,
		new_transaction_result,
		tower.id,
		tower.tier,
		next_tier,
		upgrade_cost,
		new_transaction_result.message
	)
