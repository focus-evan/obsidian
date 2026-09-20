---
type: process
domain: feedback
version: 0.1
created: 2026-05-30
status: active
tags:
  - system/feedback
  - system/rag
---
# Feedback Writeback

## 目标

让公司知识库持续进化，而不是只做一次性资料整理。

## 反馈来源

- S 老师对脚本、直播、答疑、投研结论的修改。
- 用户在 S5000AI 中的高频问题和追问。
- 视频评论区、直播间、私域社群里的真实困惑。
- 投研复盘中的错判、漏判、证伪案例。
- Agent 回答错误、引用错误、风格错误。

## 反馈流程

```text
发现问题
  -> 生成 feedback note
  -> 标注来源与错误类型
  -> 人工审核
  -> 修改或新增知识卡片
  -> 重新入库 embedding
  -> 加入评测集
```

## 错误类型

```text
fact_error
style_error
missing_context
wrong_source
compliance_risk
outdated_view
investment_logic_error
product_logic_error
video_asset_risk
```

## 反馈文件位置

- `_rag/feedback`

每条反馈使用 `_templates/feedback_note.md`。
