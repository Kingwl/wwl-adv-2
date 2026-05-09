class_name WaveState
extends RefCounted

var wave_definition: WaveDefinition
var started: bool
var cleared: bool
var spawned_count: int
var spawn_elapsed_seconds: float
var active_enemy_ids: Dictionary


func _init(new_wave_definition: WaveDefinition) -> void:
	assert(new_wave_definition != null, "Wave definition is required.")

	wave_definition = new_wave_definition
	started = false
	cleared = false
	spawned_count = 0
	spawn_elapsed_seconds = 0.0
	active_enemy_ids = {}


func track_enemy(enemy: Enemy) -> void:
	assert(enemy != null, "Enemy is required.")

	active_enemy_ids[enemy.id] = true


func refresh_active_enemies(existing_enemies: Array) -> void:
	var enemies_by_id := _index_enemies(existing_enemies)

	for enemy_id in active_enemy_ids.keys():
		var enemy := enemies_by_id.get(enemy_id, null) as Enemy
		if enemy != null and (enemy.defeated or enemy.completed):
			active_enemy_ids.erase(enemy_id)


func is_complete() -> bool:
	return spawned_count >= wave_definition.enemy_count and active_enemy_ids.is_empty()


func _index_enemies(existing_enemies: Array) -> Dictionary:
	var enemies_by_id := {}

	for candidate in existing_enemies:
		var enemy := candidate as Enemy
		if enemy == null:
			continue

		enemies_by_id[enemy.id] = enemy

	return enemies_by_id
