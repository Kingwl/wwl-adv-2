class_name TowerPlacementResult
extends RefCounted

enum FailureReason {
	NONE,
	PLACEMENT_FAILED,
	INSUFFICIENT_FUNDS,
	TRANSACTION_FAILED,
}

var succeeded: bool
var failure_reason: FailureReason
var placement_result: PlacementResult
var transaction_result: TransactionResult
var tower_id: String
var position: Vector2i
var message: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_placement_result: PlacementResult,
	new_transaction_result: TransactionResult,
	new_tower_id: String,
	new_position: Vector2i,
	new_message: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	placement_result = new_placement_result
	transaction_result = new_transaction_result
	tower_id = new_tower_id
	position = new_position
	message = new_message


static func success(
	new_placement_result: PlacementResult,
	new_transaction_result: TransactionResult,
	new_tower_id: String,
	new_position: Vector2i
) -> TowerPlacementResult:
	return TowerPlacementResult.new(
		true,
		FailureReason.NONE,
		new_placement_result,
		new_transaction_result,
		new_tower_id,
		new_position,
		"Placed %s for %d gold." % [new_tower_id, new_transaction_result.amount]
	)


static func placement_failure(
	new_placement_result: PlacementResult,
	new_tower_id: String,
	new_position: Vector2i
) -> TowerPlacementResult:
	return TowerPlacementResult.new(
		false,
		FailureReason.PLACEMENT_FAILED,
		new_placement_result,
		null,
		new_tower_id,
		new_position,
		new_placement_result.message
	)


static func transaction_failure(
	new_failure_reason: FailureReason,
	new_transaction_result: TransactionResult,
	new_tower_id: String,
	new_position: Vector2i
) -> TowerPlacementResult:
	return TowerPlacementResult.new(
		false,
		new_failure_reason,
		null,
		new_transaction_result,
		new_tower_id,
		new_position,
		new_transaction_result.message
	)
