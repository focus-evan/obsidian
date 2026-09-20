---
type: import-summary
domain: operations
created: 2026-05-30
status: active
tags:
  - import/summary
  - system/manifest
---
# Import Summary

## 范围

本次导入采用复制方式，不移动、不删除原文件。

明确排除：

- `D:/Evan/Codes`
- `D:/Evan/Programs`
- 程序缓存、运行依赖、浏览器 profile、临时检查目录

导入类型：

- 文档：Markdown、TXT、PDF、Word、PPT、XMind
- 表格：Excel、CSV、TSV
- 数据：JSON、SQL
- 媒体：MP4、MOV、音频、字幕
- 视频项目素材图片：仅限 `D:/aigc` 与 `D:/Evan/video`

## 资产清单

- `_ops/asset_manifest.csv`
- `_ops/asset_manifest.jsonl`

## 导入结果

```text
00_Inbox              418
10_S老师IP资产          4318
20_投研方法论            282
30_产业研究库            216
40_S5000AI产品库         13
50_业务运营增长           27
60_AI工具与工程           35
70_数据与系统            147
80_复盘与版本演化           5
总计                  5461
错误                     0
```

## 后续处理

1. 先为高价值资产生成摘要卡片。
2. 再对摘要卡片做人工确认。
3. 确认后进入 RAG 入库。
4. Agent 回答中的修正回写到 `_rag/feedback`。

## 2026-09-20 音视频镜像清理

- 已将知识库内的音视频镜像改为“外部原件保留、知识库不复制”模式。
- 清理前共 948 个音视频镜像；删除前均与原始路径完成 SHA-256 一致性校验。
- 原始媒体仍保留在 `D:/Evan/Files`、`D:/Evan/video`、`D:/aigc` 等原目录。
- 原始位置和历史元数据保存于 `_ops/external_media_manifest.csv` 与 `_ops/external_media_manifest.jsonl`。
- 增量导入脚本默认跳过所有音视频扩展名，避免镜像再次生成。
