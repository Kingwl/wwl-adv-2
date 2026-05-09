#!/usr/bin/env python3
"""Generate road guide, masks, and gameplay-path overlays from a level JSON."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEVEL = "res://data/levels/level_001.json"
DEFAULT_BASE_BACKGROUND = "res://assets/tilesets/stormwind_city_v2/background_frame.png"


def main() -> int:
    args = parse_args()
    level_path = resolve_resource_path(args.level)
    level = read_json(level_path)
    level_id = str(level.get("id", level_path.stem))

    style = load_level_style(level)
    cell_size = int(args.cell_size or style.get("tile_size", 128) or 128)
    grid = level.get("grid", {})
    grid_width = int(grid.get("width", 0))
    grid_height = int(grid.get("height", 0))
    if grid_width <= 0 or grid_height <= 0:
        raise SystemExit(f"Invalid grid dimensions in {level_path}")

    background_path = resolve_resource_path(args.background or style.get("background") or DEFAULT_BASE_BACKGROUND)
    overlay_path = resolve_resource_path(args.overlay_image) if args.overlay_image else background_path
    output_dir = Path(args.out_dir) if args.out_dir else PROJECT_ROOT / "tools/out/road_guides" / level_id
    output_dir.mkdir(parents=True, exist_ok=True)

    background = normalize_background(background_path, grid_width, grid_height, cell_size)
    overlay_base = normalize_background(overlay_path, grid_width, grid_height, cell_size)
    path_cells = cells_to_tuples(level.get("path_cells", []))
    if len(path_cells) < 2:
        raise SystemExit(f"Level path must contain at least two cells: {level_path}")

    points = path_center_points(path_cells, cell_size, extend_to_edges=True)
    body_mask = line_mask(background.size, points, args.body_width_cells * cell_size)
    curb_mask = line_mask(background.size, points, args.curb_width_cells * cell_size)
    shadow_mask = line_mask(background.size, points, args.shadow_width_cells * cell_size)
    curb_ring_mask = subtract_mask(curb_mask, body_mask)

    guide = compose_guide(background, body_mask, curb_mask, shadow_mask, points, cell_size, annotated=False)
    annotated = compose_guide(background, body_mask, curb_mask, shadow_mask, points, cell_size, annotated=True)
    path_overlay = compose_path_overlay(overlay_base, path_cells, points, grid_width, grid_height)

    body_mask.save(output_dir / "road_body_mask.png")
    curb_mask.save(output_dir / "road_curb_mask.png")
    curb_ring_mask.save(output_dir / "road_curb_ring_mask.png")
    shadow_mask.save(output_dir / "road_shadow_mask.png")
    guide.save(output_dir / "road_guide_preview.png")
    annotated.save(output_dir / "road_guide_annotated.png")
    path_overlay.save(output_dir / "game_path_overlay.png")

    manifest = build_manifest(
        level_path,
        background_path,
        overlay_path,
        output_dir,
        level,
        style,
        path_cells,
        points,
        body_mask,
        cell_size,
        args,
    )
    (output_dir / "road_guide_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(output_dir)
    print(output_dir / "road_guide_preview.png")
    print(output_dir / "game_path_overlay.png")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate road guide/mask/overlay images from Godot level path_cells."
    )
    parser.add_argument("--level", default=DEFAULT_LEVEL, help="Level JSON path, supports res://.")
    parser.add_argument(
        "--background",
        default=DEFAULT_BASE_BACKGROUND,
        help="Background used under the guide, supports res://. Defaults to the clean v2 frame.",
    )
    parser.add_argument(
        "--overlay-image",
        default="",
        help="Image to receive the gameplay path overlay. Defaults to --background.",
    )
    parser.add_argument("--out-dir", default="", help="Output directory.")
    parser.add_argument("--cell-size", type=int, default=0, help="Override cell size in pixels.")
    parser.add_argument("--body-width-cells", type=float, default=0.78)
    parser.add_argument("--curb-width-cells", type=float, default=0.98)
    parser.add_argument("--shadow-width-cells", type=float, default=1.08)
    return parser.parse_args()


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


def load_level_style(level: dict) -> dict:
    style_id = str(level.get("style_id", ""))
    if not style_id:
        return {}

    style_path = PROJECT_ROOT / "data/map_styles" / f"{style_id}.json"
    if not style_path.exists():
        return {}
    return read_json(style_path)


def normalize_background(path: Path, grid_width: int, grid_height: int, cell_size: int) -> Image.Image:
    expected_size = (grid_width * cell_size, grid_height * cell_size)
    image = Image.open(path).convert("RGBA")
    if image.size != expected_size:
        return image.resize(expected_size, Image.Resampling.LANCZOS)
    return image


def cells_to_tuples(cells: Iterable[object]) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for cell in cells:
        if not isinstance(cell, list | tuple) or len(cell) < 2:
            raise SystemExit(f"Invalid path cell: {cell!r}")
        result.append((int(cell[0]), int(cell[1])))
    return result


def path_center_points(
    path_cells: list[tuple[int, int]],
    cell_size: int,
    extend_to_edges: bool,
) -> list[tuple[float, float]]:
    points = [((x + 0.5) * cell_size, (y + 0.5) * cell_size) for x, y in path_cells]
    if not extend_to_edges or len(points) < 2:
        return points

    start_dir = normalize((points[0][0] - points[1][0], points[0][1] - points[1][1]))
    end_dir = normalize((points[-1][0] - points[-2][0], points[-1][1] - points[-2][1]))
    return [
        (points[0][0] + start_dir[0] * cell_size * 0.5, points[0][1] + start_dir[1] * cell_size * 0.5),
        *points,
        (points[-1][0] + end_dir[0] * cell_size * 0.5, points[-1][1] + end_dir[1] * cell_size * 0.5),
    ]


def normalize(vector: tuple[float, float]) -> tuple[float, float]:
    length = math.hypot(vector[0], vector[1])
    if length <= 0.0:
        return (0.0, 0.0)
    return (vector[0] / length, vector[1] / length)


def line_mask(size: tuple[int, int], points: list[tuple[float, float]], width: float) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.line(points, fill=255, width=max(1, int(round(width))), joint="curve")
    radius = width * 0.5
    for x, y in points[1:-1]:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    return mask


def subtract_mask(outer: Image.Image, inner: Image.Image) -> Image.Image:
    result = outer.copy()
    result_px = result.load()
    inner_px = inner.load()
    width, height = result.size
    for y in range(height):
        for x in range(width):
            if inner_px[x, y] > 0:
                result_px[x, y] = 0
    return result


def compose_guide(
    background: Image.Image,
    body_mask: Image.Image,
    curb_mask: Image.Image,
    shadow_mask: Image.Image,
    points: list[tuple[float, float]],
    cell_size: int,
    annotated: bool,
) -> Image.Image:
    guide = background.copy()
    guide = alpha_layer(guide, shadow_mask, (43, 33, 24), 0.36)
    guide = alpha_layer(guide, curb_mask, (42, 160, 255), 0.72)
    guide = alpha_layer(guide, body_mask, (255, 245, 205), 0.88)

    draw = ImageDraw.Draw(guide)
    draw.line(points, fill=(255, 55, 85, 255), width=max(4, int(cell_size * 0.04)), joint="curve")
    radius = max(5, int(cell_size * 0.05))
    for x, y in points[1:-1]:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 55, 85, 255))

    if annotated:
        draw_legend(
            draw,
            guide.size,
            "Road guide: cream = road body, blue = curb zone, red = enemy centerline.",
        )

    return guide


def alpha_layer(base: Image.Image, mask: Image.Image, color: tuple[int, int, int], alpha_scale: float) -> Image.Image:
    layer = Image.new("RGBA", base.size, (*color, 0))
    layer.putalpha(mask.point(lambda value: int(value * alpha_scale)))
    return Image.alpha_composite(base, layer)


def draw_legend(draw: ImageDraw.ImageDraw, size: tuple[int, int], text: str) -> None:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", max(15, int(size[1] * 0.016)))
    except OSError:
        font = ImageFont.load_default()

    x = 22
    y = 22
    width = int(size[0] * 0.62)
    height = max(52, int(size[1] * 0.07))
    draw.rounded_rectangle((x, y, x + width, y + height), radius=10, fill=(0, 0, 0, 125))
    draw.text((x + 14, y + 12), text, fill=(255, 255, 255, 245), font=font)


def compose_path_overlay(
    image: Image.Image,
    path_cells: list[tuple[int, int]],
    points: list[tuple[float, float]],
    grid_width: int,
    grid_height: int,
) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cell_width = image.size[0] / grid_width
    cell_height = image.size[1] / grid_height

    for x, y in path_cells:
        rect = (x * cell_width, y * cell_height, (x + 1) * cell_width, (y + 1) * cell_height)
        draw.rectangle(
            rect,
            fill=(25, 190, 255, 46),
            outline=(20, 235, 255, 230),
            width=max(2, int(min(cell_width, cell_height) * 0.018)),
        )

    line_width = max(6, int(min(cell_width, cell_height) * 0.055))
    draw.line(points, fill=(255, 255, 255, 245), width=line_width + 5, joint="curve")
    draw.line(points, fill=(255, 40, 74, 255), width=line_width, joint="curve")
    for index, (x, y) in enumerate(points[1:-1]):
        radius = max(7, int(min(cell_width, cell_height) * 0.055))
        fill = (255, 210, 35, 255) if index in (0, len(path_cells) - 1) else (255, 40, 74, 255)
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 255, 255, 245))
        draw.ellipse((x - radius + 3, y - radius + 3, x + radius - 3, y + radius - 3), fill=fill)

    draw_legend(draw, image.size, "Game path overlay: cyan = PATH cells, red = enemy centerline.")
    return Image.alpha_composite(image, overlay)


def build_manifest(
    level_path: Path,
    background_path: Path,
    overlay_path: Path,
    output_dir: Path,
    level: dict,
    style: dict,
    path_cells: list[tuple[int, int]],
    points: list[tuple[float, float]],
    body_mask: Image.Image,
    cell_size: int,
    args: argparse.Namespace,
) -> dict:
    body_px = body_mask.load()
    path_centers_inside_body = True
    for x, y in path_cells:
        center_x = int((x + 0.5) * cell_size)
        center_y = int((y + 0.5) * cell_size)
        if body_px[center_x, center_y] == 0:
            path_centers_inside_body = False
            break

    return {
        "level": to_resource_path(level_path),
        "style_id": level.get("style_id", ""),
        "style_display_name": style.get("display_name", ""),
        "background": to_resource_path(background_path),
        "overlay_image": to_resource_path(overlay_path),
        "output_dir": str(output_dir),
        "grid": level.get("grid", {}),
        "cell_size": cell_size,
        "path_cells": path_cells,
        "guide_points": [[round(x, 3), round(y, 3)] for x, y in points],
        "body_width_cells": args.body_width_cells,
        "curb_width_cells": args.curb_width_cells,
        "shadow_width_cells": args.shadow_width_cells,
        "validation": {
            "path_centers_inside_body": path_centers_inside_body,
            "output_dimensions": list(body_mask.size),
            "expected_dimensions": [
                int(level.get("grid", {}).get("width", 0)) * cell_size,
                int(level.get("grid", {}).get("height", 0)) * cell_size,
            ],
        },
    }


if __name__ == "__main__":
    raise SystemExit(main())
