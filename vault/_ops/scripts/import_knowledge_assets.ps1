param(
    [string]$HubRoot = "D:\Evan\AI-KnowledgeHub",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$importedAt = (Get-Date).ToString("s")

$sourceSpecs = @(
    @{ Root = "D:\Evan\Files"; Label = "D_Evan_Files"; IncludeImages = $false },
    @{ Root = "D:\Evan\Courses"; Label = "D_Evan_Courses"; IncludeImages = $false },
    @{ Root = "D:\Evan\video"; Label = "D_Evan_video"; IncludeImages = $true },
    @{ Root = "D:\aigc"; Label = "D_aigc"; IncludeImages = $true },
    @{ Root = "C:\Users\bzsj_\Desktop"; Label = "Desktop"; IncludeImages = $false },
    @{ Root = "C:\Users\bzsj_\Documents"; Label = "Documents"; IncludeImages = $false },
    @{ Root = "C:\Users\bzsj_\Downloads"; Label = "Downloads"; IncludeImages = $false }
)

$documentExts = @(
    ".md", ".txt", ".pdf", ".docx", ".doc", ".xlsx", ".xls", ".csv", ".tsv",
    ".pptx", ".ppt", ".xmind", ".srt", ".ass", ".json", ".sql"
)
$mediaExts = @(".mp4", ".mov", ".mkv", ".avi", ".wmv", ".mp3", ".wav")
$imageExts = @(".png", ".jpg", ".jpeg", ".webp", ".gif")

$categoryDirs = @(
    "00_Inbox",
    "10_S老师IP资产",
    "20_投研方法论",
    "30_产业研究库",
    "40_S5000AI产品库",
    "50_业务运营增长",
    "60_AI工具与工程",
    "70_数据与系统",
    "80_复盘与版本演化",
    "99_Archive",
    "_attachments",
    "_ops",
    "_rag",
    "_templates"
)

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $Path | Out-Null
        }
    }
}

function Escape-YamlSingleQuoted {
    param([string]$Value)
    return ($Value -replace "'", "''")
}

function Get-RelativePathFromRoot {
    param([string]$Root, [string]$Path)
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd("\", "/")
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.Length -le $rootFull.Length) { return "" }
    return $pathFull.Substring($rootFull.Length).TrimStart("\", "/")
}

function Get-PathId {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString("x2") }) -join "").Substring(0, 16)
    }
    finally {
        $sha.Dispose()
    }
}

function Test-IsExcludedPath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path).ToLowerInvariant()
    $excludedPrefixes = @(
        "d:\evan\codes\",
        "d:\evan\programs\",
        "d:\evan\ai-knowledgehub\",
        "d:\aigc\chrome-digital-human-profile\",
        "d:\aigc\tmp_drafts_inspect\"
    )
    foreach ($prefix in $excludedPrefixes) {
        if ($full.StartsWith($prefix)) { return $true }
    }
    $blockedParts = @("\.git\", "\node_modules\", "\venv\", "\.venv\", "\__pycache__\", "\dist\", "\build\", "\miniprogram_npm\", "\target\")
    foreach ($part in $blockedParts) {
        if ($full.Contains($part)) { return $true }
    }
    return $false
}

function Get-AssetType {
    param([string]$Extension)
    $ext = $Extension.ToLowerInvariant()
    if ($mediaExts -contains $ext) {
        if (@(".mp4", ".mov", ".mkv", ".avi", ".wmv") -contains $ext) { return "video" }
        return "audio"
    }
    if ($imageExts -contains $ext) { return "image" }
    if (@(".srt", ".ass") -contains $ext) { return "subtitle" }
    if (@(".xlsx", ".xls", ".csv", ".tsv") -contains $ext) { return "spreadsheet" }
    if (@(".pptx", ".ppt") -contains $ext) { return "presentation" }
    if (@(".sql", ".json") -contains $ext) { return "data" }
    return "document"
}

