class_name TowerMergeService
extends RefCounted

var _id_factory: Callable


func _init(id_factory: Callable = Callable()) -> void:
	_id_factory = id_factory


func try_merge(first: GameTower, second: GameTower) -> TowerMergeResult:
	assert(first != null, "First tower is required.")
	assert(second != null, "Second tower is required.")

	if first.id == second.id:
		return TowerMergeResult.failure(
			TowerMergeResult.FailureReason.SAME_TOWER,
			"A tower cannot merge with itself."
		)

	if first.tower_type != second.tower_type:
		return TowerMergeResult.failure(
			TowerMergeResult.FailureReason.TYPE_MISMATCH,
			"Only towers of the same type can merge."
		)

	if first.tier != second.tier:
		return TowerMergeResult.failure(
			TowerMergeResult.FailureReason.TIER_MISMATCH,
			"Only towers of the same tier can merge."
		)

	var merged_tower := GameTower.new(_next_id(), first.tower_type, first.tier + 1)
	return TowerMergeResult.success(merged_tower, [first.id, second.id])


func _next_id() -> String:
	if _id_factory.is_valid():
		return str(_id_factory.call())

	return "%d" % Time.get_ticks_usec()
