class_name BoardAssetCatalog
extends RefCounted

const DEFAULT_LEVEL_DEFINITION_PATH := "res://data/levels/level_001.json"
const MAP_STYLE_DEFINITION_TEMPLATE := "res://data/map_styles/%s.json"
const GOLD_ICON_PATH := "res://assets/ui/frost_rts/gold_icon.png"
const LIVES_ICON_PATH := "res://assets/ui/frost_rts/lives_icon.png"
const WAVE_ICON_PATH := "res://assets/ui/frost_rts/wave_icon.png"
const MENU_ICON_PATH := "res://assets/ui/frost_rts/menu_icon.png"
const SCENE_BACKGROUND_TEXTURE_PATH := "res://assets/ui/frost_rts/frost_stone_bg.png"
const BASIC_ENEMY_TEXTURE_PATH := "res://assets/sprites/mmo-v1/enemies/basic_enemy.png"
const ENEMY_WALK_TEXTURE_PATHS := [
	"res://assets/sprites/mmo-v1/enemies/enemy_walk_1.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_walk_2.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_walk_3.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_walk_4.png",
]
const ENEMY_DEATH_TEXTURE_PATHS := [
	"res://assets/sprites/mmo-v1/enemies/enemy_death_1.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_death_2.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_death_3.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_death_4.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_death_5.png",
	"res://assets/sprites/mmo-v1/enemies/enemy_death_6.png",
]

var level_definition: LevelDefinition
var map_style_definition: MapStyleDefinition
var board_map_renderer: BoardMapRenderer
var tower_config: TowerConfig
var gold_icon_texture: Texture2D
var lives_icon_texture: Texture2D
var wave_icon_texture: Texture2D
var menu_icon_texture: Texture2D
var scene_background_texture: Texture2D
var single_tower_texture: Texture2D
var area_tower_texture: Texture2D
var slow_tower_texture: Texture2D
var flame_tower_texture: Texture2D
var poison_tower_texture: Texture2D
var basic_enemy_texture: Texture2D
var enemy_walk_textures: Array = []
var enemy_death_textures: Array = []
var single_projectile_textures: Array = []
var area_impact_textures: Array = []
var slow_impact_textures: Array = []
var flame_impact_textures: Array = []
var poison_projectile_textures: Array = []
var poison_impact_textures: Array = []
var tower_textures_by_type := {}
var projectile_textures_by_type := {}
var impact_textures_by_type := {}


func load_all() -> void:
	if level_definition == null:
		load_level_definition()

	load_map_style_assets()
	load_sprite_assets()


func load_level_definition() -> void:
	level_definition = LevelDefinition.load_from_path(DEFAULT_LEVEL_DEFINITION_PATH)


func load_map_style_assets() -> void:
	if level_definition == null:
		load_level_definition()

	if level_definition == null:
		map_style_definition = null
		board_map_renderer = null
		return

	var style_path := MAP_STYLE_DEFINITION_TEMPLATE % level_definition.style_id
	map_style_definition = MapStyleDefinition.load_from_path(style_path)
	board_map_renderer = BoardMapRenderer.new()
	board_map_renderer.load_style(map_style_definition)


func load_sprite_assets() -> void:
	gold_icon_texture = _load_texture(GOLD_ICON_PATH)
	lives_icon_texture = _load_texture(LIVES_ICON_PATH)
	wave_icon_texture = _load_texture(WAVE_ICON_PATH)
	menu_icon_texture = _load_texture(MENU_ICON_PATH)
	scene_background_texture = _load_texture(SCENE_BACKGROUND_TEXTURE_PATH)
	basic_enemy_texture = _load_texture(BASIC_ENEMY_TEXTURE_PATH)
	enemy_walk_textures = _load_texture_sequence(ENEMY_WALK_TEXTURE_PATHS)
	enemy_death_textures = _load_texture_sequence(ENEMY_DEATH_TEXTURE_PATHS)
	_load_tower_visual_assets()


func get_tower_texture(tower_type: int) -> Texture2D:
	return tower_textures_by_type.get(tower_type, single_tower_texture) as Texture2D


func get_projectile_textures(tower_type: int) -> Array:
	var textures := projectile_textures_by_type.get(tower_type, []) as Array
	if textures != null and not textures.is_empty():
		return textures
	return get_impact_textures(tower_type)


func get_impact_textures(tower_type: int) -> Array:
	var textures := impact_textures_by_type.get(tower_type, []) as Array
	if textures != null:
		return textures
	return []


func _load_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null

	return load(resource_path) as Texture2D


func _load_texture_sequence(paths: Array) -> Array:
	var textures := []
	for resource_path in paths:
		var texture := _load_texture(resource_path)
		if texture != null:
			textures.append(texture)

	return textures


func _load_tower_visual_assets() -> void:
	if tower_config == null:
		tower_config = TowerConfig.new()

	tower_textures_by_type = {}
	projectile_textures_by_type = {}
	impact_textures_by_type = {}
	for tower_type in tower_config.get_tower_types():
		var tower_texture := _load_texture(tower_config.get_tower_texture_path(tower_type))
		if tower_texture != null:
			tower_textures_by_type[tower_type] = tower_texture

		var projectile_textures := _load_texture_sequence(tower_config.get_projectile_texture_paths(tower_type))
		if not projectile_textures.is_empty():
			projectile_textures_by_type[tower_type] = projectile_textures

		var impact_textures := _load_texture_sequence(tower_config.get_impact_texture_paths(tower_type))
		if not impact_textures.is_empty():
			impact_textures_by_type[tower_type] = impact_textures

	_sync_compatibility_texture_fields()


func _sync_compatibility_texture_fields() -> void:
	single_tower_texture = get_tower_texture(GameTower.Type.SINGLE_TARGET)
	area_tower_texture = get_tower_texture(GameTower.Type.AREA)
	slow_tower_texture = get_tower_texture(GameTower.Type.SLOW)
	flame_tower_texture = get_tower_texture(GameTower.Type.FLAME)
	poison_tower_texture = get_tower_texture(GameTower.Type.POISON)
	single_projectile_textures = get_projectile_textures(GameTower.Type.SINGLE_TARGET)
	area_impact_textures = get_impact_textures(GameTower.Type.AREA)
	slow_impact_textures = get_impact_textures(GameTower.Type.SLOW)
	flame_impact_textures = get_impact_textures(GameTower.Type.FLAME)
	poison_projectile_textures = get_projectile_textures(GameTower.Type.POISON)
	poison_impact_textures = get_impact_textures(GameTower.Type.POISON)
