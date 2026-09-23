param(
    [string]$HubRoot = "D:\Evan\AI-KnowledgeHub"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$today = (Get-Date).ToString("yyyy-MM-dd")
$now = (Get-Date).ToString("s")

$allFiles = Get-ChildItem -LiteralPath $HubRoot -Recurse -File -Force -ErrorAction SilentlyContinue
$markdownFiles = $allFiles | Where-Object Extension -eq ".md"
$manifestPath = Join-Path $HubRoot "_ops\asset_manifest.csv"
$manifestRows = if (Test-Path -LiteralPath $manifestPath) { @(Import-Csv -LiteralPath $manifestPath) } else { @() }
$evalPath = Join-Path $HubRoot "_rag\evals\latest_retrieval_eval.json"
$latestEval = if (Test-Path -LiteralPath $evalPath) { Get-Content -LiteralPath $evalPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

$typed = 0
$assetNotes = 0
$knowledgeObjects = 0
$approvedKnowledge = 0
$ragReady = 0
$ragIndexed = 0
$pendingActions = 0
$pendingFeedback = 0
$draftKnowledge = 0
$reviewDue = 0
$publishPending = 0

foreach ($file in $markdownFiles) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $typeMatch = [regex]::Match($text, '(?m)^type:[ \t]*[''"]?([^\r\n''"]+)')
    if (-not $typeMatch.Success) { continue }
    $typed++
    $type = $typeMatch.Groups[1].Value.Trim()
    $get = {
        param($name)
        $pattern = '(?m)^' + [regex]::Escape($name) + ':[ \t]*[''"]?([^\r\n''"]*)'
        $m = [regex]::Match($text, $pattern)
        if ($m.Success) { return $m.Groups[1].Value.Trim() }
        return ""
    }
    $status = & $get "status"
    $reviewStatus = & $get "review_status"
    $ragStatus = & $get "rag_status"
    $publishStatus = & $get "publish_status"
    $reviewAfter = & $get "review_after"

    if ($type -eq "asset-note") { $assetNotes++ }
    if ($type -in @("knowledge-note", "process", "runbook", "architecture", "investment-framework")) {
        $knowledgeObjects++
        if ($reviewStatus -eq "approved") { $approvedKnowledge++ }
        if ($reviewStatus -eq "approved" -and $ragStatus -in @("pending", "ready")) { $ragReady++ }
        if ($ragStatus -in @("embedded", "evaluated", "approved")) { $ragIndexed++ }
        if ($reviewStatus -ne "approved") { $draftKnowledge++ }
        if ($reviewAfter -and $reviewAfter -le $today) { $reviewDue++ }
    }
    if ($type -eq "action" -and $status -notin @("done", "completed", "cancelled")) { $pendingActions++ }
    if ($type -eq "feedback" -and $status -notin @("done", "resolved", "closed")) { $pendingFeedback++ }
    if ($type -eq "report-asset" -and $publishStatus -notin @("published", "unchanged", "not-required")) { $publishPending++ }
}

$manifestPending = @($manifestRows | Where-Object rag_status -eq "pending").Count
$manifestIndexed = @($manifestRows | Where-Object rag_status -in @("embedded", "evaluated", "approved")).Count
$typeCoverage = if ($markdownFiles.Count -gt 0) { [math]::Round(100 * $typed / $markdownFiles.Count, 1) } else { 0 }
$ragState = if ($latestEval -and $latestEval.hit_rate -ge 0.95 -and $ragReady -eq 0 -and $ragIndexed -ge $approvedKnowledge) {
    "🟢 本地检索闭环已验证"
} elseif ($ragIndexed -gt 0 -or $manifestIndexed -gt 0) {
    "🟡 已有索引，仍需完成评测"
} else {
    "🔴 尚未形成真实索引记录"
}
$metadataState = if ($typeCoverage -ge 90) { "🟢 对象化覆盖良好" } elseif ($typeCoverage -ge 60) { "🟡 仍有未对象化笔记" } else { "🔴 对象化覆盖不足" }
$feedbackState = if ($pendingFeedback -gt 0) { "🟡 有待处理反馈" } else { "🟢 当前无待处理反馈" }

$health = @"
---
type: dashboard
domain: knowledge-governance
status: active
created: 2026-09-23
updated: $today
cssclasses:
  - knowledge-hub-home
tags:
  - dashboard/health
  - system/obsidian
---
# 知识库健康度

> [!info] 自动快照
> 生成时间：$now。该页由 `_ops/scripts/update_vault_health.ps1` 生成。

## 一眼判断

| 维度 | 当前状态 | 关键数字 |
|---|---|---:|
| 对象化 | $metadataState | $typed / $($markdownFiles.Count) 篇，覆盖 $typeCoverage% |
| 知识审核 | 🟡 持续推进 | 已批准 $approvedKnowledge，待审核 $draftKnowledge |
| RAG闭环 | $ragState | 待入库 $ragReady，已索引 $ragIndexed，Hit@5 $(if($latestEval){[math]::Round(100*$latestEval.hit_rate,1).ToString()+'%'}else{'未评测'}) |
| 行动闭环 | $(if($pendingActions -gt 0){"🟡 有未完成行动"}else{"🟢 无未完成行动"}) | $pendingActions |
| 发布闭环 | $(if($publishPending -gt 0){"🟡 有待发布/核验报告"}else{"🟢 当前无待发布报告"}) | $publishPending |
| 反馈闭环 | $feedbackState | $pendingFeedback |

## 资产规模

| 指标 | 数量 |
|---|---:|
| 全部文件 | $($allFiles.Count) |
| Markdown | $($markdownFiles.Count) |
| 资产说明页 | $assetNotes |
| 可复用知识对象 | $knowledgeObjects |
| 资产清单记录 | $($manifestRows.Count) |
| 清单中待处理资产 | $manifestPending |
| 已到复查日期 | $reviewDue |

## 立即处理

- [[00_Dashboard/00_操作台|进入操作台]]
- [[00_Dashboard/知识闭环.base|处理知识审核和RAG队列]]
- [[00_Dashboard/资产入库队列.base|处理资产摘要队列]]
- [[00_Dashboard/发布与反馈.base|处理发布和反馈]]
- [[_ops/知识闭环运行规则|查看闭环规则]]

## 当前结论

1. 资产采集和对象化入口已经可用。
2. 只有 ``review_status: approved`` 的知识对象才允许进入 RAG 准备队列。
3. ``rag_status`` 必须由真实索引任务回写，不能因为生成了摘要就标记为已入库。
4. ``publish_status`` 必须经过线上链接、HTTP状态和内容哈希验证后才能写成 ``published`` 或 ``unchanged``。
5. 反馈完成后需要更新知识卡，并决定是否加入评测集。
"@

$healthPath = Join-Path $HubRoot "00_Dashboard\知识库健康度.md"
$jsonPath = Join-Path $HubRoot "_ops\vault_health.json"
[System.IO.File]::WriteAllText($healthPath, $health, $utf8NoBom)

$healthJson = [ordered]@{
    generated_at = $now
    total_files = $allFiles.Count
    markdown_files = $markdownFiles.Count
    typed_notes = $typed
    type_coverage_percent = $typeCoverage
    asset_notes = $assetNotes
    knowledge_objects = $knowledgeObjects
    approved_knowledge = $approvedKnowledge
    draft_knowledge = $draftKnowledge
    rag_ready = $ragReady
    rag_indexed = $ragIndexed
    pending_actions = $pendingActions
    pending_feedback = $pendingFeedback
    publish_pending = $publishPending
    manifest_rows = $manifestRows.Count
    manifest_pending = $manifestPending
    manifest_indexed = $manifestIndexed
    review_due = $reviewDue
    retrieval_eval_cases = if ($latestEval) { $latestEval.case_count } else { 0 }
    retrieval_hit_rate = if ($latestEval) { $latestEval.hit_rate } else { $null }
}
[System.IO.File]::WriteAllText($jsonPath, ($healthJson | ConvertTo-Json -Depth 4), $utf8NoBom)

Write-Output ("Health dashboard: " + $healthPath)
Write-Output ("Metadata coverage: " + $typeCoverage + "%")
