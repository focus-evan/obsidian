---
type: runbook
domain: operations
version: 0.1
created: 2026-05-30
status: active
tags:
  - runbook
  - system/operations
---
# Operations Runbook

## 打开知识库

用 Obsidian 打开：

```text
D:/Evan/AI-KnowledgeHub
```

## 增量导入

当原始目录新增文档或视频后，运行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Evan\AI-KnowledgeHub\_ops\scripts\import_knowledge_assets.ps1"
```

脚本会：

- 排除 `D:/Evan/Codes`。
- 排除程序运行目录和缓存目录。
- 复制文档、表格、PPT、字幕、JSON、SQL 和选定图片等知识资产。
- 跳过 MP4、MOV、MKV、AVI、WMV、MP3、WAV；音视频只保留在原始媒体库，并通过外部媒体清单追踪。
- 更新 `_ops/asset_manifest.csv` 和 `_ops/asset_manifest.jsonl`。

## 日常整理流程

1. 新资料先进入 `00_Inbox` 或对应分类的 `_imported`。
2. 高价值资料生成摘要卡片。
3. 摘要卡片补充标签、来源、适用场景。
4. 审核后将 `status` 从 `draft` 改为 `approved`。
5. RAG 入库后将 manifest 中的 `rag_status` 更新为 `embedded` 或 `approved`。

## 每周维护

- 检查 `00_Inbox` 是否有未分类资料。
- 检查 `_rag/feedback` 是否有未处理反馈。
- 检查高价值新资料是否已生成摘要。
- 检查对外内容是否存在合规风险。

## 安全边界

- 不把 API key、账号、token、证书放入 RAG。
- 不把未脱敏用户数据放入对外 Agent。
- 视频素材使用前检查授权状态。
- 投研输出保持方法论和教育定位，不输出公开买卖指令。
