class_name BoardMessage
extends RefCounted

enum Code {
	EMPTY,
	TEXT,
	SELECT_TOWER_PROMPT,
	PLACE_TOWER_HINT,
	SELECTED_TOWER_HINT,
	TOWER_SELECTED,
	TOWER_ACTION_HINT,
	TOWER_PLACED,
	TOWER_PLACE_FAILED,
	TOWER_UPGRADED,
	TOWER_UPGRADE_FAILED,
	TOWER_MAX_TIER,
	TOWER_REMOVED,
	TOWER_REMOVE_FAILED,
	KILL_REWARD,
	WAVE_CLEAR_REWARD,
	GOLD_EARNED,
	ENEMY_LEAKED,
	VICTORY,
	DEFEAT,
}

var code: int
var values: Dictionary
var full_text: String
var compact_text: String


func _init(
	new_code: int = Code.EMPTY,
	new_values: Dictionary = {},
	new_full_text: String = "",
	new_compact_text: String = ""
) -> void:
	code = new_code
	values = new_values.duplicate(true)
	full_text = new_full_text
	compact_text = new_compact_text


func display_text(compact: bool) -> String:
	if compact and not compact_text.is_empty():
		return compact_text
	return full_text


static func create(
	new_code: int,
	new_values: Dictionary,
	new_full_text: String,
	new_compact_text: String = ""
) -> BoardMessage:
	return BoardMessage.new(new_code, new_values, new_full_text, new_compact_text)


static func empty() -> BoardMessage:
	return create(Code.EMPTY, {}, "")


static func text(new_full_text: String, new_compact_text: String = "") -> BoardMessage:
	return create(Code.TEXT, {}, new_full_text, new_compact_text)


static func select_tower_prompt() -> BoardMessage:
	return create(
		Code.SELECT_TOWER_PROMPT,
		{},
		"Select a tower, then click an open tile.",
		"Select tower."
	)


static func place_tower_hint() -> BoardMessage:
	return create(
		Code.PLACE_TOWER_HINT,
		{},
		"Click a green slot to place a tower.",
		"Place on green tile."
	)


static func selected_tower_hint(tower_label: String, cost: int) -> BoardMessage:
	return create(
		Code.SELECTED_TOWER_HINT,
		{"tower_label": tower_label, "cost": cost},
		"%s tower: %dg. Enemies follow the paved road." % [tower_label, cost],
		"%s tower: %dg" % [tower_label, cost]
	)


static func tower_selected(tower_label: String, tier: int) -> BoardMessage:
	return create(
		Code.TOWER_SELECTED,
		{"tower_label": tower_label, "tier": tier},
		"%s T%d selected." % [tower_label, tier],
		"%s T%d selected." % [tower_label, tier]
	)


static func tower_action_hint() -> BoardMessage:
	return create(
		Code.TOWER_ACTION_HINT,
		{},
		"Upgrade or remove this tower.",
		"Upgrade/remove tower."
	)


static func tower_placed(tower_id: String, grid_position: Vector2i, amount: int) -> BoardMessage:
	return create(
		Code.TOWER_PLACED,
		{"tower_id": tower_id, "grid_position": grid_position, "amount": amount},
		"Placed %s at (%d, %d) for %d gold." % [tower_id, grid_position.x, grid_position.y, amount],
		"Tower placed."
	)


static func tower_place_failed(
	grid_position: Vector2i,
	reason: String,
	compact_reason: String = "Cannot place."
) -> BoardMessage:
	return create(
		Code.TOWER_PLACE_FAILED,
		{"grid_position": grid_position, "reason": reason},
		"Cannot place at (%d, %d): %s" % [grid_position.x, grid_position.y, reason],
		compact_reason
	)


static func tower_upgraded(tower_id: String, tower_label: String, tier: int, cost: int) -> BoardMessage:
	return create(
		Code.TOWER_UPGRADED,
		{"tower_id": tower_id, "tower_label": tower_label, "tier": tier, "cost": cost},
		"Upgraded %s to %s T%d for %d gold." % [tower_id, tower_label, tier, cost],
		"Tower upgraded."
	)


static func tower_upgrade_failed(
	tower_id: String,
	reason: String,
	compact_reason: String = "Cannot upgrade."
) -> BoardMessage:
	return create(
		Code.TOWER_UPGRADE_FAILED,
		{"tower_id": tower_id, "reason": reason},
		"Cannot upgrade %s: %s" % [tower_id, reason],
		compact_reason
	)


static func tower_max_tier(tower_id: String) -> BoardMessage:
	return create(
		Code.TOWER_MAX_TIER,
		{"tower_id": tower_id},
		"%s is fully upgraded." % tower_id,
		"Max tier."
	)


static func tower_removed(tower_id: String, refund_amount: int) -> BoardMessage:
	return create(
		Code.TOWER_REMOVED,
		{"tower_id": tower_id, "refund_amount": refund_amount},
		"Removed %s for %d gold refund." % [tower_id, refund_amount],
		"+%d refund" % refund_amount
	)


static func tower_remove_failed_at(
	grid_position: Vector2i,
	reason: String,
	compact_reason: String = "Cannot remove."
) -> BoardMessage:
	return create(
		Code.TOWER_REMOVE_FAILED,
		{"grid_position": grid_position, "reason": reason},
		"Cannot remove at (%d, %d): %s" % [grid_position.x, grid_position.y, reason],
		compact_reason
	)


static func tower_remove_failed(
	tower_id: String,
	reason: String,
	compact_reason: String = "Cannot remove."
) -> BoardMessage:
	return create(
		Code.TOWER_REMOVE_FAILED,
		{"tower_id": tower_id, "reason": reason},
		"Cannot remove %s: %s" % [tower_id, reason],
		compact_reason
	)


static func kill_reward(enemy_id: String, amount: int) -> BoardMessage:
	return create(
		Code.KILL_REWARD,
		{"enemy_id": enemy_id, "amount": amount},
		"Defeated %s for %d gold." % [enemy_id, amount],
		"+%d gold" % amount
	)


static func wave_clear_reward(wave_id: String, amount: int) -> BoardMessage:
	return create(
		Code.WAVE_CLEAR_REWARD,
		{"wave_id": wave_id, "amount": amount},
		"Cleared %s for %d gold." % [wave_id, amount],
		"Wave clear +%d" % amount
	)


static func gold_earned(amount: int) -> BoardMessage:
	return create(
		Code.GOLD_EARNED,
		{"amount": amount},
		"Earned %d gold." % amount,
		"+%d gold" % amount
	)


static func enemy_leaked(lives: int) -> BoardMessage:
	return create(
		Code.ENEMY_LEAKED,
		{"lives": lives},
		"Enemy leaked. Lives: %d" % lives
	)


static func victory() -> BoardMessage:
	return create(
		Code.VICTORY,
		{},
		"Victory. All waves cleared."
	)


static func defeat() -> BoardMessage:
	return create(
		Code.DEFEAT,
		{},
		"Defeat. Enemies breached the path."
	)
