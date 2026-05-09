# 设计：敌人路径移动

## 状态

已实现；BoardView 现在使用波次生成的敌人。

## 背景

当前已有 Board 路径、可视化格子、点击放塔和基础资源。下一步需要敌人沿路径移动，形成塔防循环的运动基础。

本设计先实现确定性的路径推进，不处理攻击、生命、伤害和波次生成。

## 目标

- 敌人可以沿 `Array[Vector2i]` 路径按固定速度推进。
- 移动核心不依赖 Godot 场景树。
- 同样的路径、速度和 tick 输入得到同样结果。
- 能查询当前路径段、路径进度、当前网格坐标、当前位置。
- 到达终点后标记 `completed`。
- BoardView 可以渲染一个敌人占位点。

## 非目标

- 暂不做多敌人波次。
- 暂不做碰撞体、寻路、绕路。
- 暂不做敌人生命、护甲、状态效果。
- 暂不做到达终点扣生命。

## 移动模型

路径由连续格子组成：

```gdscript
Array[Vector2i]
```

移动位置使用“路径中心点”：

```text
cell_center = board_origin + grid_position * cell_size + Vector2(cell_size / 2, cell_size / 2)
```

核心层不关心像素，只输出格子空间位置：

```text
grid_space_position: Vector2
```

场景层负责转换为像素：

```text
world_position = board_origin + grid_space_position * cell_size
```

## 敌人

建议新增：

```text
game/scripts/core/enemies/enemy.gd
```

字段：

```text
id: String
speed_cells_per_second: float
path_distance: float
completed: bool
```

MVP 默认：

- `speed_cells_per_second = 1.0`
- 起点距离 `0.0`

## PathFollower

建议新增：

```text
game/scripts/core/movement/path_follower.gd
```

职责：

- 校验路径至少两个点。
- 计算总路径长度。
- 根据 `delta_seconds` 推进敌人的 `path_distance`。
- 将 `path_distance` 转换为当前格子空间坐标。
- 判断是否到达终点。

路径每段先只支持正交相邻，长度为 `1.0` cell。

## 规则

- `delta_seconds` 必须大于等于 `0`。
- 敌人完成后继续 tick 不再移动。
- tick 后如果 `path_distance >= total_distance`，设置 `completed = true`。
- 当前 grid position 可以使用当前段起点；到达终点后返回路径最后一个格子。
- 位置插值使用线性插值。

## 测试用例

实现前先写 GUT 测试：

- 敌人从路径起点中心开始。
- tick `0.5s` 且速度 `1 cell/s` 后位于第一段中点。
- tick 跨过多个路径段时位置正确。
- 到达终点后 `completed = true`。
- completed 后继续 tick 位置不再变化。
- 同样输入重复运行结果一致。

## 场景集成

BoardView 最初持有一个 prototype enemy；当前实现已经升级为使用 `CombatSimulation.enemies` 中由 `WaveSpawner` 生成的敌人：

```text
enemies: Array[Enemy]
path_follower: PathFollower
```

渲染：

- 用红色/橙色圆点显示敌人。
- 位置来自 `path_follower.get_grid_space_position(enemy)`。
- 暂不参与碰撞和攻击。

更新：

- `_process(delta)` 调用 `path_follower.advance(enemy, delta)`。
- 如果 enemy completed，可以停在终点。

## 路线图

### Step 1: Core Movement

- [x] 新增 `Enemy`。
- [x] 新增 `PathFollower`。
- [x] 增加 GUT 测试。

完成标准：

- 敌人路径推进测试通过。

### Step 2: BoardView Rendering

- [x] BoardView 初始化 wave-spawned enemies。
- [x] `_process(delta)` 推进 enemy。
- [x] `_draw()` 绘制 enemy 占位点。

完成标准：

- 运行主场景能看到一个敌人沿路径移动。

### Step 3: Scene Tests

- [x] 主场景测试确认 enemy 和 path follower 初始化。
- [x] 测试推进后 enemy 位置变化。

完成标准：

- `./tools/test-gut.sh` 全部通过。

## 开放问题

- 敌人到达终点后是立即销毁，还是停留一小段时间用于反馈。
- 波次系统是否复用同一个 `PathFollower`，还是每个敌人持有自己的 follower。
