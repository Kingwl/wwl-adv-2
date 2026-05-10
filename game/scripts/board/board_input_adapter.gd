class_name BoardInputAdapter
extends RefCounted


func handle_unhandled_input(
	event: InputEvent,
	flow_state: int,
	playing_flow_state: int,
	menu_flow_state: int,
	screen_to_grid_position: Callable,
	update_hover: Callable,
	try_place_at_grid: Callable,
	open_pause_menu: Callable,
	resume_game: Callable
) -> void:
	if event.is_action_pressed("ui_cancel"):
		if flow_state == playing_flow_state:
			open_pause_menu.call()
		elif flow_state == menu_flow_state:
			resume_game.call()
		return

	if flow_state != playing_flow_state:
		return

	if event is InputEventMouseMotion:
		update_hover.call(screen_to_grid_position.call(event.position))
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			try_place_at_grid.call(screen_to_grid_position.call(mouse_event.position))
