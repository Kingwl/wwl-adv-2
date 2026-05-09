class_name WaveSpawnResult
extends RefCounted

var spawned_enemies: Array
var wave_clear_events: Array
var current_wave_index: int
var all_waves_cleared: bool


func _init(
	new_spawned_enemies: Array = [],
	new_wave_clear_events: Array = [],
	new_current_wave_index: int = 0,
	new_all_waves_cleared: bool = false
) -> void:
	spawned_enemies = new_spawned_enemies.duplicate()
	wave_clear_events = new_wave_clear_events.duplicate()
	current_wave_index = new_current_wave_index
	all_waves_cleared = new_all_waves_cleared
