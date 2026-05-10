#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


GAME_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = GAME_DIR / "data"
SCHEMA_DIR = DATA_DIR / "schemas"
LEVEL_DIR = DATA_DIR / "levels"
STYLE_DIR = DATA_DIR / "map_styles"
TOWER_DIR = DATA_DIR / "towers"
TOWER_CONFIG_PATH = TOWER_DIR / "towers.json"

TOWER_TYPES = {"SINGLE_TARGET", "AREA", "SLOW", "FLAME", "POISON"}
WEAPON_TYPES = {"BOW", "CROSSBOW", "CANNON", "BLADE", "SPELL", "HEROIC", "CHAOS"}
ATTACK_TYPES = {"NORMAL", "PIERCE", "SIEGE", "MAGIC", "HERO", "CHAOS"}
DAMAGE_SCHOOLS = {"PHYSICAL", "FROST", "FIRE", "POISON", "LIGHTNING", "ARCANE", "SHADOW"}
ATTACK_PATTERNS = {
    "SINGLE_PROJECTILE",
    "SPLASH_PROJECTILE",
    "STATUS_PROJECTILE",
    "STATUS_DOT",
    "CHAIN",
    "AURA",
    "GROUND_AREA",
    "MULTI_SHOT",
    "SUMMON_OR_TRAP",
}
EFFECT_TYPES = {"damage_primary", "splash_damage", "apply_status"}
STATUS_TYPES = {"SLOW", "BURN", "POISON"}
STACK_POLICIES = {"REFRESH", "STRONGEST", "REPLACE", "STACK", "INDEPENDENT"}


class ValidationError(Exception):
    pass


def load_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        raise ValidationError(f"{path}: invalid JSON: {exc}") from exc


