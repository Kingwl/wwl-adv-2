#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
SUMMARY_RE = re.compile(r"^(Scripts|Tests|Passing Tests|Failing Tests|Asserts)\s+([0-9]+)$")
TIME_RE = re.compile(r"^Time\s+([0-9.]+)s$")


def strip_ansi(text: str) -> str:
    return ANSI_RE.sub("", text)


def parse_summary_line(line: str):
    match = SUMMARY_RE.match(line.strip())
    if match:
        key = match.group(1).lower().replace(" ", "_")
        return key, int(match.group(2))
    match = TIME_RE.match(line.strip())
    if match:
        return "time_seconds", float(match.group(1))
    return None


def parse_log(log_path: Path, exit_status: int) -> dict:
    raw_text = log_path.read_text(encoding="utf-8", errors="replace")
    lines = strip_ansi(raw_text).splitlines()

    report = {
        "source": str(log_path),
        "command_exit_status": exit_status,
        "ok": exit_status == 0,
        "godot": {
            "headers": [],
        },
        "gut": {
            "version": None,
            "godot_version": None,
            "all_tests_passed": None,
            "scripts": None,
            "tests": None,
            "passing_tests": None,
            "failing_tests": None,
            "asserts": None,
            "time_seconds": None,
        },
        "findings": {
            "errors": [],
            "warnings": [],
            "known_warnings": [],
        },
    }

    known_warning_seen = set()
    for line_number, line in enumerate(lines, start=1):
        stripped = line.strip()
        if stripped.startswith("Godot Engine "):
            report["godot"]["headers"].append(stripped)
        elif stripped.startswith("Godot version:"):
            report["gut"]["godot_version"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("GUT version:"):
            report["gut"]["version"] = stripped.split(":", 1)[1].strip()
        elif "---- All tests passed! ----" in stripped:
            report["gut"]["all_tests_passed"] = True

        summary = parse_summary_line(stripped)
        if summary is not None:
            key, value = summary
            report["gut"][key] = value

        if "ObjectDB instances leaked at exit" in stripped:
            key = "TD-007"
            if key not in known_warning_seen:
                known_warning_seen.add(key)
                report["findings"]["known_warnings"].append({
                    "id": key,
                    "line": line_number,
                    "message": "ObjectDB instances leaked at exit",
                    "detail": "Known scene/resource cleanup warning tracked in docs/tech-debt/register.md.",
                })

        if stripped.startswith("SCRIPT ERROR:"):
            report["findings"]["errors"].append({
                "line": line_number,
                "kind": "script_error",
                "message": stripped.removeprefix("SCRIPT ERROR:").strip(),
            })
        elif stripped.startswith("ERROR:"):
            report["findings"]["errors"].append({
                "line": line_number,
                "kind": "godot_error",
                "message": stripped.removeprefix("ERROR:").strip(),
            })
        elif stripped.startswith("WARNING:"):
            report["findings"]["warnings"].append({
                "line": line_number,
                "kind": "godot_warning",
                "message": stripped.removeprefix("WARNING:").strip(),
            })

    tests = report["gut"]["tests"]
    passing = report["gut"]["passing_tests"]
    failing = report["gut"]["failing_tests"]
    if tests is not None and passing is not None:
        report["gut"]["all_tests_passed"] = tests == passing and (failing in (None, 0))

    if report["findings"]["errors"]:
        report["ok"] = False
    if report["gut"]["all_tests_passed"] is False:
        report["ok"] = False

    return report


def render_markdown(report: dict) -> str:
    status = "PASS" if report["ok"] else "FAIL"
    gut = report["gut"]
    findings = report["findings"]
    lines = [
        "# Godot/GUT Log Report",
        "",
        f"- Status: {status}",
        f"- Source: `{report['source']}`",
        f"- Command exit status: {report['command_exit_status']}",
        "",
        "## GUT Summary",
        "",
    ]

    if gut["tests"] is None:
        lines.append("- No GUT totals found.")
    else:
        lines.extend([
            f"- Godot version: {gut['godot_version'] or 'unknown'}",
            f"- GUT version: {gut['version'] or 'unknown'}",
            f"- Scripts: {gut['scripts']}",
            f"- Tests: {gut['tests']}",
            f"- Passing tests: {gut['passing_tests']}",
            f"- Failing tests: {gut['failing_tests'] or 0}",
            f"- Asserts: {gut['asserts']}",
            f"- Time: {gut['time_seconds']}s",
            f"- All tests passed: {gut['all_tests_passed']}",
        ])

    lines.extend([
        "",
        "## Findings",
        "",
        f"- Errors: {len(findings['errors'])}",
        f"- Warnings: {len(findings['warnings'])}",
        f"- Known warnings: {len(findings['known_warnings'])}",
    ])

    if findings["errors"]:
        lines.extend(["", "### Errors", ""])
        for item in findings["errors"][:20]:
            lines.append(f"- line {item['line']}: {item['kind']}: {item['message']}")
        if len(findings["errors"]) > 20:
            lines.append(f"- ... {len(findings['errors']) - 20} more error(s)")

    if findings["warnings"]:
        lines.extend(["", "### Warnings", ""])
        for item in findings["warnings"][:20]:
            lines.append(f"- line {item['line']}: {item['message']}")
        if len(findings["warnings"]) > 20:
            lines.append(f"- ... {len(findings['warnings']) - 20} more warning(s)")

    if findings["known_warnings"]:
        lines.extend(["", "### Known Warnings", ""])
        for item in findings["known_warnings"]:
            lines.append(f"- {item['id']}: {item['message']} ({item['detail']})")

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize Godot and GUT logs into JSON and Markdown reports.")
    parser.add_argument("log_path", type=Path)
    parser.add_argument("--exit-status", type=int, default=0)
    parser.add_argument("--out-dir", type=Path, default=None)
    args = parser.parse_args()

    if not args.log_path.exists():
        raise SystemExit(f"missing log file: {args.log_path}")

    out_dir = args.out_dir
    if out_dir is None:
        out_dir = args.log_path.parent / "godot-log"
    out_dir.mkdir(parents=True, exist_ok=True)

    report = parse_log(args.log_path, args.exit_status)
    json_path = out_dir / "report.json"
    md_path = out_dir / "report.md"
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")

    print("Godot/GUT log report")
    print("- status: %s" % ("PASS" if report["ok"] else "FAIL"))
    print("- report: %s" % md_path)
    print("- errors: %d" % len(report["findings"]["errors"]))
    print("- warnings: %d" % len(report["findings"]["warnings"]))
    print("- known_warnings: %d" % len(report["findings"]["known_warnings"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
