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


def main() -> int:
    try:
        level_schema = load_json(SCHEMA_DIR / "level.schema.json")
        style_schema = load_json(SCHEMA_DIR / "map_style.schema.json")

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

        print(f"asset check passed: {len(level_files)} level(s), {len(style_files)} map style(s)")
        return 0
    except ValidationError as exc:
        print(f"asset check failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
