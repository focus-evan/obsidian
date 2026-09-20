[CmdletBinding()]
param(
    [string]$Source = '',
    [string]$PythonExe = ''
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$repoVault = [System.IO.Path]::GetFullPath((Join-Path $repo 'vault')).TrimEnd('\')
if (-not $Source) { $Source = $repoVault }
$sourceRoot = [System.IO.Path]::GetFullPath($Source).TrimEnd('\')
$directVault = $sourceRoot -eq $repoVault
if (-not $PythonExe) {
    $bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path -LiteralPath $bundledPython) { $PythonExe = $bundledPython }
}
if (-not $PythonExe) {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { $PythonExe = $python.Source }
}
if (-not $PythonExe -or -not (Test-Path -LiteralPath $PythonExe)) {
    throw 'Python executable was not found. Pass -PythonExe with an existing Python 3.11+ path.'
}
$pushMarker = Join-Path $repo '.allow-remote-push'
if (-not (Test-Path -LiteralPath $pushMarker)) {
    throw 'Remote push is disabled. Confirm the GitHub repository is private, then create .allow-remote-push in the repository root.'
}

Push-Location $repo
try {
    $before = @(git status --porcelain)
    if ($before.Count -and -not $directVault) { throw 'Repository has uncommitted changes before synchronization; resolve them first.' }
    if ($directVault) {
        foreach ($line in $before) {
            $changedPath = $line.Substring(3).Replace('\', '/')
            if ($changedPath.Contains(' -> ')) { $changedPath = $changedPath.Split(' -> ')[-1] }
            if (-not $changedPath.StartsWith('vault/')) {
                throw "Direct-vault mode found an unrelated change outside vault/: $changedPath"
            }
        }
    }

    git fetch origin
    if ($LASTEXITCODE -ne 0) { throw 'git fetch failed' }
    git show-ref --verify --quiet refs/remotes/origin/main
    if ($LASTEXITCODE -eq 0) {
        $counts = (git rev-list --left-right --count HEAD...origin/main) -split '\s+'
        $behind = [int]$counts[1]
        if ($behind -gt 0 -and $before.Count) {
            throw 'Remote main is ahead while local vault changes exist; stop and reconcile before committing.'
        }
        if ($behind -gt 0) {
            git pull --rebase origin main
            if ($LASTEXITCODE -ne 0) { throw 'git pull --rebase failed' }
        }
    }

    if (-not $directVault) {
        & $PythonExe -X utf8 '.\scripts\sync_from_vault.py' --source $sourceRoot
        if ($LASTEXITCODE -ne 0) { throw 'Vault snapshot failed' }
    }
    & $PythonExe -X utf8 '.\scripts\check_no_secrets.py'
    if ($LASTEXITCODE -ne 0) { throw 'Secret scan failed' }

    if ($directVault) { git add -- 'vault' } else { git add --all }
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
