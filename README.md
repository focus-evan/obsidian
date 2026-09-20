# AI-KnowledgeHub Git Snapshot

This repository stores the Git-friendly knowledge, configuration, templates, manifests, and Codex synchronization state. The scheduled Codex sync writes directly to `D:\Evan\Codes\obsidian\vault`.

The `vault/` directory is the active scheduled-sync destination. `scripts/sync_from_vault.py` remains available only for importing a separate external vault. Raw SQL dumps, images, office binaries, audio, and video remain outside Git. Two source notes with password-like content are also excluded pending manual review.

## Refresh locally

```powershell
python -X utf8 .\scripts\check_no_secrets.py
```

## Commit and push

`scripts\sync_and_push.ps1` requires a repository-root marker named `.allow-remote-push`. Create that marker only after confirming the configured remote is private or after the user explicitly authorizes publishing to a public remote. The marker is ignored by Git.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync_and_push.ps1 -Source 'D:\Evan\Codes\obsidian\vault' -PythonExe 'C:\Users\Evan\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
```

The three-day Codex Obsidian automation writes directly under `vault/` and calls this script only after its note/state validation succeeds. The script refuses unrelated changes outside `vault/`, fetches first, rejects a dirty-behind state, scans for secrets, stages only `vault/`, and pushes without force.
