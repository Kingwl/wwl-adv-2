extends GutTest


func test_spawn_and_advance_enemy_death_animation() -> void:
	var visual_state := BoardVisualState.new()
	var damage_result := EnemyDamageResult.new(
		[],
		[EnemyDeathEvent.new("enemy-1", 5, "tower-1")]
	)
	var tick_result := CombatTickResult.new(0.1, [], [], [], damage_result)

	visual_state.spawn_enemy_death_animations([tick_result], Callable(self, "_enemy_position_for_test"))

	assert_eq(visual_state.enemy_death_animations.size(), 1)
	assert_eq(visual_state.enemy_death_animations[0]["position"], Vector2(42.0, 24.0))

	visual_state.advance_enemy_death_animations(BoardVisualState.ENEMY_DEATH_ANIMATION_SECONDS)

	assert_eq(visual_state.enemy_death_animations.size(), 0)


func test_spawn_and_advance_attack_feedback() -> void:
	var visual_state := BoardVisualState.new()
	var impact_event := ProjectileImpactEvent.new(
		"projectile-1",
		"tower-1",
		"enemy-1",
		GameTower.Type.AREA,
		Vector2(2.0, 3.0),
		true
	)
	var tick_result := CombatTickResult.new(
		0.1,
		[],
		[],
		[],
		EnemyDamageResult.new(),
		[],
		[],
		false,
		[],
		0,
		false,
		false,
		[],
		[impact_event]
	)

	visual_state.spawn_attack_feedback(
		[tick_result],
		Callable(self, "_grid_space_to_local_for_test"),
		Callable(self, "_impact_color_for_test")
	)

	assert_eq(visual_state.attack_feedbacks.size(), 1)
	assert_eq(visual_state.attack_feedbacks[0]["position"], Vector2(20.0, 30.0))
	assert_eq(visual_state.attack_feedbacks[0]["tower_type"], GameTower.Type.AREA)

	visual_state.advance_attack_feedbacks(BoardVisualState.ATTACK_FEEDBACK_DURATION_SECONDS)

	assert_eq(visual_state.attack_feedbacks.size(), 0)


func _enemy_position_for_test(_enemy_id: String) -> Vector2:
	return Vector2(42.0, 24.0)


func _grid_space_to_local_for_test(grid_position: Vector2) -> Vector2:
	return grid_position * 10.0


func _impact_color_for_test(_tower_type: GameTower.Type) -> Color:
	return Color(1.0, 0.5, 0.25, 1.0)
