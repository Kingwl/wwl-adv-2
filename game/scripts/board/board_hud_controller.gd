class_name BoardHudController
extends RefCounted

const TOWER_ACTION_MENU_SIZE := Vector2(196.0, 156.0)
const TOWER_ACTION_MENU_MARGIN := 10.0
const TOWER_ACTION_BUTTON_HEIGHT := 30.0

var status_label: Label
var hint_label: Label
var gold_label: Label
var lives_label: Label
var wave_label: Label
var menu_button: Button
var single_tower_button: Button
var area_tower_button: Button
var slow_tower_button: Button
var flame_tower_button: Button
var overlay_root: Control
var overlay_backdrop: ColorRect
var overlay_panel: Control
var overlay_title: Label
var overlay_message: Label
var overlay_primary_button: Button
var overlay_secondary_button: Button
var hud_frame_panel: Panel
var tower_deck_panel: Panel
var tower_action_panel: Panel
var tower_action_title: Label
var tower_action_preview_label: Label
var tower_action_upgrade_button: Button
var tower_action_remove_button: Button
var gold_icon_rect: TextureRect
var lives_icon_rect: TextureRect
var wave_icon_rect: TextureRect
var compact_messages := false


func bind(
	owner: Node,
	status_label_path: NodePath,
	hint_label_path: NodePath,
	gold_label_path: NodePath,
	lives_label_path: NodePath,
	wave_label_path: NodePath,
	menu_button_path: NodePath,
	single_tower_button_path: NodePath,
	area_tower_button_path: NodePath,
	slow_tower_button_path: NodePath,
	flame_tower_button_path: NodePath,
	overlay_root_path: NodePath,
	overlay_backdrop_path: NodePath,
	overlay_panel_path: NodePath,
	overlay_title_path: NodePath,
	overlay_message_path: NodePath,
	overlay_primary_button_path: NodePath,
	overlay_secondary_button_path: NodePath
) -> void:
	status_label = owner.get_node_or_null(status_label_path) as Label
	hint_label = owner.get_node_or_null(hint_label_path) as Label
	gold_label = owner.get_node_or_null(gold_label_path) as Label
	lives_label = owner.get_node_or_null(lives_label_path) as Label
	wave_label = owner.get_node_or_null(wave_label_path) as Label
	menu_button = owner.get_node_or_null(menu_button_path) as Button
	single_tower_button = owner.get_node_or_null(single_tower_button_path) as Button
	area_tower_button = owner.get_node_or_null(area_tower_button_path) as Button
	slow_tower_button = owner.get_node_or_null(slow_tower_button_path) as Button
	flame_tower_button = owner.get_node_or_null(flame_tower_button_path) as Button
	overlay_root = owner.get_node_or_null(overlay_root_path) as Control
	overlay_backdrop = owner.get_node_or_null(overlay_backdrop_path) as ColorRect
	overlay_panel = owner.get_node_or_null(overlay_panel_path) as Control
	overlay_title = owner.get_node_or_null(overlay_title_path) as Label
	overlay_message = owner.get_node_or_null(overlay_message_path) as Label
	overlay_primary_button = owner.get_node_or_null(overlay_primary_button_path) as Button
	overlay_secondary_button = owner.get_node_or_null(overlay_secondary_button_path) as Button


func ensure_chrome(gold_icon_texture: Texture2D, lives_icon_texture: Texture2D, wave_icon_texture: Texture2D) -> void:
	var hud_parent: Node = null
	if gold_label != null:
		hud_parent = gold_label.get_parent()
	if hud_parent == null:
		return

	hud_frame_panel = _ensure_hud_panel(hud_parent, "HudFrame")
	tower_deck_panel = _ensure_hud_panel(hud_parent, "TowerDeck")
	tower_action_panel = _ensure_tower_action_panel(hud_parent)
	gold_icon_rect = _ensure_hud_icon(hud_parent, "GoldIcon", gold_icon_texture)
	lives_icon_rect = _ensure_hud_icon(hud_parent, "LivesIcon", lives_icon_texture)
	wave_icon_rect = _ensure_hud_icon(hud_parent, "WaveIcon", wave_icon_texture)


