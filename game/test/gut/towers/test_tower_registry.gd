extends GutTest


func test_add_and_get_tower_by_id() -> void:
	var registry := TowerRegistry.new()
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(2, 1))

	registry.add_tower(tower)

	assert_true(registry.has_tower("tower-a"))
	assert_eq(registry.get_tower("tower-a"), tower)


func test_remove_tower_returns_and_deletes_existing_tower() -> void:
	var registry := TowerRegistry.new()
	var tower := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1, Vector2i(2, 1))
	registry.add_tower(tower)

	var removed_tower := registry.remove_tower("tower-a")

	assert_eq(removed_tower, tower)
	assert_false(registry.has_tower("tower-a"))
	assert_null(registry.get_tower("tower-a"))


func test_get_all_towers_returns_registered_towers() -> void:
	var registry := TowerRegistry.new()
	var tower_a := GameTower.new("tower-a", GameTower.Type.SINGLE_TARGET, 1)
	var tower_b := GameTower.new("tower-b", GameTower.Type.AREA, 1)

	registry.add_tower(tower_a)
	registry.add_tower(tower_b)

	var towers := registry.get_all_towers()

	assert_eq(towers.size(), 2)
	assert_has(towers, tower_a)
	assert_has(towers, tower_b)
