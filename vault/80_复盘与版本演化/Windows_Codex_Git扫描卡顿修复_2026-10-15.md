---
type: codex-session
domain: workstation-operations
project: Codex Desktop / D:\Evan\Codes
status: complete
source_session: 01a13ecc-6f1f-79e2-88db-095dd469a849
artifact_path: D:\Evan\pc-diagnostics\20261015-git-scan-repair\validation.json
commit: not-applicable
validation: tracked entries/config/nested repositories unchanged; untracked scan约0.22秒，完整status约2.45秒
deployed: local-workstation
next_action: 观察Codex后台扫描超时是否复发并按需调整本地排除项
created: 2026-10-18
updated: 2026-10-18
tags:
  - codex/session
  - windows/performance
  - git
---
# Windows Codex Git扫描卡顿修复

## 事实

- 日期：2026-10-15 晚间补录；来源 session `01a13ecc-6f1f-79e2-88db-095dd469a849`。
- 系统存在 16GB 内存高占用和较多并发应用，但磁盘、GPU与硬件日志没有持续异常；最明确瓶颈是 Codex 每分钟扫描聚合仓库未跟踪文件并在约 60 秒超时。
- `D:\Evan\Codes` 聚合仓库跟踪 73,793 个条目，其中 45,898 个为 `node_modules`，并包含 36 个嵌套仓库；根目录此前没有本地扫描排除。
- 按用户要求保留全部应用，只修改 `D:\Evan\Codes\.git\info\exclude`，排除缓存、临时目录、生成物、依赖目录和独立嵌套仓库。
- 文件、提交历史、跟踪条目、Git 配置和子仓库元数据均未改变；未跟踪扫描从反复 60 秒超时降至约 0.22–0.25 秒，完整 status 约 2.45–2.73 秒。
- 修复包包含备份、验证、性能测试和撤销脚本，可通过 `undo-local-exclusions.ps1` 回滚。

## 推断

- Codex 打开聚合仓库时，巨大的未跟踪扫描面会造成系统级卡顿；本地 exclude 是不改项目内容的低风险修复。
- 内存压力是次要可能因素，当前证据不足以把全部卡顿归因于内存。

## 行动项

- [ ] 继续观察 Codex 日志中 60 秒 Git 扫描超时是否复发。
- [ ] 新增大型缓存或嵌套仓库时维护本地排除项，不把机器专用规则提交到业务仓库。
