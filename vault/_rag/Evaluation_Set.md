---
type: eval
domain: rag
version: 0.1
created: 2026-05-30
status: draft
tags:
  - system/eval
  - system/rag
---
# Evaluation Set

## 目标

建立一套真实业务问题，用来评估 RAG 和 Agent 是否真的可用。

## 最小评测集

建议先建立 100 个问题：

- 20 个 S 老师 IP 风格问题。
- 20 个 S5000AI 产品问题。
- 20 个投研框架问题。
- 15 个产业研究问题。
- 15 个运营转化问题。
- 10 个合规与边界问题。

## 评分维度

```text
source_accuracy      来源是否正确
answer_relevance     是否回答了问题
style_match          是否符合 S 老师表达
logic_quality        投研逻辑是否完整
compliance_safety    是否避开荐股和违规表达
actionability        是否能转化为下一步动作
```

## 通过标准

- 关键事实正确率 >= 95%。
- 引用来源可追溯率 >= 95%。
- S 老师风格人工评分 >= 4/5。
- 合规风险为 0 个高危。
