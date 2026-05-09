class_name TowerMergeResult
extends RefCounted

enum FailureReason {
	NONE,
	SAME_TOWER,
	TYPE_MISMATCH,
	TIER_MISMATCH,
}

var succeeded: bool
var merged_tower: GameTower
var consumed_tower_ids: Array[String]
var failure_reason: FailureReason
var message: String


func _init(
	new_succeeded: bool,
	new_merged_tower: GameTower,
	new_consumed_tower_ids: Array[String],
	new_failure_reason: FailureReason,
	new_message: String
) -> void:
	succeeded = new_succeeded
	merged_tower = new_merged_tower
	consumed_tower_ids = new_consumed_tower_ids
	failure_reason = new_failure_reason
	message = new_message


static func success(new_merged_tower: GameTower, new_consumed_tower_ids: Array[String]) -> TowerMergeResult:
	return TowerMergeResult.new(
		true,
		new_merged_tower,
		new_consumed_tower_ids,
		FailureReason.NONE,
		"Merge succeeded."
	)


static func failure(reason: FailureReason, failure_message: String) -> TowerMergeResult:
	return TowerMergeResult.new(
		false,
		null,
		[],
		reason,
		failure_message
	)
