param(
    [string]$HubRoot = "D:\Evan\AI-KnowledgeHub",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$migrationDate = "2026-09-23"
$changes = New-Object System.Collections.Generic.List[object]

function Get-YamlValue {
    param([string]$Frontmatter, [string]$Name)
    $pattern = '(?m)^' + [regex]::Escape($Name) + ':[ \t]*[''"]?([^\r\n''"]*)'
    $match = [regex]::Match($Frontmatter, $pattern)
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

function Add-YamlProperty {
    param([string]$Frontmatter, [string]$Name, [string]$Value)
    if ($Frontmatter -match "(?m)^$([regex]::Escape($Name)):[ \t]*") {
        return $Frontmatter
    }
    return $Frontmatter.TrimEnd() + "`n${Name}: ${Value}"
}

function Get-FileHashHex {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha.Dispose()
    }
}

$files = Get-ChildItem -LiteralPath $HubRoot -Recurse -Filter "*.md" -File -Force |
    Where-Object { $_.FullName -notlike "$HubRoot\.obsidian\*" }

foreach ($file in $files) {
    $personalRelative = $file.FullName.Substring($HubRoot.Length + 1).Replace("\", "/")
    if ($personalRelative.StartsWith("01_个人空间/") -or $personalRelative.StartsWith("_templates/")) { continue }
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $match = [regex]::Match($text, "\A---\r?\n(?<fm>.*?)\r?\n---\r?\n(?<body>[\s\S]*)\z", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) { continue }

    $frontmatter = $match.Groups["fm"].Value
    $body = $match.Groups["body"].Value
    $originalFrontmatter = $frontmatter
    $originalBody = $body
    $originalText = $text
    $relativePath = $file.FullName.Substring($HubRoot.Length + 1)
    $type = Get-YamlValue -Frontmatter $frontmatter -Name "type"
    $isAssetNote = $file.Name.EndsWith(".asset.md") -or ($frontmatter -match "(?m)^asset_id:[ \t]*")

    if ($isAssetNote) {
        if (-not $type) {
            $frontmatter = "type: asset-note`n" + $frontmatter
            $type = "asset-note"
        }
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "status" -Value "imported"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value "intake"
        $summaryValue = if ($body -match "(?s)## 摘要\s*待补充") { "pending" } else { "draft" }
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "summary_status" -Value $summaryValue
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "review_status" -Value "pending"

        # Repair a legacy interpolation bug without touching user-authored text.
        $originalPath = Get-YamlValue -Frontmatter $frontmatter -Name "original_path"
        $hubPath = Get-YamlValue -Frontmatter $frontmatter -Name "hub_path"
        $assetType = Get-YamlValue -Frontmatter $frontmatter -Name "asset_type"
        $category = Get-YamlValue -Frontmatter $frontmatter -Name "category"
        if ($body -match '(?m)^- 原始路径：\$\(@\{') {
            $body = [regex]::Replace($body, '(?m)^- 原始路径：.*$', "- 原始路径：``$originalPath``", 1)
        }
        if ($body -match '(?m)^- 知识库路径：\$\(@\{') {
            $body = [regex]::Replace($body, '(?m)^- 知识库路径：.*$', "- 知识库路径：``$hubPath``", 1)
        }
        if ($body -match '(?m)^- 类型：\$\(@\{') {
            $body = [regex]::Replace($body, '(?m)^- 类型：.*$', "- 类型：``$assetType``", 1)
        }
        if ($body -match '(?m)^- 分类：\$\(@\{') {
            $body = [regex]::Replace($body, '(?m)^- 分类：.*$', "- 分类：``$category``", 1)
        }
    }
    elseif ($type -in @("knowledge-note", "process", "runbook", "architecture", "investment-framework")) {
        $status = Get-YamlValue -Frontmatter $frontmatter -Name "status"
        $reviewStatus = if ($status -in @("active", "approved", "completed", "done")) { "approved" } else { "pending" }
        $workflowStage = if ($reviewStatus -eq "approved") { "validated" } else { "review" }
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value $workflowStage
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "review_status" -Value $reviewStatus
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "rag_status" -Value "pending"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "publish_status" -Value "internal"
    }
    elseif ($type -eq "report-asset") {
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value "delivery"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "publish_status" -Value "pending"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "feedback_status" -Value "none"
    }
    elseif ($type -eq "feedback") {
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value "feedback"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "resolution_status" -Value "pending"
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "eval_added" -Value "false"
    }
    elseif ($type -eq "action") {
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value "action"
    }
    elseif ($type -eq "codex-session") {
        $frontmatter = Add-YamlProperty -Frontmatter $frontmatter -Name "workflow_stage" -Value "execution"
    }

    if (-not $type -and -not $isAssetNote) { continue }
    if ($frontmatter -eq $originalFrontmatter -and $body -eq $originalBody) { continue }
    $newText = "---`n$($frontmatter.Trim())`n---`n$body"
    if ($newText -eq $originalText) { continue }

    $changes.Add([pscustomobject]@{
        path = $relativePath
        type = $type
        original_sha256 = Get-FileHashHex -Text $originalText
        migrated_sha256 = Get-FileHashHex -Text $newText
        migrated_at = $migrationDate
    })
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($file.FullName, $newText, $utf8NoBom)
    }
}

if (-not $DryRun) {
    $logPath = Join-Path $HubRoot "_ops\knowledge_metadata_migration_20260923.csv"
    $changes | Sort-Object path | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8
}

Write-Output ("Scanned markdown files: " + $files.Count)
Write-Output ("Changed markdown files: " + $changes.Count)
if ($changes.Count -gt 0) {
    $changes | Select-Object -First 25 | ForEach-Object { Write-Output ("  " + $_.path) }
}
if ($DryRun) { Write-Output "Dry run only: no files changed." }
