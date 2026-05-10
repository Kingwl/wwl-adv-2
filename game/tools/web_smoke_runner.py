#!/usr/bin/env python3
from __future__ import annotations

import argparse
import functools
import http.server
import json
import shutil
import struct
import sys
import threading
import time
import zlib
from pathlib import Path
from typing import Any


DEFAULT_TIMEOUT_SECONDS = 60.0
MIN_CANVAS_WIDTH = 320
MIN_CANVAS_HEIGHT = 180
MIN_NON_DARK_RATIO = 0.03
MIN_LUMINANCE_RANGE = 0.04


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }

    def log_message(self, _format: str, *_args: Any) -> None:
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke-test a Godot Web export with a headless browser.")
    parser.add_argument("export_dir", help="Directory containing index.html and Web export files.")
    parser.add_argument(
        "--artifact-dir",
        default=None,
        help="Directory for report.json, report.md, screenshots, and console logs.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="Maximum seconds to wait for a visible nonblank canvas.",
    )
    return parser.parse_args()


def resolve_dir(path: str) -> Path:
    return Path(path).expanduser().resolve(strict=False)


def start_http_server(export_dir: Path) -> tuple[http.server.ThreadingHTTPServer, str]:
    handler = functools.partial(QuietHandler, directory=str(export_dir))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, name="web-smoke-http", daemon=True)
    thread.start()
    host, port = server.server_address
    return server, f"http://{host}:{port}/index.html"


def paeth_predictor(left: int, up: int, up_left: int) -> int:
    p = left + up - up_left
    pa = abs(p - left)
    pb = abs(p - up)
    pc = abs(p - up_left)
    if pa <= pb and pa <= pc:
        return left
    if pb <= pc:
        return up
    return up_left