def validate_schema(value: Any, schema: dict[str, Any], path: str) -> None:
    expected_type = schema.get("type")
    if expected_type is not None and not matches_type(value, expected_type):
        raise ValidationError(f"{path}: expected {expected_type}, got {type(value).__name__}")

    if "enum" in schema and value not in schema["enum"]:
        raise ValidationError(f"{path}: expected one of {schema['enum']!r}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        for key in required:
            if key not in value:
                raise ValidationError(f"{path}: missing required key {key!r}")

        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            extra = sorted(set(value.keys()) - set(properties.keys()))
            if extra:
                raise ValidationError(f"{path}: unexpected keys {extra!r}")

        for key, child_schema in properties.items():
            if key in value:
                validate_schema(value[key], child_schema, f"{path}.{key}")

    if isinstance(value, list):
        if "minItems" in schema and len(value) < int(schema["minItems"]):
            raise ValidationError(f"{path}: expected at least {schema['minItems']} items")
        if "maxItems" in schema and len(value) > int(schema["maxItems"]):
            raise ValidationError(f"{path}: expected at most {schema['maxItems']} items")
        if "items" in schema:
            for index, item in enumerate(value):
                validate_schema(item, schema["items"], f"{path}[{index}]")

    if isinstance(value, str):
        if "minLength" in schema and len(value) < int(schema["minLength"]):
            raise ValidationError(f"{path}: expected string length >= {schema['minLength']}")
        if "pattern" in schema and re.match(str(schema["pattern"]), value) is None:
            raise ValidationError(f"{path}: value {value!r} does not match {schema['pattern']!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            raise ValidationError(f"{path}: value {value!r} is below minimum {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            raise ValidationError(f"{path}: value {value!r} is above maximum {schema['maximum']}")


def matches_type(value: Any, expected_type: str) -> bool:
    if expected_type == "object":
        return isinstance(value, dict)
    if expected_type == "array":
        return isinstance(value, list)
    if expected_type == "string":
        return isinstance(value, str)
    if expected_type == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected_type == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected_type == "boolean":
        return isinstance(value, bool)
    raise ValidationError(f"Unsupported schema type {expected_type!r}")


def as_cell(value: Any, path: str) -> tuple[int, int]:
    if (
        not isinstance(value, list)
        or len(value) != 2
        or not all(isinstance(item, int) and not isinstance(item, bool) for item in value)
    ):
        raise ValidationError(f"{path}: expected [x, y] integer cell")
    return int(value[0]), int(value[1])


def ensure_cell_in_bounds(cell: tuple[int, int], width: int, height: int, path: str) -> None:
    x, y = cell
    if x < 0 or y < 0 or x >= width or y >= height:
        raise ValidationError(f"{path}: cell {cell!r} is outside {width}x{height} grid")


def ensure_res_path_exists(resource_path: str, path: str, allow_empty: bool = False) -> None:
    if resource_path == "" and allow_empty:
        return
    if not resource_path.startswith("res://"):
        raise ValidationError(f"{path}: expected res:// path, got {resource_path!r}")

    file_path = GAME_DIR / resource_path.removeprefix("res://")
    if not file_path.is_file():
        raise ValidationError(f"{path}: missing resource {resource_path}")


def validate_level(path: Path, schema: dict[str, Any], style_ids: set[str]) -> str:
    level = load_json(path)
    validate_schema(level, schema, path.name)

    if level["id"] != path.stem:
        raise ValidationError(f"{path.name}.id: must match file name {path.stem!r}")

    width = int(level["grid"]["width"])
    height = int(level["grid"]["height"])
    if level["style_id"] not in style_ids:
        raise ValidationError(f"{path.name}.style_id: unknown map style {level['style_id']!r}")

    path_cells = [as_cell(cell, f"{path.name}.path_cells[{index}]") for index, cell in enumerate(level["path_cells"])]
    if len(set(path_cells)) != len(path_cells):
        raise ValidationError(f"{path.name}.path_cells: duplicate cells are not allowed")

    for index, cell in enumerate(path_cells):
        ensure_cell_in_bounds(cell, width, height, f"{path.name}.path_cells[{index}]")
        if index > 0:
            previous = path_cells[index - 1]
            manhattan_distance = abs(cell[0] - previous[0]) + abs(cell[1] - previous[1])
            if manhattan_distance != 1:
                raise ValidationError(
                    f"{path.name}.path_cells[{index}]: path must move orthogonally by one cell"
                )

    for key in ("blocked_cells", "locked_cells"):
        for index, raw_cell in enumerate(level[key]):
            cell = as_cell(raw_cell, f"{path.name}.{key}[{index}]")
            ensure_cell_in_bounds(cell, width, height, f"{path.name}.{key}[{index}]")
            if cell in path_cells:
                raise ValidationError(f"{path.name}.{key}[{index}]: cell overlaps path")

    spawn_cell = as_cell(level["spawn_cell"], f"{path.name}.spawn_cell")
    exit_cell = as_cell(level["exit_cell"], f"{path.name}.exit_cell")
    if spawn_cell != path_cells[0]:
        raise ValidationError(f"{path.name}.spawn_cell: must match first path cell")
    if exit_cell != path_cells[-1]:
        raise ValidationError(f"{path.name}.exit_cell: must match last path cell")

    return str(level["id"])


def validate_style(path: Path, schema: dict[str, Any]) -> str:
    style = load_json(path)
    validate_schema(style, schema, path.name)
    if style["id"] != path.stem:
        raise ValidationError(f"{path.name}.id: must match file name {path.stem!r}")

    ensure_res_path_exists(style["background"], f"{path.name}.background")
    ensure_res_path_exists(style["background_normal"], f"{path.name}.background_normal", allow_empty=True)
    for key in ("blocked", "locked"):
        ensure_res_path_exists(style["tiles"][key], f"{path.name}.tiles.{key}", allow_empty=True)
    return str(style["id"])


def validate_enum(value: Any, allowed: set[str], path: str) -> None:
    if value not in allowed:
        raise ValidationError(f"{path}: expected one of {sorted(allowed)!r}, got {value!r}")


def validate_positive_number(value: Any, path: str) -> None:
    if not isinstance(value, (int, float)) or isinstance(value, bool) or float(value) <= 0:
        raise ValidationError(f"{path}: expected positive number")


def validate_tower_effect(effect: dict[str, Any], path: str) -> str:
    effect_type = str(effect["type"])
    validate_enum(effect_type, EFFECT_TYPES, f"{path}.type")

    damage_multiplier = effect.get("damage_multiplier", 1.0)
    if not isinstance(damage_multiplier, (int, float)) or isinstance(damage_multiplier, bool) or damage_multiplier < 0:
        raise ValidationError(f"{path}.damage_multiplier: cannot be negative")

    if "attack_type" in effect:
        validate_enum(effect["attack_type"], ATTACK_TYPES, f"{path}.attack_type")
    if "damage_school" in effect:
        validate_enum(effect["damage_school"], DAMAGE_SCHOOLS, f"{path}.damage_school")

    if effect_type == "splash_damage":
        validate_positive_number(effect.get("radius_cells"), f"{path}.radius_cells")

    if effect_type == "apply_status":
        if "status_type" not in effect:
            raise ValidationError(f"{path}.status_type: required for apply_status")
        validate_enum(effect["status_type"], STATUS_TYPES, f"{path}.status_type")
        validate_positive_number(effect.get("duration"), f"{path}.duration")

        move_speed_multiplier = effect.get("move_speed_multiplier", 1.0)
        validate_positive_number(move_speed_multiplier, f"{path}.move_speed_multiplier")

        tick_interval = effect.get("tick_interval", 0.0)
        tick_damage = effect.get("tick_damage", 0.0)
        if not isinstance(tick_interval, (int, float)) or isinstance(tick_interval, bool) or tick_interval < 0:
            raise ValidationError(f"{path}.tick_interval: cannot be negative")
        if not isinstance(tick_damage, (int, float)) or isinstance(tick_damage, bool) or tick_damage < 0:
            raise ValidationError(f"{path}.tick_damage: cannot be negative")
        if tick_damage > 0 and tick_interval <= 0:
            raise ValidationError(f"{path}.tick_interval: must be positive when tick_damage is positive")

        if "stack_policy" in effect:
            validate_enum(effect["stack_policy"], STACK_POLICIES, f"{path}.stack_policy")

    return effect_type


def validate_towers(path: Path, schema: dict[str, Any]) -> int:
    tower_config = load_json(path)
    validate_schema(tower_config, schema, path.name)

    tower_ids: set[str] = set()
    tower_types: set[str] = set()
    for tower_index, tower in enumerate(tower_config["towers"]):
        tower_path = f"{path.name}.towers[{tower_index}]"
        tower_id = str(tower["id"])
        tower_type = str(tower["type"])
        if tower_id in tower_ids:
            raise ValidationError(f"{tower_path}.id: duplicate tower id {tower_id!r}")
        if tower_type in tower_types:
            raise ValidationError(f"{tower_path}.type: duplicate tower type {tower_type!r}")
        tower_ids.add(tower_id)
        tower_types.add(tower_type)

        validate_enum(tower_type, TOWER_TYPES, f"{tower_path}.type")
        validate_enum(tower["weapon_type"], WEAPON_TYPES, f"{tower_path}.weapon_type")
        validate_enum(tower["attack_type"], ATTACK_TYPES, f"{tower_path}.attack_type")
        validate_enum(tower["damage_school"], DAMAGE_SCHOOLS, f"{tower_path}.damage_school")
        validate_enum(tower["attack_pattern"], ATTACK_PATTERNS, f"{tower_path}.attack_pattern")

        projectile = tower["projectile"]
        validate_positive_number(projectile["speed_cells_per_second"], f"{tower_path}.projectile.speed_cells_per_second")
        if projectile["hit_radius_cells"] < 0:
            raise ValidationError(f"{tower_path}.projectile.hit_radius_cells: cannot be negative")

        previous_damage: float | None = None
        previous_range: float | None = None
        previous_splash = False
        previous_status_types: set[str] | None = None
        for tier_index, tier in enumerate(tower["tiers"]):
            tier_number = tier_index + 1
            tier_path = f"{tower_path}.tiers[{tier_index}]"
            if int(tier["tier"]) != tier_number:
                raise ValidationError(f"{tier_path}.tier: expected sequential tier {tier_number}")

            validate_positive_number(tier["range_cells"], f"{tier_path}.range_cells")
            validate_positive_number(tier["attack_interval"], f"{tier_path}.attack_interval")

            is_max_tier = tier_index == len(tower["tiers"]) - 1
            upgrade_cost = int(tier.get("upgrade_cost", 0))
            if is_max_tier and upgrade_cost != 0:
                raise ValidationError(f"{tier_path}.upgrade_cost: max tier cannot define upgrade_cost")
            if not is_max_tier and upgrade_cost <= 0:
                raise ValidationError(f"{tier_path}.upgrade_cost: non-max tiers require positive upgrade_cost")

            if previous_damage is not None and float(tier["damage"]) <= previous_damage:
                raise ValidationError(f"{tier_path}.damage: must be greater than previous tier")
            if previous_range is not None and float(tier["range_cells"]) <= previous_range:
                raise ValidationError(f"{tier_path}.range_cells: must be greater than previous tier")

            effect_types: set[str] = set()
            status_types: set[str] = set()
            for effect_index, effect in enumerate(tier["effects"]):
                effect_type = validate_tower_effect(effect, f"{tier_path}.effects[{effect_index}]")
                effect_types.add(effect_type)
                if effect_type == "apply_status":
                    status_types.add(str(effect["status_type"]))

            has_splash = "splash_damage" in effect_types
            if tier_index > 0 and not previous_splash and has_splash:
                raise ValidationError(f"{tier_path}.effects: cannot add splash_damage after tier 1")
            if previous_status_types is not None and status_types != previous_status_types:
                raise ValidationError(f"{tier_path}.effects: cannot change apply_status status types across tiers")

            previous_damage = float(tier["damage"])
            previous_range = float(tier["range_cells"])
            previous_splash = has_splash
            previous_status_types = status_types

    return len(tower_config["towers"])


def main() -> int:
    try:
        level_schema = load_json(SCHEMA_DIR / "level.schema.json")
        style_schema = load_json(SCHEMA_DIR / "map_style.schema.json")
        towers_schema = load_json(SCHEMA_DIR / "towers.schema.json")

        style_files = sorted(STYLE_DIR.glob("*.json"))
        level_files = sorted(LEVEL_DIR.glob("*.json"))
        if not style_files:
            raise ValidationError("No map style JSON files found")
        if not level_files:
            raise ValidationError("No level JSON files found")

        style_ids: set[str] = set()
        for path in style_files:
            style_id = validate_style(path, style_schema)
            if style_id in style_ids:
                raise ValidationError(f"{path.name}.id: duplicate map style id {style_id!r}")
            style_ids.add(style_id)

        level_ids: set[str] = set()
        for path in level_files:
            level_id = validate_level(path, level_schema, style_ids)
            if level_id in level_ids:
                raise ValidationError(f"{path.name}.id: duplicate level id {level_id!r}")
            level_ids.add(level_id)

        tower_count = validate_towers(TOWER_CONFIG_PATH, towers_schema)

        print(
            "asset check passed: "
            f"{len(level_files)} level(s), {len(style_files)} map style(s), {tower_count} tower(s)"
        )
        return 0
    except ValidationError as exc:
        print(f"asset check failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
