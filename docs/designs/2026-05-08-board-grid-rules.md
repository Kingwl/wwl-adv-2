# Design: 格子规则

## Status

Draft

## Context

格子系统是塔防合成玩法的基础。它需要支撑放置塔、禁止占用路径、合成位置处理、敌人路径、UI 点击映射和后续关卡配置。

本设计先服务 MVP：单地图、单路径、固定格子放置。

## Goals

- 核心规则可用 GUT 单测，不依赖 Godot 场景树。
- 放置失败必须返回结构化原因，方便 UI 展示。
- 路径、建造区、锁定格、占用格的规则清晰。
- 坐标系统稳定，后续能从 UI 点击映射到格子。
- 为合成和敌人路径预留接口。

## Non-Goals

- 暂不支持六边形格子。
- 暂不支持多层高度、飞行路径、动态地形破坏。
- 暂不做复杂建筑 footprint，MVP 所有塔占 1x1。
- 暂不在格子规则里处理资源扣费，资源由 Economy 系统负责。

## Coordinate System

使用整数网格坐标：

```text
(0, 0) is top-left
x increases to the right
y increases downward
```

MVP 默认棋盘建议：

- `width = 10`
- `height = 8`
- `cell_size = 64` pixels

核心层只关心 `Vector2i` 或等价整数坐标，不关心像素位置。像素到格子的转换放在场景 adapter 层。

## Slot Types

每个格子有一个基础类型：

| Type | Meaning | Can Build | Can Enemy Path |
| --- | --- | --- | --- |
| `BUILDABLE` | 可建造格 | Yes | No |
| `PATH` | 敌人路径格 | No | Yes |
| `BLOCKED` | 永久阻挡格 | No | No |
| `LOCKED` | 暂未解锁格 | No | No |

格子还可以有运行时状态：

- `occupant_id`: 当前占用该格的塔 id，空格为 `""`。
- `reserved`: 用于后续动画、拖拽、异步操作的临时占位。MVP 可以先不实现。

## Placement Rules

放置塔需要满足：

1. 坐标在棋盘范围内。
2. 格子类型是 `BUILDABLE`。
3. 格子没有 `occupant_id`。
4. 格子没有被运行时 reserved。

放置操作只负责写入占用关系，不负责：

- 扣资源。
- 创建塔对象。
- 播放动画。
- 更新 UI。

这些由上层系统编排。

## Placement Result

所有放置尝试返回 `PlacementResult`：

```text
succeeded: bool
failure_reason: enum
message: String
position: Vector2i
occupant_id: String
```

失败原因：

| Reason | Meaning |
| --- | --- |
| `NONE` | 成功 |
| `OUT_OF_BOUNDS` | 坐标越界 |
| `NOT_BUILDABLE` | 不是可建造格 |
| `OCCUPIED` | 已有塔占用 |
| `RESERVED` | 格子被临时保留 |

## Remove And Move Rules

MVP 需要支持移除塔，暂不支持移动塔。

移除塔需要满足：

1. 坐标在棋盘范围内。
2. 格子当前有 `occupant_id`。
3. 传入 tower id 时，必须和格子里的 `occupant_id` 一致。

移动塔在后续实现时应拆成：

1. 校验目标格。
2. 清理来源格。
3. 写入目标格。
4. 返回结构化移动结果。

不要在移动中隐式合成。

## Merge Position Rules

MVP 合成规则：

- 两个同类型同阶塔合成一个高一阶塔。
- 合成结果默认留在第一个被选择的塔所在格。
- 第二个塔所在格被清空。
- 如果第一个格子不再可用，合成失败，不自动寻找新格子。

这样规则简单、可预测，也容易做 UI 高亮。

后续如果要支持拖拽合成，可以把“目标格”显式传入合成流程。

## Enemy Path Rules

敌人路径由一组连续格子定义：

```text
path: Array[Vector2i]
```

路径要求：

- 至少包含起点和终点两个格。
- 每一步必须和前一步正交相邻，不能斜向跳跃。
- 路径格必须全部在棋盘范围内。
- 路径格类型必须是 `PATH`。
- 建造系统不能把塔放到路径格。

路径移动的精细位置由后续 Enemy/Movement 系统处理，Board 只负责校验路径格合法。

## Scene Adapter Rules

Godot 场景层负责：

- `screen_position -> grid_position`。
- 根据 `PlacementResult` 展示成功、错误提示或格子高亮。
- 根据 slot type 渲染不同视觉状态。
- 把点击、拖拽、hover 转成核心规则调用。

核心层不直接读鼠标、不访问节点、不播放动画。

## Test Cases

实现前先写 GUT 测试：

- 可以创建指定宽高棋盘。
- 越界坐标返回 `OUT_OF_BOUNDS`。
- `BUILDABLE` 空格可以放置塔。
- `PATH` 格不能放置塔。
- `BLOCKED` 格不能放置塔。
- `LOCKED` 格不能放置塔。
- 已占用格不能再次放置塔。
- 移除已占用格会清空 `occupant_id`。
- 移除空格返回结构化失败。
- 路径必须连续。
- 路径不能包含越界格。
- 路径不能包含非 `PATH` 格。

## Proposed Files

```text
game/scripts/core/board/
├── board.gd
├── board_slot.gd
├── placement_result.gd
├── removal_result.gd
└── path_validation_result.gd

game/test/gut/board/
├── test_board_placement.gd
└── test_path_validation.gd
```

## Open Questions

- MVP 棋盘尺寸是否固定为 `10x8`，还是每个关卡配置。
- 是否需要在 Prototype 阶段支持拖拽合成。
- 是否需要多入口或多出口路径。
