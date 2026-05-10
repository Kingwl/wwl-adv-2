class_name StatusEffectService
extends RefCounted

const FLOAT_EPSILON := 0.000001


func apply_status_events(enemies: Array, status_events: Array) -> Array:
	var enemy_by_id := _index_enemies(enemies)
	var applied_status_events := []

	for candidate in status_events:
		var status_event := candidate as StatusEvent
		if status_event == null:
			continue

		var enemy := enemy_by_id.get(status_event.enemy_id, null) as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			continue

		_apply_status_effect(enemy, _build_effect(status_event))
		applied_status_events.append(status_event)

	return applied_status_events


func advance_statuses(enemies: Array, delta_seconds: float) -> StatusEffectAdvanceResult:
	assert(delta_seconds >= 0.0, "Delta seconds cannot be negative.")

	var damage_events := []
	var expired_effects := []

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null or enemy.completed or enemy.defeated:
			continue

		var active_effects := []
		for effect_candidate in enemy.status_effects:
			var effect := effect_candidate as StatusEffect
			if effect == null:
				continue

			var active_delta := minf(delta_seconds, effect.remaining_seconds)
			damage_events.append_array(_advance_dot(enemy, effect, active_delta))
			effect.remaining_seconds -= delta_seconds

			if effect.remaining_seconds > FLOAT_EPSILON:
				active_effects.append(effect)
			else:
				expired_effects.append(effect)

		enemy.status_effects = active_effects

	return StatusEffectAdvanceResult.new(damage_events, expired_effects)


func _build_effect(status_event: StatusEvent) -> StatusEffect:
	return StatusEffect.new(
		status_event.status_type,
		status_event.source_tower_id,
		status_event.duration,
		status_event.multiplier,
		status_event.tick_interval,
		status_event.tick_damage,
		status_event.attack_type,
		status_event.damage_school,
		status_event.stack_policy
	)


func _apply_status_effect(enemy: Enemy, effect: StatusEffect) -> void:
	match effect.stack_policy:
		StatusEffect.StackPolicy.STRONGEST:
			_apply_strongest_status(enemy, effect)
		StatusEffect.StackPolicy.REPLACE:
			_remove_status_type(enemy, effect.status_type)
			enemy.status_effects.append(effect)
		StatusEffect.StackPolicy.STACK, StatusEffect.StackPolicy.INDEPENDENT:
			enemy.status_effects.append(effect)
		_:
			_apply_refresh_status(enemy, effect)


func _apply_refresh_status(enemy: Enemy, effect: StatusEffect) -> void:
	var existing := _find_status_effect(enemy, effect.status_type)
	if existing == null:
		enemy.status_effects.append(effect)
		return

	existing.refresh_from(effect)


func _apply_strongest_status(enemy: Enemy, effect: StatusEffect) -> void:
	var existing := _find_status_effect(enemy, effect.status_type)
	if existing == null:
		enemy.status_effects.append(effect)
		return

	if effect.move_speed_multiplier < existing.move_speed_multiplier:
		existing.source_tower_id = effect.source_tower_id
		existing.move_speed_multiplier = effect.move_speed_multiplier
		existing.duration_seconds = effect.duration_seconds
		existing.tick_interval_seconds = effect.tick_interval_seconds
		existing.tick_damage = effect.tick_damage
		existing.tick_elapsed_seconds = 0.0
		existing.attack_type = effect.attack_type
		existing.damage_school = effect.damage_school
		existing.stack_policy = effect.stack_policy

	existing.remaining_seconds = maxf(existing.remaining_seconds, effect.duration_seconds)


func _advance_dot(enemy: Enemy, effect: StatusEffect, active_delta: float) -> Array:
	if not effect.is_dot() or active_delta <= 0.0:
		return []

	var damage_events := []
	effect.tick_elapsed_seconds += active_delta
	while effect.tick_elapsed_seconds + FLOAT_EPSILON >= effect.tick_interval_seconds:
		damage_events.append(DamageEvent.new(
			enemy.id,
			effect.tick_damage,
			effect.source_tower_id,
			effect.attack_type,
			effect.damage_school
		))
		effect.tick_elapsed_seconds -= effect.tick_interval_seconds
		if effect.tick_elapsed_seconds < FLOAT_EPSILON:
			effect.tick_elapsed_seconds = 0.0

	return damage_events


func _find_status_effect(enemy: Enemy, status_type: int) -> StatusEffect:
	for candidate in enemy.status_effects:
		var effect := candidate as StatusEffect
		if effect != null and effect.status_type == status_type:
			return effect

	return null


func _remove_status_type(enemy: Enemy, status_type: int) -> void:
	var remaining_effects := []
	for candidate in enemy.status_effects:
		var effect := candidate as StatusEffect
		if effect == null or effect.status_type == status_type:
			continue

		remaining_effects.append(effect)

	enemy.status_effects = remaining_effects


func _index_enemies(enemies: Array) -> Dictionary:
	var enemy_by_id := {}

	for candidate in enemies:
		var enemy := candidate as Enemy
		if enemy == null:
			continue

		enemy_by_id[enemy.id] = enemy

	return enemy_by_id
