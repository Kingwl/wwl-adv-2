#!/usr/bin/env python3
"""Generate focused map visual review crops and block downsample probes."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from statistics import median
from typing import Iterable

try:
    from PIL import Image, ImageDraw
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


GAME_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = GAME_DIR.parent
STYLE_DIR = GAME_DIR / "data/map_styles"
LEVEL_DIR = GAME_DIR / "data/levels"
DEFAULT_OUTPUT_DIR = GAME_DIR / "tools/out/map_visual_review"


def main() -> int:
    args = parse_args()
    if args.block_size <= 0:
        raise SystemExit("--block-size must be positive.")

    level = read_json(resolve_resource_path(args.level))
    level_id = str(level.get("id") or Path(args.level).stem)
    style = read_json(STYLE_DIR / f"{level['style_id']}.json")
    output_dir = (Path(args.out_dir).expanduser().resolve() if args.out_dir else DEFAULT_OUTPUT_DIR / level_id)
    output_dir.mkdir(parents=True, exist_ok=True)

    sources = collect_sources(level_id, style, args)
    loaded = {name: visible_image(name, open_rgba(path)) for name, path in sources.items() if path.is_file()}
    if "background" not in loaded or "preview" not in loaded:
        raise SystemExit("Visual review needs at least background and preview images.")

    base_size = loaded["background"].size
    regions = regions_for_level(level_id, base_size)
    review = generate_review(output_dir, loaded, sources, regions, base_size, args.block_size)

    print(output_dir)
    print(review["downsample_contact_sheet"])
    print(review["sampling_contact_sheet"])
    print(review["preview_crop_atlas"])
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate map visual review crops and downsample comparisons.")
    parser.add_argument("--level", default="res://data/levels/level_005.json", help="Level JSON path, supports res://.")
    parser.add_argument("--out-dir", default="", help="Output directory. Defaults to game/tools/out/map_visual_review/<level_id>.")
    parser.add_argument("--background", default="", help="Override background image path.")
    parser.add_argument("--grid-layer", default="", help="Override grid layer image path.")
    parser.add_argument("--preview", default="", help="Override composed preview image path.")
    parser.add_argument("--buildable-game", default="", help="Override in-game buildable grid screenshot path.")
    parser.add_argument("--path-game", default="", help="Override in-game path enemies screenshot path.")
    parser.add_argument(
        "--block-size",
        type=int,
        default=4,
        help="Downsample block size in pixels. Use 4 for 4x4 blocks, 2 for 2x2 blocks.",
    )
    return parser.parse_args()


def collect_sources(level_id: str, style: dict, args: argparse.Namespace) -> dict[str, Path]:
    return {
        "background": source_path(args.background, style.get("background", "")),
        "grid_layer": source_path(args.grid_layer, style.get("grid_layer", "")),
        "preview": source_path(args.preview, GAME_DIR / f"tools/out/composed_map_layers/{level_id}/preview.png"),
        "buildable_game": source_path(
            args.buildable_game,
            REPO_ROOT / f"ci-artifacts/level-grid-audit/native/{level_id}/{level_id}-buildable-grid-board.png",
        ),
        "path_game": source_path(
            args.path_game,
            REPO_ROOT / f"ci-artifacts/level-grid-audit/native/{level_id}/{level_id}-path-enemies-board.png",
        ),
    }


def source_path(override: str, default: str | Path) -> Path:
    value = override or default
    if value == "":
        return Path("__missing__")
    return resolve_resource_path(value)


def generate_review(
    output_dir: Path,
    loaded: dict[str, Image.Image],
    sources: dict[str, Path],
    regions: list[dict],
    base_size: tuple[int, int],
    block_size: int,
) -> dict:
    downsample_contact = output_dir / "00-downsample-contact-sheet.png"
    region_index = output_dir / "00-region-index-overlay.png"
    preview_crop_atlas = output_dir / "01-preview-crop-atlas.png"
    sampling_contact = output_dir / f"02-sampling-{block_size}x{block_size}-contact-sheet.png"
    block_manifest_path = output_dir / f"review_manifest-{block_size}x{block_size}.json"
    latest_manifest_path = output_dir / "review_manifest.json"

    save_downsample_contact(loaded, downsample_contact)
    add_bbox_overlay(loaded["preview"], regions).save(region_index)
    save_preview_crop_atlas(loaded["preview"], regions, base_size, preview_crop_atlas)
    sampling_outputs = save_sampling_comparison(loaded, output_dir, sampling_contact, block_size)
    region_outputs = save_region_contacts(loaded, regions, base_size, output_dir)

    manifest = {
        "purpose": "Focused map visual review crops and block downsample probes.",
        "sources": {key: str(path) for key, path in sources.items()},
        "base_size": list(base_size),
        "block_size": block_size,
        "downsample_contact_sheet": str(downsample_contact),
        "region_index_overlay": str(region_index),
        "preview_crop_atlas": str(preview_crop_atlas),
        "sampling_contact_sheet": str(sampling_contact),
        "sampling_outputs": sampling_outputs,
        "regions": region_outputs,
        "review_rules": [
            "Use 160/320 px thumbnails for visual hierarchy: road and pads should be legible without dominating.",
            f"Use {block_size}x{block_size} mean and BOX sampling to judge dominant shapes after local detail is removed.",
            f"Use median{block_size}x{block_size} to suppress texture noise and expose silhouette/palette conflicts.",
            f"Use nearest{block_size}x{block_size} only as a control; it can overemphasize unlucky individual pixels.",
            "Use region contacts to compare ownership: background, grid layer, composed preview, tower screenshot, and enemy screenshot.",
        ],
    }
    manifest["manifest"] = str(block_manifest_path)
    manifest_json = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
    block_manifest_path.write_text(manifest_json, encoding="utf-8")
    latest_manifest_path.write_text(manifest_json, encoding="utf-8")
    return manifest


def save_downsample_contact(loaded: dict[str, Image.Image], path: Path) -> None:
    columns = []
    for name in ordered_source_names(loaded):
        image = loaded[name]
        column = stack_vertical(
            [
                label_strip(name, 320),
                fit_width(image, 320),
                fit_width(image, 160),
            ],
            gap=4,
        )
        columns.append(column)
    stack_horizontal(columns, gap=10).save(path)


def save_sampling_comparison(
    loaded: dict[str, Image.Image],
    output_dir: Path,
    contact_path: Path,
    block_size: int,
) -> dict[str, dict[str, str]]:
    outputs: dict[str, dict[str, str]] = {}
    sample_dir = output_dir / f"sampling/{block_size}x{block_size}"
    sample_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    for name in ordered_source_names(loaded):
        image = crop_to_block_multiple(loaded[name], block_size)
        algorithms = {
            f"nearest{block_size}x{block_size}": downsample_nearest(image, block_size),
            f"box{block_size}x{block_size}": downsample_box(image, block_size),
            f"mean{block_size}x{block_size}": downsample_block_mean(image, block_size),
            f"median{block_size}x{block_size}": downsample_block_median(image, block_size),
        }
        outputs[name] = {}
        cards = [label_strip(name, 160, height=50)]
        for algorithm, result in algorithms.items():
            result_path = sample_dir / f"{name}-{algorithm}.png"
            result.save(result_path)
            outputs[name][algorithm] = str(result_path)
            cards.append(stack_vertical([label_strip(algorithm, 220), fit_width(result, 220)], gap=0))
        rows.append(stack_horizontal(cards, gap=8))
    stack_vertical(rows, gap=10).save(contact_path)
    return outputs


def save_preview_crop_atlas(
    preview: Image.Image,
    regions: list[dict],
    base_size: tuple[int, int],
    path: Path,
) -> None:
    atlas_cards = []
    for region in regions:
        crop = fit_width(preview.crop(scaled_bbox(region["bbox"], preview, base_size)), 300)
        atlas_cards.append(stack_vertical([label_strip(region["id"], 300), crop], gap=0))

    rows = []
    for index in range(0, len(atlas_cards), 2):
        rows.append(stack_horizontal(atlas_cards[index : index + 2], gap=10))
    stack_vertical(rows, gap=10).save(path)


def save_region_contacts(
    loaded: dict[str, Image.Image],
    regions: list[dict],
    base_size: tuple[int, int],
    output_dir: Path,
) -> list[dict]:
    outputs = []
    for region in regions:
        cards = []
        crop_paths = {}
        for name in ordered_source_names(loaded):
            image = loaded[name]
            crop = fit_width(image.crop(scaled_bbox(region["bbox"], image, base_size)), 360)
            crop_path = output_dir / f"{region['id']}-{name}.png"
            crop.save(crop_path)
            crop_paths[name] = str(crop_path)
            cards.append(stack_vertical([label_strip(name, crop.size[0]), crop], gap=0))

        title = label_strip(f"{region['label']} | {region['reason']}", 360 * 3 + 16, 44)
        first_row = stack_horizontal(cards[:3], gap=8)
        second_row = stack_horizontal(cards[3:], gap=8) if len(cards) > 3 else Image.new("RGBA", (1, 1), (12, 16, 20, 255))
        sheet = stack_vertical([title, first_row, second_row], gap=8)
        sheet_path = output_dir / f"{region['id']}-contact.png"
        sheet.save(sheet_path)
        outputs.append({**region, "contact": str(sheet_path), "crops": crop_paths})
    return outputs


def downsample_nearest(image: Image.Image, block_size: int) -> Image.Image:
    width, height = image.size
    return image.resize((width // block_size, height // block_size), Image.Resampling.NEAREST)


def downsample_box(image: Image.Image, block_size: int) -> Image.Image:
    width, height = image.size
    return image.resize((width // block_size, height // block_size), Image.Resampling.BOX)


def downsample_block_mean(image: Image.Image, block_size: int) -> Image.Image:
    source = image.convert("RGBA")
    width, height = source.size
    out = Image.new("RGBA", (width // block_size, height // block_size), (0, 0, 0, 0))
    src = source.load()
    dst = out.load()
    area = block_size * block_size
    for oy in range(out.size[1]):
        for ox in range(out.size[0]):
            total_a = 0
            total_r = 0
            total_g = 0
            total_b = 0
            for dy in range(block_size):
                for dx in range(block_size):
                    r, g, b, a = src[ox * block_size + dx, oy * block_size + dy]
                    total_a += a
                    total_r += r * a
                    total_g += g * a
                    total_b += b * a
            if total_a == 0:
                dst[ox, oy] = (0, 0, 0, 0)
            else:
                dst[ox, oy] = (
                    round(total_r / total_a),
                    round(total_g / total_a),
                    round(total_b / total_a),
                    round(total_a / area),
                )
    return out


def downsample_block_median(image: Image.Image, block_size: int) -> Image.Image:
    source = image.convert("RGBA")
    width, height = source.size
    out = Image.new("RGBA", (width // block_size, height // block_size), (0, 0, 0, 0))
    src = source.load()
    dst = out.load()
    for oy in range(out.size[1]):
        for ox in range(out.size[0]):
            channels = [[], [], [], []]
            for dy in range(block_size):
                for dx in range(block_size):
                    pixel = src[ox * block_size + dx, oy * block_size + dy]
                    for channel_index in range(4):
                        channels[channel_index].append(pixel[channel_index])
            dst[ox, oy] = tuple(int(round(median(values))) for values in channels)
    return out


def crop_to_block_multiple(image: Image.Image, block_size: int) -> Image.Image:
    width, height = image.size
    cropped_width = width - (width % block_size)
    cropped_height = height - (height % block_size)
    if cropped_width <= 0 or cropped_height <= 0:
        raise SystemExit(f"Image is smaller than block size {block_size}: {image.size}")
    return image.crop((0, 0, cropped_width, cropped_height))


def regions_for_level(level_id: str, base_size: tuple[int, int]) -> list[dict]:
    if level_id == "level_005":
        return [
            {
                "id": "left_entry",
                "label": "Left entry / spawn bridge",
                "bbox": [0, 620, 430, 1024],
                "reason": "Path starts from exterior opening; should not sit on wall/water.",
            },
            {
                "id": "right_exit",
                "label": "Right exit / final bridge",
                "bbox": [840, 300, 1280, 620],
                "reason": "Path exits through right wall opening without clipping bridge/wall.",
            },
            {
                "id": "upper_left_pad_cluster",
                "label": "Upper-left 2x2 pad cluster",
                "bbox": [170, 70, 570, 430],
                "reason": "Grouped pads should feel like a platform; towers should dominate the pad.",
            },
            {
                "id": "upper_right_pad_cluster",
                "label": "Upper-right 2x2 pad cluster",
                "bbox": [600, 180, 960, 610],
                "reason": "Pad shape, tower spacing, and separation from road corridor.",
            },
            {
                "id": "center_crossing",
                "label": "Center bend and mid pads",
                "bbox": [280, 330, 950, 690],
                "reason": "Busiest area: road turn, nearby pad groups, visual hierarchy.",
            },
            {
                "id": "bottom_center_pad",
                "label": "Bottom-center vertical pad",
                "bbox": [420, 620, 740, 1024],
                "reason": "Bottom frame clearance and lower-gate conflict check.",
            },
            {
                "id": "top_road_hairpin",
                "label": "Top road hairpin",
                "bbox": [470, 80, 1070, 440],
                "reason": "Road width and corner shape should read as native map path.",
            },
            {
                "id": "right_empty_plaza",
                "label": "Right empty plaza",
                "bbox": [900, 500, 1280, 980],
                "reason": "Unused stone floor should not imply buildable slots.",
            },
        ]

    width, height = base_size
    return [
        {"id": "top_left", "label": "Top-left quadrant", "bbox": [0, 0, width // 2, height // 2], "reason": "Generic map review quadrant."},
        {"id": "top_right", "label": "Top-right quadrant", "bbox": [width // 2, 0, width, height // 2], "reason": "Generic map review quadrant."},
        {"id": "bottom_left", "label": "Bottom-left quadrant", "bbox": [0, height // 2, width // 2, height], "reason": "Generic map review quadrant."},
        {"id": "bottom_right", "label": "Bottom-right quadrant", "bbox": [width // 2, height // 2, width, height], "reason": "Generic map review quadrant."},
    ]


def ordered_source_names(loaded: dict[str, Image.Image]) -> list[str]:
    preferred = ["background", "grid_layer", "preview", "buildable_game", "path_game"]
    return [name for name in preferred if name in loaded] + sorted(set(loaded) - set(preferred))


def open_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    image = Image.new("RGBA", size, (205, 205, 205, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle([x, y, x + cell - 1, y + cell - 1], fill=(235, 235, 235, 255))
    return image


def visible_image(name: str, image: Image.Image) -> Image.Image:
    if name != "grid_layer":
        return image
    background = checker(image.size)
    background.alpha_composite(image)
    return background


def scaled_bbox(bbox: list[int], image: Image.Image, base_size: tuple[int, int]) -> tuple[int, int, int, int]:
    scale_x = image.size[0] / base_size[0]
    scale_y = image.size[1] / base_size[1]
    x1, y1, x2, y2 = bbox
    return (int(x1 * scale_x), int(y1 * scale_y), int(x2 * scale_x), int(y2 * scale_y))


def fit_width(image: Image.Image, width: int) -> Image.Image:
    if image.size[0] == width:
        return image
    height = max(1, int(image.size[1] * width / image.size[0]))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def label_strip(text: str, width: int, height: int = 34) -> Image.Image:
    image = Image.new("RGBA", (width, height), (18, 22, 28, 255))
    draw = ImageDraw.Draw(image)
    draw.text((8, 10), text[:120], fill=(245, 248, 252, 255))
    return image


def stack_vertical(items: list[Image.Image], gap: int = 8, background=(12, 16, 20, 255)) -> Image.Image:
    width = max(item.size[0] for item in items)
    height = sum(item.size[1] for item in items) + gap * (len(items) - 1)
    canvas = Image.new("RGBA", (width, height), background)
    y = 0
    for item in items:
        canvas.alpha_composite(item, ((width - item.size[0]) // 2, y))
        y += item.size[1] + gap
    return canvas


def stack_horizontal(items: list[Image.Image], gap: int = 8, background=(12, 16, 20, 255)) -> Image.Image:
    width = sum(item.size[0] for item in items) + gap * (len(items) - 1)
    height = max(item.size[1] for item in items)
    canvas = Image.new("RGBA", (width, height), background)
    x = 0
    for item in items:
        canvas.alpha_composite(item, (x, (height - item.size[1]) // 2))
        x += item.size[0] + gap
    return canvas


def add_bbox_overlay(image: Image.Image, regions: Iterable[dict]) -> Image.Image:
    result = image.copy()
    draw = ImageDraw.Draw(result)
    colors = [(255, 73, 92, 255), (66, 214, 164, 255), (255, 207, 80, 255), (99, 179, 237, 255)]
    for index, region in enumerate(regions):
        x1, y1, x2, y2 = region["bbox"]
        color = colors[index % len(colors)]
        draw.rectangle([x1, y1, x2, y2], outline=color, width=4)
        draw.rectangle([x1, y1, x1 + 170, y1 + 24], fill=(0, 0, 0, 160))
        draw.text((x1 + 6, y1 + 6), region["id"], fill=color)
    return result


def read_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def resolve_resource_path(path_value: str | Path) -> Path:
    path = str(path_value)
    if path.startswith("res://"):
        return GAME_DIR / path.removeprefix("res://")
    return Path(path).expanduser().resolve()


if __name__ == "__main__":
    raise SystemExit(main())
