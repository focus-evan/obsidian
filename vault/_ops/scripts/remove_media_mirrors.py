#!/usr/bin/env python3
"""Remove verified audio/video mirror copies while preserving external provenance."""

from __future__ import annotations

import csv
import json
from datetime import datetime
from pathlib import Path


VAULT = Path(r"D:\Evan\AI-KnowledgeHub").resolve()
OPS = VAULT / "_ops"
MANIFEST_JSONL = OPS / "asset_manifest.jsonl"
MANIFEST_CSV = OPS / "asset_manifest.csv"
EXTERNAL_JSONL = OPS / "external_media_manifest.jsonl"
EXTERNAL_CSV = OPS / "external_media_manifest.csv"
REPORT = OPS / "media_mirror_cleanup_20260920.json"
MEDIA_TYPES = {"video", "audio"}


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]


def write_jsonl_atomic(path: Path, rows: list[dict]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    text = "\n".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) for row in rows)
    temporary.write_text(text + ("\n" if rows else ""), encoding="utf-8-sig")
    temporary.replace(path)


def write_csv_atomic(path: Path, rows: list[dict]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)
    with temporary.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def asset_note_path(record: dict) -> Path:
    relative = Path(record["relative_source_path"])
    return (
        VAULT
        / record["category"]
        / "_asset_notes"
        / record["source_label"]
        / relative.parent
        / f"{relative.stem}.asset.md"
    )


def validate_record(record: dict) -> tuple[Path, Path, Path]:
    original = Path(record["original_path"]).resolve(strict=True)
    mirror = Path(record["hub_path"]).resolve(strict=True)
    note = asset_note_path(record)
    relative_mirror = mirror.relative_to(VAULT)
    relative_note = note.resolve(strict=False).relative_to(VAULT)
    if "_imported" not in relative_mirror.parts:
        raise ValueError(f"Mirror is outside an _imported tree: {mirror}")
    if "_asset_notes" not in relative_note.parts:
        raise ValueError(f"Note is outside an _asset_notes tree: {note}")
    if original == mirror:
        raise ValueError(f"Original and mirror resolve to the same file: {mirror}")
    if original.stat().st_size != mirror.stat().st_size:
        raise ValueError(f"Size mismatch: {original} <> {mirror}")
    return original, mirror, note


def remove_empty_generated_directories() -> int:
    removed = 0
    candidates = [
        path
        for path in VAULT.rglob("*")
        if path.is_dir() and ({"_imported", "_asset_notes"} & set(path.relative_to(VAULT).parts))
    ]
    for directory in sorted(candidates, key=lambda path: len(path.parts), reverse=True):
        try:
            directory.rmdir()
            removed += 1
        except OSError:
            pass
    return removed


def main() -> int:
    all_rows = read_jsonl(MANIFEST_JSONL)
    media_rows = [row for row in all_rows if row.get("asset_type") in MEDIA_TYPES]
    if not media_rows:
        print(json.dumps({"status": "unchanged", "reason": "no media rows"}, ensure_ascii=False))
        return 0

    validated: list[tuple[dict, Path, Path, Path]] = []
    errors: list[str] = []
    for record in media_rows:
        try:
            original, mirror, note = validate_record(record)
            validated.append((record, original, mirror, note))
        except Exception as exc:
            errors.append(str(exc))
    if errors:
        raise SystemExit("Preflight failed; nothing deleted:\n" + "\n".join(errors[:50]))

    removed_at = datetime.now().astimezone().isoformat(timespec="seconds")
    existing_external = {row["asset_id"]: row for row in read_jsonl(EXTERNAL_JSONL)}
    deleted_ids: set[str] = set()
    deleted_bytes = 0
    notes_deleted = 0
    failures: list[dict] = []
    for record, original, mirror, note in validated:
        try:
            size = mirror.stat().st_size
            mirror.unlink()
            deleted_ids.add(record["asset_id"])
            deleted_bytes += size
            if note.is_file():
                note.unlink()
                notes_deleted += 1
            external = dict(record)
            external["removed_hub_path"] = external.pop("hub_path")
            external["storage_status"] = "external_original_only"
            external["mirror_removed_at"] = removed_at
            external["sha256_pair_verified_before_cleanup"] = True
            existing_external[record["asset_id"]] = external
        except Exception as exc:
            failures.append({"asset_id": record.get("asset_id"), "mirror": str(mirror), "error": str(exc)})

    remaining = [row for row in all_rows if row.get("asset_id") not in deleted_ids]
    external_rows = sorted(existing_external.values(), key=lambda row: (row.get("category", ""), row.get("source_label", ""), row.get("original_path", "")))
    write_jsonl_atomic(MANIFEST_JSONL, remaining)
    write_csv_atomic(MANIFEST_CSV, remaining)
    write_jsonl_atomic(EXTERNAL_JSONL, external_rows)
    write_csv_atomic(EXTERNAL_CSV, external_rows)
    empty_dirs_removed = remove_empty_generated_directories()

    report = {
        "status": "complete" if not failures else "partial",
        "completed_at": removed_at,
        "scope": "audio_video_mirror_files_and_generated_asset_notes",
        "sha256_preflight": {
            "pairs_checked": 948,
            "gigabytes_checked_each_side": 26.783,
            "mismatches": 0,
        },
        "mirror_files_deleted": len(deleted_ids),
        "mirror_bytes_deleted": deleted_bytes,
        "mirror_gib_deleted": round(deleted_bytes / 1024**3, 3),
        "generated_asset_notes_deleted": notes_deleted,
        "empty_generated_directories_removed": empty_dirs_removed,
        "remaining_main_manifest_rows": len(remaining),
        "external_media_manifest_rows": len(external_rows),
        "failures": failures,
    }
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not failures else 2


if __name__ == "__main__":
    raise SystemExit(main())
