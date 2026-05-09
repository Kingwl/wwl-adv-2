---
name: wwl-godot-core-rules
description: 当修改 WWL Advanced 2D Tower Merge Godot 仓库中的确定性玩法规则时使用，包括棋盘放置、合成行为、塔、目标选择、战斗、投射物、经济、波次、敌人、玩家生命、胜利或失败状态，以及数据驱动规则行为。
metadata:
  short-description: WWL Godot 核心玩法规则工作流
---

# WWL Godot 核心规则

在 `/Users/bytedance/opensource/wwl-adv-2` 中处理玩法规则时使用这个 skill。

## 优先阅读

1. 阅读 `AGENTS.md`。
2. 阅读 `docs/status.md`。
3. 如果改动触及已有决策，阅读 `docs/designs/` 下相关设计。
4. 阅读 `docs/gameplay/features.md` 和 `docs/gameplay/test-plan.md` 中相关条目。
5. 在选择验证命令前阅读 `docs/testing/gates.md`。

## 开发规则

- 确定性玩法逻辑放在 `game/scripts/core/`。
- 核心规则服务不要依赖场景节点、HUD 文本、输入坐标、渲染和帧时间。
- 除非局部模式另有要求，核心逻辑优先使用 `RefCounted` 规则/服务类。
- 修改合成、战斗、波次、经济、放置、目标选择、敌人移动、玩家生命或胜负规则前，先新增或更新聚焦的 GUT 测试。
- 如果规则返回结果对象，同时测试成功路径和结构化失败路径。
- 如果规则改动影响可玩场景状态，等核心测试通过后再更新场景适配层。
- 新增或改变核心玩法功能、规则状态、配置形状、数值来源或测试覆盖时，更新 `docs/gameplay/features.md` 和 `docs/gameplay/test-plan.md`。

## 常见文件目标

- 核心代码：`game/scripts/core/<domain>/`。
- 规则测试：`game/test/gut/<domain>/`。
- 仅在必要时改场景适配层：`game/scripts/board/board_view.gd`。
- 数据/schema 改动：`game/data/`、`game/tools/check-assets.sh` 和相关 schema。
- 玩法功能和测试计划：`docs/gameplay/features.md`、`docs/gameplay/test-plan.md`。

## 验证

聚焦规则迭代时：

```bash
cd game
./tools/test-gut.sh
```

实质性改动：

```bash
cd game
./tools/check-all.sh
```

如果规则改动影响 UI 状态、放置输入、渲染或场景流程：

```bash
cd game
./tools/check-gameplay-smoke.sh
./tools/check-ui-smoke.sh
```

交付非平凡改动前：

```bash
cd game
./tools/agent-preflight.sh
```

最终说明新增或修改了哪些测试、运行了哪些命令，以及是否有 TD-007 这类已知警告。