func configure(menu_icon_texture: Texture2D) -> void:
	for label in [gold_label, lives_label, wave_label]:
		if label == null:
			continue

		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_stat_label(label)

	for label in [status_label, hint_label]:
		if label == null:
			continue

		label.clip_text = true
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		FrostRtsTheme.apply_body_label(label, 14, FrostRtsTheme.TEXT_DIM)

	FrostRtsTheme.apply_title_label(overlay_title, 28)
	FrostRtsTheme.apply_body_label(overlay_message, 16, FrostRtsTheme.TEXT)
	FrostRtsTheme.apply_backdrop(overlay_backdrop, 0.78)
	FrostRtsTheme.apply_overlay_panel(overlay_panel)

	if overlay_title != null:
		overlay_title.clip_text = true
		overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if overlay_message != null:
		overlay_message.clip_text = true
		overlay_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	FrostRtsTheme.apply_button(menu_button, 14)
	if menu_button != null:
		menu_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		menu_button.icon = menu_icon_texture
		menu_button.expand_icon = true
		menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		menu_button.add_theme_constant_override("icon_max_width", 22)
		menu_button.add_theme_constant_override("h_separation", 8)

	for button in [single_tower_button, area_tower_button, slow_tower_button, flame_tower_button]:
		if button == null:
			continue

		button.clip_text = true
		button.toggle_mode = true
		FrostRtsTheme.apply_tower_button(button)

	for button in [overlay_primary_button, overlay_secondary_button]:
		FrostRtsTheme.apply_button(button, 15)

	FrostRtsTheme.apply_hud_panel(tower_action_panel)
	FrostRtsTheme.apply_body_label(tower_action_title, 13, FrostRtsTheme.TEXT)
	FrostRtsTheme.apply_body_label(tower_action_preview_label, 11, FrostRtsTheme.TEXT_DIM)
	if tower_action_title != null:
		tower_action_title.clip_text = true
		tower_action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tower_action_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if tower_action_preview_label != null:
		tower_action_preview_label.clip_text = true
		tower_action_preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tower_action_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tower_action_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	for button in [tower_action_upgrade_button, tower_action_remove_button]:
		if button == null:
			continue

		FrostRtsTheme.apply_button(button, 12)
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func connect_signals(
	menu_pressed: Callable,
	single_pressed: Callable,
	area_pressed: Callable,
	slow_pressed: Callable,
	flame_pressed: Callable,
	primary_pressed: Callable,
	secondary_pressed: Callable,
	upgrade_pressed: Callable,
	remove_pressed: Callable
) -> void:
	_connect_button(menu_button, menu_pressed)
	_connect_button(single_tower_button, single_pressed)
	_connect_button(area_tower_button, area_pressed)
	_connect_button(slow_tower_button, slow_pressed)
	_connect_button(flame_tower_button, flame_pressed)
	_connect_button(overlay_primary_button, primary_pressed)
	_connect_button(overlay_secondary_button, secondary_pressed)
	_connect_button(tower_action_upgrade_button, upgrade_pressed)
	_connect_button(tower_action_remove_button, remove_pressed)


func apply_layout(metrics: BoardLayoutMetrics) -> void:
	compact_messages = metrics.compact_messages
	_set_control_rect(hud_frame_panel, metrics.hud_frame_rect)
	_set_control_rect(tower_deck_panel, metrics.tower_deck_rect)
	_set_control_rect(gold_icon_rect, metrics.gold_icon_rect)
	_set_control_rect(lives_icon_rect, metrics.lives_icon_rect)
	_set_control_rect(wave_icon_rect, metrics.wave_icon_rect)
	_set_control_rect(gold_label, metrics.gold_label_rect)
	_set_control_rect(lives_label, metrics.lives_label_rect)
	_set_control_rect(wave_label, metrics.wave_label_rect)
	_set_control_rect(menu_button, metrics.menu_button_rect)
	_set_control_rect(single_tower_button, metrics.single_tower_button_rect)
	_set_control_rect(area_tower_button, metrics.area_tower_button_rect)
	_set_control_rect(slow_tower_button, metrics.slow_tower_button_rect)
	_set_control_rect(flame_tower_button, metrics.flame_tower_button_rect)
	_set_control_rect(status_label, metrics.status_label_rect)
	_set_control_rect(hint_label, metrics.hint_label_rect)
	_set_message_label_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	_apply_overlay_layout(metrics)


