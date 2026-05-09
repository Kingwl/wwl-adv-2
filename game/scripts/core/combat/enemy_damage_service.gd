class_name EnemyDamageService
extends RefCounted


func apply_damage_events(enemies: Array, damage_events: Array) -> EnemyDamageResult:
	var enemy_by_id := _index_enemies(enemies)
	var applied_damage_events := []
	var death_events := []
	var ignored_damage_events := []

	for candidate in damage_events:
		var damage_event := candidate as DamageEvent
		if damage_event == null:
			continue

		var enemy := enemy_by_id.get(damage_event.enemy_id, null) as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			ignored_damage_events.append(damage_event)
			continue

		var defeated_now := enemy.apply_damage(damage_event.amount)
		applied_damage_events.append(damage_event)

		if defeated_now:
			death_events.append(
				EnemyDeathEvent.new(
					enemy.id,
					enemy.kill_reward,
					damage_event.source_tower_id
				)
			)

	return EnemyDamageResult.new(applied_damage_events, death_events, ignored_damage_events)


func _index_enemies(enemies: Array) -> Dictionary:
	var enemy_by_id := {}

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null:
			continue

		enemy_by_id[enemy.id] = enemy

	return enemy_by_id
