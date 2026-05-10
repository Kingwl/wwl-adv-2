# 设计：核心玩法架构

## 状态

Implemented

## 背景

早期玩法实现按棋盘、经济、敌人、战斗、投射物、塔、波次和胜负条件分别记录了细分设计。当前这些规则已经落到 `game/scripts/core/` 和对应 GUT 测试中，日常维护更需要一个稳定的边界说明，而不是逐个阅读历史实现计划。

历史细分设计已归档到 `docs/designs/archive/`。

## 当前边界

- `game/scripts/core/board/`：棋盘尺寸、格子类型、放置、移除、路径校验和保留格规则。
- `game/scripts/core/economy/`：钱包、交易、放置费用、击杀奖励和清波奖励。
- `game/scripts/core/enemies/`：敌人状态、生命值、伤害、死亡和漏怪事件。
- `game/scripts/core/movement/`：确定性路径进度和 grid-space 位置。
- `game/scripts/core/combat/`：固定 tick 战斗循环、目标选择接线、投射物推进、命中、奖励、漏怪和胜负结果聚合。
- `game/scripts/core/towers/`：塔运行时对象、塔配置、注册表、目标选择、攻击服务和合成服务。
- `game/scripts/core/waves/`：波次定义、生成间隔、清波事件和全部清空判定。
- `game/scripts/core/player/`：玩家生命和失败状态。

核心层不依赖 Godot 场景树、UI 节点、输入事件、CanvasItem、Texture2D 或资源加载。这个约束由 `game/tools/check-structure.sh` 维护。

## 运行时关系

`BoardGameSession` 位于 `game/scripts/board/`，是场景层使用核心规则的一局游戏应用状态。它负责把棋盘、钱包、放置服务、战斗模拟、波次、奖励和胜负 flow 组合起来，但不应该承载新的核心规则。

场景/UI 通过 `BoardView.get_session()` 访问 session 边界；核心规则本身继续由 GUT 直接覆盖。

## 测试入口

- 核心规则矩阵：`docs/gameplay/test-plan.md`。
- 当前玩法功能清单：`docs/gameplay/features.md`。
- 默认核心验证：`cd game && ./tools/test-gut.sh`。
- 实质性改动门禁：`cd game && ./tools/check-all.sh`。
- 影响玩家可见结果时：`cd game && ./tools/check-gameplay-smoke.sh` 或 `./tools/agent-preflight-full.sh`。

## 仍未解决

- Prototype 塔成长模型仍未定案：合成交互还是直接升级。
- 塔、敌人、经济和波次仍有部分硬编码在 GDScript 中，后续应迁移到数据/配置层，并纳入 schema 检查。
- 长局 replay 和批准式 snapshot 对比还没有成为门禁。

## 历史参考

旧的功能级设计已经实现并归档。需要追溯原始取舍时，从 `docs/designs/archive/` 中查找对应文件。
