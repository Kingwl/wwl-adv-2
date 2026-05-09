class_name PlayerLife
extends RefCounted

const DEFAULT_MAX_LIVES := 10

var max_lives: int
var lives: int
var failed: bool


func _init(new_max_lives: int = DEFAULT_MAX_LIVES) -> void:
	assert(new_max_lives > 0, "Max lives must be positive.")

	max_lives = new_max_lives
	lives = max_lives
	failed = false


func apply_leak_events(leak_events: Array) -> int:
	var lost_lives := 0

	for candidate in leak_events:
		var leak_event := candidate as EnemyLeakEvent
		if leak_event == null:
			continue

		lost_lives += leak_event.life_damage

	if lost_lives <= 0:
		return 0

	lives = maxi(0, lives - lost_lives)
	failed = lives <= 0
	return lost_lives
