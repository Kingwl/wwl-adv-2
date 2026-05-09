class_name WaveSpawner
extends RefCounted

const FLOAT_EPSILON := 0.000001

var wave_definitions: Array
var current_wave_index: int
var current_wave_state: WaveState
var all_waves_cleared: bool


func _init(new_wave_definitions: Array) -> void:
	assert(not new_wave_definitions.is_empty(), "At least one wave definition is required.")

	wave_definitions = []
	for candidate in new_wave_definitions:
		var wave_definition := candidate as WaveDefinition
		assert(wave_definition != null, "Wave definitions must contain only WaveDefinition values.")
		wave_definitions.append(wave_definition)

	current_wave_index = 0
	current_wave_state = WaveState.new(wave_definitions[current_wave_index])
	all_waves_cleared = false


func advance(delta_seconds: float, existing_enemies: Array) -> WaveSpawnResult:
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	if all_waves_cleared:
		return WaveSpawnResult.new([], [], current_wave_index, true)

	current_wave_state.refresh_active_enemies(existing_enemies)
	if current_wave_state.is_complete():
		var clear_event := WaveClearEvent.new(
			current_wave_state.wave_definition.wave_id,
			current_wave_state.wave_definition.clear_reward_gold
		)
		_advance_to_next_wave()
		return WaveSpawnResult.new([], [clear_event], current_wave_index, all_waves_cleared)

	var spawned_enemies := _spawn_enemies(delta_seconds)
	return WaveSpawnResult.new(spawned_enemies, [], current_wave_index, all_waves_cleared)


func _spawn_enemies(delta_seconds: float) -> Array:
	var spawned_enemies := []
	var wave_definition := current_wave_state.wave_definition

	if current_wave_state.spawned_count >= wave_definition.enemy_count:
		return spawned_enemies

	current_wave_state.started = true
	current_wave_state.spawn_elapsed_seconds += delta_seconds

	while (
		current_wave_state.spawn_elapsed_seconds + FLOAT_EPSILON >= wave_definition.spawn_interval_seconds
		and current_wave_state.spawned_count < wave_definition.enemy_count
	):
		current_wave_state.spawn_elapsed_seconds -= wave_definition.spawn_interval_seconds
		var enemy := _create_enemy(wave_definition, current_wave_state.spawned_count + 1)
		current_wave_state.spawned_count += 1
		current_wave_state.track_enemy(enemy)
		spawned_enemies.append(enemy)

	if current_wave_state.spawned_count >= wave_definition.enemy_count:
		current_wave_state.spawn_elapsed_seconds = 0.0

	return spawned_enemies


func _create_enemy(wave_definition: WaveDefinition, sequence_number: int) -> Enemy:
	return Enemy.new(
		"%s-enemy-%d" % [wave_definition.wave_id, sequence_number],
		wave_definition.enemy_speed_cells_per_second,
		wave_definition.enemy_max_health,
		wave_definition.enemy_kill_reward
	)


func _advance_to_next_wave() -> void:
	current_wave_state.cleared = true
	current_wave_index += 1

	if current_wave_index >= wave_definitions.size():
		all_waves_cleared = true
		current_wave_state = null
		return

	current_wave_state = WaveState.new(wave_definitions[current_wave_index])
