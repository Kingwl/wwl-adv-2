class_name TransactionRecord
extends RefCounted

enum Reason {
	STARTING_GOLD,
	PLACE_TOWER,
	UPGRADE_TOWER,
	KILL_ENEMY,
	CLEAR_WAVE,
	REFUND,
	DEBUG,
}

var reason: Reason
var amount: int
var balance_before: int
var balance_after: int
var reference_id: String


func _init(
	new_reason: Reason,
	new_amount: int,
	new_balance_before: int,
	new_balance_after: int,
	new_reference_id: String = ""
) -> void:
	reason = new_reason
	amount = new_amount
	balance_before = new_balance_before
	balance_after = new_balance_after
	reference_id = new_reference_id
