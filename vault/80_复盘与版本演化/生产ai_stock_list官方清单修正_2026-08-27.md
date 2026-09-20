---
type: codex-session
domain: production-data
project: dify-api-bzsj
status: completed
source_session: 01a04202-db5e-7bf3-8259-db227d970999
artifact_path: ai_stock_list
commit: none
validation: official-list-readback
deployed: production-data-updated
next_action: 修同步逻辑避免每日任务覆盖 listingStatus
created: 2026-08-31
updated: 2026-08-31
---
# 生产 ai_stock_list 官方清单修正 2026-08-27

## 事实
- 按官方市场清单修正生产表，未删除历史记录。
- A 股有效公司 5,550 家，港股有效公司 2,762 家，合计 8,312 家。
- 备份表：`ai_stock_list_bak_20260827_1525`。

## 推断
- `cn + hk` 原始行数不能直接当上市公司数，统计必须按有效 `listingStatus`。

## 行动项
- 每日同步 `AiMessageUtils.updateExistingData` 可能覆盖修正，需要改同步映射或增加官方清单对账。
r
