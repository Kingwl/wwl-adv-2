class_name WaveConfig
extends RefCounted

const DEFAULT_WAVE_DEFINITION_PATH := "res://data/waves/waves.json"
const WAVE_DEFINITION_PATH_TEMPLATE := "res://data/waves/%s.json"

const WAVES_KEY := "waves"
const ID_KEY := "id"
const ENEMY_TYPE_KEY := "enemy_type"
const ENEMY_COUNT_KEY := "enemy_count"
const SPAWN_INTERVAL_SECONDS_KEY := "spawn_interval_seconds"
const CLEAR_REWARD_GOLD_KEY := "clear_reward_gold"


static func wave_set_path(wave_set_id: String) -> String:
	if wave_set_id.is_empty():
		return DEFAULT_WAVE_DEFINITION_PATH
	return WAVE_DEFINITION_PATH_TEMPLATE % wave_set_id


static func load_definitions_for_wave_set_id(wave_set_id: String, enemy_catalog: EnemyCatalog = null) -> Array:
	return load_definitions_from_path(wave_set_path(wave_set_id), enemy_catalog)


static func load_definitions_for_level(level_definition: LevelDefinition, enemy_catalog: EnemyCatalog = null) -> Array:
	if level_definition == null:
		return load_definitions_from_path(DEFAULT_WAVE_DEFINITION_PATH, enemy_catalog)
	return load_definitions_for_wave_set_id(level_definition.wave_set_id, enemy_catalog)


static func load_definitions_from_path(resource_path: String, enemy_catalog: EnemyCatalog = null) -> Array:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load wave definitions: %s" % resource_path)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Wave definitions must be a JSON object: %s" % resource_path)
		return []

	return definitions_from_dictionary(parsed as Dictionary, enemy_catalog)


static func definitions_from_dictionary(data: Dictionary, enemy_catalog: EnemyCatalog = null) -> Array:
	var waves := []
	var wave_entries := data.get(WAVES_KEY, []) as Array
	if wave_entries == null:
		return waves

	var catalog := enemy_catalog if enemy_catalog != null else EnemyCatalog.new()
	for candidate in wave_entries:
		var wave_data := candidate as Dictionary
		if wave_data == null:
			continue

		var enemy_type_id := str(wave_data.get(ENEMY_TYPE_KEY, ""))
		var enemy_definition := catalog.get_definition(enemy_type_id)
		if enemy_definition == null:
			continue

		waves.append(WaveDefinition.new(
			str(wave_data.get(ID_KEY, "")),
			int(wave_data.get(ENEMY_COUNT_KEY, 0)),
			float(wave_data.get(SPAWN_INTERVAL_SECONDS_KEY, 0.0)),
			enemy_definition.max_health,
			enemy_definition.speed_cells_per_second,
			enemy_definition.kill_reward,
			int(wave_data.get(CLEAR_REWARD_GOLD_KEY, 0)),
			enemy_definition.id,
			enemy_definition.armor_type,
			enemy_definition.race_type,
			enemy_definition.school_resistance_overrides
		))

	return waves


static func validate_data(data: Dictionary, enemy_catalog: EnemyCatalog) -> Array:
	var errors := []
	var seen_ids := {}
	var wave_entries := data.get(WAVES_KEY, []) as Array
	if wave_entries == null or wave_entries.is_empty():
		errors.append("At least one wave definition is required.")
		return errors

	for candidate in wave_entries:
		var wave_data := candidate as Dictionary
		if wave_data == null:
			errors.append("Wave definition must be a dictionary.")
			continue

		var wave_id := str(wave_data.get(ID_KEY, ""))
		if wave_id.is_empty():
			errors.append("Wave id is required.")
			continue
		if seen_ids.has(wave_id):
			errors.append("Duplicate wave id: %s." % wave_id)
			continue
		seen_ids[wave_id] = true

		_validate_wave_definition(errors, wave_id, wave_data, enemy_catalog)

	return errors


static func _validate_wave_definition(
	errors: Array,
	wave_id: String,
	wave_data: Dictionary,
	enemy_catalog: EnemyCatalog
) -> void:
	var enemy_type_id := str(wave_data.get(ENEMY_TYPE_KEY, ""))
	if enemy_type_id.is_empty():
		errors.append("%s enemy_type is required." % wave_id)
	elif enemy_catalog == null or not enemy_catalog.has_definition(enemy_type_id):
		errors.append("%s enemy_type is unknown: %s." % [wave_id, enemy_type_id])

	if int(wave_data.get(ENEMY_COUNT_KEY, 0)) <= 0:
		errors.append("%s enemy_count must be positive." % wave_id)
	if float(wave_data.get(SPAWN_INTERVAL_SECONDS_KEY, 0.0)) <= 0.0:
		errors.append("%s spawn_interval_seconds must be positive." % wave_id)
	if int(wave_data.get(CLEAR_REWARD_GOLD_KEY, 0)) < 0:
		errors.append("%s clear_reward_gold cannot be negative." % wave_id)
