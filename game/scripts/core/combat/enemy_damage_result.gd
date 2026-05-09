class_name EnemyDamageResult
extends RefCounted

var applied_damage_events: Array
var death_events: Array
var ignored_damage_events: Array


func _init(
	new_applied_damage_events: Array = [],
	new_death_events: Array = [],
	new_ignored_damage_events: Array = []
) -> void:
	applied_damage_events = new_applied_damage_events.duplicate()
	death_events = new_death_events.duplicate()
	ignored_damage_events = new_ignored_damage_events.duplicate()