function Get-Category {
    param([string]$Path)
    $p = $Path.ToLowerInvariant()

    if ($p -match "s5000|小程序|产品战略|产品库|asset_allocation|持仓诊断|财报体检|投资逻辑复盘|市场解读|估值训练营|agent_strategy|qa-concierge") {
        return "40_S5000AI产品库"
    }
    if ($p -match "选股|题材雷达|投研|股票|战法|策略|情绪|北向|宏观|大盘|资产配置|持仓|估值|财报|利润池|总龙头|同题材|s100|五维分析|五层六维") {
        return "20_投研方法论"
    }
    if ($p -match "产业链|产业报告|具身智能|商业航天|芯片|半导体|存储|算力|ai全产业|新能源|机器人|低空|英伟达|茅台|行业|赛道") {
        return "30_产业研究库"
    }
    if ($p -match "aigc|\\video\\|视频|ip-video|剪映|jianying|分镜|storyboard|素材|拍摄|直播|脚本|口播|数字人|voiceover|字幕|fed_rate|芯片韬定律|黄埔语料库|realtime-video|course|课程") {
        return "10_S老师IP资产"
    }
    if ($p -match "学员|作业|问题列表|答疑|私域|运营|增长|转化|销售|社群|高阶|黄埔|计划表") {
        return "50_业务运营增长"
    }
    if ($p -match "ai工具|提示词|prompt|大模型|rag|obsidian|dify|n8n|知识库|llm|接口|自动化|工作流|agent|工具") {
        return "60_AI工具与工程"
    }
    if ($p -match "wiki|database|数据库|sql|schema|table|数据|日志|chat_history|stockinfo|candidate|fund_|training_feedback|training_qa") {
        return "70_数据与系统"
    }
    if ($p -match "复盘|总结|review|report|优化|升级|版本|月报|周报|日报|开发计划") {
        return "80_复盘与版本演化"
    }
    return "00_Inbox"
}

function Get-DomainTag {
    param([string]$Category)
    switch ($Category) {
        "10_S老师IP资产" { return "domain/ip" }
        "20_投研方法论" { return "domain/investment" }
        "30_产业研究库" { return "domain/industry" }
        "40_S5000AI产品库" { return "domain/s5000ai" }
        "50_业务运营增长" { return "domain/operations" }
        "60_AI工具与工程" { return "domain/ai-engineering" }
        "70_数据与系统" { return "domain/data-system" }
        "80_复盘与版本演化" { return "domain/review" }
        default { return "domain/inbox" }
    }
}

function New-AssetNoteText {
    param(
        [pscustomobject]$Record,
        [string]$VaultRelativePath
    )
    $title = $Record.title
    $assetTag = "asset/$($Record.asset_type)"
    $domainTag = Get-DomainTag -Category $Record.category
    $original = Escape-YamlSingleQuoted -Value $Record.original_path
    $hubPath = Escape-YamlSingleQuoted -Value $Record.hub_path
    $vaultRelYaml = Escape-YamlSingleQuoted -Value $VaultRelativePath

    $embedLine = ""
    if ($Record.asset_type -in @("video", "audio", "image")) {
        $embedLine = "![[${VaultRelativePath}]]"
    }
    else {
        $embedLine = "[[${VaultRelativePath}]]"
    }

    return @"
---
asset_id: '$($Record.asset_id)'
asset_type: '$($Record.asset_type)'
category: '$($Record.category)'
source_label: '$($Record.source_label)'
original_path: '$original'
hub_path: '$hubPath'
vault_relative_path: '$vaultRelYaml'
extension: '$($Record.extension)'
size_bytes: $($Record.size_bytes)
source_last_write_time: '$($Record.source_last_write_time)'
imported_at: '$($Record.imported_at)'
rag_status: 'pending'
feedback_status: 'none'
confidential_level: 'internal'
tags:
  - '$assetTag'
  - '$domainTag'
  - 'status/pending-summary'
---
# $title

$embedLine

## 资产信息
- 原始路径：`$($Record.original_path)`
- 知识库路径：`$($Record.hub_path)`
- 类型：`$($Record.asset_type)`
- 分类：`$($Record.category)`
- RAG 状态：待入库

## 摘要
待补充。建议由摘要 Agent 读取原文件后生成 5-10 行摘要，并标注适用场景。

## 可用于
- S 老师 IP 语料 / 投研方法 / 产品设计 / 内容生产 / 运营复盘 / 数据系统，按实际情况勾选。

## 反馈回写
- 修正意见：
- 关联问题：
- 审核人：
- 是否进入正式知识库：
"@
}

Ensure-Directory -Path $HubRoot
foreach ($dir in $categoryDirs) {
    Ensure-Directory -Path (Join-Path $HubRoot $dir)
}

$records = New-Object System.Collections.Generic.List[object]
$errors = New-Object System.Collections.Generic.List[object]

