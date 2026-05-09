---
name: wwl-godot-harness-maintainer
description: 当修改本 WWL Godot 仓库的 agent harness、CI 工作流、GitHub Pages 导出流水线、验证脚本、资产检查、项目 skills、测试门禁或文档地图时使用。
metadata:
  short-description: WWL harness、CI 和 skill 维护工作流
---

# WWL Harness 维护

当处理帮助 agent 和人类验证项目的基础设施时使用这个 skill。

## 优先阅读

1. 阅读 `AGENTS.md`。
2. 阅读 `docs/status.md`。
3. 阅读 `docs/testing/gates.md`。
4. 做 harness backlog 时，阅读 `docs/todo/harness-engineering-todo.md`。
5. 做 UI/可玩性验证时，阅读 `docs/designs/2026-05-09-ui-playability-validation.md`。

## Harness 规则

- 可执行检查放在 `game/tools/`，让人类、agent 和 CI 共享同一组命令。
- 生成产物不要放进 `game/`；使用 `ci-artifacts/` 或 `build/`。
- shell 工具要可移植：支持 `GODOT_BIN`，失败时明确报错，避免机器本地假设。
- CI 应调用仓库脚本，不要在 workflow 里重复实现逻辑。
- 当失败需要 agent 检查时，CI 应上传日志、报告和截图。
- 架构边界检查通过 `game/tools/check-structure.sh` 维护；Tree-sitter cache 放在 `build/structure-cache/`，报告放在 `ci-artifacts/structure/`。
- 新增持久策略时更新 `docs/testing/`；新增待跟进工作时更新 `docs/todo/harness-engineering-todo.md`。
- 项目状态变化时更新 `docs/status.md`。

## 项目 Skills

项目 skills 位于 `.codex/skills/<skill-name>/SKILL.md`。

新增或修改 skill 时：

- 保持 `SKILL.md` 简短、流程化。
- skill 里只放值得触发的工作流；较长的项目状态放在 docs。
- 不要在 skill 里重复 shell 脚本内部实现。
- 更新 `AGENTS.md`，让 agent 能发现项目 skills。
- 如果本地 Codex 需要启用该 skill，在版本化文件提交后把它链接或复制到 `$CODEX_HOME/skills`。

## 验证

仅文档类 harness 改动：

```bash
cd game
./tools/check-docs.sh
```

脚本、CI、资产或测试门禁改动：

```bash
cd game
./tools/check-all.sh
```

只验证 structural lint 改动：

```bash
cd game
./tools/check-structure.sh
```

UI smoke、场景验证或 agent 反馈环改动：

```bash
cd game
./tools/agent-preflight.sh
```

只验证 gameplay smoke 改动：

```bash
cd game
./tools/check-gameplay-smoke.sh
```

Web 导出或 Pages 改动：

```bash
cd game
./tools/export-web.sh ../build/web
```

除非 GitHub run 已经实际完成，不要声称 CI 或 Pages 改动已经在远端验证。
