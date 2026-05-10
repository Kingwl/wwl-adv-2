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
	resume_game: Callable,
	keyboard_actions: Dictionary = {}
) -> void:
	if _is_cancel_event(event):
		if flow_state == playing_flow_state:
			if _call_bool_action(keyboard_actions, "has_tower_action_menu"):
				_call_action(keyboard_actions, "clear_tower_action_menu")
			else:
				open_pause_menu.call()
		elif flow_state == menu_flow_state:
			resume_game.call()
		return

	if flow_state != playing_flow_state:
		return

	if event is InputEventKey:
		_handle_key_shortcut(event as InputEventKey, keyboard_actions)
		return

	if event is InputEventMouseMotion:
		update_hover.call(screen_to_grid_position.call(event.position))
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			try_place_at_grid.call(screen_to_grid_position.call(mouse_event.position))


func _handle_key_shortcut(event: InputEventKey, keyboard_actions: Dictionary) -> void:
	if not event.pressed or event.echo:
		return

	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var action: Callable = keyboard_actions.get("select_tower_by_shortcut_index", Callable())
		if action.is_valid():
			action.call(event.keycode - KEY_1)
		return

	match event.keycode:
		KEY_U:
			_call_action(keyboard_actions, "upgrade_selected_tower")
		KEY_X, KEY_DELETE, KEY_BACKSPACE:
			_call_action(keyboard_actions, "remove_selected_tower")


func _is_cancel_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true

	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE

	return false


func _call_action(keyboard_actions: Dictionary, action_name: String) -> bool:
	var action: Callable = keyboard_actions.get(action_name, Callable())
	if not action.is_valid():
		return false

	action.call()
	return true


func _call_bool_action(keyboard_actions: Dictionary, action_name: String) -> bool:
	var action: Callable = keyboard_actions.get(action_name, Callable())
	if not action.is_valid():
		return false

	return bool(action.call())
