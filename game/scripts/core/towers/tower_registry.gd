class_name TowerRegistry
extends RefCounted

var _towers := {}


func add_tower(tower: GameTower) -> void:
	assert(tower != null, "Tower is required.")

	_towers[tower.id] = tower


func get_tower(tower_id: String) -> GameTower:
	return _towers.get(tower_id, null)


func has_tower(tower_id: String) -> bool:
	return _towers.has(tower_id)


func remove_tower(tower_id: String) -> GameTower:
	var tower := get_tower(tower_id)
	if tower != null:
		_towers.erase(tower_id)

	return tower


func get_all_towers() -> Array:
	return _towers.values()
