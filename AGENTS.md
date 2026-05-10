# Agents 指南

## 优先阅读

先阅读 `docs/status.md`。它是给 agent 使用的一页式当前项目状态。

把 `docs/README.md` 当作文档地图。不要依赖手工维护的完整文件树；需要精确当前布局时，用 `find` 或 `rg --files`。

## 项目方向

这是一个 Godot 2D 塔防合成游戏。开发应保持测试驱动：

- 玩法规则放在 `game/scripts/core/`，不要直接嵌进 Godot 场景。
- 优先使用固定 tick 和带 seed 的随机数，保持模拟确定性。
- 修改合成、战斗、波次、经济、放置或目标选择规则前，先新增或更新 GUT 测试。
- 场景测试只用于集成边界：节点、资源、UI 状态同步、场景流程和 Godot 特有连接。

## 文档路线

| 需求 | 阅读或更新 |
| --- | --- |
| 当前状态、开放决策、已验证命令 | `docs/status.md` |
| 文档地图 | `docs/README.md` |
| 专用 agent 的项目 skills | `.codex/skills/` |
| 架构决策和提案 | `docs/designs/README.md` 和 `docs/designs/` 的当前聚合设计；不要默认阅读 `docs/designs/archive/` |
| 当前核心玩法功能、状态和测试计划 | `docs/gameplay/features.md` 和 `docs/gameplay/test-plan.md` |
| 当前 UI surface、状态、验证覆盖和测试计划 | `docs/ui/features.md` 和 `docs/ui/test-plan.md` |
| 交付范围和路线图 | `docs/milestone/` |
| 当前工作队列 | `docs/todo/backlog.md` |
| Harness engineering 自动化缺口 | `docs/todo/harness-engineering-todo.md` |
| 测试策略和门禁 | `docs/testing/` |
| 风险和清理工作 | `docs/tech-debt/register.md` |

## 文档规则

- 使用 `docs/designs/template.md`，把长期架构或玩法决策加入 `docs/designs/`。已实现且被聚合设计吸收的历史设计放入 `docs/designs/archive/`。
- 新增、延后、替代或实现设计时，更新 `docs/designs/README.md`。
- 当前里程碑状态、已验证命令、开放决策或主要风险变化时，更新 `docs/status.md`。
- 新增或改变核心玩法功能、规则状态、配置形状、数值来源或测试覆盖时，检查并更新 `docs/gameplay/features.md` 和 `docs/gameplay/test-plan.md`。
- 临时任务列表放在 `docs/todo/`；持久测试指导迁移到 `docs/testing/`。
- agent 在截图、smoke、试玩或审查中看到的任何 UI 问题或 UI 美观度问题，都必须作为单独 checkbox 条目记录到 `docs/todo/backlog.md`；不要只写在对话总结里，也不要和其他问题合并成一条。
- 面向 agent 的 harness 自动化后续项放在 `docs/todo/harness-engineering-todo.md`，直到它们变成已实现门禁或持久测试策略。
- 清理工作和工程风险记录在 `docs/tech-debt/register.md`。

## 项目 Skills

项目 skills 版本化存放在 `.codex/skills/`。

- 处理 `game/scripts/core/` 下的确定性玩法规则时，使用 `wwl-godot-core-rules`。
- 处理场景、UI、布局、输入、截图或可玩性验证时，使用 `wwl-godot-scene-harness`。
- 处理 CI、GitHub Pages、验证脚本、资产检查、文档门禁或项目 skill 维护时，使用 `wwl-godot-harness-maintainer`。

如果当前 Codex runtime 不会自动加载仓库内 skills，把这些文件视为权威工作流参考，并可按需链接到 `$CODEX_HOME/skills` 供本机使用。

## 项目布局

```text
.codex/
└── skills/
game/
├── project.godot
├── addons/gut/
├── scenes/
├── scripts/
│   ├── board/
│   ├── core/
│   └── ui/
├── data/
├── assets/
├── test/
└── tools/
```

## 验证

实质性改动运行：

```bash
cd game
./tools/check-all.sh
```

agent 本地快速 preflight 运行：

```bash
cd game
./tools/agent-preflight.sh
```

完整交付或需要视觉证据时运行：

```bash
cd game
./tools/agent-preflight-full.sh
```

场景、布局、渲染、输入或 UI 资产改动时，遵循 `docs/testing/gates.md` 的 UI 变更验证流程，运行 `./tools/check-ui-smoke.sh`，并检查打印摘要、`../ci-artifacts/ui-smoke/native/report.md`、整屏截图、局部 crop 和 overlay 辅助线图。

核心玩法改动影响玩家可见结果、战斗表现、奖励、漏怪或胜负状态时，运行 `./tools/check-gameplay-smoke.sh`，并检查 `../ci-artifacts/gameplay-smoke/native/report.md`、scenario 截图、board crop 和 overlay。

单项检查：

```bash
cd game
./tools/agent-preflight.sh
./tools/agent-preflight-full.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-docs.sh
./tools/check-assets.sh
./tools/check-structure.sh
./tools/check-ui-smoke.sh
./tools/check-gameplay-smoke.sh
./tools/check-web-smoke.sh ../build/web-smoke
./tools/summarize-godot-log.py ../ci-artifacts/check-all.log
./tools/summarize-ui-smoke.py
./tools/export-web.sh ../build/web
```

如果某项检查无法运行，在最终回复中说明原因。
