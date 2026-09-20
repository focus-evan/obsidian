[CmdletBinding()]
param(
    [string]$Source = 'D:\Evan\AI-KnowledgeHub'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$pushMarker = Join-Path $repo '.allow-remote-push'
if (-not (Test-Path -LiteralPath $pushMarker)) {
    throw 'Remote push is disabled. Confirm the GitHub repository is private, then create .allow-remote-push in the repository root.'
}

Push-Location $repo
try {
    $before = @(git status --porcelain)
    if ($before.Count) { throw 'Repository has uncommitted changes before synchronization; resolve them first.' }

    git fetch origin
    if ($LASTEXITCODE -ne 0) { throw 'git fetch failed' }
    git show-ref --verify --quiet refs/remotes/origin/main
    if ($LASTEXITCODE -eq 0) {
        git pull --rebase origin main
        if ($LASTEXITCODE -ne 0) { throw 'git pull --rebase failed' }
    }

    python -X utf8 '.\scripts\sync_from_vault.py' --source $Source
    if ($LASTEXITCODE -ne 0) { throw 'Vault snapshot failed' }
    python -X utf8 '.\scripts\check_no_secrets.py'
    if ($LASTEXITCODE -ne 0) { throw 'Secret scan failed' }

    git add --all
    # Preserve source notes byte-for-byte; validate only repository-maintained files.
    git diff --cached --check -- . ':(exclude)vault/**' ':(exclude)snapshot_manifest.json'
    if ($LASTEXITCODE -ne 0) { throw 'git diff --cached --check failed' }
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'No knowledge changes to push.'
    } else {
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        git commit -m "Sync Obsidian knowledge $stamp"
        if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
    }

    # Always push, including a previously committed change from an earlier failed run.
    git push -u origin HEAD:main
    if ($LASTEXITCODE -ne 0) { throw 'git push failed' }
    Write-Host 'Obsidian knowledge snapshot pushed successfully.'
} finally {
    Pop-Location
}