def read_png_stats(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"{path} is not a PNG")

    pos = 8
    width = height = bit_depth = color_type = None
    idat = bytearray()

    while pos < len(data):
        if pos + 8 > len(data):
            raise ValueError(f"{path} has a truncated PNG chunk")
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        chunk_type = data[pos + 4 : pos + 8]
        chunk_start = pos + 8
        chunk_end = chunk_start + length
        chunk_data = data[chunk_start:chunk_end]
        pos = chunk_end + 4

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, _interlace = struct.unpack(
                ">IIBBBBB", chunk_data
            )
        elif chunk_type == b"IDAT":
            idat.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or bit_depth is None or color_type is None:
        raise ValueError(f"{path} is missing IHDR")
    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(f"{path} uses unsupported PNG format bit_depth={bit_depth} color_type={color_type}")

    channels = 4 if color_type == 6 else 3
    stride = width * channels
    raw = zlib.decompress(bytes(idat))
    expected = (stride + 1) * height
    if len(raw) < expected:
        raise ValueError(f"{path} has truncated image data")

    previous = bytearray(stride)
    offset = 0
    sample_count = 0
    non_dark = 0
    transparent = 0
    luminance_min = 1.0
    luminance_max = 0.0
    luminance_total = 0.0
    color_buckets: set[tuple[int, int, int]] = set()

    step_x = max(1, width // 192)
    step_y = max(1, height // 108)

    for y in range(height):
        filter_type = raw[offset]
        offset += 1
        row = bytearray(raw[offset : offset + stride])
        offset += stride

        for i in range(stride):
            left = row[i - channels] if i >= channels else 0
            up = previous[i]
            up_left = previous[i - channels] if i >= channels else 0
            if filter_type == 1:
                row[i] = (row[i] + left) & 0xFF
            elif filter_type == 2:
                row[i] = (row[i] + up) & 0xFF
            elif filter_type == 3:
                row[i] = (row[i] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                row[i] = (row[i] + paeth_predictor(left, up, up_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"{path} uses unsupported PNG filter {filter_type}")

        if y % step_y == 0:
            for x in range(0, width, step_x):
                idx = x * channels
                r = row[idx]
                g = row[idx + 1]
                b = row[idx + 2]
                a = row[idx + 3] if channels == 4 else 255
                luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
                sample_count += 1
                luminance_total += luminance
                luminance_min = min(luminance_min, luminance)
                luminance_max = max(luminance_max, luminance)
                if a <= 8:
                    transparent += 1
                if a > 8 and luminance > 0.03:
                    non_dark += 1
                color_buckets.add((r // 16, g // 16, b // 16))

        previous = row

    if sample_count == 0:
        raise ValueError(f"{path} has no sampled pixels")

    return {
        "path": str(path),
        "width": width,
        "height": height,
        "sample_count": sample_count,
        "non_dark_ratio": non_dark / sample_count,
        "transparent_ratio": transparent / sample_count,
        "luminance_min": luminance_min,
        "luminance_max": luminance_max,
        "luminance_range": luminance_max - luminance_min,
        "average_luminance": luminance_total / sample_count,
        "color_bucket_count": len(color_buckets),
    }


def is_canvas_nonblank(stats: dict[str, Any]) -> bool:
    return (
        stats["width"] >= MIN_CANVAS_WIDTH
        and stats["height"] >= MIN_CANVAS_HEIGHT
        and stats["non_dark_ratio"] >= MIN_NON_DARK_RATIO
        and stats["luminance_range"] >= MIN_LUMINANCE_RANGE
        and stats["color_bucket_count"] >= 8
    )


def write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_report(report_path: Path, report: dict[str, Any]) -> None:
    checks = report["checks"]
    status = "PASS" if report["ok"] else "FAIL"
    lines = [
        f"# Web export smoke: {status}",
        "",
        f"- URL: `{report['url']}`",
        f"- Export dir: `{report['export_dir']}`",
        f"- Artifact dir: `{report['artifact_dir']}`",
        "",
        "## Checklist",
    ]
    for check in checks:
        mark = "x" if check["ok"] else " "
        lines.append(f"- [{mark}] {check['name']}")

    lines.extend(["", "## Canvas"])
    canvas = report.get("canvas") or {}
    stats = canvas.get("stats") or {}
    if stats:
        lines.extend(
            [
                f"- Size: `{stats['width']}x{stats['height']}`",
                f"- Non-dark ratio: `{stats['non_dark_ratio']:.4f}`",
                f"- Luminance range: `{stats['luminance_range']:.4f}`",
                f"- Color buckets: `{stats['color_bucket_count']}`",
            ]
        )
    else:
        lines.append("- No canvas stats captured.")

    lines.extend(
        [
            "",
            "## Artifacts",
            "- `page.png`: full page screenshot.",
            "- `canvas.png`: canvas-only screenshot.",
            "- `browser-console.json`: console/page/request events.",
            "- `report.json`: machine-readable report.",
        ]
    )

    critical = report.get("critical_events") or []
    if critical:
        lines.extend(["", "## Critical Events"])
        for event in critical[:20]:
            lines.append(f"- `{event['source']}`: {event['message']}")
        if len(critical) > 20:
            lines.append(f"- ... {len(critical) - 20} more")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_browser(export_dir: Path, artifact_dir: Path, url: str, timeout: float) -> dict[str, Any]:
    try:
        from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise RuntimeError(
            "missing Playwright Python package; install with "
            "`python3 -m pip install playwright && python3 -m playwright install chromium`"
        ) from exc

    page_png = artifact_dir / "page.png"
    canvas_png = artifact_dir / "canvas.png"
    events: list[dict[str, str]] = []
    critical_events: list[dict[str, str]] = []

    def add_event(source: str, message: str, critical: bool = False) -> None:
        item = {"source": source, "message": message}
        events.append(item)
        if critical:
            critical_events.append(item)

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True, args=["--no-sandbox"])
        context = browser.new_context(
            viewport={"width": 1280, "height": 720},
            device_scale_factor=1,
        )
        page = context.new_page()

        page.on(
            "console",
            lambda msg: add_event(
                f"console.{msg.type}",
                msg.text,
                critical=msg.type in {"error", "assert"},
            ),
        )
        page.on("pageerror", lambda error: add_event("pageerror", str(error), critical=True))

        def on_request_failed(request: Any) -> None:
            if request.url.endswith("/favicon.ico"):
                return
            failure = request.failure
            message = f"{request.method} {request.url}"
            if failure:
                message += f" ({failure})"
            add_event("requestfailed", message, critical=True)

        page.on("requestfailed", on_request_failed)

        response = page.goto(url, wait_until="domcontentloaded", timeout=timeout * 1000)
        http_status = response.status if response is not None else None
        if http_status is None or http_status >= 400:
            add_event("navigation", f"index.html returned HTTP {http_status}", critical=True)

        try:
            page.wait_for_load_state("networkidle", timeout=10_000)
        except PlaywrightTimeoutError:
            add_event("load_state", "networkidle was not reached within 10s")

        canvas_locator = page.locator("canvas").first
        canvas_seen = False
        canvas_box: dict[str, float] | None = None
        canvas_stats: dict[str, Any] | None = None
        deadline = time.monotonic() + timeout

        while time.monotonic() < deadline:
            try:
                if canvas_locator.count() > 0:
                    box = canvas_locator.bounding_box()
                    if box:
                        canvas_seen = True
                        canvas_box = box
                        canvas_locator.screenshot(path=str(canvas_png))
                        canvas_stats = read_png_stats(canvas_png)
                        if is_canvas_nonblank(canvas_stats):
                            break
            except Exception as exc:
                add_event("canvas_probe", str(exc))
            page.wait_for_timeout(500)

        page.screenshot(path=str(page_png), full_page=True)
        if not canvas_png.exists():
            shutil.copyfile(page_png, canvas_png)
            canvas_stats = read_png_stats(canvas_png)

        context.close()
        browser.close()

    checks = [
        {"name": "index.html responds successfully", "ok": not any(e["source"] == "navigation" for e in critical_events)},
        {"name": "canvas element exists", "ok": canvas_seen},
        {
            "name": "canvas size is plausible",
            "ok": bool(
                canvas_stats
                and canvas_stats["width"] >= MIN_CANVAS_WIDTH
                and canvas_stats["height"] >= MIN_CANVAS_HEIGHT
            ),
        },
        {"name": "canvas is not blank", "ok": bool(canvas_stats and is_canvas_nonblank(canvas_stats))},
        {"name": "no critical console/page/request errors", "ok": len(critical_events) == 0},
    ]

    return {
        "ok": all(check["ok"] for check in checks),
        "url": url,
        "export_dir": str(export_dir),
        "artifact_dir": str(artifact_dir),
        "checks": checks,
        "canvas": {
            "seen": canvas_seen,
            "box": canvas_box,
            "stats": canvas_stats,
        },
        "critical_events": critical_events,
        "event_count": len(events),
        "artifacts": {
            "page_screenshot": str(page_png),
            "canvas_screenshot": str(canvas_png),
        },
        "events": events,
    }


def main() -> int:
    args = parse_args()
    export_dir = resolve_dir(args.export_dir)
    artifact_dir = resolve_dir(args.artifact_dir) if args.artifact_dir else export_dir.parent / "web-smoke-artifacts"

    artifact_dir.mkdir(parents=True, exist_ok=True)

    if not (export_dir / "index.html").is_file():
        print(f"missing {export_dir / 'index.html'}", file=sys.stderr)
        return 1

    server, url = start_http_server(export_dir)
    report: dict[str, Any] | None = None
    try:
        report = run_browser(export_dir, artifact_dir, url, args.timeout)
        write_json(artifact_dir / "browser-console.json", report["events"])
        write_json(artifact_dir / "report.json", {k: v for k, v in report.items() if k != "events"})
        write_report(artifact_dir / "report.md", report)
        return 0 if report["ok"] else 1
    except Exception as exc:
        report = {
            "ok": False,
            "url": url,
            "export_dir": str(export_dir),
            "artifact_dir": str(artifact_dir),
            "checks": [{"name": "runner completed", "ok": False}],
            "canvas": None,
            "critical_events": [{"source": "runner", "message": str(exc)}],
            "event_count": 0,
            "artifacts": {},
        }
        write_json(artifact_dir / "browser-console.json", [])
        write_json(artifact_dir / "report.json", report)
        write_report(artifact_dir / "report.md", report)
        print(str(exc), file=sys.stderr)
        return 1
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
