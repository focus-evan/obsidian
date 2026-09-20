---
type: codex-session
domain: production
project: dify-api-bzsj
status: completed
source_session: 01a06a43-8d1d-7ea3-a9a5-c1c2f8375b81
artifact_path: C:\Users\bzsj_\Documents\Codex\2026-09-04\new-chat-2\work\dify-api-bzsj-dim12-opt
commit: 3f2bc58fbc7b6d58fb7b0842782346496fd54121
validation: 44-tests-swagger-200-container-healthy
deployed: production
next_action: 观察队列吞吐、失败率和GPT排队时间
created: 2026-09-06
updated: 2026-09-06
---
# dify-api-bzsj 一二维度吞吐生产优化 2026-09-04

## 事实
- 生产拓扑是单 ECS、单 host-network 容器、端口 9016。
- 优化点包括数据库优先公司上下文、4 个维度一二 Worker、GPT 并发提升、单批次 guard、耗时与队列指标。
- 发布镜像：`dify-api-bzsj:prod-3f2bc58fbc7b-20260904120343`。
- 44 项测试通过，本机/公网 Swagger 200，容器 healthy、0 重启、无 OOM。

## 推断
- CPU/内存空闲不代表任务吞吐宽裕，模型并发和上游延迟才是主要瓶颈。

## 行动项
- 观察未来批次的吞吐、失败率、上游排队时间，不只看容器健康。
