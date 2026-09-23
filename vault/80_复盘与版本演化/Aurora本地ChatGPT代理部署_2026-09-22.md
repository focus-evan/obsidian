---
type: codex-session
domain: local-ai-infrastructure
project: Aurora
status: complete
source_session: 01a0c7e5-8b40-7130-804c-1807e1cec6f7
artifact_path: D:\Evan\Codes\aurora
commit: cbfbabc9c14c7278e4dd91cf8807b2bf500860b1
validation: Go测试通过；模型列表、普通对话和流式对话验证成功；仅监听127.0.0.1:8080
deployed: local-only
next_action: 2026-09-26 10:59前安全更新accessToken；生产使用前评估非官方接口和账号风控
created: 2026-09-22
updated: 2026-09-22
tags:
  - codex/session
  - local-proxy
  - security/credential
workflow_stage: execution
---
# Aurora本地ChatGPT代理部署

## 事实

- 日期：2026-09-22。
- 来源：session `01a0c7e5-8b40-7130-804c-1807e1cec6f7`。
- 项目路径：`D:\Evan\Codes\aurora`。
- 完成事项：拉取上游提交 `cbfbabc9c14c7278e4dd91cf8807b2bf500860b1`，完成本地编译、测试、启停脚本、服务密钥和 ChatGPT accessToken 安全输入。
- 验证：读取到 21 个模型；普通对话返回 `AURORA_OK`；流式对话返回 `AURORA_STREAM_OK` 和正常结束标记。
- 服务边界：`http://127.0.0.1:8080/v1`，只监听本机。当前检查仍有本地 8080 监听；`/health` 返回 404，不作为会话中的模型/对话验证结论。
- 产物路径：`D:\Evan\Codes\aurora\DEPLOYMENT.local.md`、`run-local.ps1`、`stop-local.ps1`。
- 凭据边界：accessToken 和 API Key 不写入聊天、Obsidian 或 Git；本笔记不记录任何令牌值。

## 推断

- 该方案依赖 ChatGPT Web 内部接口，不等同于官方 OpenAI API；可用性和账号风险会随上游变化。
- 当前只适合本机验证和受控使用，不应直接暴露到局域网或公网。

## 行动项

- [ ] accessToken 预计 2026-09-26 10:59（北京时间）到期，届时通过安全输入脚本更新。
- [ ] 若要扩展给其他设备或生产系统，先增加独立鉴权、网络访问控制、审计、限流和稳定性验证。
