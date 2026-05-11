class_name TowerDefinitionParser
extends RefCounted


static func load_definitions_from_path(resource_path: String) -> Dictionary:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Cannot load tower definitions: %s" % resource_path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Tower definitions must be a JSON object: %s" % resource_path)
		return {}

	return definitions_from_dictionary(parsed as Dictionary)


static func definitions_from_dictionary(data: Dictionary) -> Dictionary:
	var definitions := {}
	var tower_entries := data.get(TowerConfig.TOWERS_KEY, []) as Array
	if tower_entries == null:
		return definitions

	for candidate in tower_entries:
		var tower_data := candidate as Dictionary
		if tower_data == null:
			continue

		var tower_type := TowerConfig._tower_type_from_value(tower_data.get(TowerConfig.TYPE_KEY, ""))
		definitions[tower_type] = tower_definition_from_data(tower_data, tower_type)

	return definitions


static func tower_definition_from_data(tower_data: Dictionary, tower_type: int) -> Dictionary:
	var projectile_data := tower_data.get(TowerConfig.PROJECTILE_KEY, {}) as Dictionary
	var visuals_data := tower_data.get(TowerConfig.VISUALS_KEY, {}) as Dictionary
	var tiers := []
	for candidate in tower_data.get(TowerConfig.TIERS_KEY, []):
		var tier_data := candidate as Dictionary
		if tier_data != null:
			tiers.append(tier_definition_from_data(tier_data))

	return {
		TowerConfig.ID_KEY: str(tower_data.get(TowerConfig.ID_KEY, TowerConfig._tower_type_id(tower_type))),
		TowerConfig.DISPLAY_NAME_KEY: str(tower_data.get(TowerConfig.DISPLAY_NAME_KEY, TowerConfig._tower_type_name(tower_type))),
		TowerConfig.DESCRIPTION_KEY: str(tower_data.get(TowerConfig.DESCRIPTION_KEY, "")),
		TowerConfig.BUILD_COST_KEY: int(tower_data.get(TowerConfig.BUILD_COST_KEY, TowerConfig.DEFAULT_BUILD_COST)),
		TowerConfig.WEAPON_TYPE_KEY: TowerConfig._weapon_type_from_value(tower_data.get(TowerConfig.WEAPON_TYPE_KEY, TowerConfig._default_weapon_type(tower_type))),
		TowerConfig.ATTACK_TYPE_KEY: TowerConfig._attack_type_from_value(tower_data.get(TowerConfig.ATTACK_TYPE_KEY, -1)),
		TowerConfig.DAMAGE_SCHOOL_KEY: TowerConfig._damage_school_from_value(tower_data.get(TowerConfig.DAMAGE_SCHOOL_KEY, TowerConfig._default_damage_school(tower_type))),
		TowerConfig.ATTACK_PATTERN_KEY: TowerConfig._attack_pattern_from_value(tower_data.get(TowerConfig.ATTACK_PATTERN_KEY, TowerConfig._default_attack_pattern(tower_type))),
		TowerConfig.VISUAL_TEST_ENABLED_KEY: bool(tower_data.get(TowerConfig.VISUAL_TEST_ENABLED_KEY, true)),
		TowerConfig.VISUALS_KEY: {
			TowerConfig.TOWER_TEXTURE_KEY: str(visuals_data.get(TowerConfig.TOWER_TEXTURE_KEY, "")),
			TowerConfig.PROJECTILE_TEXTURES_KEY: string_array_from_value(visuals_data.get(TowerConfig.PROJECTILE_TEXTURES_KEY, [])),
			TowerConfig.IMPACT_TEXTURES_KEY: string_array_from_value(visuals_data.get(TowerConfig.IMPACT_TEXTURES_KEY, [])),
		},
		TowerConfig.PROJECTILE_KEY: {
			TowerConfig.PROJECTILE_SPEED_KEY: float(projectile_data.get(TowerConfig.PROJECTILE_SPEED_KEY, TowerConfig.DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND)),
			TowerConfig.PROJECTILE_HIT_RADIUS_KEY: float(projectile_data.get(TowerConfig.PROJECTILE_HIT_RADIUS_KEY, TowerConfig.DEFAULT_PROJECTILE_HIT_RADIUS_CELLS)),
		},
		TowerConfig.TIERS_KEY: tiers,
	}


