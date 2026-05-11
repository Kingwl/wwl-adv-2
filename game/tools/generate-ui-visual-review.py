#!/usr/bin/env python3
"""Generate 4x4-first visual review sheets from UI smoke artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


GAME_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = GAME_DIR.parent
DEFAULT_ARTIFACT_DIR = REPO_DIR / "ci-artifacts/ui-smoke/native"
DEFAULT_BLOCK_SIZE = 4

KEY_CROPS = [
    "start-screen-full",
    "start-screen",
    "hud-resources",
    "status-hint",
    "status-reward",
    "status-leak",
    "tower-deck",
    "tower-action-menu",
    "tower-placement-preview",
    "pause-overlay",
    "victory-overlay",
    "defeat-overlay",
]


def main() -> int:
    args = parse_args()
    if args.block_size <= 0:
        raise SystemExit("--block-size must be positive.")

    artifact_dir = Path(args.artifact_dir).expanduser().resolve() if args.artifact_dir else DEFAULT_ARTIFACT_DIR
    report_path = Path(args.report).expanduser().resolve() if args.report else artifact_dir / "report.json"
    output_dir = Path(args.out_dir).expanduser().resolve() if args.out_dir else artifact_dir / "visual-review"
    output_dir.mkdir(parents=True, exist_ok=True)

    report = read_json(report_path)
    manifest = generate_visual_review(report, report_path, artifact_dir, output_dir, args.block_size)
    write_review_report(manifest, output_dir / "report.md")

    print("UI visual review artifacts: %s" % output_dir)
    print(manifest["outputs"]["fullscreens_contact"])
    print(manifest["outputs"]["key_crops_contact"])
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate 4x4 UI visual review contact sheets from UI smoke artifacts.")
    parser.add_argument("--artifact-dir", default="", help="UI smoke artifact directory. Defaults to ci-artifacts/ui-smoke/native.")
    parser.add_argument("--report", default="", help="UI smoke report JSON. Defaults to <artifact-dir>/report.json.")
    parser.add_argument("--out-dir", default="", help="Output directory. Defaults to <artifact-dir>/visual-review.")
    parser.add_argument("--block-size", type=int, default=DEFAULT_BLOCK_SIZE, help="Source pixel block size; 4 means 4x4 to 1.")
    return parser.parse_args()


def generate_visual_review(
    report: dict[str, Any],
    report_path: Path,
    artifact_dir: Path,
    output_dir: Path,
    block_size: int,
) -> dict[str, Any]:
    viewports = [viewport for viewport in report.get("viewports", []) if isinstance(viewport, dict)]
    sample_dir = output_dir / "sampling" / f"{block_size}x{block_size}"
    sample_dir.mkdir(parents=True, exist_ok=True)

    fullscreens_contact = output_dir / f"ui-fullscreens-mean{block_size}x{block_size}-contact.png"
    key_crops_contact = output_dir / f"ui-key-crops-mean{block_size}x{block_size}-contact.png"
    manifest_path = output_dir / "manifest.json"

    sampled: dict[str, dict[str, str]] = {}
    full_cards = []
    for viewport in viewports:
        name = str(viewport.get("name", "unknown"))
        screenshot = viewport.get("screenshot", {})
        source_path = resolve_artifact_path(screenshot.get("path", ""), artifact_dir) if isinstance(screenshot, dict) else None
        if source_path is None or not source_path.is_file():
            continue
        sample = mean_downsample(Image.open(source_path), block_size)
        sample_path = sample_dir / f"{name}-fullscreen-mean{block_size}x{block_size}.png"
        sample.save(sample_path)
        sampled.setdefault(name, {})["fullscreen"] = str(sample_path)
        full_cards.append(stack_vertical([label_strip(name, 320), fit_width(sample, 320)], gap=0))
    if full_cards:
        stack_horizontal(full_cards, gap=10).save(fullscreens_contact)

    artifact_index = {str(viewport.get("name", "unknown")): artifacts_by_name(viewport) for viewport in viewports}
    rows = [label_strip(f"key crops mean{block_size}x{block_size}: rows=crops, columns=viewports", 980, 34)]
    for crop_name in KEY_CROPS:
        row_cards = [label_strip(crop_name, 160, 50)]
        has_crop = False
        for viewport in viewports:
            viewport_name = str(viewport.get("name", "unknown"))
            artifact = artifact_index.get(viewport_name, {}).get(crop_name)
            if artifact is None:
                row_cards.append(blank_card(viewport_name, 250, 90))
                continue
            crop_path = resolve_artifact_path(artifact.get("crop", {}).get("path", ""), artifact_dir)
            if crop_path is None or not crop_path.is_file():
                row_cards.append(blank_card(viewport_name, 250, 90))
                continue
            sample = mean_downsample(Image.open(crop_path), block_size)
            sample_path = sample_dir / f"{viewport_name}-{crop_name}-mean{block_size}x{block_size}.png"
            sample.save(sample_path)
            sampled.setdefault(viewport_name, {})[crop_name] = str(sample_path)
            row_cards.append(stack_vertical([label_strip(viewport_name, 250), fit_width(sample, 250)], gap=0))
            has_crop = True
        if has_crop:
            rows.append(stack_horizontal(row_cards, gap=8))
    stack_vertical(rows, gap=8).save(key_crops_contact)

    atlas_paths: dict[str, str] = {}
    for viewport in viewports:
        viewport_name = str(viewport.get("name", "unknown"))
        cards = []
        for artifact in viewport.get("review_artifacts", []):
            if not isinstance(artifact, dict):
                continue
            crop_name = str(artifact.get("name", "unknown"))
            crop_path = resolve_artifact_path(artifact.get("crop", {}).get("path", ""), artifact_dir)
            if crop_path is None or not crop_path.is_file():
                continue
            sample_path = Path(sampled.get(viewport_name, {}).get(crop_name, ""))
            if not sample_path.is_file():
                sample = mean_downsample(Image.open(crop_path), block_size)
                sample_path = sample_dir / f"{viewport_name}-{crop_name}-mean{block_size}x{block_size}.png"
                sample.save(sample_path)
                sampled.setdefault(viewport_name, {})[crop_name] = str(sample_path)
            cards.append(stack_vertical([label_strip(crop_name, 230), fit_width(Image.open(sample_path), 230)], gap=0))

        if not cards:
            continue
        atlas_rows = [label_strip(f"{viewport_name} crop atlas mean{block_size}x{block_size}", 720, 34)]
        for index in range(0, len(cards), 3):
            atlas_rows.append(stack_horizontal(cards[index : index + 3], gap=8))
        atlas_path = output_dir / f"{viewport_name}-crop-atlas-mean{block_size}x{block_size}.png"
        stack_vertical(atlas_rows, gap=8).save(atlas_path)
        atlas_paths[viewport_name] = str(atlas_path)

    manifest = {
        "purpose": "4x4-first visual review sheets for UI smoke artifacts.",
        "report": str(report_path),
        "artifact_dir": str(artifact_dir),
        "output_dir": str(output_dir),
        "block_size": block_size,
        "algorithm": "alpha-aware arithmetic mean over each NxN source pixel block; edge blocks use available source pixels",
        "outputs": {
            "fullscreens_contact": str(fullscreens_contact),
            "key_crops_contact": str(key_crops_contact),
            "crop_atlases": atlas_paths,
            "sample_dir": str(sample_dir),
            "review_report": str(output_dir / "report.md"),
        },
        "sampled": sampled,
        "review_order": KEY_CROPS,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


def artifacts_by_name(viewport: dict[str, Any]) -> dict[str, dict[str, Any]]:
    artifacts = {}
    for artifact in viewport.get("review_artifacts", []):
        if isinstance(artifact, dict):
            artifacts[str(artifact.get("name", ""))] = artifact
    return artifacts


def mean_downsample(image: Image.Image, block_size: int) -> Image.Image:
    source = image.convert("RGBA")
    width, height = source.size
    out_width = max(1, (width + block_size - 1) // block_size)
    out_height = max(1, (height + block_size - 1) // block_size)
    out = Image.new("RGBA", (out_width, out_height), (0, 0, 0, 0))
    src = source.load()
    dst = out.load()
    for oy in range(out.size[1]):
        for ox in range(out.size[0]):
            x0 = ox * block_size
            y0 = oy * block_size
            x1 = min(width, x0 + block_size)
            y1 = min(height, y0 + block_size)
            area = max(1, (x1 - x0) * (y1 - y0))
            total_a = 0
            total_r = 0
            total_g = 0
            total_b = 0
            for y in range(y0, y1):
                for x in range(x0, x1):
                    r, g, b, a = src[x, y]
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


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit(f"{path}: report root must be an object.")
    return data


def resolve_artifact_path(path_value: Any, artifact_dir: Path) -> Path | None:
    path_text = str(path_value or "")
    if not path_text:
        return None
    path = Path(path_text).expanduser()
    if path.is_absolute():
        return path
    return artifact_dir / path


def label_strip(text: str, width: int, height: int = 30) -> Image.Image:
    image = Image.new("RGBA", (width, height), (18, 22, 28, 255))
    draw = ImageDraw.Draw(image)
    draw.text((8, max(4, (height - 12) // 2)), text[:120], fill=(245, 248, 252, 255))
    return image


def blank_card(text: str, width: int, height: int) -> Image.Image:
    return stack_vertical(
        [
            label_strip(text, width),
            label_strip("missing", width, height),
        ],
        gap=0,
    )


def fit_width(image: Image.Image, width: int) -> Image.Image:
    if image.size[0] == width:
        return image
    height = max(1, int(image.size[1] * width / image.size[0]))
    return image.resize((width, height), Image.Resampling.LANCZOS)


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


def write_review_report(manifest: dict[str, Any], path: Path) -> None:
    outputs = manifest["outputs"]
    lines = [
        "# UI Visual Review",
        "",
        f"- Block size: {manifest['block_size']}x{manifest['block_size']}",
        "- Algorithm: alpha-aware arithmetic mean per block; edge blocks use available source pixels.",
        f"- Fullscreens: [{Path(outputs['fullscreens_contact']).name}]({Path(outputs['fullscreens_contact']).name})",
        f"- Key crops: [{Path(outputs['key_crops_contact']).name}]({Path(outputs['key_crops_contact']).name})",
        "",
        "## Crop Atlases",
        "",
    ]
    for viewport_name, atlas_path in outputs["crop_atlases"].items():
        lines.append(f"- {viewport_name}: [{Path(atlas_path).name}]({Path(atlas_path).name})")
    lines.append("")
    lines.append("Review flow: inspect the 4x4 contact sheets first, then open original smoke crops only for suspicious regions.")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
