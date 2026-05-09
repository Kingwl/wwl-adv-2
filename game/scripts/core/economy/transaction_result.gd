class_name TransactionResult
extends RefCounted

enum FailureReason {
	NONE,
	INVALID_AMOUNT,
	INSUFFICIENT_FUNDS,
}

var succeeded: bool
var failure_reason: FailureReason
var reason: TransactionRecord.Reason
var amount: int
var balance_before: int
var balance_after: int
var reference_id: String
var message: String


func _init(
	new_succeeded: bool,
	new_failure_reason: FailureReason,
	new_reason: TransactionRecord.Reason,
	new_amount: int,
	new_balance_before: int,
	new_balance_after: int,
	new_reference_id: String,
	new_message: String
) -> void:
	succeeded = new_succeeded
	failure_reason = new_failure_reason
	reason = new_reason
	amount = new_amount
	balance_before = new_balance_before
	balance_after = new_balance_after
	reference_id = new_reference_id
	message = new_message


static func success(
	new_reason: TransactionRecord.Reason,
	new_amount: int,
	new_balance_before: int,
	new_balance_after: int,
	new_reference_id: String = "",
	success_message: String = "Transaction succeeded."
) -> TransactionResult:
	return TransactionResult.new(
		true,
		FailureReason.NONE,
		new_reason,
		new_amount,
		new_balance_before,
		new_balance_after,
		new_reference_id,
		success_message
	)


static func failure(
	new_failure_reason: FailureReason,
	new_reason: TransactionRecord.Reason,
	new_amount: int,
	current_balance: int,
	new_reference_id: String = "",
	failure_message: String = "Transaction failed."
) -> TransactionResult:
	return TransactionResult.new(
		false,
		new_failure_reason,
		new_reason,
		new_amount,
		current_balance,
		current_balance,
		new_reference_id,
		failure_message
	)
