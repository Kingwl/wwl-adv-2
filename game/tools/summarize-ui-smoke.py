#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


GAME_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = GAME_DIR.parent
DEFAULT_REPORT = REPO_DIR / "ci-artifacts" / "ui-smoke" / "native" / "report.json"


def load_report(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError("report root must be a JSON object")
    return data


def rel(path: str | Path) -> str:
    try:
        return str(Path(path).resolve().relative_to(REPO_DIR))
    except ValueError:
        return str(path)


def main() -> int:
    report_path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else DEFAULT_REPORT
    if not report_path.is_absolute():
        report_path = (Path.cwd() / report_path).resolve()

    try:
        report = load_report(report_path)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"UI smoke summary unavailable: {report_path}: {exc}", file=sys.stderr)
        return 2

    ok = bool(report.get("ok", False))
    viewports = report.get("viewports", [])
    failures = report.get("failures", [])
    if not isinstance(viewports, list):
        viewports = []
    if not isinstance(failures, list):
        failures = []

    print("UI smoke summary")
    print(f"- status: {'PASS' if ok else 'FAIL'}")
    print(f"- report: {rel(report_path)}")
    print(f"- viewports: {len(viewports)}")
    print(f"- failures: {len(failures)}")

    for viewport in viewports:
        if not isinstance(viewport, dict):
            continue
        name = str(viewport.get("name", "unknown"))
        size = viewport.get("size", {})
        width = size.get("width", "?") if isinstance(size, dict) else "?"
        height = size.get("height", "?") if isinstance(size, dict) else "?"
        screenshot = viewport.get("screenshot", {})
        screenshot_path = ""
        non_dark = None
        contrast = None
        if isinstance(screenshot, dict):
            screenshot_path = str(screenshot.get("path", ""))
            stats = screenshot.get("stats", {})
            if isinstance(stats, dict):
                non_dark = stats.get("non_dark_ratio")
                contrast = stats.get("luminance_range")

        viewport_status = "PASS" if bool(viewport.get("ok", False)) else "FAIL"
        line = f"- {name} {width}x{height}: {viewport_status}"
        if screenshot_path:
            line += f", screenshot={rel(screenshot_path)}"
        if isinstance(non_dark, (int, float)) and isinstance(contrast, (int, float)):
            line += f", non_dark={non_dark:.3f}, contrast={contrast:.3f}"
        print(line)

    if failures:
        print("Failed checks:")
        for failure in failures:
            if not isinstance(failure, dict):
                continue
            viewport = failure.get("viewport", "unknown")
            name = failure.get("name", "unknown")
            print(f"- {viewport}: {name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
