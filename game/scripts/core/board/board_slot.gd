class_name BoardSlot
extends RefCounted

enum Type {
	BUILDABLE,
	PATH,
	BLOCKED,
	LOCKED,
}

var position: Vector2i
var slot_type: Type
var occupant_id: String
var reserved: bool


func _init(new_position: Vector2i, new_slot_type: Type = Type.BUILDABLE) -> void:
	position = new_position
	slot_type = new_slot_type
	occupant_id = ""
	reserved = false


func is_buildable() -> bool:
	return slot_type == Type.BUILDABLE


func is_empty() -> bool:
	return occupant_id.is_empty()
