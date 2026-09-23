---
type: eval
domain: rag
version: 0.2
created: 2026-05-30
status: active
tags:
  - system/eval
  - system/rag
---
# Evaluation Set

## 目标

建立一套真实业务问题，用来评估 RAG 和 Agent 是否真的可用。

## 最小评测集

已建立 100 个本地检索问题，文件为：

- `_rag/evals/retrieval_cases.jsonl`
- `_rag/evals/latest_retrieval_eval.json`
- `_rag/evals/latest_retrieval_eval.md`

当前分布以 13 个已审核知识对象为准，覆盖：

- 20 个 S 老师 IP 风格问题。
- 20 个 S5000AI 产品问题。
- 20 个投研框架问题。
- 15 个产业研究问题。
- 15 个运营转化问题。
- 10 个合规与边界问题。

后续新增已审核知识对象时，应同步增加问题，不能通过删除难例维持命中率。

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

## 当前结果

- 本地字符 n-gram/BM25：100 个问题，Hit@5 为 100%。
- 该结果只表示预期来源能够进入前五名，不等于生成答案已经达到 100% 正确。
- 语义向量、答案质量和人工风格评分仍需分别评测，不能共用一个通过状态。
