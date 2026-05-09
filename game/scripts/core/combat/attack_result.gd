class_name AttackResult
extends RefCounted

enum FailureReason {
	NONE,
	COOLDOWN,
	NO_TARGET,
}

var succeeded: bool
var failure_reason: FailureReason
var tower_id: String
var target_enemy_id: String
var projectile: CombatProjectile
var damage_events: Array
var status_events: Array
var message: String


static func success(
	new_tower_id: String,
	new_target_enemy_id: String,
	new_projectile: CombatProjectile
) -> AttackResult:
	var result := AttackResult.new()
	result.succeeded = true
	result.failure_reason = FailureReason.NONE
	result.tower_id = new_tower_id
	result.target_enemy_id = new_target_enemy_id
	result.projectile = new_projectile
	return result


static func failure(new_failure_reason: FailureReason, new_tower_id: String, new_message: String) -> AttackResult:
	var result := AttackResult.new()
	result.succeeded = false
	result.failure_reason = new_failure_reason
	result.tower_id = new_tower_id
	result.message = new_message
	return result


func _init() -> void:
	succeeded = false
	failure_reason = FailureReason.NONE
	tower_id = ""
	target_enemy_id = ""
	projectile = null
	damage_events = []
	status_events = []
	message = ""
