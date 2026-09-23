---
type: vault-home
domain: knowledge-hub
version: 0.2
created: 2026-05-30
status: active
tags:
  - hub/home
  - system/obsidian
  - system/rag
---
# AI-KnowledgeHub

这是公司 AI 金融 IP 与个人投研系统的 Obsidian 主知识库。

> [!tip] 统一入口
> 打开 [[00_开始这里]]。它会把行动、资产入库、知识审核、RAG、发布和反馈串成一条完整路径。

## 使用原则

1. 这里是知识中台，不是原始文件唯一存放地。当前导入采用复制方式，原文件仍保留在原位置。
2. `D:/Evan/Codes` 和程序项目未导入、未移动、未修改。
3. 新资料先放入 `00_Inbox` 或对应主题目录，确认分类后再进入正式知识卡片。
4. RAG 入库以 `_ops/asset_manifest.csv` 和 `_rag/collections/*.yml` 为准。
5. AI 生成的摘要、标签、问答、修正都必须经过人工确认，才能进入正式知识库。
6. 自 2026-09-20 起不再复制音视频原件；音视频保留在原始媒体库，知识库只保存文字、元数据、分镜、授权记录和必要图片。历史媒体原件位置见 `_ops/external_media_manifest.csv`。

## 入口

- [[00_开始这里]]
- [[00_Dashboard/00_操作台]]
- [[00_Dashboard/知识库健康度]]
- [[00_Index]]
- [[10_S老师IP资产/00_MOC_S老师IP资产]]
- [[20_投研方法论/00_MOC_投研方法论]]
- [[30_产业研究库/00_MOC_产业研究库]]
- [[40_S5000AI产品库/00_MOC_S5000AI产品库]]
- [[50_业务运营增长/00_MOC_业务运营增长]]
- [[60_AI工具与工程/00_MOC_AI工具与工程]]
- [[70_数据与系统/00_MOC_数据与系统]]
- [[80_复盘与版本演化/00_MOC_复盘与版本演化]]
- [[_rag/RAG_Architecture]]
- [[_rag/Feedback_Writeback]]
- [[_ops/Operations_Runbook]]

## 当前导入结果

资产清单：

- CSV：`_ops/asset_manifest.csv`
- JSONL：`_ops/asset_manifest.jsonl`

导入脚本：

- `_ops/scripts/import_knowledge_assets.ps1`

当前目录设计：

```text
00_Inbox
10_S老师IP资产
20_投研方法论
30_产业研究库
40_S5000AI产品库
50_业务运营增长
60_AI工具与工程
70_数据与系统
80_复盘与版本演化
99_Archive
_rag
_templates
_ops
```

## 下一步

1. 用 Obsidian 打开 `D:/Evan/AI-KnowledgeHub`。
2. 从 `00_Index` 进入分类索引。
3. 优先处理 `20_投研方法论`、`10_S老师IP资产`、`40_S5000AI产品库` 三类资产。
4. 对高价值 PDF、DOCX、PPTX、视频，先生成摘要卡片，再进入 RAG。
5. 建立 100 个真实业务问题作为 RAG 评测集。
