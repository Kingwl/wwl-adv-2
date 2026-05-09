class_name RemovalResult
extends RefCounted

enum FailureReason {
	NONE,
	OUT_OF_BOUNDS,
	EMPTY,
	OCCUPANT_MISMATCH,
}

var succeeded: bool
var failure_reason: FailureReason
var message: String
var position: Vector2i
var removed_occupant_id: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_message: String,
	new_position: Vector2i,
	new_removed_occupant_id: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	message = new_message
	position = new_position
	removed_occupant_id = new_removed_occupant_id


static func success(new_position: Vector2i, occupant_id: String) -> RemovalResult:
	return RemovalResult.new(
		true,
		FailureReason.NONE,
		"Removal succeeded.",
		new_position,
		occupant_id
	)


static func failure(
	reason: FailureReason,
	failure_message: String,
	failure_position: Vector2i,
	current_occupant_id: String = ""
) -> RemovalResult:
	return RemovalResult.new(
		false,
		reason,
		failure_message,
		failure_position,
		current_occupant_id
	)