foreach ($spec in $sourceSpecs) {
    $root = $spec.Root
    if (-not (Test-Path -LiteralPath $root)) { continue }

    $files = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            if (Test-IsExcludedPath -Path $file.FullName) { continue }
            $ext = $file.Extension.ToLowerInvariant()
            # Audio/video remain in their original media libraries. The knowledge hub stores
            # text, metadata, storyboards, authorization records, and selected images only.
            if ($mediaExts -contains $ext) { continue }
            $allowed = ($documentExts -contains $ext) -or (($spec.IncludeImages -eq $true) -and ($imageExts -contains $ext))
            if (-not $allowed) { continue }

            $category = Get-Category -Path $file.FullName
            $assetType = Get-AssetType -Extension $ext
            $relative = Get-RelativePathFromRoot -Root $root -Path $file.FullName
            $destDir = Join-Path $HubRoot (Join-Path $category (Join-Path "_imported" $spec.Label))
            $relativeDir = Split-Path -Path $relative -Parent
            if ($relativeDir) {
                $destDir = Join-Path $destDir $relativeDir
            }
            $destPath = Join-Path $destDir $file.Name

            Ensure-Directory -Path $destDir
            $copyNeeded = $true
            if (Test-Path -LiteralPath $destPath) {
                $existing = Get-Item -LiteralPath $destPath
                if ($existing.Length -eq $file.Length -and $existing.LastWriteTime -eq $file.LastWriteTime) {
                    $copyNeeded = $false
                }
            }
            if ($copyNeeded -and -not $DryRun) {
                Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force
                try {
                    (Get-Item -LiteralPath $destPath).LastWriteTime = $file.LastWriteTime
                }
                catch {
                    # A few Office templates can refuse timestamp changes on Windows.
                    # The file copy is still valid, so keep the asset in the manifest.
                }
            }

            $assetId = Get-PathId -Text "$($file.FullName)|$($file.Length)|$($file.LastWriteTimeUtc.Ticks)"
            $record = [pscustomobject]@{
                asset_id = $assetId
                title = $file.BaseName
                asset_type = $assetType
                category = $category
                source_label = $spec.Label
                source_root = $root
                original_path = $file.FullName
                hub_path = $destPath
                relative_source_path = $relative
                extension = $ext
                size_bytes = $file.Length
                source_last_write_time = $file.LastWriteTime.ToString("s")
                imported_at = $importedAt
                rag_status = "pending"
                feedback_status = "none"
                confidential_level = "internal"
            }
            $records.Add($record)

            if ($assetType -in @("video", "audio", "image", "presentation", "spreadsheet", "document") -and $ext -notin @(".md", ".txt")) {
                $noteDir = Join-Path $HubRoot (Join-Path $category (Join-Path "_asset_notes" $spec.Label))
                if ($relativeDir) {
                    $noteDir = Join-Path $noteDir $relativeDir
                }
                Ensure-Directory -Path $noteDir
                $notePath = Join-Path $noteDir ("$($file.BaseName).asset.md")
                $vaultRel = Get-RelativePathFromRoot -Root $HubRoot -Path $destPath
                $vaultRel = $vaultRel -replace "\\", "/"
                if (-not $DryRun) {
                    $noteText = New-AssetNoteText -Record $record -VaultRelativePath $vaultRel
                    Set-Content -LiteralPath $notePath -Value $noteText -Encoding UTF8
                }
            }
        }
        catch {
            $errors.Add([pscustomobject]@{
                source = $file.FullName
                error = $_.Exception.Message
            })
        }
    }
}

$manifestCsv = Join-Path $HubRoot "_ops\asset_manifest.csv"
$manifestJsonl = Join-Path $HubRoot "_ops\asset_manifest.jsonl"
$errorsCsv = Join-Path $HubRoot "_ops\import_errors.csv"

if (-not $DryRun) {
    $records | Sort-Object category, source_label, original_path | Export-Csv -LiteralPath $manifestCsv -NoTypeInformation -Encoding UTF8
    $jsonLines = $records | Sort-Object category, source_label, original_path | ForEach-Object { $_ | ConvertTo-Json -Compress }
    Set-Content -LiteralPath $manifestJsonl -Value $jsonLines -Encoding UTF8
    if ($errors.Count -gt 0) {
        $errors | Export-Csv -LiteralPath $errorsCsv -NoTypeInformation -Encoding UTF8
    }
}

$summary = $records |
    Group-Object category |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            category = $_.Name
            files = $_.Count
            size_gb = [math]::Round(($_.Group | Measure-Object size_bytes -Sum).Sum / 1GB, 3)
        }
    }

$summary | Format-Table -AutoSize
"Imported records: $($records.Count)"
"Errors: $($errors.Count)"
if ($DryRun) { "Dry run only: no files copied." }
