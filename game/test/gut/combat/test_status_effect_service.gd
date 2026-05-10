extends GutTest


func test_apply_slow_status_uses_strongest_multiplier_and_refreshes_duration() -> void:
	var service := StatusEffectService.new()
	var enemy := Enemy.new("enemy-1")

	service.apply_status_events([enemy], [
		StatusEvent.new("enemy-1", StatusEvent.StatusType.SLOW, 1.0, 0.8, "tower-a"),
	])
	var first_effect: StatusEffect = enemy.status_effects[0]
	first_effect.remaining_seconds = 0.25

	service.apply_status_events([enemy], [
		StatusEvent.new("enemy-1", StatusEvent.StatusType.SLOW, 1.5, 0.5, "tower-b"),
		StatusEvent.new("enemy-1", StatusEvent.StatusType.SLOW, 2.0, 0.75, "tower-c"),
	])

	assert_eq(enemy.status_effects.size(), 1)
	var effect: StatusEffect = enemy.status_effects[0]
	assert_eq(effect.status_type, StatusEffect.StatusType.SLOW)
	assert_eq(effect.source_tower_id, "tower-b")
	assert_eq(effect.move_speed_multiplier, 0.5)
	assert_eq(effect.remaining_seconds, 2.0)
	assert_eq(effect.stack_policy, StatusEffect.StackPolicy.STRONGEST)


func test_refresh_status_replaces_dot_values_without_stacking() -> void:
	var service := StatusEffectService.new()
	var enemy := Enemy.new("enemy-1")

	service.apply_status_events([enemy], [
		_build_burn_event("enemy-1", "tower-a", 3.0, 1.0, 2.0),
	])
	var first_effect: StatusEffect = enemy.status_effects[0]
	first_effect.tick_elapsed_seconds = 0.5

	service.apply_status_events([enemy], [
		_build_burn_event("enemy-1", "tower-b", 4.0, 0.75, 3.0),
	])

	assert_eq(enemy.status_effects.size(), 1)
	var effect: StatusEffect = enemy.status_effects[0]
	assert_eq(effect.status_type, StatusEffect.StatusType.BURN)
	assert_eq(effect.source_tower_id, "tower-b")
	assert_eq(effect.remaining_seconds, 4.0)
	assert_eq(effect.tick_interval_seconds, 0.75)
	assert_eq(effect.tick_damage, 3.0)
	assert_eq(effect.tick_elapsed_seconds, 0.0)
	assert_eq(effect.stack_policy, StatusEffect.StackPolicy.REFRESH)


func test_dot_damage_waits_for_full_interval_and_expires() -> void:
	var service := StatusEffectService.new()
	var enemy := Enemy.new("enemy-1")

	service.apply_status_events([enemy], [
		_build_burn_event("enemy-1", "tower-a", 1.0, 0.5, 2.0),
	])

	var first_result := service.advance_statuses([enemy], 0.25)
	assert_eq(first_result.damage_events.size(), 0)
	assert_eq(enemy.status_effects.size(), 1)

	var second_result := service.advance_statuses([enemy], 0.25)
	assert_eq(second_result.damage_events.size(), 1)
	assert_eq(second_result.damage_events[0].enemy_id, "enemy-1")
	assert_eq(second_result.damage_events[0].source_tower_id, "tower-a")
	assert_eq(second_result.damage_events[0].amount, 2.0)
	assert_eq(second_result.damage_events[0].attack_type, DamageTypes.AttackType.MAGIC)
	assert_eq(second_result.damage_events[0].damage_school, DamageTypes.DamageSchool.FIRE)

	var third_result := service.advance_statuses([enemy], 0.5)
	assert_eq(third_result.damage_events.size(), 1)
	assert_eq(third_result.expired_effects.size(), 1)
	assert_eq(enemy.status_effects.size(), 0)


func test_poison_dot_damage_keeps_pierce_poison_damage_types() -> void:
	var service := StatusEffectService.new()
	var enemy := Enemy.new("enemy-1")

	service.apply_status_events([enemy], [
		StatusEvent.new(
			"enemy-1",
			StatusEvent.StatusType.POISON,
			2.0,
			1.0,
			"tower-poison",
			1.0,
			3.0,
			DamageTypes.AttackType.PIERCE,
			DamageTypes.DamageSchool.POISON
		),
	])

	var result := service.advance_statuses([enemy], 1.0)

	assert_eq(result.damage_events.size(), 1)
	assert_eq(result.damage_events[0].enemy_id, "enemy-1")
	assert_eq(result.damage_events[0].source_tower_id, "tower-poison")
	assert_eq(result.damage_events[0].amount, 3.0)
	assert_eq(result.damage_events[0].attack_type, DamageTypes.AttackType.PIERCE)
	assert_eq(result.damage_events[0].damage_school, DamageTypes.DamageSchool.POISON)


func test_status_events_for_inactive_enemies_are_ignored() -> void:
	var service := StatusEffectService.new()
	var active_enemy := Enemy.new("enemy-active")
	var defeated_enemy := Enemy.new("enemy-defeated")
	defeated_enemy.apply_damage(defeated_enemy.health)

	var applied_events := service.apply_status_events([active_enemy, defeated_enemy], [
		StatusEvent.new("enemy-missing", StatusEvent.StatusType.SLOW, 1.0, 0.6, "tower-a"),
		StatusEvent.new("enemy-defeated", StatusEvent.StatusType.SLOW, 1.0, 0.6, "tower-a"),
		StatusEvent.new("enemy-active", StatusEvent.StatusType.SLOW, 1.0, 0.6, "tower-a"),
	])

	assert_eq(applied_events.size(), 1)
	assert_eq(active_enemy.status_effects.size(), 1)
	assert_eq(defeated_enemy.status_effects.size(), 0)


func _build_burn_event(
	enemy_id: String,
	tower_id: String,
	duration: float,
	tick_interval: float,
	tick_damage: float
) -> StatusEvent:
	return StatusEvent.new(
		enemy_id,
		StatusEvent.StatusType.BURN,
		duration,
		1.0,
		tower_id,
		tick_interval,
		tick_damage,
		DamageTypes.AttackType.MAGIC,
		DamageTypes.DamageSchool.FIRE
	)
