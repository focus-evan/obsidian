---
type: architecture
domain: rag
version: 0.1
created: 2026-05-30
status: active
tags:
  - system/rag
  - architecture
---
# RAG Architecture

## 总体结构

```text
原始资产
  -> asset_manifest.csv
  -> 摘要/标签/分类
  -> 知识卡片
  -> chunk
  -> embedding
  -> hybrid search
  -> graph expansion
  -> Agent answer
  -> user/S老师 correction
  -> feedback writeback
```

## 三层知识

1. 文件资产层：保留 PDF、DOCX、PPTX、Excel、视频、字幕、SQL 等原始资料。
2. 知识卡片层：用 Markdown 管理摘要、标签、关联、版本和可复用结论。
3. 向量/图谱层：给 Agent 检索和推理使用。

## 推荐集合

集合配置见：

- `collections/collections.yml`

## 检索策略

1. 先按用户意图路由到 collection。
2. 同时做关键词检索和向量检索。
3. 通过 Obsidian wikilink、标签、同源文件、同公司、同产业链做一跳扩展。
4. 答案必须带来源路径。
5. 高风险主题必须输出免责声明和置信度。

## 入库状态

资产清单字段 `rag_status` 建议状态：

```text
pending
summarized
chunked
embedded
evaluated
approved
deprecated
```

## 不直接入库的内容

- 明确包含个人隐私但未脱敏的数据。
- API key、账号、token、证书。
- 未确认版权的视频素材。
- 未经 S 老师确认的风格模仿内容。
- 对外可能构成荐股的具体买卖指令。
