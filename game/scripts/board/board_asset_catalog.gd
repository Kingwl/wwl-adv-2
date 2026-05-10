class_name BoardAssetCatalog
extends RefCounted

const DEFAULT_LEVEL_DEFINITION_PATH := "res://data/levels/level_001.json"
const MAP_STYLE_DEFINITION_TEMPLATE := "res://data/map_styles/%s.json"
const GOLD_ICON_PATH := "res://assets/ui/frost_rts/gold_icon.png"
const LIVES_ICON_PATH := "res://assets/ui/frost_rts/lives_icon.png"
const WAVE_ICON_PATH := "res://assets/ui/frost_rts/wave_icon.png"
const MENU_ICON_PATH := "res://assets/ui/frost_rts/menu_icon.png"
const SCENE_BACKGROUND_TEXTURE_PATH := "res://assets/ui/frost_rts/frost_stone_bg.png"
const SINGLE_TOWER_TEXTURE_PATH := "res://assets/sprites/towers/round_rotating/single.png"
const AREA_TOWER_TEXTURE_PATH := "res://assets/sprites/towers/round_rotating/area.png"
const SLOW_TOWER_TEXTURE_PATH := "res://assets/sprites/towers/round_rotating/slow.png"
const FLAME_TOWER_TEXTURE_PATH := "res://assets/sprites/towers/round_rotating/flame.png"
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
const SINGLE_PROJECTILE_TEXTURE_PATHS := [
	"res://assets/sprites/mvp-v1/fx/single_projectile_1.png",
	"res://assets/sprites/mvp-v1/fx/single_projectile_2.png",
	"res://assets/sprites/mvp-v1/fx/single_projectile_3.png",
	"res://assets/sprites/mvp-v1/fx/single_projectile_4.png",
]
const AREA_IMPACT_TEXTURE_PATHS := [
	"res://assets/sprites/mvp-v1/fx/area_impact_1.png",
	"res://assets/sprites/mvp-v1/fx/area_impact_2.png",
	"res://assets/sprites/mvp-v1/fx/area_impact_3.png",
	"res://assets/sprites/mvp-v1/fx/area_impact_4.png",
]
const SLOW_IMPACT_TEXTURE_PATHS := [
	"res://assets/sprites/mvp-v1/fx/slow_impact_1.png",
	"res://assets/sprites/mvp-v1/fx/slow_impact_2.png",
	"res://assets/sprites/mvp-v1/fx/slow_impact_3.png",
	"res://assets/sprites/mvp-v1/fx/slow_impact_4.png",
]
const FLAME_IMPACT_TEXTURE_PATHS := [
	"res://assets/sprites/mvp-v1/fx/flame_impact_1.png",
	"res://assets/sprites/mvp-v1/fx/flame_impact_2.png",
	"res://assets/sprites/mvp-v1/fx/flame_impact_3.png",
	"res://assets/sprites/mvp-v1/fx/flame_impact_4.png",
]

var level_definition: LevelDefinition
var map_style_definition: MapStyleDefinition
var board_map_renderer: BoardMapRenderer
var gold_icon_texture: Texture2D
var lives_icon_texture: Texture2D
var wave_icon_texture: Texture2D
var menu_icon_texture: Texture2D
var scene_background_texture: Texture2D
var single_tower_texture: Texture2D
var area_tower_texture: Texture2D
var slow_tower_texture: Texture2D
var flame_tower_texture: Texture2D
var basic_enemy_texture: Texture2D
var enemy_walk_textures: Array = []
var enemy_death_textures: Array = []
var single_projectile_textures: Array = []
var area_impact_textures: Array = []
var slow_impact_textures: Array = []
var flame_impact_textures: Array = []


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
	single_tower_texture = _load_texture(SINGLE_TOWER_TEXTURE_PATH)
	area_tower_texture = _load_texture(AREA_TOWER_TEXTURE_PATH)
	slow_tower_texture = _load_texture(SLOW_TOWER_TEXTURE_PATH)
	flame_tower_texture = _load_texture(FLAME_TOWER_TEXTURE_PATH)
	basic_enemy_texture = _load_texture(BASIC_ENEMY_TEXTURE_PATH)
	enemy_walk_textures = _load_texture_sequence(ENEMY_WALK_TEXTURE_PATHS)
	enemy_death_textures = _load_texture_sequence(ENEMY_DEATH_TEXTURE_PATHS)
	single_projectile_textures = _load_texture_sequence(SINGLE_PROJECTILE_TEXTURE_PATHS)
	area_impact_textures = _load_texture_sequence(AREA_IMPACT_TEXTURE_PATHS)
	slow_impact_textures = _load_texture_sequence(SLOW_IMPACT_TEXTURE_PATHS)
	flame_impact_textures = _load_texture_sequence(FLAME_IMPACT_TEXTURE_PATHS)


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
