class_name WaveClearEvent
extends RefCounted

var wave_id: String
var reward_gold: int


func _init(new_wave_id: String, new_reward_gold: int) -> void:
	assert(not new_wave_id.is_empty(), "Wave id is required.")
	assert(new_reward_gold >= 0, "Reward gold cannot be negative.")

	wave_id = new_wave_id
	reward_gold = new_reward_gold
