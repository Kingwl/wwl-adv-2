extends GutTest


func test_try_merge_with_same_type_and_tier_returns_next_tier_tower() -> void:
	var first := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)
	var second := GameTower.new("tower-b", GameTower.Type.SINGLE_TARGET, 1)
	var service := TowerMergeService.new(func() -> String: return "tower-c")

	var result := service.try_merge(first, second)

	assert_true(result.succeeded)
	assert_not_null(result.merged_tower)
	assert_eq(result.merged_tower.id, "tower-c")
	assert_eq(result.merged_tower.tower_type, GameTower.Type.SINGLE_TARGET)
	assert_eq(result.merged_tower.tier, 2)
	assert_eq(result.consumed_tower_ids, ["tower-a", "tower-b"])
	assert_eq(result.failure_reason, TowerMergeResult.FailureReason.NONE)


func test_try_merge_with_different_types_returns_structured_failure() -> void:
	var first := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)
	var second := GameTower.new("tower-b", GameTower.Type.AREA, 1)
	var service := TowerMergeService.new(func() -> String: return "tower-c")

	var result := service.try_merge(first, second)

	assert_false(result.succeeded)
	assert_null(result.merged_tower)
	assert_eq(result.consumed_tower_ids, [])
	assert_eq(result.failure_reason, TowerMergeResult.FailureReason.TYPE_MISMATCH)


func test_try_merge_with_different_tiers_returns_structured_failure() -> void:
	var first := GameTower.new("tower-a", GameTower.Type.SLOW, 1)
	var second := GameTower.new("tower-b", GameTower.Type.SLOW, 2)
	var service := TowerMergeService.new(func() -> String: return "tower-c")

	var result := service.try_merge(first, second)

	assert_false(result.succeeded)
	assert_null(result.merged_tower)
	assert_eq(result.consumed_tower_ids, [])
	assert_eq(result.failure_reason, TowerMergeResult.FailureReason.TIER_MISMATCH)


func test_try_merge_with_same_tower_returns_structured_failure() -> void:
	var first := GameTower.new("tower-a", GameTower.Type.AREA, 1)
	var second := GameTower.new("tower-a", GameTower.Type.AREA, 1)
	var service := TowerMergeService.new(func() -> String: return "tower-c")

	var result := service.try_merge(first, second)

	assert_false(result.succeeded)
	assert_null(result.merged_tower)
	assert_eq(result.consumed_tower_ids, [])
	assert_eq(result.failure_reason, TowerMergeResult.FailureReason.SAME_TOWER)
