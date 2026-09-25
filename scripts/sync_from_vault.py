#!/usr/bin/env python3
"""Mirror Git-friendly Obsidian knowledge files into this repository."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from datetime import datetime
from pathlib import Path


DEFAULT_SOURCE = Path(r"D:\Evan\AI-KnowledgeHub")
REPO_ROOT = Path(__file__).resolve().parents[1]
DESTINATION = REPO_ROOT / "vault"
MANIFEST = REPO_ROOT / "snapshot_manifest.json"

ALLOWED_EXTENSIONS = {
    ".md",
    ".txt",
    ".json",
    ".jsonl",
    ".csv",
    ".tsv",
    ".yaml",
    ".yml",
    ".toml",
    ".base",
    ".py",
    ".ps1",
    ".srt",
    ".ass",
}

EXCLUDED_RELATIVE_PATHS = {
    ".obsidian/bookmarks.json",
    ".obsidian/workspace.json",
    "00_Inbox/_imported/D_Evan_Files/optimization/login_enhancement_summary.md",
    "00_Inbox/_imported/D_Evan_Files/optimization/qmt_integration_plan.md",
    "00_Inbox/_imported/D_Evan_Files/devops/nacos-integration/SOLUTION_OVERVIEW.md",
    "00_Inbox/_imported/D_Evan_Files/code_readme/oss-upload-user.txt",
}

EXCLUDED_PREFIXES = {
    "01_个人空间/",
    "00_Inbox/_imported/D_Evan_Files/optimization/",
    "60_AI工具与工程/_imported/D_Evan_Files/optimization/",
}


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def wanted(relative: Path) -> bool:
    portable = relative.as_posix()
    if portable in EXCLUDED_RELATIVE_PATHS:
        return False
    if any(portable.startswith(prefix) for prefix in EXCLUDED_PREFIXES):
        return False
    if any(part in {".git", "__pycache__"} for part in relative.parts):
        return False
    return relative.suffix.lower() in ALLOWED_EXTENSIONS


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default=str(DEFAULT_SOURCE), help="AI-KnowledgeHub root")
    args = parser.parse_args()

    source = Path(args.source).resolve(strict=True)
    destination = DESTINATION.resolve(strict=False)
    if source == destination or source in destination.parents or destination in source.parents:
        raise SystemExit("Source and destination must not overlap")
    destination.mkdir(parents=True, exist_ok=True)

    selected = {
        path.relative_to(source): path
        for path in source.rglob("*")
        if path.is_file() and wanted(path.relative_to(source))
    }
    copied = 0
    unchanged = 0
    for relative, origin in sorted(selected.items(), key=lambda item: item[0].as_posix()):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_file() and origin.stat().st_size == target.stat().st_size and digest(origin) == digest(target):
            unchanged += 1
            continue
        temporary = target.with_suffix(target.suffix + ".tmp")
        shutil.copy2(origin, temporary)
        temporary.replace(target)
        copied += 1

    removed = 0
    for target in sorted((path for path in destination.rglob("*") if path.is_file()), reverse=True):
        relative = target.relative_to(destination)
        if relative not in selected:
            target.unlink()
            removed += 1
    for directory in sorted((path for path in destination.rglob("*") if path.is_dir()), key=lambda path: len(path.parts), reverse=True):
        try:
            directory.rmdir()
        except OSError:
            pass

    rows = [
        {
            "path": relative.as_posix(),
            "bytes": origin.stat().st_size,
            "sha256": digest(origin),
        }
        for relative, origin in sorted(selected.items(), key=lambda item: item[0].as_posix())
    ]
    payload = {
        "schema_version": 1,
        "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "source": str(source),
        "destination": str(destination),
        "files": len(rows),
        "bytes": sum(row["bytes"] for row in rows),
        "copied_or_updated": copied,
        "unchanged": unchanged,
        "removed": removed,
        "excluded_sensitive_paths": sorted(EXCLUDED_RELATIVE_PATHS),
        "excluded_sensitive_prefixes": sorted(EXCLUDED_PREFIXES),
        "entries": rows,
    }
    temporary_manifest = MANIFEST.with_suffix(".json.tmp")
    temporary_manifest.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary_manifest.replace(MANIFEST)
    print(json.dumps({key: value for key, value in payload.items() if key != "entries"}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
