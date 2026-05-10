class_name BoardVisualState
extends RefCounted

const ATTACK_FEEDBACK_DURATION_SECONDS := 0.18
const TOWER_ATTACK_ANIMATION_SECONDS := 0.32
const ENEMY_DEATH_ANIMATION_SECONDS := 0.54

var attack_feedbacks: Array
var tower_attack_animations: Dictionary
var enemy_death_animations: Array
var visual_elapsed_seconds := 0.0


func _init() -> void:
	reset()


func reset() -> void:
	attack_feedbacks = []
	tower_attack_animations = {}
	enemy_death_animations = []
	visual_elapsed_seconds = 0.0


func advance(delta_seconds: float) -> void:
	visual_elapsed_seconds += delta_seconds
	advance_tower_attack_animations(delta_seconds)
	advance_enemy_death_animations(delta_seconds)


func advance_tower_attack_animations(delta_seconds: float) -> void:
	if tower_attack_animations.is_empty():
		return

	for tower_id in tower_attack_animations.keys():
		var animation: Dictionary = tower_attack_animations.get(tower_id, {})
		var elapsed: float = animation.get("elapsed", 0.0) + delta_seconds
		var duration: float = animation.get("duration", TOWER_ATTACK_ANIMATION_SECONDS)
		if elapsed >= duration:
			tower_attack_animations.erase(tower_id)
			continue

		animation["elapsed"] = elapsed
		tower_attack_animations[tower_id] = animation


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


func spawn_tower_attack_animations(tick_results: Array) -> void:
	for candidate in tick_results:
		var tick_result := candidate as CombatTickResult
		if tick_result == null:
			continue

		for attack_candidate in tick_result.attack_results:
			var attack_result := attack_candidate as AttackResult
			if attack_result == null or not attack_result.succeeded or attack_result.tower_id.is_empty():
				continue

			tower_attack_animations[attack_result.tower_id] = {
				"elapsed": 0.0,
				"duration": TOWER_ATTACK_ANIMATION_SECONDS,
			}


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