static func tier_definition_from_data(tier_data: Dictionary) -> Dictionary:
	var effects := []
	for candidate in tier_data.get(TowerConfig.EFFECTS_KEY, []):
		var effect_data := candidate as Dictionary
		if effect_data != null:
			effects.append(effect_definition_from_data(effect_data))

	var tier_definition := {
		TowerConfig.DAMAGE_KEY: float(tier_data.get(TowerConfig.DAMAGE_KEY, 0.0)),
		TowerConfig.RANGE_KEY: float(tier_data.get(TowerConfig.RANGE_KEY, 1.0)),
		TowerConfig.ATTACK_INTERVAL_KEY: float(tier_data.get(TowerConfig.ATTACK_INTERVAL_KEY, 1.0)),
		TowerConfig.EFFECTS_KEY: effects,
	}
	if tier_data.has(TowerConfig.UPGRADE_COST_KEY):
		tier_definition[TowerConfig.UPGRADE_COST_KEY] = int(tier_data[TowerConfig.UPGRADE_COST_KEY])
	if tier_data.has(TowerConfig.UPGRADE_PREVIEW_KEY):
		tier_definition[TowerConfig.UPGRADE_PREVIEW_KEY] = str(tier_data[TowerConfig.UPGRADE_PREVIEW_KEY])

	return tier_definition


static func effect_definition_from_data(effect_data: Dictionary) -> Dictionary:
	var effect_type := TowerConfig._effect_type_from_value(effect_data.get(TowerConfig.EFFECT_TYPE_KEY, ""))
	var definition := {
		TowerConfig.EFFECT_TYPE_KEY: effect_type,
		TowerConfig.EFFECT_DAMAGE_MULTIPLIER_KEY: float(effect_data.get(TowerConfig.EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)),
		TowerConfig.EFFECT_RADIUS_KEY: float(effect_data.get(TowerConfig.EFFECT_RADIUS_KEY, 0.0)),
		TowerConfig.STATUS_TYPE_KEY: TowerConfig._status_type_from_value(effect_data.get(TowerConfig.STATUS_TYPE_KEY, -1)),
		TowerConfig.EFFECT_DURATION_KEY: float(effect_data.get(TowerConfig.EFFECT_DURATION_KEY, 0.0)),
		TowerConfig.EFFECT_MOVE_SPEED_MULTIPLIER_KEY: float(effect_data.get(TowerConfig.EFFECT_MOVE_SPEED_MULTIPLIER_KEY, 1.0)),
		TowerConfig.EFFECT_TICK_INTERVAL_KEY: float(effect_data.get(TowerConfig.EFFECT_TICK_INTERVAL_KEY, 0.0)),
		TowerConfig.EFFECT_TICK_DAMAGE_KEY: float(effect_data.get(TowerConfig.EFFECT_TICK_DAMAGE_KEY, 0.0)),
		TowerConfig.STATUS_STACK_POLICY_KEY: TowerConfig._stack_policy_from_value(effect_data.get(TowerConfig.STACK_POLICY_KEY, -1)),
	}
	if effect_data.has(TowerConfig.ATTACK_TYPE_KEY):
		definition[TowerConfig.ATTACK_TYPE_KEY] = TowerConfig._attack_type_from_value(effect_data[TowerConfig.ATTACK_TYPE_KEY])
	if effect_data.has(TowerConfig.DAMAGE_SCHOOL_KEY):
		definition[TowerConfig.DAMAGE_SCHOOL_KEY] = TowerConfig._damage_school_from_value(effect_data[TowerConfig.DAMAGE_SCHOOL_KEY])

	return definition


static func string_array_from_value(value) -> Array:
	var result := []
	var source := value as Array
	if source == null:
		return result

	for candidate in source:
		result.append(str(candidate))

	return result
