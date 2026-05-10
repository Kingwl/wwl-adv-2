class_name StatusEffectAdvanceResult
extends RefCounted

var damage_events: Array
var expired_effects: Array


func _init(
	new_damage_events: Array = [],
	new_expired_effects: Array = []
) -> void:
	damage_events = new_damage_events.duplicate()
	expired_effects = new_expired_effects.duplicate()
