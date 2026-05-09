# 文档

这个目录存放需要和代码保持同步的项目文档。

## Agent 阅读顺序

1. `status.md`：当前状态、开放决策、已验证命令和已知风险。
2. `designs/README.md`：设计状态索引。
3. `designs/` 下的相关设计文档。
4. `gameplay/features.md` 或 `ui/features.md`：本次改动影响的玩家可见功能。
5. `testing/gates.md`：本次改动的验证期望。
6. `todo/backlog.md` 和 `tech-debt/register.md`：后续工作。

项目专用 Codex skills 位于 `docs/` 外的 `.codex/skills/`。当任务匹配核心玩法规则、场景/UI 验证或 harness 维护等专门工作流时使用它们。

## 项目 Skills

项目 skills 版本化存放在 `.codex/skills/`：

- `wwl-godot-core-rules`：确定性玩法规则开发。
- `wwl-godot-scene-harness`：场景、UI、布局、输入和可玩性验证。
- `wwl-godot-harness-maintainer`：CI、Pages、验证脚本、资产检查、文档门禁和 skill 维护。

## 结构

| 路径 | 用途 |
| --- | --- |
| `status.md` | 给 agent 和人类使用的一页式当前项目状态。 |
| `designs/` | 设计提案、架构说明和决策记录。 |
| `gameplay/` | 当前核心玩法功能、规则状态、自动化覆盖和测试计划。 |
| `ui/` | 当前 UI surface、玩家可见状态、交互、验证覆盖和测试计划。 |
| `milestone/` | 路线图、交付计划和进度检查点。 |
| `todo/` | 当前工作项、backlog 记录和短期后续项。 |
| `testing/` | 测试策略、门禁、structural lint 和覆盖清单。 |
| `tech-debt/` | 已知技术债、清理计划和风险跟踪。 |

## 维护

- 里程碑状态、开放决策、已验证命令或主要风险变化时，保持 `status.md` 最新。
- 新增设计或设计状态变化时，更新 `designs/README.md`。
- 新增或改变核心玩法功能、规则状态、配置形状、数值来源或核心测试覆盖时，检查并更新 `gameplay/features.md` 和 `gameplay/test-plan.md`。
- 新增或改变玩家可见 UI surface、状态、交互、响应式行为或 UI smoke review artifact 时，检查并更新 `ui/features.md` 和 `ui/test-plan.md`。
- 持久测试期望放在 `testing/`，不要放在 `todo/`。
- 已完成 todo 如果仍有价值，迁移到相关里程碑、设计或状态文档。
