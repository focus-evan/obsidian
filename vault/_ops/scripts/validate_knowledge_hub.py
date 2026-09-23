#!/usr/bin/env python3
"""Validate AI-KnowledgeHub structure, metadata, links, and local RAG outputs."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml


ENTRY_FILES = [
    "00_开始这里.md",
    "00_Index.md",
    "00_Dashboard/00_操作台.md",
    "00_Dashboard/知识库健康度.md",
    "_ops/知识闭环运行规则.md",
    "80_复盘与版本演化/Obsidian知识闭环与友好入口_2026-09-23.md",
]


def split_frontmatter(text: str) -> tuple[str | None, str]:
    match = re.match(r"\A---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)\Z", text)
    if not match:
        return None, text
    return match.group(1), match.group(2)


def resolve_link(vault: Path, source: Path, target: str) -> bool:
    target = target.split("|", 1)[0].split("#", 1)[0].strip()
    if not target or target.startswith(("http://", "https://")):
        return True
    target = target.replace("\\", "/")
    candidates = []
    for base in (source.parent, vault):
        raw = base / target
        candidates.extend([raw, Path(str(raw) + ".md"), Path(str(raw) + ".base"), Path(str(raw) + ".canvas")])
    if any(path.exists() for path in candidates):
        return True
    name = Path(target).name
    return any(vault.rglob(name)) or any(vault.rglob(name + ".md")) or any(vault.rglob(name + ".base"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--vault", default=r"D:\Evan\AI-KnowledgeHub")
    args = parser.parse_args()
    vault = Path(args.vault)
    errors: list[str] = []
    warnings: list[str] = []

    markdown_files = list(vault.rglob("*.md"))
    typed = 0
    asset_notes = 0
    approved_knowledge = 0
    for path in markdown_files:
        text = path.read_text(encoding="utf-8-sig", errors="strict")
        if "\ufffd" in text:
            errors.append(f"replacement character: {path.relative_to(vault)}")
        frontmatter, _ = split_frontmatter(text)
        if frontmatter is None:
            continue
        try:
            props = yaml.safe_load(frontmatter) or {}
        except Exception as exc:  # noqa: BLE001
            errors.append(f"invalid frontmatter: {path.relative_to(vault)}: {exc}")
            continue
        if not isinstance(props, dict):
            errors.append(f"frontmatter is not mapping: {path.relative_to(vault)}")
            continue
        note_type = props.get("type")
        if note_type:
            typed += 1
        if note_type == "asset-note":
            asset_notes += 1
            for field in ("asset_id", "workflow_stage", "summary_status", "review_status", "rag_status"):
                if field not in props:
                    errors.append(f"asset-note missing {field}: {path.relative_to(vault)}")
        if note_type in {"knowledge-note", "process", "runbook", "architecture", "investment-framework"} and props.get("review_status") == "approved":
            approved_knowledge += 1
            if props.get("rag_status") not in {"indexed", "embedded", "evaluated", "approved"}:
                warnings.append(f"approved knowledge not indexed: {path.relative_to(vault)}")

    for path in vault.rglob("*.base"):
        try:
            parsed = yaml.safe_load(path.read_text(encoding="utf-8-sig"))
            if not isinstance(parsed, dict) or "views" not in parsed:
                errors.append(f"invalid base structure: {path.relative_to(vault)}")
        except Exception as exc:  # noqa: BLE001
            errors.append(f"invalid base yaml: {path.relative_to(vault)}: {exc}")

    for relative in ENTRY_FILES:
        path = vault / relative
        if not path.exists():
            errors.append(f"missing entry file: {relative}")
            continue
        text = path.read_text(encoding="utf-8-sig")
        for target in re.findall(r"!?\[\[([^\]]+)\]\]", text):
            if not resolve_link(vault, path, target):
                errors.append(f"broken entry link: {relative} -> {target}")

    index_meta_path = vault / "_rag" / "index" / "index_meta.json"
    eval_path = vault / "_rag" / "evals" / "latest_retrieval_eval.json"
    cases_path = vault / "_rag" / "evals" / "retrieval_cases.jsonl"
    try:
        index_meta = json.loads(index_meta_path.read_text(encoding="utf-8"))
        if index_meta.get("source_count") != approved_knowledge:
            errors.append(
                f"RAG source count mismatch: index={index_meta.get('source_count')} approved={approved_knowledge}"
            )
    except Exception as exc:  # noqa: BLE001
        errors.append(f"invalid RAG index metadata: {exc}")
        index_meta = {}
    try:
        evaluation = json.loads(eval_path.read_text(encoding="utf-8"))
        cases = [json.loads(line) for line in cases_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        if len(cases) != 100 or len({item["id"] for item in cases}) != 100:
            errors.append("retrieval cases must contain 100 unique ids")
        if evaluation.get("case_count") != 100 or evaluation.get("hit_rate", 0) < 0.95:
            errors.append(f"retrieval evaluation below gate: {evaluation.get('hit_rate')}")
    except Exception as exc:  # noqa: BLE001
        errors.append(f"invalid RAG evaluation: {exc}")
        evaluation = {}

    summary = {
        "markdown_files": len(markdown_files),
        "typed_notes": typed,
        "asset_notes": asset_notes,
        "approved_knowledge": approved_knowledge,
        "rag_sources": index_meta.get("source_count"),
        "rag_chunks": index_meta.get("chunk_count"),
        "retrieval_cases": evaluation.get("case_count"),
        "retrieval_hit_rate": evaluation.get("hit_rate"),
        "warnings": len(warnings),
        "errors": len(errors),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())

