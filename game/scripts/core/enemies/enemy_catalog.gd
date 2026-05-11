class_name EnemyCatalog
extends RefCounted

const DEFAULT_ENEMY_DEFINITION_PATH := "res://data/enemies/enemies.json"
const ENEMIES_KEY := "enemies"

var enemy_definitions: Dictionary


func _init(new_enemy_definitions: Dictionary = {}) -> void:
	if new_enemy_definitions.is_empty():
		enemy_definitions = load_definitions_from_path(DEFAULT_ENEMY_DEFINITION_PATH)
	else:
		enemy_definitions = new_enemy_definitions.duplicate(true)

	var validation_errors := validate_definitions(enemy_definitions)
	assert(
		validation_errors.is_empty(),
		"Invalid enemy catalog: %s" % "; ".join(validation_errors)
	)


func has_definition(enemy_type_id: String) -> bool:
	return enemy_definitions.has(enemy_type_id)


func get_definition(enemy_type_id: String) -> EnemyDefinition:
	return enemy_definitions.get(enemy_type_id, null) as EnemyDefinition


static func load_definitions_from_path(resource_path: String) -> Dictionary:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load enemy definitions: %s" % resource_path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Enemy definitions must be a JSON object: %s" % resource_path)
		return {}

	return definitions_from_dictionary(parsed as Dictionary)


static func definitions_from_dictionary(data: Dictionary) -> Dictionary:
	var definitions := {}
	var enemy_entries := data.get(ENEMIES_KEY, []) as Array
	if enemy_entries == null:
		return definitions

	for candidate in enemy_entries:
		var enemy_data := candidate as Dictionary
		if enemy_data == null:
			continue

		var definition := EnemyDefinition.from_dictionary(enemy_data)
		definitions[definition.id] = definition

	return definitions


static func validate_data(data: Dictionary) -> Array:
	var errors := []
	var seen_ids := {}
	var enemy_entries := data.get(ENEMIES_KEY, []) as Array
	if enemy_entries == null or enemy_entries.is_empty():
		errors.append("At least one enemy definition is required.")
		return errors

	for candidate in enemy_entries:
		var enemy_data := candidate as Dictionary
		if enemy_data == null:
			errors.append("Enemy definition must be a dictionary.")
			continue

		var enemy_id := str(enemy_data.get(EnemyDefinition.ID_KEY, ""))
		if enemy_id.is_empty():
			errors.append("Enemy id is required.")
			continue
		if seen_ids.has(enemy_id):
			errors.append("Duplicate enemy id: %s." % enemy_id)
			continue
		seen_ids[enemy_id] = true

		_validate_enemy_definition(errors, enemy_id, enemy_data)

	return errors


static func validate_definitions(definitions: Dictionary) -> Array:
	var errors := []
	if definitions.is_empty():
		errors.append("At least one enemy definition is required.")
		return errors

	for enemy_id in definitions.keys():
		var definition := definitions[enemy_id] as EnemyDefinition
		if definition == null:
			errors.append("%s definition must be an EnemyDefinition." % enemy_id)
			continue

		_validate_enemy_definition(errors, str(enemy_id), {
			EnemyDefinition.ID_KEY: definition.id,
			EnemyDefinition.DISPLAY_NAME_KEY: definition.display_name,
			EnemyDefinition.SPEED_KEY: definition.speed_cells_per_second,
			EnemyDefinition.MAX_HEALTH_KEY: definition.max_health,
			EnemyDefinition.KILL_REWARD_KEY: definition.kill_reward,
			EnemyDefinition.ARMOR_TYPE_KEY: definition.armor_type,
			EnemyDefinition.RACE_TYPE_KEY: definition.race_type,
		})

	return errors


static func _validate_enemy_definition(errors: Array, enemy_id: String, enemy_data: Dictionary) -> void:
	if str(enemy_data.get(EnemyDefinition.DISPLAY_NAME_KEY, "")).is_empty():
		errors.append("%s display_name is required." % enemy_id)
	if float(enemy_data.get(EnemyDefinition.SPEED_KEY, 0.0)) <= 0.0:
		errors.append("%s speed_cells_per_second must be positive." % enemy_id)
	if float(enemy_data.get(EnemyDefinition.MAX_HEALTH_KEY, 0.0)) <= 0.0:
		errors.append("%s max_health must be positive." % enemy_id)
	if int(enemy_data.get(EnemyDefinition.KILL_REWARD_KEY, 0)) < 0:
		errors.append("%s kill_reward cannot be negative." % enemy_id)
	if EnemyDefinition.armor_type_from_value(enemy_data.get(EnemyDefinition.ARMOR_TYPE_KEY, -1)) < 0:
		errors.append("%s armor_type is invalid." % enemy_id)
	if EnemyDefinition.race_type_from_value(enemy_data.get(EnemyDefinition.RACE_TYPE_KEY, -1)) < 0:
		errors.append("%s race_type is invalid." % enemy_id)

	var resistance_overrides := enemy_data.get(EnemyDefinition.SCHOOL_RESISTANCE_OVERRIDES_KEY, {}) as Dictionary
	if resistance_overrides == null:
		errors.append("%s school_resistance_overrides must be a dictionary." % enemy_id)
		return

	for key in resistance_overrides.keys():
		if EnemyDefinition.damage_school_from_value(key) < 0:
			errors.append("%s school_resistance_overrides has invalid damage school: %s." % [enemy_id, key])
