#!/usr/bin/env python3
"""Generate deterministic map layout references from level JSON.

The output is a model-facing guide, not final art. Gameplay level data remains
the source of truth for path, buildable, blocked, and locked cells.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEVEL_DIR = "res://data/levels"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "tools/out/map_layout_guides"
DEFAULT_CELL_SIZE = 128

COLOR_BACKGROUND = (18, 22, 28, 255)
COLOR_EXTERIOR = (37, 62, 82, 255)
COLOR_EMPTY_CENTER = (122, 116, 96, 255)
COLOR_BUILDABLE = (104, 166, 91, 255)
COLOR_PATH = (239, 211, 150, 255)
COLOR_INTERIOR_BLOCKED = (132, 100, 66, 255)
COLOR_LOCKED = (112, 74, 146, 255)
COLOR_GRID = (255, 255, 255, 110)
COLOR_BOARD_BORDER = (22, 215, 255, 255)
COLOR_PATH_LINE = (255, 63, 88, 255)
COLOR_TEXT = (245, 248, 252, 255)
COLOR_TEXT_SHADOW = (0, 0, 0, 190)


def main() -> int:
    args = parse_args()
    level_paths = collect_level_paths(args)
    if not level_paths:
        raise SystemExit("No level JSON files matched.")

    output_root = Path(args.out_dir).expanduser().resolve() if args.out_dir else DEFAULT_OUTPUT_DIR
    output_root.mkdir(parents=True, exist_ok=True)

    summaries = []
    for level_path in level_paths:
        summary = generate_for_level(level_path, output_root, args.cell_size)
        summaries.append(summary)
        print(summary["output_dir"])
        print(summary["outputs"]["model_reference"])

    index = {
        "levels": summaries,
        "output_root": str(output_root),
        "cell_size": args.cell_size,
    }
    (output_root / "index.json").write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate model-facing layout guide images from level path/buildable/blocked cells."
    )
    parser.add_argument(
        "--level",
        action="append",
        default=[],
        help="Level JSON path, supports res://. Repeat for multiple levels. Defaults to every data/levels/*.json.",
    )
    parser.add_argument("--level-dir", default=DEFAULT_LEVEL_DIR, help="Directory used when --level is omitted.")
    parser.add_argument("--out-dir", default="", help="Output root directory. Defaults to game/tools/out/map_layout_guides.")
    parser.add_argument("--cell-size", type=int, default=DEFAULT_CELL_SIZE, help="Guide cell size in pixels.")
    return parser.parse_args()


def collect_level_paths(args: argparse.Namespace) -> list[Path]:
    if args.cell_size <= 0:
        raise SystemExit("--cell-size must be positive.")

    if args.level:
        paths = [resolve_resource_path(value) for value in args.level]
    else:
        level_dir = resolve_resource_path(args.level_dir)
        paths = sorted(level_dir.glob("*.json"))

    for path in paths:
        if not path.is_file():
            raise SystemExit(f"Missing level file: {path}")
    return paths


def generate_for_level(level_path: Path, output_root: Path, cell_size: int) -> dict:
    level = read_json(level_path)
    level_id = str(level.get("id") or level_path.stem)
    grid = level.get("grid", {})
    width = int(grid.get("width", 0))
    height = int(grid.get("height", 0))
    if width <= 0 or height <= 0:
        raise SystemExit(f"{level_path}: invalid grid dimensions.")

    all_cells = {(x, y) for y in range(height) for x in range(width)}
    path_cells = cells_to_tuples(level.get("path_cells", []), "path_cells")
    blocked_cells = cells_to_tuples(level.get("blocked_cells", []), "blocked_cells")
    locked_cells = cells_to_tuples(level.get("locked_cells", []), "locked_cells")
    path_set = set(path_cells)
    blocked_set = set(blocked_cells)
    locked_set = set(locked_cells)
    non_buildable_set = blocked_set | locked_set

    validate_cells(level_path, width, height, path_cells, blocked_cells, locked_cells)
    exterior_set = flood_exterior_cells(width, height, non_buildable_set, path_set)
    interior_blocked_set = blocked_set - exterior_set
    buildable_set = all_cells - path_set - non_buildable_set
    locked_interior_set = locked_set - exterior_set

    output_dir = output_root / level_id
    output_dir.mkdir(parents=True, exist_ok=True)

    size = (width * cell_size, height * cell_size)
    model_reference = compose_model_reference(
        size,
        width,
        height,
        cell_size,
        buildable_set,
        path_set,
        exterior_set,
        interior_blocked_set,
        locked_interior_set,
        path_cells,
    )
    annotated_reference = compose_annotated_reference(model_reference, level, width, height, cell_size, path_cells)
    background_empty_center_rect = fixed_empty_center_rect(width, height)
    background_reference = compose_background_reference(size, width, height, cell_size, background_empty_center_rect)
    grid_layer_reference = compose_grid_layer_reference(
        size,
        width,
        height,
        cell_size,
        buildable_set,
        path_set,
        exterior_set,
        interior_blocked_set,
        locked_interior_set,
        path_cells,
    )
    semantic_mask = compose_semantic_mask(
        size,
        width,
        height,
        cell_size,
        buildable_set,
        path_set,
        exterior_set,
        interior_blocked_set,
        locked_interior_set,
    )

    model_reference_path = output_dir / "layout_reference.png"
    annotated_reference_path = output_dir / "layout_reference_annotated.png"
    background_reference_path = output_dir / "background_reference.png"
    grid_layer_reference_path = output_dir / "grid_layer_reference.png"
    semantic_mask_path = output_dir / "layout_semantic_mask.png"
    contract_path = output_dir / "layout_contract.json"
    prompt_path = output_dir / "layout_prompt_fragment.txt"
    background_prompt_path = output_dir / "background_prompt_fragment.txt"
    grid_layer_prompt_path = output_dir / "grid_layer_prompt_fragment.txt"

    model_reference.save(model_reference_path)
    annotated_reference.save(annotated_reference_path)
    background_reference.save(background_reference_path)
    grid_layer_reference.save(grid_layer_reference_path)
    semantic_mask.save(semantic_mask_path)
    prompt_path.write_text(build_prompt_fragment(level, width, height), encoding="utf-8")
    background_prompt_path.write_text(build_background_prompt_fragment(level, width, height), encoding="utf-8")
    grid_layer_prompt_path.write_text(build_grid_layer_prompt_fragment(level, width, height), encoding="utf-8")

    summary = {
        "level": to_resource_path(level_path),
        "level_id": level_id,
        "display_name": level.get("display_name", level_id),
        "style_id": level.get("style_id", ""),
        "grid": {"width": width, "height": height},
        "cell_size": cell_size,
        "counts": {
            "buildable": len(buildable_set),
            "path": len(path_set),
            "exterior": len(exterior_set),
            "interior_blocked": len(interior_blocked_set),
            "locked": len(locked_interior_set),
        },
        "background_empty_center": background_empty_center_rect,
        "cells": {
            "buildable": sorted_cells(buildable_set),
            "path": sorted_cells(path_set),
            "exterior": sorted_cells(exterior_set),
            "interior_blocked": sorted_cells(interior_blocked_set),
            "locked": sorted_cells(locked_interior_set),
        },
        "edge_warnings": edge_warnings(width, height, buildable_set, path_set),
        "output_dir": str(output_dir),
        "outputs": {
            "model_reference": str(model_reference_path),
            "annotated_reference": str(annotated_reference_path),
            "background_reference": str(background_reference_path),
            "grid_layer_reference": str(grid_layer_reference_path),
            "semantic_mask": str(semantic_mask_path),
            "prompt_fragment": str(prompt_path),
            "background_prompt_fragment": str(background_prompt_path),
            "grid_layer_prompt_fragment": str(grid_layer_prompt_path),
            "contract": str(contract_path),
        },
    }
    contract_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return summary


def read_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


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


def compose_model_reference(
    size: tuple[int, int],
    width: int,
    height: int,
    cell_size: int,
    buildable_set: set[tuple[int, int]],
    path_set: set[tuple[int, int]],
    exterior_set: set[tuple[int, int]],
    interior_blocked_set: set[tuple[int, int]],
    locked_set: set[tuple[int, int]],
    path_cells: list[tuple[int, int]],
) -> Image.Image:
    image = Image.new("RGBA", size, COLOR_BACKGROUND)
    draw = ImageDraw.Draw(image, "RGBA")

    for y in range(height):
        for x in range(width):
            cell = (x, y)
            rect = cell_rect(x, y, cell_size)
            if cell in path_set:
                fill = COLOR_PATH
            elif cell in buildable_set:
                fill = COLOR_BUILDABLE
            elif cell in locked_set:
                fill = COLOR_LOCKED
            elif cell in interior_blocked_set:
                fill = COLOR_INTERIOR_BLOCKED
            else:
                fill = COLOR_EXTERIOR
            draw.rectangle(rect, fill=fill)

    draw_path_ribbon(draw, path_cells, cell_size, annotated=False)
    draw_buildable_pad_marks(draw, buildable_set, cell_size)
    draw_grid(draw, width, height, cell_size)
    draw.rectangle((0, 0, size[0] - 1, size[1] - 1), outline=COLOR_BOARD_BORDER, width=max(4, cell_size // 24))
    return image


def compose_background_reference(
    size: tuple[int, int],
    width: int,
    height: int,
    cell_size: int,
    empty_center_rect: dict[str, int],
) -> Image.Image:
    image = Image.new("RGBA", size, COLOR_BACKGROUND)
    draw = ImageDraw.Draw(image, "RGBA")
    center_cells = rect_cells(empty_center_rect)

    for y in range(height):
        for x in range(width):
            cell = (x, y)
            fill = COLOR_EMPTY_CENTER if cell in center_cells else COLOR_EXTERIOR
            draw.rectangle(cell_rect(x, y, cell_size), fill=fill)

    draw_grid(draw, width, height, cell_size)
    draw.rectangle((0, 0, size[0] - 1, size[1] - 1), outline=COLOR_BOARD_BORDER, width=max(4, cell_size // 24))
    return image


def fixed_empty_center_rect(width: int, height: int) -> dict[str, int]:
    if width <= 2 or height <= 2:
        return {"x": 0, "y": 0, "width": width, "height": height}
    return {"x": 1, "y": 1, "width": width - 2, "height": height - 2}


def rect_cells(rect: dict[str, int]) -> set[tuple[int, int]]:
    x0 = int(rect["x"])
    y0 = int(rect["y"])
    rect_width = int(rect["width"])
    rect_height = int(rect["height"])
    return {(x, y) for y in range(y0, y0 + rect_height) for x in range(x0, x0 + rect_width)}


def compose_grid_layer_reference(
    size: tuple[int, int],
    width: int,
    height: int,
    cell_size: int,
    buildable_set: set[tuple[int, int]],
    path_set: set[tuple[int, int]],
    exterior_set: set[tuple[int, int]],
    interior_blocked_set: set[tuple[int, int]],
    locked_set: set[tuple[int, int]],
    path_cells: list[tuple[int, int]],
) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    grid_cells: set[tuple[int, int]] = set()

    for y in range(height):
        for x in range(width):
            cell = (x, y)
            if cell in exterior_set:
                continue
            if cell in path_set:
                fill = COLOR_PATH
            elif cell in buildable_set:
                fill = COLOR_BUILDABLE
            elif cell in locked_set:
                fill = COLOR_LOCKED
            elif cell in interior_blocked_set:
                fill = COLOR_INTERIOR_BLOCKED
            else:
                fill = COLOR_EMPTY_CENTER

            grid_cells.add(cell)
            draw.rectangle(cell_rect(x, y, cell_size), fill=fill)

    draw_path_ribbon(draw, path_cells, cell_size, annotated=False)
    draw_buildable_pad_marks(draw, buildable_set, cell_size)
    draw_cell_outlines(draw, grid_cells, cell_size)
    return image


def compose_annotated_reference(
    model_reference: Image.Image,
    level: dict,
    width: int,
    height: int,
    cell_size: int,
    path_cells: list[tuple[int, int]],
) -> Image.Image:
    image = model_reference.copy()
    draw = ImageDraw.Draw(image, "RGBA")
    draw_path_ribbon(draw, path_cells, cell_size, annotated=True)
    draw_cell_coordinates(draw, width, height, cell_size)
    draw_legend(draw, image.size, level)
    return image


def compose_semantic_mask(
    size: tuple[int, int],
    width: int,
    height: int,
    cell_size: int,
    buildable_set: set[tuple[int, int]],
    path_set: set[tuple[int, int]],
    exterior_set: set[tuple[int, int]],
    interior_blocked_set: set[tuple[int, int]],
    locked_set: set[tuple[int, int]],
) -> Image.Image:
    image = Image.new("RGB", size, (0, 0, 0))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        for x in range(width):
            cell = (x, y)
            if cell in path_set:
                fill = COLOR_PATH[:3]
            elif cell in buildable_set:
                fill = COLOR_BUILDABLE[:3]
            elif cell in locked_set:
                fill = COLOR_LOCKED[:3]
            elif cell in interior_blocked_set:
                fill = COLOR_INTERIOR_BLOCKED[:3]
            elif cell in exterior_set:
                fill = COLOR_EXTERIOR[:3]
            else:
                fill = COLOR_BACKGROUND[:3]
            draw.rectangle(cell_rect(x, y, cell_size), fill=fill)
    return image


def cell_rect(x: int, y: int, cell_size: int) -> tuple[int, int, int, int]:
    return (
        x * cell_size,
        y * cell_size,
        (x + 1) * cell_size - 1,
        (y + 1) * cell_size - 1,
    )


def draw_path_ribbon(
    draw: ImageDraw.ImageDraw,
    path_cells: list[tuple[int, int]],
    cell_size: int,
    annotated: bool,
) -> None:
    if len(path_cells) < 2:
        return
    points = [((x + 0.5) * cell_size, (y + 0.5) * cell_size) for x, y in path_cells]
    road_width = max(18, int(cell_size * 0.72))
    curb_width = max(20, int(cell_size * 0.86))
    draw.line(points, fill=(90, 76, 54, 180), width=curb_width, joint="curve")
    draw.line(points, fill=(255, 232, 174, 255), width=road_width, joint="curve")
    radius = road_width * 0.5
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 232, 174, 255))

    if annotated:
        center_width = max(4, int(cell_size * 0.045))
        draw.line(points, fill=COLOR_PATH_LINE, width=center_width, joint="curve")
        dot_radius = max(5, int(cell_size * 0.055))
        for index, (x, y) in enumerate(points):
            fill = (255, 214, 42, 255) if index in (0, len(points) - 1) else COLOR_PATH_LINE
            draw.ellipse((x - dot_radius, y - dot_radius, x + dot_radius, y + dot_radius), fill=fill)


def draw_buildable_pad_marks(
    draw: ImageDraw.ImageDraw,
    buildable_set: set[tuple[int, int]],
    cell_size: int,
) -> None:
    pad_margin = max(10, int(cell_size * 0.18))
    for x, y in buildable_set:
        rect = (
            x * cell_size + pad_margin,
            y * cell_size + pad_margin,
            (x + 1) * cell_size - pad_margin,
            (y + 1) * cell_size - pad_margin,
        )
        draw.rounded_rectangle(
            rect,
            radius=max(8, int(cell_size * 0.08)),
            fill=(158, 207, 126, 120),
            outline=(232, 255, 214, 190),
            width=max(2, int(cell_size * 0.018)),
        )


def draw_grid(draw: ImageDraw.ImageDraw, width: int, height: int, cell_size: int) -> None:
    line_width = max(1, cell_size // 48)
    for x in range(width + 1):
        pixel_x = x * cell_size
        draw.line((pixel_x, 0, pixel_x, height * cell_size), fill=COLOR_GRID, width=line_width)
    for y in range(height + 1):
        pixel_y = y * cell_size
        draw.line((0, pixel_y, width * cell_size, pixel_y), fill=COLOR_GRID, width=line_width)


def draw_cell_outlines(draw: ImageDraw.ImageDraw, cells: Iterable[tuple[int, int]], cell_size: int) -> None:
    line_width = max(1, cell_size // 48)
    for x, y in cells:
        draw.rectangle(cell_rect(x, y, cell_size), outline=COLOR_GRID, width=line_width)


def draw_cell_coordinates(draw: ImageDraw.ImageDraw, width: int, height: int, cell_size: int) -> None:
    font = load_font(max(12, int(cell_size * 0.12)))
    for y in range(height):
        for x in range(width):
            text = f"{x},{y}"
            position = (x * cell_size + 8, y * cell_size + 7)
            draw.text((position[0] + 1, position[1] + 1), text, fill=COLOR_TEXT_SHADOW, font=font)
            draw.text(position, text, fill=COLOR_TEXT, font=font)


def draw_legend(draw: ImageDraw.ImageDraw, size: tuple[int, int], level: dict) -> None:
    font = load_font(max(15, int(size[1] * 0.016)))
    title_font = load_font(max(18, int(size[1] * 0.021)))
    x = 20
    y = 20
    width = int(size[0] * 0.50)
    height = max(122, int(size[1] * 0.13))
    draw.rounded_rectangle((x, y, x + width, y + height), radius=12, fill=(0, 0, 0, 145))
    title = f"{level.get('id', '')} / {level.get('display_name', '')}"
    draw.text((x + 14, y + 10), title, fill=COLOR_TEXT, font=title_font)
    legend_rows = [
        ("blue-gray", "exterior scenery / no build", COLOR_EXTERIOR),
        ("green", "buildable tower pad cells", COLOR_BUILDABLE),
        ("cream", "enemy road path cells", COLOR_PATH),
        ("brown", "interior blocker / no build", COLOR_INTERIOR_BLOCKED),
    ]
    row_y = y + 44
    for _name, label, color in legend_rows:
        draw.rectangle((x + 16, row_y + 4, x + 38, row_y + 26), fill=color)
        draw.text((x + 48, row_y + 2), label, fill=COLOR_TEXT, font=font)
        row_y += 25


def load_font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def build_prompt_fragment(level: dict, width: int, height: int) -> str:
    return (
        "Use the attached layout_reference.png as a strict layout guide, not as final art.\n"
        f"Preserve the exact {width}x{height} board geometry, camera framing, and cell coverage.\n"
        "Blue-gray cells are exterior scenery and must stay non-buildable: paint them as outer walls, canals, rooftops, cliffs, trees, or other scenic border dressing. Do not place tower pads there.\n"
        "Green cells are buildable gameplay cells: keep them visibly flat, open, and readable as tower placement ground or paved plaza pads.\n"
        "Cream cells are the enemy road: preserve the route, road width, entrances, exits, and turns. Do not add extra branches or alternate roads.\n"
        "Brown or purple cells are non-buildable interior blockers: paint them as props, gardens, water, barricades, ruins, or raised structures.\n"
        "Remove the guide colors, grid lines, coordinates, labels, and markers in the final art. No UI, no text, no logos, no characters.\n"
        f"Level id: {level.get('id', '')}. Display name: {level.get('display_name', '')}. Style id: {level.get('style_id', '')}.\n"
    )


def build_background_prompt_fragment(level: dict, width: int, height: int) -> str:
    center_rect = fixed_empty_center_rect(width, height)
    return (
        "Use the attached background_reference.png as a strict geometry guide for the background layer only.\n"
        f"Preserve the exact {width}x{height} board framing and the fixed empty middle area.\n"
        f"The empty middle rectangle is x={center_rect['x']}, y={center_rect['y']}, width={center_rect['width']}, height={center_rect['height']} cells.\n"
        "Blue-gray cells are the outer scenery ring: paint them as non-buildable environment such as walls, water, rooftops, cliffs, trees, or dense border dressing.\n"
        "Muted center cells are deliberately empty gameplay ground under the future grid layer. Keep this center flat, low-detail, and free of tower pads, roads, obstacles, props, text, labels, grid lines, UI, characters, or decorative clutter.\n"
        "Do not draw individual gameplay cells, path art, or buildable markers on this background layer.\n"
        f"Level id: {level.get('id', '')}. Display name: {level.get('display_name', '')}. Style id: {level.get('style_id', '')}.\n"
    )


def build_grid_layer_prompt_fragment(level: dict, width: int, height: int) -> str:
    return (
        "Use the attached grid_layer_reference.png as a strict geometry guide for the transparent grid overlay layer.\n"
        f"Preserve the exact {width}x{height} board framing, transparent exterior ring, and per-cell coverage.\n"
        "Green cells become readable buildable tower pads or paved placement tiles. Cream cells become the enemy road and must preserve route order, entrances, exits, width, and turns. Brown or purple cells become non-buildable interior blockers.\n"
        "The exterior scenery ring must stay transparent on this layer. Do not paint background scenery, UI, text, labels, characters, or extra path branches.\n"
        "Final art should remove guide colors, grid lines, and markers while keeping the same cell semantics.\n"
        f"Level id: {level.get('id', '')}. Display name: {level.get('display_name', '')}. Style id: {level.get('style_id', '')}.\n"
    )


def edge_warnings(
    width: int,
    height: int,
    buildable_set: set[tuple[int, int]],
    path_set: set[tuple[int, int]],
) -> list[str]:
    warnings: list[str] = []
    buildable_edges = sorted_cells(
        {
            cell
            for cell in buildable_set
            if cell[0] in (0, width - 1) or cell[1] in (0, height - 1)
        }
    )
    if buildable_edges:
        warnings.append(f"Buildable edge cells make the exterior ring incomplete: {buildable_edges}")

    path_edges = sorted_cells(
        {
            cell
            for cell in path_set
            if cell[0] in (0, width - 1) or cell[1] in (0, height - 1)
        }
    )
    if len(path_edges) > 2:
        warnings.append(f"More than spawn/exit path cells touch the edge: {path_edges}")
    return warnings


def sorted_cells(cells: Iterable[tuple[int, int]]) -> list[list[int]]:
    return [[x, y] for x, y in sorted(cells, key=lambda cell: (cell[1], cell[0]))]


if __name__ == "__main__":
    raise SystemExit(main())
