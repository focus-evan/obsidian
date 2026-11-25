---
type: codex-session
domain: production-migration
project: D:\Evan\Codes\ai-stock; D:\Evan\Codes\ai-stock-web
status: deployed-with-migration-gaps
source_session: 01a206a1-5ff2-7231-8ffe-f04c5666217c
source_rollout: 2026-11-23T04-19-28-65XK-ai_stock_migration_production_and_backup_20261123.md
artifact_path: D:\Evan\Backups\ai-stock-migration-20261123-122108\恢复与部署说明.md
commit: backend-434f4bed; frontend-4c65d56e
validation: 新机外部六项路径与数据逐表回读；本地37文件SHA256通过
deployed: new-ECS-testable; final-cutover-not-proven
next_action: 增量同步、旧历史及依赖核对后切流
created: 2026-11-25
updated: 2026-11-25
tags:
  - production/migration
  - backup/verified
---
# ai-stock新ECS迁移与备份

## 事实

- 日期：2026-11-23；来源：session `01a206a1-5ff2-7231-8ffe-f04c5666217c`及对应rollout摘要。
- 项目路径：`D:\Evan\Codes\ai-stock`、`D:\Evan\Codes\ai-stock-web`。会话报告旧生产镜像和网页迁至新ECS，公网首页、静态资源、API健康、知识库入口等六项验收通过；新机调度关闭以免双跑。
- 产物路径：`D:\Evan\Backups\ai-stock-migration-20261123-122108\恢复与部署说明.md`、`SHA256SUMS.txt`，本轮回查两文件存在。原会话校验37文件约1.80 GB，包括Git历史、本地改动、镜像、数据库和当时线上知识库。
- 生产数据库基于11月23日14:24一致性快照；源库一张历史视图因依赖缺列未恢复为可用视图；更早的知识库发布历史尚未取回，源端未找到可用Qdrant快照。项目代码备份与网站当前发布快照不等于这些历史和向量数据完整。

## 推断

- 新机路径验收是迁移的阶段性成功，不能推断快照后写入已同步、旧机全部历史可恢复或正式流量切换已完成。

## 行动项

- [ ] 核对源/目标数据库增量、外部依赖和调度单点，形成切流和回滚计划。
- [ ] 单独解决失效视图、旧知识库发布历史与向量索引；缺失部分不得写成完整备份。见[[00_Inbox/补齐ai-stock迁移增量与历史验收_2026-11-23]]。