func _apply_overlay_layout(metrics: BoardLayoutMetrics) -> void:
	_set_control_rect(overlay_root, metrics.overlay_root_rect)
	_set_control_rect(overlay_backdrop, metrics.overlay_backdrop_rect)
	_set_control_rect(overlay_panel, metrics.overlay_panel_rect)
	_set_control_rect(overlay_title, metrics.overlay_title_rect)
	_set_control_rect(overlay_message, metrics.overlay_message_rect)

	var primary_rect := metrics.overlay_primary_button_rect
	var secondary_rect := metrics.overlay_secondary_button_rect
	if overlay_secondary_button == null or not overlay_secondary_button.visible:
		primary_rect.position.x = floorf((metrics.overlay_panel_rect.size.x - primary_rect.size.x) * 0.5)

	_set_control_rect(overlay_primary_button, primary_rect)
	_set_control_rect(overlay_secondary_button, secondary_rect)


func show_overlay(title: String, message: String, primary_text: String, secondary_text: String, metrics: BoardLayoutMetrics) -> void:
	if overlay_title != null:
		overlay_title.text = title
	if overlay_message != null:
		overlay_message.text = message
	if overlay_primary_button != null:
		overlay_primary_button.text = primary_text
		overlay_primary_button.visible = not primary_text.is_empty()
	if overlay_secondary_button != null:
		overlay_secondary_button.text = secondary_text
		overlay_secondary_button.visible = not secondary_text.is_empty()

	if metrics != null:
		_apply_overlay_layout(metrics)
	set_overlay_visible(true)


func set_overlay_visible(should_be_visible: bool) -> void:
	if overlay_root != null:
		overlay_root.visible = should_be_visible


func show_tower_action_menu(
	tower: GameTower,
	tower_config: TowerConfig,
	wallet: Wallet,
	refund_amount: int,
	menu_rect: Rect2,
	flow_state: int
) -> void:
	if tower_action_panel == null or tower == null or tower_config == null:
		return

	_set_control_rect(tower_action_panel, menu_rect)
	_layout_tower_action_menu(menu_rect.size)

	var can_upgrade := tower_config.can_upgrade(tower)
	var upgrade_cost := tower_config.get_upgrade_cost(tower.tower_type, tower.tier) if can_upgrade else 0
	var can_afford := wallet != null and wallet.gold >= upgrade_cost
	var actions_enabled := flow_state == BoardGameSession.FlowState.PLAYING
	if tower_action_title != null:
		tower_action_title.text = "%s T%d" % [tower_type_label(tower.tower_type), tower.tier]
	if tower_action_preview_label != null:
		tower_action_preview_label.text = tower_config.get_upgrade_preview(tower.tower_type, tower.tier)
	if tower_action_upgrade_button != null:
		tower_action_upgrade_button.text = "Upgrade %dg" % upgrade_cost if can_upgrade else "Max tier"
		tower_action_upgrade_button.disabled = not actions_enabled or not can_upgrade or not can_afford
	if tower_action_remove_button != null:
		tower_action_remove_button.text = "Remove +%dg" % refund_amount
		tower_action_remove_button.disabled = not actions_enabled

	tower_action_panel.visible = true


func hide_tower_action_menu() -> void:
	if tower_action_panel != null:
		tower_action_panel.visible = false


func sync_menu_button_state(flow_state: int) -> void:
	if menu_button != null:
		menu_button.disabled = flow_state != BoardGameSession.FlowState.PLAYING


