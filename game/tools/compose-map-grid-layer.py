#!/usr/bin/env python3
"""Compose deterministic grid layers from gameplay level JSON.

The output is final-runtime geometry composed from an existing visual source.
The creative texture source remains image-generated art; gameplay-critical path
and buildable placement comes only from level data.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageStat
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LEVEL_DIR = PROJECT_ROOT / "data/levels"
STYLE_DIR = PROJECT_ROOT / "data/map_styles"
ASSET_TILESET_DIR = PROJECT_ROOT / "assets/tilesets"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "tools/out/composed_map_layers"

BUILDABLE_TINT = (151, 150, 121, 255)
PATH_TINT = (190, 162, 112, 255)
BLOCKED_TINT = (102, 82, 65, 255)
CLEAN_GROUND_TINTS = {
    "long_road_v1": (174, 163, 134),
    "kill_zone_v1": (112, 101, 78),
    "armored_column_v1": (136, 127, 100),
    "mvp_showcase_v1": (160, 151, 125),
}


def main() -> int:
    args = parse_args()
    level_paths = collect_level_paths(args)
    output_root = Path(args.out_dir).expanduser().resolve() if args.out_dir else DEFAULT_OUTPUT_DIR
    output_root.mkdir(parents=True, exist_ok=True)

    summaries: list[dict] = []
    for level_path in level_paths:
        summary = compose_for_level(level_path, output_root, args)
        summaries.append(summary)
        print(summary["outputs"]["grid_layer"])
        print(summary["outputs"]["preview"])

    index = {
        "levels": summaries,
        "output_root": str(output_root),
    }
    (output_root / "index.json").write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compose runtime grid layers from level data.")
    parser.add_argument(
        "--level",
        action="append",
        default=[],
        help="Level JSON path, supports res://. Repeat for multiple levels. Defaults to data/levels/*.json.",
    )
    parser.add_argument("--out-dir", default="", help="Output root. Defaults to game/tools/out/composed_map_layers.")
    parser.add_argument(
        "--source-background",
        default="",
        help="Optional visual source image. Defaults to the level map style background.",
    )
    parser.add_argument(
        "--write-style-assets",
        action="store_true",
        help="Also write grid_layer_composed.png and manifest into assets/tilesets/<style_id>/.",
    )
    parser.add_argument("--asset-name", default="grid_layer_composed", help="Base filename for style asset output.")
    parser.add_argument(
        "--write-clean-background",
        action="store_true",
        help="Replace the inner playfield with a deterministic clean ground texture before composing the grid layer.",
    )
    parser.add_argument(
        "--clean-background-name",
        default="background_frame_clean",
        help="Base filename for clean background output when --write-clean-background is used.",
    )
    parser.add_argument(
        "--path-width",
        type=float,
        default=0.62,
        help="Path ribbon width as a fraction of tile size.",
    )
    return parser.parse_args()


def collect_level_paths(args: argparse.Namespace) -> list[Path]:
    if args.path_width <= 0.0 or args.path_width > 1.0:
        raise SystemExit("--path-width must be in the range (0, 1].")

    if args.level:
        paths = [resolve_resource_path(value) for value in args.level]
    else:
        paths = sorted(LEVEL_DIR.glob("*.json"))

    for path in paths:
        if not path.is_file():
            raise SystemExit(f"Missing level file: {path}")
    return paths


def compose_for_level(level_path: Path, output_root: Path, args: argparse.Namespace) -> dict:
    level = read_json(level_path)
    style = read_style(level)
    level_id = str(level.get("id") or level_path.stem)
    style_id = str(level.get("style_id", ""))
    tile_size = int(style.get("tile_size", 128))
    width, height = grid_size(level, level_path)
    size = (width * tile_size, height * tile_size)

    cells = classify_cells(level, level_path, width, height)
    background_path = source_background_path(args.source_background, style)
    background = load_background(background_path, size)
    runtime_background = background
    if args.write_clean_background:
        runtime_background = render_clean_background(background, cells, tile_size, style_id)

    textures = make_textures(runtime_background, cells, tile_size)
    grid_layer = render_grid_layer(size, tile_size, cells, textures, args.path_width)
    preview = Image.alpha_composite(runtime_background, grid_layer)

    output_dir = output_root / level_id
    output_dir.mkdir(parents=True, exist_ok=True)
    output_grid_layer = output_dir / "grid_layer_composed.png"
    output_preview = output_dir / "preview.png"
    output_manifest = output_dir / "composition_manifest.json"
    output_clean_background = output_dir / f"{args.clean_background_name}.png"
    if args.write_clean_background:
        runtime_background.save(output_clean_background)
    grid_layer.save(output_grid_layer)
    preview.save(output_preview)

    outputs = {
        "grid_layer": str(output_grid_layer),
        "preview": str(output_preview),
        "manifest": str(output_manifest),
    }
    if args.write_clean_background:
        outputs["clean_background"] = str(output_clean_background)
    asset_grid_layer = ""
    asset_clean_background = ""
    asset_manifest = ""
    if args.write_style_assets:
        asset_dir = ASSET_TILESET_DIR / style_id
        asset_dir.mkdir(parents=True, exist_ok=True)
        asset_grid_path = asset_dir / f"{args.asset_name}.png"
        asset_manifest_path = asset_dir / f"{args.asset_name}.manifest.json"
        grid_layer.save(asset_grid_path)
        if args.write_clean_background:
            asset_clean_background_path = asset_dir / f"{args.clean_background_name}.png"
            runtime_background.save(asset_clean_background_path)
            asset_clean_background = to_resource_path(asset_clean_background_path)
            outputs["style_clean_background"] = str(asset_clean_background_path)
        asset_manifest = str(asset_manifest_path)
        asset_grid_layer = to_resource_path(asset_grid_path)
        outputs["style_grid_layer"] = str(asset_grid_path)
        outputs["style_manifest"] = str(asset_manifest_path)

    summary = {
        "level": to_resource_path(level_path),
        "level_id": level_id,
        "style_id": style_id,
        "source_background": to_resource_path(background_path) if background_path else "",
        "tile_size": tile_size,
        "grid": {"width": width, "height": height},
        "path_width_fraction": args.path_width,
        "counts": {
            "buildable": len(cells["buildable"]),
            "path": len(cells["path"]),
            "blocked": len(cells["blocked"]),
            "exterior": len(cells["exterior"]),
            "interior_blocked": len(cells["interior_blocked"]),
            "locked": len(cells["locked"]),
        },
        "cells": {
            "buildable": sorted_cells(cells["buildable"]),
            "path": sorted_cells(cells["path"]),
            "path_order": [[x, y] for x, y in cells["path_order"]],
            "blocked": sorted_cells(cells["blocked"]),
            "interior_blocked": sorted_cells(cells["interior_blocked"]),
            "locked": sorted_cells(cells["locked"]),
        },
        "method": "deterministic clean playfield, road, buildable-pad, and blocker geometry from level JSON over image-generated exterior art"
        if args.write_clean_background
        else "deterministic road, buildable-pad, and blocker geometry from level JSON over image-generated background art",
        "runtime_clean_background": asset_clean_background,
        "runtime_grid_layer": asset_grid_layer,
        "outputs": outputs,
    }
    output_manifest.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    if asset_manifest:
        Path(asset_manifest).write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return summary


def read_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_style(level: dict) -> dict:
    style_id = str(level.get("style_id", ""))
    if not style_id:
        raise SystemExit("Level is missing style_id.")
    style_path = STYLE_DIR / f"{style_id}.json"
    if not style_path.is_file():
        raise SystemExit(f"Missing map style: {style_path}")
    return read_json(style_path)


def grid_size(level: dict, level_path: Path) -> tuple[int, int]:
    grid = level.get("grid", {})
    width = int(grid.get("width", 0))
    height = int(grid.get("height", 0))
    if width <= 0 or height <= 0:
        raise SystemExit(f"{level_path}: invalid grid dimensions.")
    return width, height


def source_background_path(source_background: str, style: dict) -> Path:
    source = source_background or str(style.get("background", ""))
    if not source:
        raise SystemExit("No source background was provided and the map style has no background.")
    path = resolve_resource_path(source)
    if not path.is_file():
        raise SystemExit(f"Missing source background: {path}")
    return path


def load_background(path: Path, size: tuple[int, int]) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != size:
        image = image.resize(size, Image.Resampling.LANCZOS)
    return image


def render_clean_background(
    background: Image.Image,
    cells: dict,
    tile_size: int,
    style_id: str,
) -> Image.Image:
    """Preserve the image-generated exterior while normalizing the playable center."""

    size = background.size
    width = size[0] // tile_size
    height = size[1] // tile_size
    if width < 3 or height < 3:
        return background.copy()

    tint = CLEAN_GROUND_TINTS.get(style_id, (150, 140, 112))
    texture = clean_ground_texture(background, cells, tile_size, tint)
    ground = tile_ground_texture(texture, size, tile_size)

    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    inset = tile_size
    draw.rectangle((inset, inset, size[0] - inset, size[1] - inset), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(4, int(tile_size * 0.055))))
    return Image.composite(ground, background, mask)


def clean_ground_texture(
    background: Image.Image,
    cells: dict,
    tile_size: int,
    tint: tuple[int, int, int],
) -> Image.Image:
    width = background.size[0] // tile_size
    height = background.size[1] // tile_size
    candidates = {
        cell
        for cell in cells["buildable"]
        if 0 < cell[0] < width - 1 and 0 < cell[1] < height - 1
    }
    if not candidates:
        candidates = set(cells["buildable"])

    source_cell = lowest_detail_cell(background, candidates, tile_size)
    texture = texture_from_cell(background, source_cell, tile_size, (*tint, 255), 1.01, 0.46)
    texture = texture.filter(ImageFilter.GaussianBlur(max(3, tile_size // 18)))
    tint_layer = Image.new("RGBA", (tile_size, tile_size), (*tint, 255))
    texture = Image.blend(texture, tint_layer, 0.52)
    texture.putalpha(255)
    return texture


def lowest_detail_cell(
    background: Image.Image,
    cells: Iterable[tuple[int, int]],
    tile_size: int,
) -> tuple[int, int] | None:
    cell_list = list(cells)
    if not cell_list:
        return None

    center_x = background.size[0] / 2.0
    center_y = background.size[1] / 2.0

    def score(cell: tuple[int, int]) -> float:
        margin = max(12, int(tile_size * 0.2))
        x, y = cell
        crop = background.crop(
            (
                x * tile_size + margin,
                y * tile_size + margin,
                (x + 1) * tile_size - margin,
                (y + 1) * tile_size - margin,
            )
        )
        luma = crop.convert("L").resize((24, 24), Image.Resampling.BILINEAR)
        variance = ImageStat.Stat(luma).var[0]
        dx = (x + 0.5) * tile_size - center_x
        dy = (y + 0.5) * tile_size - center_y
        return variance + (dx * dx + dy * dy) * 0.00004

    return min(cell_list, key=score)


def tile_ground_texture(texture: Image.Image, size: tuple[int, int], tile_size: int) -> Image.Image:
    rgb_texture = texture.convert("RGB")
    base_color = tuple(int(channel) for channel in ImageStat.Stat(rgb_texture).mean)
    ground_rgb = Image.new("RGB", size, base_color)
    draw = ImageDraw.Draw(ground_rgb)
    stone_size = max(22, int(tile_size * 0.19))
    outline_color = adjust_rgb(base_color, -18)

    for y in range(-stone_size, size[1] + stone_size, stone_size):
        row = y // stone_size
        offset = (row % 2) * (stone_size // 2)
        for x in range(-stone_size - offset, size[0] + stone_size, stone_size):
            seed = stable_noise(x // stone_size, row, 11)
            inset = 1 + seed % 3
            jitter_x = stable_noise(x, y, 17) % 5 - 2
            jitter_y = stable_noise(x, y, 23) % 5 - 2
            shade = stable_noise(x, y, 31) % 17 - 8
            rect = (
                x + jitter_x + inset,
                y + jitter_y + inset,
                x + stone_size + jitter_x - inset,
                y + stone_size + jitter_y - inset,
            )
            draw.rounded_rectangle(
                rect,
                radius=max(2, stone_size // 10),
                fill=adjust_rgb(base_color, shade),
                outline=outline_color,
                width=1,
            )

    source_texture = rgb_texture.resize(size, Image.Resampling.BICUBIC)
    ground_rgb = Image.blend(ground_rgb.filter(ImageFilter.GaussianBlur(0.45)), source_texture, 0.08)
    ground = ground_rgb.convert("RGBA")
    ground.putalpha(255)
    return ground


def stable_noise(x: int, y: int, salt: int) -> int:
    value = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    return value & 0xFFFFFFFF


def adjust_rgb(color: tuple[int, int, int], delta: int) -> tuple[int, int, int]:
    return tuple(max(0, min(255, channel + delta)) for channel in color)


def resolve_resource_path(path_value: str | Path) -> Path:
    path = str(path_value)
    if path.startswith("res://"):
        return PROJECT_ROOT / path.removeprefix("res://")
    return Path(path).expanduser().resolve()


def to_resource_path(path: Path) -> str:
    try:
        relative = path.resolve().relative_to(PROJECT_ROOT)
    except ValueError:
        return str(path)
    return "res://" + relative.as_posix()


def classify_cells(level: dict, level_path: Path, width: int, height: int) -> dict[str, set[tuple[int, int]] | list[tuple[int, int]]]:
    all_cells = {(x, y) for y in range(height) for x in range(width)}
    path_cells = cells_to_tuples(level.get("path_cells", []), "path_cells")
    blocked_cells = cells_to_tuples(level.get("blocked_cells", []), "blocked_cells")
    locked_cells = cells_to_tuples(level.get("locked_cells", []), "locked_cells")
    validate_cells(level_path, width, height, path_cells, blocked_cells, locked_cells)

    path_set = set(path_cells)
    blocked_set = set(blocked_cells)
    locked_set = set(locked_cells)
    non_buildable_set = blocked_set | locked_set
    exterior_set = flood_exterior_cells(width, height, non_buildable_set, path_set)
    return {
        "buildable": all_cells - path_set - non_buildable_set,
        "path": path_set,
        "path_order": path_cells,
        "blocked": blocked_set,
        "exterior": exterior_set,
        "interior_blocked": blocked_set - exterior_set,
        "locked": locked_set - exterior_set,
    }


def cells_to_tuples(cells: Iterable[object], field_name: str) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for index, cell in enumerate(cells):
        if not isinstance(cell, (list, tuple)) or len(cell) != 2:
            raise SystemExit(f"{field_name}[{index}] must be [x, y], got {cell!r}")
        result.append((int(cell[0]), int(cell[1])))
    return result


def validate_cells(
    level_path: Path,
    width: int,
    height: int,
    path_cells: list[tuple[int, int]],
    blocked_cells: list[tuple[int, int]],
    locked_cells: list[tuple[int, int]],
) -> None:
    for field_name, cells in (
        ("path_cells", path_cells),
        ("blocked_cells", blocked_cells),
        ("locked_cells", locked_cells),
    ):
        if len(set(cells)) != len(cells):
            raise SystemExit(f"{level_path}: {field_name} contains duplicate cells.")
        for x, y in cells:
            if x < 0 or y < 0 or x >= width or y >= height:
                raise SystemExit(f"{level_path}: {field_name} cell {(x, y)!r} is outside the grid.")

    overlap = set(path_cells) & (set(blocked_cells) | set(locked_cells))
    if overlap:
        raise SystemExit(f"{level_path}: blocked/locked cells overlap path cells: {sorted_cells(overlap)}")


def flood_exterior_cells(
    width: int,
    height: int,
    non_buildable_set: set[tuple[int, int]],
    path_set: set[tuple[int, int]],
) -> set[tuple[int, int]]:
    exterior: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        for cell in ((x, 0), (x, height - 1)):
            if cell in non_buildable_set:
                queue.append(cell)
    for y in range(height):
        for cell in ((0, y), (width - 1, y)):
            if cell in non_buildable_set:
                queue.append(cell)

    while queue:
        cell = queue.popleft()
        if cell in exterior or cell not in non_buildable_set or cell in path_set:
            continue
        exterior.add(cell)
        x, y = cell
        for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            nx, ny = neighbor
            if nx < 0 or ny < 0 or nx >= width or ny >= height:
                continue
            if neighbor in non_buildable_set and neighbor not in exterior:
                queue.append(neighbor)
    return exterior


def make_textures(background: Image.Image, cells: dict, tile_size: int) -> dict[str, Image.Image]:
    buildable_cell = nearest_to_center(cells["buildable"], background.size, tile_size)
    path_order = cells["path_order"]
    path_cell = path_order[len(path_order) // 2] if path_order else None
    blocked_cell = nearest_to_center(cells["interior_blocked"] or cells["blocked"], background.size, tile_size)

    return {
        "buildable": texture_from_cell(background, buildable_cell, tile_size, BUILDABLE_TINT, 1.08, 1.12),
        "path": texture_from_cell(background, path_cell, tile_size, PATH_TINT, 1.05, 1.02),
        "blocked": texture_from_cell(background, blocked_cell, tile_size, BLOCKED_TINT, 0.88, 1.18),
    }


def nearest_to_center(cells: Iterable[tuple[int, int]], size: tuple[int, int], tile_size: int) -> tuple[int, int] | None:
    cell_list = list(cells)
    if not cell_list:
        return None
    center_x = size[0] / 2.0
    center_y = size[1] / 2.0
    return min(
        cell_list,
        key=lambda cell: ((cell[0] + 0.5) * tile_size - center_x) ** 2
        + ((cell[1] + 0.5) * tile_size - center_y) ** 2,
    )


def texture_from_cell(
    background: Image.Image,
    cell: tuple[int, int] | None,
    tile_size: int,
    tint: tuple[int, int, int, int],
    brightness: float,
    contrast: float,
) -> Image.Image:
    if cell is None:
        texture = Image.new("RGBA", (tile_size, tile_size), tint)
    else:
        margin = max(4, int(tile_size * 0.12))
        x, y = cell
        box = (
            x * tile_size + margin,
            y * tile_size + margin,
            (x + 1) * tile_size - margin,
            (y + 1) * tile_size - margin,
        )
        texture = background.crop(box).resize((tile_size, tile_size), Image.Resampling.LANCZOS)

    rgb = texture.convert("RGB")
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    tint_layer = Image.new("RGB", (tile_size, tile_size), tint[:3])
    rgb = Image.blend(rgb, tint_layer, 0.28)
    texture = rgb.convert("RGBA")
    texture.putalpha(255)
    return texture


def render_grid_layer(
    size: tuple[int, int],
    tile_size: int,
    cells: dict,
    textures: dict[str, Image.Image],
    path_width_fraction: float,
) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_path(layer, cells["path_order"], tile_size, textures["path"], path_width_fraction)
    draw_buildable_pads(layer, cells["buildable"], tile_size, textures["buildable"])
    width = size[0] // tile_size
    height = size[1] // tile_size
    blocker_cells = inner_playfield_cells(cells["blocked"] | cells["locked"], width, height)
    blocker_cells -= cells["path"] | cells["buildable"]
    for cell in sorted(blocker_cells, key=lambda value: (value[1], value[0])):
        draw_blocker(layer, cell, tile_size, textures["blocked"])
    return layer


def inner_playfield_cells(
    cells: set[tuple[int, int]],
    width: int,
    height: int,
) -> set[tuple[int, int]]:
    return {
        cell
        for cell in cells
        if 0 < cell[0] < width - 1 and 0 < cell[1] < height - 1
    }


def draw_path(
    layer: Image.Image,
    path_order: list[tuple[int, int]],
    tile_size: int,
    texture: Image.Image,
    path_width_fraction: float,
) -> None:
    if not path_order:
        return

    body_width = max(4, int(tile_size * path_width_fraction))
    border_width = body_width + max(6, int(tile_size * 0.055))
    shadow_width = border_width + max(4, int(tile_size * 0.035))
    points = extended_path_points(path_order, layer.size, tile_size)
    shadow_offset = (0, max(2, int(tile_size * 0.025)))

    shadow_mask = path_mask(layer.size, points, shadow_width, shadow_offset)
    border_mask = path_mask(layer.size, points, border_width)
    body_mask = path_mask(layer.size, points, body_width)

    composite_solid(layer, (0, 0, 0, 34), shadow_mask)
    composite_solid(layer, (87, 70, 52, 150), border_mask)
    composite_texture(layer, tile_texture(texture, layer.size), scaled_mask(body_mask, 224))

    highlight_width = max(3, int(tile_size * 0.035))
    highlight_mask = path_mask(layer.size, points, max(4, body_width - int(tile_size * 0.2)), (0, -highlight_width))
    composite_solid(layer, (255, 240, 203, 28), highlight_mask)


def path_mask(
    size: tuple[int, int],
    points: list[tuple[int, int]],
    width: int,
    offset: tuple[int, int] = (0, 0),
) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    shifted = [(x + offset[0], y + offset[1]) for x, y in points]
    if len(shifted) == 1:
        x, y = shifted[0]
        radius = width // 2
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
        return mask
    try:
        draw.line(shifted, fill=255, width=width, joint="curve")
    except TypeError:
        draw.line(shifted, fill=255, width=width)
    radius = width // 2
    for x, y in shifted:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    return mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))


def extended_path_points(
    path_order: list[tuple[int, int]],
    size: tuple[int, int],
    tile_size: int,
) -> list[tuple[int, int]]:
    points = [cell_center(cell, tile_size) for cell in path_order]
    if not path_order:
        return points

    width = size[0] // tile_size
    height = size[1] // tile_size
    start_extension = endpoint_extension(path_order[0], width, height, tile_size, size)
    end_extension = endpoint_extension(path_order[-1], width, height, tile_size, size)
    if start_extension != points[0]:
        points.insert(0, start_extension)
    if end_extension != points[-1]:
        points.append(end_extension)
    return points


def endpoint_extension(
    cell: tuple[int, int],
    width: int,
    height: int,
    tile_size: int,
    size: tuple[int, int],
) -> tuple[int, int]:
    center = cell_center(cell, tile_size)
    x, y = cell
    if x == 0:
        return (-tile_size // 2, center[1])
    if x == width - 1:
        return (size[0] + tile_size // 2, center[1])
    if y == 0:
        return (center[0], -tile_size // 2)
    if y == height - 1:
        return (center[0], size[1] + tile_size // 2)
    return center


def draw_buildable_pads(
    layer: Image.Image,
    cells: set[tuple[int, int]],
    tile_size: int,
    texture: Image.Image,
) -> None:
    for component in buildable_pad_groups(cells):
        draw_buildable_component(layer, component, tile_size, texture)


def draw_buildable_component(
    layer: Image.Image,
    component: set[tuple[int, int]],
    tile_size: int,
    texture: Image.Image,
) -> None:
    pad_mask = build_component_mask(layer.size, component, tile_size, offset=(0, 0))
    shadow_mask = build_component_mask(
        layer.size,
        component,
        tile_size,
        offset=(max(2, tile_size // 36), max(3, tile_size // 28)),
    )
    composite_solid(layer, (0, 0, 0, 42), shadow_mask)
    composite_texture(layer, tile_texture(texture, layer.size), scaled_mask(pad_mask, 198))

    outline_mask = ImageChops.subtract(pad_mask.filter(ImageFilter.MaxFilter(5)), pad_mask)
    inner_mask = ImageChops.subtract(pad_mask, pad_mask.filter(ImageFilter.MinFilter(5)))
    composite_solid(layer, (78, 77, 58, 146), outline_mask)
    composite_solid(layer, (230, 222, 182, 34), inner_mask)


def build_component_mask(
    size: tuple[int, int],
    component: set[tuple[int, int]],
    tile_size: int,
    offset: tuple[int, int],
) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    inset = max(12, int(tile_size * 0.16))
    radius = max(7, int(tile_size * 0.075))
    ox, oy = offset
    min_x = min(cell[0] for cell in component)
    max_x = max(cell[0] for cell in component)
    min_y = min(cell[1] for cell in component)
    max_y = max(cell[1] for cell in component)
    if (max_x - min_x + 1) * (max_y - min_y + 1) == len(component):
        rect = (
            min_x * tile_size + inset + ox,
            min_y * tile_size + inset + oy,
            (max_x + 1) * tile_size - inset + ox,
            (max_y + 1) * tile_size - inset + oy,
        )
        draw.rounded_rectangle(rect, radius=radius, fill=255)
        return mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))

    for x, y in sorted(component, key=lambda cell: (cell[1], cell[0])):
        left = x * tile_size + inset + ox
        top = y * tile_size + inset + oy
        right = (x + 1) * tile_size - inset + ox
        bottom = (y + 1) * tile_size - inset + oy
        draw.rounded_rectangle((left, top, right, bottom), radius=radius, fill=255)

        if (x + 1, y) in component:
            bridge = (
                right - radius,
                top + radius // 2,
                (x + 1) * tile_size + inset + radius + ox,
                bottom - radius // 2,
            )
            draw.rectangle(bridge, fill=255)
        if (x, y + 1) in component:
            bridge = (
                left + radius // 2,
                bottom - radius,
                right - radius // 2,
                (y + 1) * tile_size + inset + radius + oy,
            )
            draw.rectangle(bridge, fill=255)
    return mask


def buildable_pad_groups(cells: set[tuple[int, int]]) -> list[set[tuple[int, int]]]:
    remaining = set(cells)
    groups: list[set[tuple[int, int]]] = []
    for x, y in sorted(cells, key=lambda cell: (cell[1], cell[0])):
        if (x, y) not in remaining:
            continue

        square = {(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)}
        horizontal = {(x, y), (x + 1, y)}
        vertical = {(x, y), (x, y + 1)}
        if square <= remaining:
            group = square
        elif horizontal <= remaining:
            group = horizontal
        elif vertical <= remaining:
            group = vertical
        else:
            group = {(x, y)}

        remaining -= group
        groups.append(group)
    return groups


def connected_components(cells: set[tuple[int, int]]) -> list[set[tuple[int, int]]]:
    remaining = set(cells)
    components: list[set[tuple[int, int]]] = []
    while remaining:
        root = remaining.pop()
        component = {root}
        queue = deque([root])
        while queue:
            x, y = queue.popleft()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor not in remaining:
                    continue
                remaining.remove(neighbor)
                component.add(neighbor)
                queue.append(neighbor)
        components.append(component)
    return sorted(components, key=lambda item: min((cell[1], cell[0]) for cell in item))


def draw_blocker(
    layer: Image.Image,
    cell: tuple[int, int],
    tile_size: int,
    texture: Image.Image,
) -> None:
    cell_layer = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(cell_layer)
    inset_x = max(14, int(tile_size * 0.18))
    inset_y = max(18, int(tile_size * 0.23))
    rect = (inset_x, inset_y, tile_size - inset_x, tile_size - inset_y)
    draw.rounded_rectangle(
        (inset_x + 3, inset_y + 5, tile_size - inset_x + 3, tile_size - inset_y + 5),
        radius=max(5, tile_size // 18),
        fill=(0, 0, 0, 62),
    )

    mask = Image.new("L", (tile_size, tile_size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(rect, radius=max(5, tile_size // 18), fill=190)
    composite_texture(cell_layer, texture, mask)
    draw.rounded_rectangle(rect, radius=max(5, tile_size // 18), outline=(66, 47, 39, 210), width=2)
    layer.alpha_composite(cell_layer, (cell[0] * tile_size, cell[1] * tile_size))


def cell_center(cell: tuple[int, int], tile_size: int) -> tuple[int, int]:
    return (cell[0] * tile_size + tile_size // 2, cell[1] * tile_size + tile_size // 2)


def tile_texture(texture: Image.Image, size: tuple[int, int]) -> Image.Image:
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    for y in range(0, size[1], texture.size[1]):
        for x in range(0, size[0], texture.size[0]):
            result.alpha_composite(texture, (x, y))
    return result


def composite_texture(layer: Image.Image, texture: Image.Image, mask: Image.Image) -> None:
    source = texture.copy()
    if source.size != layer.size:
        source = source.resize(layer.size, Image.Resampling.LANCZOS)
    alpha = source.getchannel("A")
    source.putalpha(ImageChops.multiply(alpha, mask))
    layer.alpha_composite(source)


def composite_solid(layer: Image.Image, color: tuple[int, int, int, int], mask: Image.Image) -> None:
    source = Image.new("RGBA", layer.size, color)
    alpha = source.getchannel("A")
    source.putalpha(ImageChops.multiply(alpha, mask))
    layer.alpha_composite(source)


def scaled_mask(mask: Image.Image, alpha: int) -> Image.Image:
    alpha = max(0, min(255, int(alpha)))
    return mask.point(lambda value: min(value, alpha))


def sorted_cells(cells: Iterable[tuple[int, int]]) -> list[list[int]]:
    return [[x, y] for x, y in sorted(cells, key=lambda cell: (cell[1], cell[0]))]


if __name__ == "__main__":
    raise SystemExit(main())
