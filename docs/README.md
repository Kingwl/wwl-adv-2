# 文档

这个目录存放需要和代码保持同步的项目文档。

## Agent 阅读顺序

1. `status.md`：当前状态、开放决策、已验证命令和已知风险。
2. `designs/README.md`：当前架构设计索引。
3. `designs/` 下的当前聚合设计文档；不要从 `designs/archive/` 开始阅读。
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
| `designs/` | 当前架构设计、仍未完成的决策和归档历史设计。 |
| `gameplay/` | 当前核心玩法功能、规则状态、自动化覆盖和测试计划。 |
| `ui/` | 当前 UI surface、玩家可见状态、交互、验证覆盖和测试计划。 |
| `milestone/` | 低频路线图、交付范围和历史进度检查点。 |
| `todo/` | 当前工作项、backlog 记录和短期后续项。 |
| `testing/` | 测试策略、门禁、structural lint 和覆盖清单。 |
| `tech-debt/` | 已知技术债、清理计划和风险跟踪。 |

## 文档更新矩阵

| 变化 | 更新 |
| --- | --- |
| 当前状态、最近验证、开放决策、主要风险或下一步优先级变化 | `status.md` |
| 里程碑范围、完成标准、顺序或 checklist 完成状态变化 | `milestone/godot-2d-td-merge-roadmap.md` |
| 新增、缓解或关闭工程风险 | `tech-debt/register.md` |
| 临时工作项、试玩反馈、UI 问题或尚未形成技术债的后续项 | `todo/backlog.md` |
| 核心玩法功能、规则语义、配置形状、数值来源或核心测试覆盖变化 | `gameplay/features.md` 和 `gameplay/test-plan.md` |
| 玩家可见 UI surface、状态、交互、响应式行为或 UI smoke artifact 变化 | `ui/features.md` 和 `ui/test-plan.md` |
| 持久测试策略、门禁或验证命令变化 | `testing/` 下对应文档 |
| 顶层设计新增、替代、实现或归档 | `designs/README.md` 和对应设计文档 |

## 维护

- 里程碑状态、开放决策、已验证命令或主要风险变化时，保持 `status.md` 最新。
- `milestone/` 是低频路线图，不替代 `status.md`；只有范围、完成标准、顺序或 checklist 状态变化时才更新。
- `tech-debt/` 跟踪工程风险生命周期；普通待办和视觉反馈优先放入 `todo/backlog.md`。
- 新增顶层设计或设计状态变化时，更新 `designs/README.md`；已实现并被聚合设计吸收的旧设计放入 `designs/archive/`。
- 新增或改变核心玩法功能、规则状态、配置形状、数值来源或核心测试覆盖时，检查并更新 `gameplay/features.md` 和 `gameplay/test-plan.md`。
- 新增或改变玩家可见 UI surface、状态、交互、响应式行为或 UI smoke review artifact 时，检查并更新 `ui/features.md` 和 `ui/test-plan.md`。
- 持久测试期望放在 `testing/`，不要放在 `todo/`。
- 已完成 todo 如果仍有价值，迁移到相关里程碑、设计或状态文档。