func sync_message_labels(status_text: String, hint_text: String) -> void:
	if status_label != null:
		status_label.text = compact_status_text(status_text) if compact_messages else status_text
	if hint_label != null:
		hint_label.text = compact_hint_text(hint_text) if compact_messages else hint_text


func update_selected_tower_hint(selected_tower_type: GameTower.Type, economy_config: EconomyConfig) -> String:
	var cost := 0
	if economy_config != null:
		cost = economy_config.basic_tower_cost
	return "%s tower: %dg. Enemies follow the paved road." % [
		tower_type_label(selected_tower_type),
		cost,
	]


func sync_tower_button_state(
	flow_state: int,
	selected_tower_type: GameTower.Type,
	wallet: Wallet,
	economy_config: EconomyConfig,
	get_tower_sprite_texture: Callable
) -> void:
	_set_tower_button_text(single_tower_button, GameTower.Type.SINGLE_TARGET, "Single", flow_state, selected_tower_type, wallet, economy_config, get_tower_sprite_texture)
	_set_tower_button_text(area_tower_button, GameTower.Type.AREA, "Area", flow_state, selected_tower_type, wallet, economy_config, get_tower_sprite_texture)
	_set_tower_button_text(slow_tower_button, GameTower.Type.SLOW, "Slow", flow_state, selected_tower_type, wallet, economy_config, get_tower_sprite_texture)
	_set_tower_button_text(flame_tower_button, GameTower.Type.FLAME, "Flame", flow_state, selected_tower_type, wallet, economy_config, get_tower_sprite_texture)


func update_gold_label(wallet: Wallet) -> void:
	if gold_label != null and wallet != null:
		gold_label.text = "Gold: %d" % wallet.gold


func update_lives_label(combat_simulation: CombatSimulation) -> void:
	if lives_label != null and combat_simulation != null:
		lives_label.text = "Lives: %d" % combat_simulation.player_life.lives


func update_wave_label(wave_spawner: WaveSpawner) -> void:
	if wave_label == null or wave_spawner == null:
		return

	if wave_spawner.all_waves_cleared:
		wave_label.text = "Wave: Complete"
		return

	wave_label.text = "Wave: %d/%d" % [
		wave_spawner.current_wave_index + 1,
		wave_spawner.wave_definitions.size(),
	]


func compact_status_text(text: String) -> String:
	if text.begins_with("Cannot place"):
		if text.find("buildable") != -1:
			return "Road tile blocked."
		if text.find("Need") != -1:
			return text.get_slice(": ", 1)
		return "Cannot place."
	if text.begins_with("Cannot upgrade"):
		return text.get_slice(": ", 1)
	if text.begins_with("Placed"):
		return "Tower placed."
	if text.begins_with("Upgraded"):
		return "Tower upgraded."
	if text.begins_with("Removed"):
		return "+%s refund" % text.get_slice(" for ", 1).get_slice(" gold", 0)
	if text.begins_with("Click a green"):
		return "Place on green tile."
	if text.begins_with("Select a tower"):
		return "Select tower."
	if text.begins_with("Defeated"):
		return "+%s gold" % text.get_slice(" for ", 1).get_slice(" gold", 0)
	if text.begins_with("Cleared"):
		return "Wave clear +%s" % text.get_slice(" for ", 1).get_slice(" gold", 0)
	if text.begins_with("Earned"):
		return "+%s gold" % text.get_slice("Earned ", 1).get_slice(" gold", 0)
	return text


func compact_hint_text(text: String) -> String:
	var first_sentence := text.get_slice(".", 0)
	if not first_sentence.is_empty():
		return first_sentence
	return text


func tower_type_label(tower_type: GameTower.Type) -> String:
	match tower_type:
		GameTower.Type.AREA:
			return "Area"
		GameTower.Type.SLOW:
			return "Slow"
		GameTower.Type.FLAME:
			return "Flame"

	return "Single"


func tower_type_description(tower_type: GameTower.Type) -> String:
	match tower_type:
		GameTower.Type.AREA:
			return "Splash hit"
		GameTower.Type.SLOW:
			return "Frost slow"
		GameTower.Type.FLAME:
			return "Burn DoT"

	return "Focus fire"


