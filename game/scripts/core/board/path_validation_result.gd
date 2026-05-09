class_name PathValidationResult
extends RefCounted

enum FailureReason {
	NONE,
	TOO_SHORT,
	OUT_OF_BOUNDS,
	NOT_PATH_SLOT,
	NOT_CONTIGUOUS,
}

var succeeded: bool
var failure_reason: FailureReason
var message: String
var position: Vector2i


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_message: String,
	new_position: Vector2i
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	message = new_message
	position = new_position


static func success() -> PathValidationResult:
	return PathValidationResult.new(
		true,
		FailureReason.NONE,
		"Path is valid.",
		Vector2i(-1, -1)
	)


static func failure(
	reason: FailureReason,
	failure_message: String,
	failure_position: Vector2i = Vector2i(-1, -1)
) -> PathValidationResult:
	return PathValidationResult.new(
		false,
		reason,
		failure_message,
		failure_position
	)
