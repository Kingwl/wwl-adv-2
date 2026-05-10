class_name TowerRemovalResult
extends RefCounted

enum FailureReason {
	NONE,
	BOARD_REMOVE_FAILED,
	TOWER_MISSING,
	REFUND_FAILED,
}

var succeeded: bool
var failure_reason: FailureReason
var removal_result: RemovalResult
var refund_transaction_result: TransactionResult
var removed_tower: GameTower
var tower_id: String
var position: Vector2i
var refund_amount: int
var message: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_removal_result: RemovalResult,
	new_refund_transaction_result: TransactionResult,
	new_removed_tower: GameTower,
	new_tower_id: String,
	new_position: Vector2i,
	new_refund_amount: int,
	new_message: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	removal_result = new_removal_result
	refund_transaction_result = new_refund_transaction_result
	removed_tower = new_removed_tower
	tower_id = new_tower_id
	position = new_position
	refund_amount = new_refund_amount
	message = new_message


static func success(
	new_removal_result: RemovalResult,
	new_refund_transaction_result: TransactionResult,
	new_removed_tower: GameTower,
	new_refund_amount: int
) -> TowerRemovalResult:
	return TowerRemovalResult.new(
		true,
		FailureReason.NONE,
		new_removal_result,
		new_refund_transaction_result,
		new_removed_tower,
		new_removed_tower.id,
		new_removed_tower.grid_position,
		new_refund_amount,
		"Removed %s for %d gold refund." % [new_removed_tower.id, new_refund_amount]
	)


static func board_failure(new_removal_result: RemovalResult) -> TowerRemovalResult:
	return TowerRemovalResult.new(
		false,
		FailureReason.BOARD_REMOVE_FAILED,
		new_removal_result,
		null,
		null,
		new_removal_result.removed_occupant_id,
		new_removal_result.position,
		0,
		new_removal_result.message
	)


static func tower_missing(missing_position: Vector2i, missing_tower_id: String) -> TowerRemovalResult:
	return TowerRemovalResult.new(
		false,
		FailureReason.TOWER_MISSING,
		null,
		null,
		null,
		missing_tower_id,
		missing_position,
		0,
		"Tower does not exist."
	)


static func refund_failure(
	new_removal_result: RemovalResult,
	new_refund_transaction_result: TransactionResult,
	new_removed_tower: GameTower,
	new_refund_amount: int
) -> TowerRemovalResult:
	return TowerRemovalResult.new(
		false,
		FailureReason.REFUND_FAILED,
		new_removal_result,
		new_refund_transaction_result,
		new_removed_tower,
		new_removed_tower.id,
		new_removed_tower.grid_position,
		new_refund_amount,
		new_refund_transaction_result.message
	)
