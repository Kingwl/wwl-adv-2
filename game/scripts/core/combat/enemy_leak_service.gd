class_name EnemyLeakService
extends RefCounted

var _leaked_enemy_ids := {}


func collect_leak_events(enemies: Array) -> Array:
	var leak_events := []

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.defeated or not enemy.completed:
			continue

		if _leaked_enemy_ids.has(enemy.id):
			continue

		_leaked_enemy_ids[enemy.id] = true
		leak_events.append(EnemyLeakEvent.new(enemy.id))

	return leak_events
