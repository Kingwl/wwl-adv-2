#!/usr/bin/env python3
"""Tree-sitter based structural lint for the Godot project."""

from __future__ import annotations

import argparse
import datetime as _datetime
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

from tree_sitter import Language, Parser


BOARD_VIEW_REL = Path("game/scripts/board/board_view.gd")
BOARD_ASSET_CATALOG_REL = Path("game/scripts/board/board_asset_catalog.gd")

CORE_SCENE_EXTENDS = (
    "Node",
    "Node2D",
    "CanvasItem",
    "Control",
    "Panel",
    "Label",
    "Button",
    "TextureRect",
    "ColorRect",
    "DirectionalLight2D",
)

CORE_SCENE_SYMBOLS = (
    "NodePath",
    "InputEvent",
    "get_node",
    "get_node_or_null",
    "get_tree",
    "add_child",
    "queue_redraw",
    "change_scene_to_file",
)

CORE_RENDER_WARNING_SYMBOLS = (
    "CanvasItem",
    "Texture2D",
    "CanvasTexture",
    "draw_texture_rect",
    "draw_rect",
    "load",
)


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    path: str
    line: int
    message: str

    def to_json(self) -> dict:
        return {
            "severity": self.severity,
            "code": self.code,
            "path": self.path,
            "line": self.line,
            "message": self.message,
        }


@dataclass
class GDScriptDoc:
    path: Path
    rel_path: Path
    source: bytes
    masked_text: str
    root_node: object
    function_count: int
    line_count: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Tree-sitter structural lint.")
    parser.add_argument("--repo-root", required=True, type=Path)
    parser.add_argument("--artifact-dir", required=True, type=Path)
    parser.add_argument("--cache-dir", required=True, type=Path)
    parser.add_argument("--grammar-dir", required=True, type=Path)
    return parser.parse_args()


def iter_gdscript_files(repo_root: Path) -> List[Path]:
    roots = [
        repo_root / "game" / "scripts",
        repo_root / "game" / "test" / "gut",
        repo_root / "game" / "tools",
    ]
    files: List[Path] = []
    for root in roots:
        if root.exists():
            files.extend(sorted(root.rglob("*.gd")))
    return sorted(set(files))


def load_parser(cache_dir: Path, grammar_dir: Path) -> Parser:
    cache_dir.mkdir(parents=True, exist_ok=True)
    extension = ".dylib" if sys.platform == "darwin" else ".so"
    library_path = cache_dir / ("gdscript-tree-sitter" + extension)
    if not library_path.exists():
        Language.build_library(str(library_path), [str(grammar_dir)])

    language = Language(str(library_path), "gdscript")
    parser = Parser()
    parser.set_language(language)
    return parser


def iter_nodes(node: object) -> Iterable[object]:
    yield node
    for child in getattr(node, "children", []):
        yield from iter_nodes(child)


def node_text(source: bytes, node: object) -> str:
    return source[node.start_byte:node.end_byte].decode("utf-8", errors="replace")


def should_mask_node(node_type: str) -> bool:
    lowered = node_type.lower()
    return (
        lowered == "comment"
        or lowered.endswith("_comment")
        or "string" in lowered
    )


def collect_mask_ranges(node: object, ranges: List[Tuple[int, int]]) -> None:
    if should_mask_node(node.type):
        ranges.append((node.start_byte, node.end_byte))
        return

    for child in getattr(node, "children", []):
        collect_mask_ranges(child, ranges)


def masked_source(source: bytes, root_node: object) -> str:
    mutable = bytearray(source)
    ranges: List[Tuple[int, int]] = []
    collect_mask_ranges(root_node, ranges)
    for start, end in ranges:
        for index in range(start, end):
            if mutable[index] not in (10, 13):
                mutable[index] = 32
    return mutable.decode("utf-8", errors="replace")


