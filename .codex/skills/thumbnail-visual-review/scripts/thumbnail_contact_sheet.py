#!/usr/bin/env python3
"""Generate block-downsampled image thumbnails and contact sheets."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from statistics import median
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    raise SystemExit("Pillow is required. Install with: python3 -m pip install Pillow") from exc


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff"}
METHODS = ("mean", "median", "box", "nearest")
MIN_REVIEW_DIMENSION = 100


def main() -> int:
    args = parse_args()
    block_size = positive_int(args.block_size, "--block-size")
    thumb_width = positive_int(args.thumb_width, "--thumb-width")
    gap = positive_int(args.gap, "--gap")
    label_height = positive_int(args.label_height, "--label-height")

    image_paths = collect_images(args.inputs, recursive=args.recursive)
    if not image_paths:
        raise SystemExit("No input images found.")

    out_dir = Path(args.out_dir).expanduser().resolve()
    sample_dir = out_dir / "sampling" / f"{block_size}x{block_size}"
    sample_dir.mkdir(parents=True, exist_ok=True)

    outputs: dict[str, dict[str, str]] = {}
    for index, image_path in enumerate(image_paths, start=1):
        slug = f"{index:03d}-{slugify(image_path.stem)}"
        outputs[str(image_path)] = {}
        with Image.open(image_path) as image:
            warn_if_low_resolution(image_path, image)
            source = image.convert("RGBA")
            for method in args.methods:
                sampled = downsample(source, block_size, method)
                sample_path = sample_dir / f"{slug}-{method}{block_size}x{block_size}.png"
                sampled.save(sample_path)
                outputs[str(image_path)][method] = str(sample_path)

    contact_path = out_dir / (
        args.contact_name
        or (
            f"contact-{args.methods[0]}{block_size}x{block_size}.png"
            if len(args.methods) == 1
            else f"contact-{block_size}x{block_size}-methods.png"
        )
    )
    contact = build_contact_sheet(
        image_paths=image_paths,
        outputs=outputs,
        methods=args.methods,
        columns=args.columns,
        label_mode=args.label_mode,
        thumb_width=thumb_width,
        gap=gap,
        label_height=label_height,
    )
    contact.save(contact_path)

    manifest = {
        "block_size": block_size,
        "methods": args.methods,
        "inputs": [str(path) for path in image_paths],
        "outputs": {
            "contact_sheet": str(contact_path),
            "samples": outputs,
        },
    }
    manifest_path = out_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(contact_path)
    print(manifest_path)
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate 4x4/2x2-style thumbnails and contact sheets from image files."
    )
    parser.add_argument("inputs", nargs="+", help="Image files or directories to include.")
    parser.add_argument(
        "--out-dir",
        default="thumbnail-visual-review-out",
        help="Output directory. Defaults to ./thumbnail-visual-review-out.",
    )
    parser.add_argument(
        "--block-size",
        type=int,
        default=4,
        help="Source pixels merged into one output pixel. Use 4 for overview, 2 for detail.",
    )
    parser.add_argument(
        "--methods",
        nargs="+",
        choices=METHODS,
        default=["mean"],
        help="Downsampling methods to write for any block size. Default: mean.",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Search input directories recursively.",
    )
    parser.add_argument(
        "--columns",
        type=int,
        default=0,
        help="Columns for single-method contact sheets. Default chooses a square-ish grid.",
    )
    parser.add_argument(
        "--thumb-width",
        type=int,
        default=320,
        help="Rendered width for each contact sheet thumbnail.",
    )
    parser.add_argument(
        "--label-mode",
        choices=("name", "stem", "path", "none"),
        default="name",
        help="How to label source images in the contact sheet.",
    )
    parser.add_argument(
        "--contact-name",
        default="",
        help="Optional contact sheet filename.",
    )
    parser.add_argument("--gap", type=int, default=10, help="Pixels between contact sheet cards.")
    parser.add_argument("--label-height", type=int, default=26, help="Pixels reserved for labels.")
    return parser.parse_args()


def positive_int(value: int, option: str) -> int:
    if value <= 0:
        raise SystemExit(f"{option} must be greater than zero.")
    return value


def collect_images(inputs: Iterable[str], recursive: bool) -> list[Path]:
    paths: list[Path] = []
    for raw_input in inputs:
        path = Path(raw_input).expanduser()
        if path.is_dir():
            iterator = path.rglob("*") if recursive else path.glob("*")
            paths.extend(
                candidate.resolve()
                for candidate in iterator
                if candidate.is_file() and candidate.suffix.lower() in IMAGE_EXTENSIONS
            )
        elif path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
            paths.append(path.resolve())
        else:
            raise SystemExit(f"Input is not a supported image file or directory: {raw_input}")
    return sorted(dict.fromkeys(paths))


def downsample(image: Image.Image, block_size: int, method: str) -> Image.Image:
    if method == "nearest":
        return resize_down(image, block_size, Image.Resampling.NEAREST)
    if method == "box":
        return resize_down(image, block_size, Image.Resampling.BOX)
    if method == "mean":
        return downsample_block_average(image, block_size)
    if method == "median":
        return downsample_block_median(image, block_size)
    raise ValueError(f"Unsupported method: {method}")


def warn_if_low_resolution(image_path: Path, image: Image.Image) -> None:
    if image.width >= MIN_REVIEW_DIMENSION and image.height >= MIN_REVIEW_DIMENSION:
        return
    print(
        (
            "Warning: input image is smaller than "
            f"{MIN_REVIEW_DIMENSION}x{MIN_REVIEW_DIMENSION}; "
            "thumbnail visual review may not be needed: "
            f"{image_path} ({image.width}x{image.height})"
        ),
        file=sys.stderr,
    )


def resize_down(image: Image.Image, block_size: int, resampling: Image.Resampling) -> Image.Image:
    width, height = output_size(image, block_size)
    return image.resize((width, height), resampling)


def downsample_block_average(image: Image.Image, block_size: int) -> Image.Image:
    out_width, out_height = output_size(image, block_size)
    source = image.convert("RGBA")
    src = source.load()
    result = Image.new("RGBA", (out_width, out_height))
    dst = result.load()
    for out_y in range(out_height):
        y1 = min((out_y + 1) * block_size, source.height)
        for out_x in range(out_width):
            x1 = min((out_x + 1) * block_size, source.width)
            totals = [0, 0, 0, 0]
            count = 0
            for y in range(out_y * block_size, y1):
                for x in range(out_x * block_size, x1):
                    pixel = src[x, y]
                    totals[0] += pixel[0]
                    totals[1] += pixel[1]
                    totals[2] += pixel[2]
                    totals[3] += pixel[3]
                    count += 1
            dst[out_x, out_y] = tuple(round(channel / count) for channel in totals)
    return result


def downsample_block_median(image: Image.Image, block_size: int) -> Image.Image:
    out_width, out_height = output_size(image, block_size)
    source = image.convert("RGBA")
    src = source.load()
    result = Image.new("RGBA", (out_width, out_height))
    dst = result.load()
    for out_y in range(out_height):
        y1 = min((out_y + 1) * block_size, source.height)
        for out_x in range(out_width):
            x1 = min((out_x + 1) * block_size, source.width)
            channels = [[], [], [], []]
            for y in range(out_y * block_size, y1):
                for x in range(out_x * block_size, x1):
                    pixel = src[x, y]
                    channels[0].append(pixel[0])
                    channels[1].append(pixel[1])
                    channels[2].append(pixel[2])
                    channels[3].append(pixel[3])
            dst[out_x, out_y] = tuple(round(median(channel)) for channel in channels)
    return result


def output_size(image: Image.Image, block_size: int) -> tuple[int, int]:
    return max(1, math.ceil(image.width / block_size)), max(1, math.ceil(image.height / block_size))


def build_contact_sheet(
    image_paths: list[Path],
    outputs: dict[str, dict[str, str]],
    methods: list[str],
    columns: int,
    label_mode: str,
    thumb_width: int,
    gap: int,
    label_height: int,
) -> Image.Image:
    if len(methods) == 1:
        cards = [
            make_sample_card(
                image_path=Path(outputs[str(path)][methods[0]]),
                label=source_label(path, label_mode),
                width=thumb_width,
                label_height=label_height,
            )
            for path in image_paths
        ]
        if columns <= 0:
            columns = max(1, math.ceil(math.sqrt(len(cards))))
        return stack_grid(cards, columns=columns, gap=gap)

    rows = []
    for source_path in image_paths:
        method_cards = [
            make_sample_card(
                image_path=Path(outputs[str(source_path)][method]),
                label=f"{method}{source_label_suffix(source_path, label_mode)}",
                width=thumb_width,
                label_height=label_height,
            )
            for method in methods
        ]
        row = stack_horizontal(method_cards, gap=gap)
        title = label_strip(source_label(source_path, label_mode), row.width, label_height)
        rows.append(stack_vertical([title, row], gap=0))
    return stack_vertical(rows, gap=gap)


def make_sample_card(image_path: Path, label: str, width: int, label_height: int) -> Image.Image:
    with Image.open(image_path) as image:
        thumbnail = fit_width(image.convert("RGBA"), width)
    if not label:
        return thumbnail
    return stack_vertical([label_strip(label, thumbnail.width, label_height), thumbnail], gap=0)


def source_label(path: Path, mode: str) -> str:
    if mode == "none":
        return ""
    if mode == "stem":
        return path.stem
    if mode == "path":
        return str(path)
    return path.name


def source_label_suffix(path: Path, mode: str) -> str:
    label = source_label(path, mode)
    return f" / {label}" if label else ""


def label_strip(text: str, width: int, height: int) -> Image.Image:
    strip = Image.new("RGBA", (width, height), (248, 248, 248, 255))
    draw = ImageDraw.Draw(strip)
    font = ImageFont.load_default()
    clipped = clip_text(text, max(1, width - 10), draw, font)
    draw.text((5, max(0, (height - 10) // 2)), clipped, fill=(24, 24, 24, 255), font=font)
    return strip


def clip_text(text: str, max_width: int, draw: ImageDraw.ImageDraw, font: ImageFont.ImageFont) -> str:
    if text_width(text, draw, font) <= max_width:
        return text
    ellipsis = "..."
    available = max(0, max_width - text_width(ellipsis, draw, font))
    clipped = ""
    for character in text:
        if text_width(clipped + character, draw, font) > available:
            break
        clipped += character
    return clipped + ellipsis


def text_width(text: str, draw: ImageDraw.ImageDraw, font: ImageFont.ImageFont) -> int:
    left, _top, right, _bottom = draw.textbbox((0, 0), text, font=font)
    return right - left


def fit_width(image: Image.Image, width: int) -> Image.Image:
    if image.width == width:
        return image
    height = max(1, round(image.height * (width / image.width)))
    return image.resize((width, height), Image.Resampling.BOX)


def stack_grid(images: list[Image.Image], columns: int, gap: int) -> Image.Image:
    rows = []
    for index in range(0, len(images), columns):
        rows.append(stack_horizontal(images[index : index + columns], gap=gap))
    return stack_vertical(rows, gap=gap)


def stack_horizontal(images: list[Image.Image], gap: int) -> Image.Image:
    if not images:
        raise ValueError("Cannot stack an empty image list.")
    width = sum(image.width for image in images) + gap * (len(images) - 1)
    height = max(image.height for image in images)
    result = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    x = 0
    for image in images:
        result.alpha_composite(image.convert("RGBA"), (x, 0))
        x += image.width + gap
    return result


def stack_vertical(images: list[Image.Image], gap: int) -> Image.Image:
    if not images:
        raise ValueError("Cannot stack an empty image list.")
    width = max(image.width for image in images)
    height = sum(image.height for image in images) + gap * (len(images) - 1)
    result = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    y = 0
    for image in images:
        result.alpha_composite(image.convert("RGBA"), (0, y))
        y += image.height + gap
    return result


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", value.strip()).strip("-")
    return slug or "image"


if __name__ == "__main__":
    raise SystemExit(main())
