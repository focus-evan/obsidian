---
type: moc
domain: data-system
version: 0.1
created: 2026-05-30
status: active
tags:
  - moc/data-system
  - domain/data-system
---
# 数据与系统

## 这里管理什么

- SQL 表结构、历史聊天、训练问答、用户反馈。
- 股票数据、基金持仓、候选股宽表。
- 数据字典、RAG 入库状态、系统接口说明。

## 注意

这里可能包含敏感数据。进入 RAG 或对外使用前，需要检查：

- 是否包含用户个人信息。
- 是否包含账号、密钥、token。
- 是否包含不能外发的业务数据。
- 是否需要脱敏。

## Agent 用途

- 数据字典 Agent
- 指标解释 Agent
- SQL 表关系 Agent
- 脱敏检查 Agent
