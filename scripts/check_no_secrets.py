#!/usr/bin/env python3
"""Fail when the staged knowledge snapshot contains obvious credential material."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKIP = {Path("scripts/check_no_secrets.py"), Path("snapshot_manifest.json")}
TEXT_EXTENSIONS = {".md", ".txt", ".json", ".jsonl", ".csv", ".tsv", ".yaml", ".yml", ".toml", ".py", ".ps1", ".srt", ".ass", ".base"}
PATTERNS = {
    "private-key": re.compile(r"BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY"),
    "aws-access-key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "alibaba-access-key": re.compile(r"\bLTAI[A-Za-z0-9]{12,24}\b"),
    "openai-style-key": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}"),
    "credential-assignment": re.compile(r"(?i)(?:api[_-]?key|access[_-]?key|secret[_-]?key|password|token)\s*[:=]\s*(?:['\"][^'\"]{6,}|[^\s#]{6,})"),
}
SENSITIVE_NAMES = re.compile(r"(?i)(?:^|/)(?:\.env(?:\..*)?|id_rsa|id_ed25519|credentials.*\.json|.*\.(?:pem|p12|pfx|key))$")


def main() -> int:
    failures: list[str] = []
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        relative = path.relative_to(REPO_ROOT)
        if relative in SKIP:
            continue
        portable = relative.as_posix()
        if SENSITIVE_NAMES.search(portable):
            failures.append(f"sensitive filename: {portable}")
            continue
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            continue
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        for name, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                failures.append(f"{name}: {portable}:{line}")
    if failures:
        print("Potential secrets detected; values are intentionally hidden:")
        print("\n".join(failures[:100]))
        return 2
    print("OK: no obvious credential material detected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
