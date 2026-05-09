class_name PlacementResult
extends RefCounted

enum FailureReason {
	NONE,
	OUT_OF_BOUNDS,
	NOT_BUILDABLE,
	OCCUPIED,
	RESERVED,
}

var succeeded: bool
var failure_reason: FailureReason
var message: String
var position: Vector2i
var occupant_id: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_message: String,
	new_position: Vector2i,
	new_occupant_id: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	message = new_message
	position = new_position
	occupant_id = new_occupant_id


static func success(new_position: Vector2i, new_occupant_id: String) -> PlacementResult:
	return PlacementResult.new(
		true,
		FailureReason.NONE,
		"Placement succeeded.",
		new_position,
		new_occupant_id
	)


static func failure(
	reason: FailureReason,
	failure_message: String,
	failure_position: Vector2i,
	current_occupant_id: String = ""
) -> PlacementResult:
	return PlacementResult.new(
		false,
		reason,
		failure_message,
		failure_position,
		current_occupant_id
	)
