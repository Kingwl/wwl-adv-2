#!/usr/bin/env python3
"""Tests for thumbnail_contact_sheet.py."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit("Pillow is required. Install with: python3 -m pip install Pillow") from exc


SCRIPT_PATH = Path(__file__).with_name("thumbnail_contact_sheet.py").resolve()


def load_tool_module():
    spec = importlib.util.spec_from_file_location("thumbnail_contact_sheet", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load script: {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


tool = load_tool_module()


class ThumbnailContactSheetTests(unittest.TestCase):
    def test_downsample_output_size(self) -> None:
        image = Image.new("RGBA", (8, 8), (10, 20, 30, 255))

        self.assertEqual(tool.downsample(image, 4, "mean").size, (2, 2))
        self.assertEqual(tool.downsample(image, 2, "mean").size, (4, 4))

    def test_mean_downsample_pixel_values(self) -> None:
        image = Image.new("RGBA", (8, 8), (0, 0, 0, 255))
        self.fill_rect(image, (0, 0, 4, 4), (255, 0, 0, 255))
        self.fill_rect(image, (4, 0, 8, 4), (0, 255, 0, 255))
        self.fill_rect(image, (0, 4, 4, 8), (0, 0, 255, 255))
        self.fill_rect(image, (4, 4, 8, 8), (255, 255, 255, 255))

        sampled = tool.downsample(image, 4, "mean")

        self.assertEqual(sampled.getpixel((0, 0)), (255, 0, 0, 255))
        self.assertEqual(sampled.getpixel((1, 0)), (0, 255, 0, 255))
        self.assertEqual(sampled.getpixel((0, 1)), (0, 0, 255, 255))
        self.assertEqual(sampled.getpixel((1, 1)), (255, 255, 255, 255))

    def test_median_downsample_reduces_outlier(self) -> None:
        gray = (32, 48, 64, 255)
        image = Image.new("RGBA", (4, 4), gray)
        image.putpixel((0, 0), (255, 255, 255, 255))

        sampled = tool.downsample(image, 4, "median")

        self.assertEqual(sampled.size, (1, 1))
        self.assertEqual(sampled.getpixel((0, 0)), gray)

    def test_cli_generates_4x4_multi_method_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_dir = temp_path / "inputs"
            out_dir = temp_path / "out"
            self.write_png(input_dir / "alpha.png", size=(8, 8), color=(200, 10, 10, 255))
            self.write_png(input_dir / "beta.png", size=(12, 8), color=(10, 200, 10, 255))

            self.run_cli(
                input_dir,
                out_dir,
                "--block-size",
                "4",
                "--methods",
                "mean",
                "median",
                "box",
                "nearest",
            )

            self.assert_multi_method_outputs(
                out_dir,
                block_size=4,
                image_count=2,
                methods=["mean", "median", "box", "nearest"],
            )

    def test_cli_generates_2x2_multi_method_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_dir = temp_path / "inputs"
            out_dir = temp_path / "out"
            self.write_png(input_dir / "alpha.png", size=(8, 8), color=(20, 20, 220, 255))
            self.write_png(input_dir / "beta.png", size=(10, 6), color=(220, 220, 20, 255))

            self.run_cli(input_dir, out_dir, "--block-size", "2", "--methods", "mean", "median", "nearest")

            self.assert_multi_method_outputs(
                out_dir,
                block_size=2,
                image_count=2,
                methods=["mean", "median", "nearest"],
            )

    def test_manifest_records_inputs_outputs_methods(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_dir = temp_path / "inputs"
            out_dir = temp_path / "out"
            first = self.write_png(input_dir / "first.png", size=(8, 8), color=(1, 2, 3, 255))
            second = self.write_png(input_dir / "second.png", size=(8, 8), color=(4, 5, 6, 255))

            self.run_cli(input_dir, out_dir, "--block-size", "4", "--methods", "mean", "median")

            manifest = json.loads((out_dir / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["block_size"], 4)
            self.assertEqual(manifest["methods"], ["mean", "median"])
            self.assertEqual(manifest["inputs"], sorted([str(first.resolve()), str(second.resolve())]))
            self.assertTrue(Path(manifest["outputs"]["contact_sheet"]).is_file())
            self.assertEqual(
                set(manifest["outputs"]["samples"].keys()),
                {str(first.resolve()), str(second.resolve())},
            )

    def test_recursive_directory_collection(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "inputs"
            top = self.write_png(root / "top.png", size=(4, 4), color=(0, 0, 0, 255))
            nested = self.write_png(root / "nested" / "nested.png", size=(4, 4), color=(255, 255, 255, 255))

            shallow = tool.collect_images([str(root)], recursive=False)
            recursive = tool.collect_images([str(root)], recursive=True)

            self.assertEqual(shallow, [top.resolve()])
            self.assertEqual(recursive, sorted([top.resolve(), nested.resolve()]))

    def test_invalid_input_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            missing = Path(temp_dir) / "missing.png"
            out_dir = Path(temp_dir) / "out"

            result = subprocess.run(
                [sys.executable, str(SCRIPT_PATH), str(missing), "--out-dir", str(out_dir)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Input is not a supported image file or directory", result.stderr)

    def test_low_resolution_input_warns_without_failing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_dir = temp_path / "inputs"
            out_dir = temp_path / "out"
            self.write_png(input_dir / "tiny.png", size=(80, 80), color=(8, 9, 10, 255))

            result = self.run_cli(input_dir, out_dir, "--block-size", "4", "--methods", "mean")

            self.assertIn("Warning: input image is smaller than 100x100", result.stderr)
            self.assertIn("tiny.png (80x80)", result.stderr)
            self.assertTrue((out_dir / "contact-mean4x4.png").is_file())

    @staticmethod
    def fill_rect(
        image: Image.Image,
        bounds: tuple[int, int, int, int],
        color: tuple[int, int, int, int],
    ) -> None:
        x0, y0, x1, y1 = bounds
        for y in range(y0, y1):
            for x in range(x0, x1):
                image.putpixel((x, y), color)

    @staticmethod
    def write_png(path: Path, size: tuple[int, int], color: tuple[int, int, int, int]) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", size, color).save(path)
        return path

    def run_cli(
        self,
        input_dir: Path,
        out_dir: Path,
        *extra_args: str,
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(input_dir), "--out-dir", str(out_dir), *extra_args],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        return result

    def assert_multi_method_outputs(
        self,
        out_dir: Path,
        block_size: int,
        image_count: int,
        methods: list[str],
    ) -> None:
        self.assertTrue((out_dir / f"contact-{block_size}x{block_size}-methods.png").is_file())
        self.assertTrue((out_dir / "manifest.json").is_file())
        sample_dir = out_dir / "sampling" / f"{block_size}x{block_size}"
        for method in methods:
            self.assertEqual(
                len(list(sample_dir.glob(f"*-{method}{block_size}x{block_size}.png"))),
                image_count,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