def line_for_offset(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def first_match_line(text: str, pattern: str, flags: int = 0) -> int:
    match = re.search(pattern, text, flags)
    if match is None:
        return 0
    return line_for_offset(text, match.start())


def const_resource_nodes(doc: GDScriptDoc) -> List[object]:
    matches = []
    for node in iter_nodes(doc.root_node):
        if node.type != "const_statement":
            continue
        if "res://" in node_text(doc.source, node):
            matches.append(node)
    return matches


def function_count(root_node: object) -> int:
    return sum(1 for node in iter_nodes(root_node) if node.type == "function_definition")


def format_path(path: Path) -> str:
    return path.as_posix()


def parse_docs(repo_root: Path, parser: Parser, findings: List[Finding]) -> List[GDScriptDoc]:
    docs: List[GDScriptDoc] = []
    for path in iter_gdscript_files(repo_root):
        rel_path = path.relative_to(repo_root)
        source = path.read_bytes()
        tree = parser.parse(source)
        root = tree.root_node
        if root.has_error:
            error_line = first_error_line(root)
            findings.append(Finding(
                "error",
                "GD_PARSE",
                format_path(rel_path),
                error_line,
                "Tree-sitter could not parse this GDScript file cleanly.",
            ))
        docs.append(GDScriptDoc(
            path=path,
            rel_path=rel_path,
            source=source,
            masked_text=masked_source(source, root),
            root_node=root,
            function_count=function_count(root),
            line_count=source.count(b"\n") + 1,
        ))
    return docs


def first_error_line(root_node: object) -> int:
    for node in iter_nodes(root_node):
        if (
            node.type == "ERROR"
            or getattr(node, "is_error", False)
            or getattr(node, "is_missing", False)
        ):
            return node.start_point[0] + 1
    return root_node.start_point[0] + 1


def add_finding_once(
    findings: List[Finding],
    severity: str,
    code: str,
    doc: GDScriptDoc,
    line: int,
    message: str,
) -> None:
    key = (severity, code, format_path(doc.rel_path), line, message)
    for finding in findings:
        if (
            finding.severity,
            finding.code,
            finding.path,
            finding.line,
            finding.message,
        ) == key:
            return
    findings.append(Finding(severity, code, format_path(doc.rel_path), line, message))


def check_core_boundaries(docs: Sequence[GDScriptDoc], findings: List[Finding]) -> None:
    extends_pattern = r"(?m)^\s*extends\s+(%s)\b" % "|".join(map(re.escape, CORE_SCENE_EXTENDS))
    for doc in docs:
        if not doc.rel_path.as_posix().startswith("game/scripts/core/"):
            continue

        line = first_match_line(doc.masked_text, extends_pattern)
        if line:
            add_finding_once(
                findings,
                "error",
                "CORE001",
                doc,
                line,
                "Core rules must not extend scene/UI node classes; use RefCounted data/services.",
            )

        for symbol in CORE_SCENE_SYMBOLS:
            line = first_match_line(doc.masked_text, r"\b%s\b" % re.escape(symbol))
            if line:
                add_finding_once(
                    findings,
                    "error",
                    "CORE002",
                    doc,
                    line,
                    "Core rules must not use scene tree, input, node lookup, or node lifecycle APIs.",
                )

        for symbol in CORE_RENDER_WARNING_SYMBOLS:
            line = first_match_line(doc.masked_text, r"\b%s\b" % re.escape(symbol))
            if line:
                add_finding_once(
                    findings,
                    "warning",
                    "CORE101",
                    doc,
                    line,
                    "Rendering/resource coupling exists under core; keep new render adapters outside core.",
                )


def check_board_asset_catalog(repo_root: Path, docs_by_rel: dict, findings: List[Finding]) -> None:
    catalog_path = repo_root / BOARD_ASSET_CATALOG_REL
    board_view_doc = docs_by_rel.get(BOARD_VIEW_REL)

    if not catalog_path.exists():
        findings.append(Finding(
            "error",
            "BV001",
            format_path(BOARD_ASSET_CATALOG_REL),
            1,
            "BoardAssetCatalog is required to own BoardView asset and data resource paths.",
        ))
        return

    catalog_doc = docs_by_rel.get(BOARD_ASSET_CATALOG_REL)
    if catalog_doc is None:
        return

    if "class_name BoardAssetCatalog" not in catalog_doc.masked_text:
        findings.append(Finding(
            "error",
            "BV002",
            format_path(BOARD_ASSET_CATALOG_REL),
            1,
            "Board asset catalog must declare class_name BoardAssetCatalog.",
        ))

    if len(const_resource_nodes(catalog_doc)) == 0:
        findings.append(Finding(
            "warning",
            "BV101",
            format_path(BOARD_ASSET_CATALOG_REL),
            1,
            "BoardAssetCatalog should be the explicit home for BoardView resource path constants.",
        ))

    if board_view_doc is not None and "BoardAssetCatalog" not in board_view_doc.masked_text:
        findings.append(Finding(
            "error",
            "BV003",
            format_path(BOARD_VIEW_REL),
            1,
            "BoardView must depend on BoardAssetCatalog instead of owning asset path loading directly.",
        ))


def check_board_view(docs_by_rel: dict, findings: List[Finding]) -> None:
    doc = docs_by_rel.get(BOARD_VIEW_REL)
    if doc is None:
        findings.append(Finding(
            "error",
            "BV004",
            format_path(BOARD_VIEW_REL),
            1,
            "BoardView script is missing.",
        ))
        return

    resource_consts = const_resource_nodes(doc)
    if len(resource_consts) > 1:
        first_extra = resource_consts[1]
        add_finding_once(
            findings,
            "error",
            "BV005",
            doc,
            first_extra.start_point[0] + 1,
            "BoardView may keep scene routing constants only; asset/data resource paths belong in BoardAssetCatalog.",
        )

    line = first_match_line(doc.masked_text, r"\b(?:load|preload)\s*\(")
    if line:
        add_finding_once(
            findings,
            "error",
            "BV006",
            doc,
            line,
            "BoardView must not call load/preload directly; route board assets through BoardAssetCatalog.",
        )

    if doc.line_count > 1200:
        findings.append(Finding(
            "warning",
            "BV102",
            format_path(doc.rel_path),
            1,
            "BoardView is still larger than 1200 lines; continue splitting rendering, HUD, input, and flow adapters.",
        ))

    if doc.function_count > 70:
        findings.append(Finding(
            "warning",
            "BV103",
            format_path(doc.rel_path),
            1,
            "BoardView still owns many functions; future feature work should split a bounded adapter first.",
        ))

    for pattern, message in (
        (r"\bWaveDefinition\.new\s*\(", "BoardView still constructs default wave definitions; move wave data to config when balancing starts."),
        (r"\bEconomyConfig\.new\s*\(", "BoardView still constructs economy config; move gameplay config ownership out of the scene adapter."),
    ):
        line = first_match_line(doc.masked_text, pattern)
        if line:
            findings.append(Finding("warning", "BV104", format_path(doc.rel_path), line, message))


def write_reports(artifact_dir: Path, docs: Sequence[GDScriptDoc], findings: Sequence[Finding]) -> None:
    artifact_dir.mkdir(parents=True, exist_ok=True)
    errors = [finding for finding in findings if finding.severity == "error"]
    warnings = [finding for finding in findings if finding.severity == "warning"]
    payload = {
        "generated_at": _datetime.datetime.now(_datetime.timezone.utc).isoformat(),
        "status": "failed" if errors else "passed",
        "parsed_gdscript_files": len(docs),
        "errors": len(errors),
        "warnings": len(warnings),
        "findings": [finding.to_json() for finding in findings],
    }
    (artifact_dir / "report.json").write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Structural Lint Report",
        "",
        f"- Status: {payload['status']}",
        f"- Parsed GDScript files: {len(docs)}",
        f"- Errors: {len(errors)}",
        f"- Warnings: {len(warnings)}",
        "",
    ]
    for title, group in (("Errors", errors), ("Warnings", warnings)):
        lines.append(f"## {title}")
        if group:
            for finding in group:
                lines.append(
                    f"- [{finding.severity}] {finding.code} {finding.path}:{finding.line} - {finding.message}"
                )
        else:
            lines.append("- none")
        lines.append("")

    (artifact_dir / "report.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    artifact_dir = args.artifact_dir.resolve()
    cache_dir = args.cache_dir.resolve()
    grammar_dir = args.grammar_dir.resolve()
    findings: List[Finding] = []

    parser = load_parser(cache_dir, grammar_dir)
    docs = parse_docs(repo_root, parser, findings)
    docs_by_rel = {doc.rel_path: doc for doc in docs}

    check_core_boundaries(docs, findings)
    check_board_asset_catalog(repo_root, docs_by_rel, findings)
    check_board_view(docs_by_rel, findings)
    findings.sort(key=lambda item: (item.severity != "error", item.path, item.line, item.code))
    write_reports(artifact_dir, docs, findings)

    errors = [finding for finding in findings if finding.severity == "error"]
    warnings = [finding for finding in findings if finding.severity == "warning"]
    print(
        "Structural lint: %d error(s), %d warning(s), %d GDScript file(s) parsed."
        % (len(errors), len(warnings), len(docs))
    )
    for finding in findings[:20]:
        print("%s %s %s:%d %s" % (
            finding.severity.upper(),
            finding.code,
            finding.path,
            finding.line,
            finding.message,
        ))
    if len(findings) > 20:
        print("... %d more finding(s). See %s" % (len(findings) - 20, artifact_dir / "report.md"))
    else:
        print("Report: %s" % (artifact_dir / "report.md"))

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
