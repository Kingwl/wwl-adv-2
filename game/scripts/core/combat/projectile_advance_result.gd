class_name ProjectileAdvanceResult
extends RefCounted

var active_projectiles: Array
var damage_events: Array
var status_events: Array
var impact_events: Array
var missed_projectile_ids: Array


func _init(
	new_active_projectiles: Array = [],
	new_damage_events: Array = [],
	new_status_events: Array = [],
	new_impact_events: Array = [],
	new_missed_projectile_ids: Array = []
) -> void:
	active_projectiles = new_active_projectiles.duplicate()
	damage_events = new_damage_events.duplicate()
	status_events = new_status_events.duplicate()
	impact_events = new_impact_events.duplicate()
	missed_projectile_ids = new_missed_projectile_ids.duplicate()
