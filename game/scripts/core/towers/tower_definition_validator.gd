class_name TowerDefinitionValidator
extends RefCounted


static func validate_definitions(definitions: Dictionary) -> Array:
	var errors := []
	if definitions.is_empty():
		errors.append("At least one tower definition is required.")
		return errors

	for tower_type in definitions.keys():
		var tower_name := TowerConfig._tower_type_name(tower_type)
		var tower_definition := definitions[tower_type] as Dictionary
		if tower_definition == null:
			errors.append("%s definition must be a dictionary." % tower_name)
			continue

		_validate_tower_definition(errors, tower_name, tower_definition)
		_validate_projectile_definition(errors, tower_name, tower_definition)

		var tiers := tower_definition.get(TowerConfig.TIERS_KEY, []) as Array
		if tiers.is_empty():
			errors.append("%s tiers are required." % tower_name)
			continue

		for index in range(tiers.size()):
			var tier_number := index + 1
			var tier_definition := tiers[index] as Dictionary
			if tier_definition == null:
				errors.append("%s tier %d must be a dictionary." % [tower_name, tier_number])
				continue

			_validate_tier_stats(errors, tower_name, tier_number, tier_definition)
			_validate_tier_upgrade_cost(errors, tower_name, tier_number, tier_definition, index == tiers.size() - 1)
			if index > 0:
				var previous_definition := tiers[index - 1] as Dictionary
				if previous_definition != null:
					_validate_tier_growth(errors, tower_name, tier_number, previous_definition, tier_definition)

	return errors


static func _validate_tower_definition(errors: Array, tower_name: String, tower_definition: Dictionary) -> void:
	if int(tower_definition.get(TowerConfig.BUILD_COST_KEY, TowerConfig.DEFAULT_BUILD_COST)) <= 0:
		errors.append("%s build_cost must be positive." % tower_name)

	var visuals := tower_definition.get(TowerConfig.VISUALS_KEY, {}) as Dictionary
	if visuals == null:
		errors.append("%s visuals must be a dictionary." % tower_name)
		return

	if tower_definition.has(TowerConfig.VISUALS_KEY):
		if str(visuals.get(TowerConfig.TOWER_TEXTURE_KEY, "")).is_empty():
			errors.append("%s visuals tower texture is required." % tower_name)
		if not (visuals.get(TowerConfig.PROJECTILE_TEXTURES_KEY, []) is Array):
			errors.append("%s visuals projectiles must be an array." % tower_name)
		if not (visuals.get(TowerConfig.IMPACT_TEXTURES_KEY, []) is Array):
			errors.append("%s visuals impacts must be an array." % tower_name)


static func _validate_projectile_definition(errors: Array, tower_name: String, tower_definition: Dictionary) -> void:
	var projectile_definition := tower_definition.get(TowerConfig.PROJECTILE_KEY, {}) as Dictionary
	if projectile_definition == null:
		errors.append("%s projectile must be a dictionary." % tower_name)
		return

	if float(projectile_definition.get(TowerConfig.PROJECTILE_SPEED_KEY, TowerConfig.DEFAULT_PROJECTILE_SPEED_CELLS_PER_SECOND)) <= 0.0:
		errors.append("%s projectile speed_cells_per_second must be positive." % tower_name)
	if float(projectile_definition.get(TowerConfig.PROJECTILE_HIT_RADIUS_KEY, TowerConfig.DEFAULT_PROJECTILE_HIT_RADIUS_CELLS)) < 0.0:
		errors.append("%s projectile hit_radius_cells cannot be negative." % tower_name)