func _set_tower_button_text(
	button: Button,
	tower_type: GameTower.Type,
	label: String,
	flow_state: int,
	selected_tower_type: GameTower.Type,
	wallet: Wallet,
	economy_config: EconomyConfig,
	get_tower_sprite_texture: Callable
) -> void:
	if button == null:
		return

	var cost := 0
	if economy_config != null:
		cost = economy_config.basic_tower_cost

	var can_afford := wallet != null and wallet.gold >= cost
	var is_selected := selected_tower_type == tower_type
	button.disabled = flow_state != BoardGameSession.FlowState.PLAYING or not can_afford
	button.tooltip_text = "%s tower: %s, %d gold" % [label, tower_type_description(tower_type), cost]
	button.button_pressed = is_selected
	button.modulate = _tower_button_modulate(is_selected, button.disabled)
	button.icon = get_tower_sprite_texture.call(tower_type)
	button.text = "%s\n%s  %dg" % [
		label.to_upper(),
		tower_type_description(tower_type),
		cost,
	]


func _tower_button_modulate(is_selected: bool, is_disabled: bool) -> Color:
	if is_disabled:
		return Color(0.55, 0.58, 0.60, 0.85)
	if is_selected:
		return Color.WHITE
	return Color(0.88, 0.92, 0.94, 1.0)


func _connect_button(button: Button, callback: Callable) -> void:
	if button != null and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _set_message_label_alignment(alignment: HorizontalAlignment) -> void:
	for label in [status_label, hint_label]:
		if label != null:
			label.horizontal_alignment = alignment


func _ensure_hud_panel(parent: Node, node_name: String) -> Panel:
	var panel := parent.get_node_or_null(node_name) as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = node_name
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		parent.move_child(panel, 0)

	return panel


func _ensure_hud_icon(parent: Node, node_name: String, texture: Texture2D) -> TextureRect:
	var icon := parent.get_node_or_null(node_name) as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parent.add_child(icon)

	icon.texture = texture
	return icon


func _ensure_tower_action_panel(parent: Node) -> Panel:
	var panel := parent.get_node_or_null("TowerActionPanel") as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = "TowerActionPanel"
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.visible = false
		parent.add_child(panel)

	tower_action_title = _ensure_action_label(panel, "Title")
	tower_action_preview_label = _ensure_action_label(panel, "Preview")
	tower_action_upgrade_button = _ensure_action_button(panel, "UpgradeButton")
	tower_action_remove_button = _ensure_action_button(panel, "RemoveButton")
	return panel


func _ensure_action_label(parent: Node, node_name: String) -> Label:
	var label := parent.get_node_or_null(node_name) as Label
	if label == null:
		label = Label.new()
		label.name = node_name
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(label)

	return label


func _ensure_action_button(parent: Node, node_name: String) -> Button:
	var button := parent.get_node_or_null(node_name) as Button
	if button == null:
		button = Button.new()
		button.name = node_name
		parent.add_child(button)

	return button


func _layout_tower_action_menu(menu_size: Vector2) -> void:
	var inner_left := TOWER_ACTION_MENU_MARGIN
	var inner_width := menu_size.x - TOWER_ACTION_MENU_MARGIN * 2.0
	var title_height := 22.0
	var preview_height := 18.0
	var button_gap := 8.0
	var first_button_top := 68.0
	var second_button_top := first_button_top + TOWER_ACTION_BUTTON_HEIGHT + button_gap

	_set_control_rect(tower_action_title, Rect2(inner_left, 8.0, inner_width, title_height))
	_set_control_rect(tower_action_preview_label, Rect2(inner_left, 32.0, inner_width, preview_height))
	_set_control_rect(tower_action_upgrade_button, Rect2(inner_left, first_button_top, inner_width, TOWER_ACTION_BUTTON_HEIGHT))
	_set_control_rect(tower_action_remove_button, Rect2(inner_left, second_button_top, inner_width, TOWER_ACTION_BUTTON_HEIGHT))


func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return

	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
