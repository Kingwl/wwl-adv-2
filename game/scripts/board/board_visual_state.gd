class_name BoardVisualState
extends RefCounted

const ATTACK_FEEDBACK_DURATION_SECONDS := 0.18
const ENEMY_DEATH_ANIMATION_SECONDS := 0.54

var attack_feedbacks: Array
var enemy_death_animations: Array
var visual_elapsed_seconds := 0.0


func _init() -> void:
	reset()


func reset() -> void:
	attack_feedbacks = []
	enemy_death_animations = []
	visual_elapsed_seconds = 0.0


func advance(delta_seconds: float) -> void:
	visual_elapsed_seconds += delta_seconds
	advance_enemy_death_animations(delta_seconds)


func advance_enemy_death_animations(delta_seconds: float) -> void:
	if enemy_death_animations.is_empty():
		return

	var active_animations := []
	for animation in enemy_death_animations:
		var elapsed: float = animation.get("elapsed", 0.0) + delta_seconds
		var duration: float = animation.get("duration", ENEMY_DEATH_ANIMATION_SECONDS)
		if elapsed >= duration:
			continue

		animation["elapsed"] = elapsed
		active_animations.append(animation)

	enemy_death_animations = active_animations


func spawn_enemy_death_animations(tick_results: Array, get_enemy_position: Callable) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null or tick_result.damage_result == null:
			continue

		for death_candidate in tick_result.damage_result.death_events:
			var death_event := death_candidate as EnemyDeathEvent
			if death_event == null:
				continue

			var position = get_enemy_position.call(death_event.enemy_id)
			if not position is Vector2:
				continue

			enemy_death_animations.append({
				"position": position,
				"elapsed": 0.0,
				"duration": ENEMY_DEATH_ANIMATION_SECONDS,
			})


func spawn_attack_feedback(tick_results: Array, grid_space_to_local: Callable, impact_color: Callable) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		for impact_candidate in tick_result.projectile_impact_events:
			var impact_event := impact_candidate as ProjectileImpactEvent
			if impact_event == null or not impact_event.hit:
				continue

			attack_feedbacks.append({
				"position": grid_space_to_local.call(impact_event.position),
				"elapsed": 0.0,
				"duration": ATTACK_FEEDBACK_DURATION_SECONDS,
				"color": impact_color.call(impact_event.tower_type),
				"tower_type": impact_event.tower_type,
			})


func advance_attack_feedbacks(delta_seconds: float) -> void:
	if attack_feedbacks.is_empty():
		return

	var active_feedbacks := []
	for feedback in attack_feedbacks:
		var elapsed: float = feedback.get("elapsed", 0.0) + delta_seconds
		var duration: float = feedback.get("duration", ATTACK_FEEDBACK_DURATION_SECONDS)
		if elapsed >= duration:
			continue

		feedback["elapsed"] = elapsed
		active_feedbacks.append(feedback)

	attack_feedbacks = active_feedbacks