static func _validate_tier_stats(
	errors: Array,
	tower_name: String,
	tier_number: int,
	tier_definition: Dictionary
) -> void:
	if float(tier_definition.get(TowerConfig.DAMAGE_KEY, -1.0)) < 0.0:
		errors.append("%s tier %d damage cannot be negative." % [tower_name, tier_number])
	if float(tier_definition.get(TowerConfig.RANGE_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d range_cells must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(TowerConfig.ATTACK_INTERVAL_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d attack_interval must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(TowerConfig.SPLASH_RADIUS_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d splash_radius_cells cannot be negative." % [tower_name, tier_number])
	if float(tier_definition.get(TowerConfig.SLOW_MULTIPLIER_KEY, 1.0)) <= 0.0:
		errors.append("%s tier %d slow_multiplier must be positive." % [tower_name, tier_number])
	if float(tier_definition.get(TowerConfig.SLOW_DURATION_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d slow_duration cannot be negative." % [tower_name, tier_number])
	if TowerConfig._get_status_type(tier_definition) >= 0 and TowerConfig._get_status_duration(tier_definition) <= 0.0:
		errors.append("%s tier %d status_duration must be positive when status_type is configured." % [tower_name, tier_number])
	if TowerConfig._status_move_speed_multiplier_from_tier(tier_definition) <= 0.0:
		errors.append("%s tier %d status_move_speed_multiplier must be positive." % [tower_name, tier_number])
	if TowerConfig._status_tick_interval_from_tier(tier_definition) < 0.0:
		errors.append("%s tier %d status_tick_interval cannot be negative." % [tower_name, tier_number])
	if TowerConfig._status_tick_damage_from_tier(tier_definition) < 0.0:
		errors.append("%s tier %d status_tick_damage cannot be negative." % [tower_name, tier_number])
	if (
		TowerConfig._status_tick_damage_from_tier(tier_definition) > 0.0
		and TowerConfig._status_tick_interval_from_tier(tier_definition) <= 0.0
	):
		errors.append("%s tier %d status_tick_interval must be positive when status_tick_damage is positive." % [tower_name, tier_number])

	if tier_definition.has(TowerConfig.EFFECTS_KEY):
		var effect_definitions := tier_definition.get(TowerConfig.EFFECTS_KEY, []) as Array
		if effect_definitions == null or effect_definitions.is_empty():
			errors.append("%s tier %d effects must include at least one effect." % [tower_name, tier_number])
		else:
			for index in range(effect_definitions.size()):
				_validate_effect_definition(errors, tower_name, tier_number, index + 1, effect_definitions[index])


static func _validate_effect_definition(
	errors: Array,
	tower_name: String,
	tier_number: int,
	effect_number: int,
	effect_definition
) -> void:
	var effect_type := TowerConfig._effect_type_from_value(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_TYPE_KEY, -1))
	if effect_type < 0:
		errors.append("%s tier %d effect %d type is invalid." % [tower_name, tier_number, effect_number])
		return

	if float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_DAMAGE_MULTIPLIER_KEY, 1.0)) < 0.0:
		errors.append("%s tier %d effect %d damage_multiplier cannot be negative." % [tower_name, tier_number, effect_number])

	if (
		effect_type == TowerEffect.EffectType.SPLASH_DAMAGE
		and float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_RADIUS_KEY, 0.0)) <= 0.0
	):
		errors.append("%s tier %d effect %d radius_cells must be positive for splash_damage." % [tower_name, tier_number, effect_number])

	if effect_type != TowerEffect.EffectType.APPLY_STATUS:
		return

	if TowerConfig._status_type_from_value(TowerConfig._effect_value(effect_definition, TowerConfig.STATUS_TYPE_KEY, -1)) < 0:
		errors.append("%s tier %d effect %d status_type is required for apply_status." % [tower_name, tier_number, effect_number])
	if float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_DURATION_KEY, 0.0)) <= 0.0:
		errors.append("%s tier %d effect %d duration must be positive for apply_status." % [tower_name, tier_number, effect_number])
	if float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_MOVE_SPEED_MULTIPLIER_KEY, 1.0)) <= 0.0:
		errors.append("%s tier %d effect %d move_speed_multiplier must be positive." % [tower_name, tier_number, effect_number])
	if float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_TICK_INTERVAL_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d effect %d tick_interval cannot be negative." % [tower_name, tier_number, effect_number])
	if float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_TICK_DAMAGE_KEY, 0.0)) < 0.0:
		errors.append("%s tier %d effect %d tick_damage cannot be negative." % [tower_name, tier_number, effect_number])
	if (
		float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_TICK_DAMAGE_KEY, 0.0)) > 0.0
		and float(TowerConfig._effect_value(effect_definition, TowerConfig.EFFECT_TICK_INTERVAL_KEY, 0.0)) <= 0.0
	):
		errors.append("%s tier %d effect %d tick_interval must be positive when tick_damage is positive." % [tower_name, tier_number, effect_number])


static func _validate_tier_upgrade_cost(
	errors: Array,
	tower_name: String,
	tier_number: int,
	tier_definition: Dictionary,
	is_max_tier: bool
) -> void:
	var upgrade_cost := int(tier_definition.get(TowerConfig.UPGRADE_COST_KEY, 0))
	if is_max_tier:
		if upgrade_cost != 0:
			errors.append("%s max tier cannot define upgrade_cost." % tower_name)
		return

	if upgrade_cost <= 0:
		errors.append("%s tier %d upgrade_cost must be positive." % [tower_name, tier_number])


static func _validate_tier_growth(
	errors: Array,
	tower_name: String,
	tier_number: int,
	previous_definition: Dictionary,
	tier_definition: Dictionary
) -> void:
	var previous_damage := float(previous_definition.get(TowerConfig.DAMAGE_KEY, 0.0))
	var next_damage := float(tier_definition.get(TowerConfig.DAMAGE_KEY, 0.0))
	if next_damage <= previous_damage:
		errors.append("%s tier %d damage must be greater than tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_range := float(previous_definition.get(TowerConfig.RANGE_KEY, 0.0))
	var next_range := float(tier_definition.get(TowerConfig.RANGE_KEY, 0.0))
	if next_range <= previous_range:
		errors.append("%s tier %d range_cells must be greater than tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_splash := TowerConfig._get_splash_radius_from_tier(previous_definition)
	var next_splash := TowerConfig._get_splash_radius_from_tier(tier_definition)
	if previous_splash <= 0.0 and next_splash > 0.0:
		errors.append("%s tier %d cannot add splash to a tower that did not have splash at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_has_slow := TowerConfig._tier_has_slow(previous_definition)
	var next_has_slow := TowerConfig._tier_has_slow(tier_definition)
	if not previous_has_slow and next_has_slow:
		errors.append("%s tier %d cannot add slow to a tower that did not have slow at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])

	var previous_status_type := TowerConfig._get_status_type(previous_definition)
	var next_status_type := TowerConfig._get_status_type(tier_definition)
	if previous_status_type < 0 and next_status_type >= 0:
		errors.append("%s tier %d cannot add status to a tower that did not have status at tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])
	if previous_status_type >= 0 and next_status_type >= 0 and previous_status_type != next_status_type:
		errors.append("%s tier %d cannot change status type from tier %d." % [
			tower_name,
			tier_number,
			tier_number - 1,
		])
