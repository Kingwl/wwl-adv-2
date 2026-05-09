# 设计：合成 UI 集成

## 状态

Deferred。保留为参考方案，直到 Prototype 成长模型决策完成。

## 背景

核心合成规则已经存在于 `TowerMergeService`：只有同类型、同等级且不是同一实例的两座塔可以合成。棋盘规则也定义了 MVP 合成位置：合成后的塔留在第一个选中塔的格子里，第二座塔所在格子清空。

`BoardView` 当前把每次左键点击都当成放置尝试。点击已占用格会返回 occupied-placement 失败，因此核心合成规则无法从可玩场景触达。

截至 2026-05-09，具体实现暂停，因为项目尚未决定 Prototype 的塔成长模型是合成还是直接升级。

## 目标

- 添加场景级合成交互，同时不引入拖拽。
- 合成 mutation 保持在可测试核心层，不嵌入 `BoardView`。
- 选中一座塔后，让合法合成目标明显可见。
- 保持空格放置行为不变。
- 让用于未来放置的 tower-card 选择独立于合成选择。
- 合成后保持确定性战斗状态。

## 非目标

- Prototype 不做拖拽合成。
- 不做塔移动。
- 合成不消耗或返还金币。
- 此步骤不做随机召唤概率。
- 第一版除高亮/status 反馈外，不做合成动画。

## 方案

使用两次点击的合成流程：

1. 点击一个已占用可建造格，将该塔选为合成源。
2. 高亮选中塔和所有兼容合成目标。
3. 点击兼容的已占用格，将它合成进源格。
4. 点击不兼容的已占用格，将源选择切换到该塔，并显示短提示。
5. 再次点击已选源塔、按 Escape、重开、暂停或返回开始时，清除合成选择。
6. 点击空可建造格时，按当前行为放置塔，并清除任何合成选择。

合成后的塔保留在源位置。被点击的目标塔被消耗。Tower-card selection 仍表示新放置的选中类型；选择棋盘上的塔不会改变它。

## 核心服务

在场景外添加一个小型编排服务：

```text
game/scripts/core/placement/
├── tower_merge_placement_service.gd
└── tower_merge_placement_result.gd
```

`TowerMergePlacementService` 负责棋盘和 registry mutation：

```text
try_merge_positions(source_position: Vector2i, target_position: Vector2i) -> TowerMergePlacementResult
```

职责：

- 校验两个位置都在边界内。
- 校验两个格子都包含塔。
- 通过 `TowerRegistry` 解析两个 tower id。
- 调用 `TowerMergeService.try_merge(source_tower, target_tower)`。
- 成功时：
  - 从 `TowerRegistry` 移除 source 和 target id；
  - 清空目标棋盘格；
  - 将源棋盘格占用者替换为合成塔 id；
  - 设置 `merged_tower.grid_position = source_position`；
  - 将合成塔加入 `TowerRegistry`；
  - 返回被消耗 id 和合成 id。

服务应返回结构化失败原因，用于场景反馈：

```text
NONE
SOURCE_OUT_OF_BOUNDS
TARGET_OUT_OF_BOUNDS
SOURCE_EMPTY
TARGET_EMPTY
SOURCE_TOWER_MISSING
TARGET_TOWER_MISSING
SAME_TOWER
TYPE_MISMATCH
TIER_MISMATCH
BOARD_UPDATE_FAILED
```

现有 `TowerMergeResult.FailureReason` 应保留，并映射到 placement-level result，而不是在 `BoardView` 中重复实现。

## Board API

优先添加一个明确的 board helper，而不是从场景代码直接修改 slot 内部状态：

```text
replace_tower(position: Vector2i, expected_occupant_id: String, new_occupant_id: String) -> PlacementResult
```

规则：

- 位置必须在边界内。
- 格子当前必须包含 `expected_occupant_id`。
- 新 occupant id 不能为空。
- 格子类型仍必须是 buildable。

这让合成服务对 MVP 来说足够原子：校验两个格子，替换 source，清空 target，然后更新 registry。如果 board update 失败，场景 UI 不应猜测如何恢复。

## BoardView 状态

只为交互和绘制添加场景状态：

```text
var merge_source_position := INVALID_GRID_POSITION
var merge_source_tower_id := ""
var last_merge_result: TowerMergePlacementResult
var merge_feedback_elapsed_seconds := 0.0
```

添加 helper：

```text
has_merge_source() -> bool
clear_merge_source() -> void
select_merge_source(position: Vector2i) -> void
try_merge_with_source(target_position: Vector2i) -> TowerMergePlacementResult
is_compatible_merge_target(position: Vector2i) -> bool
```

`BoardView._unhandled_input()` 应通过一个方法路由左键点击：

```text
handle_board_click(grid_position)
```

点击路由：

- 越界：走放置路径或显示现有非法反馈。
- 空格：清除合成选择，并调用 `try_place_at_grid()`。
- 已占用且没有合成源：选择源。
- 已占用且是当前选中源：清除源。
- 已占用且是兼容目标：调用合成服务。
- 已占用但不兼容：将被点击塔设为新源，并显示它为什么不能和之前的源合成。

成功合成后：

- 清除合成选择。
- 调用 `_sync_combat_towers()`。
- 清理被消耗 tower id 的攻击动画条目。
- 保留现有投射物；投射物伤害已经携带自身塔类型和伤害。
- 用合成后的类型和等级更新 status。
- 重绘。

合成后的塔会重置冷却，因为 `TowerMergeService` 会创建新的 `GameTower`。这对 Prototype 可以接受，并应作为平衡选择记录。

## 视觉反馈

在添加专用节点前，先在 `BoardView` 中使用轻量绘制：

- 选中源：源格周围明亮金色描边。
- 兼容目标：匹配的已占用格显示青色或绿色描边。
- 源已选中时，hover 不兼容已占用格：红色描边。
- 合成成功：源格短暂 pulse。
- 合成失败：status 文本加目标格红色描边。

塔 sprite 应在无需立即新增美术的情况下显示等级。第一版：

- 对 `tier > 1` 的塔，在格子右上角绘制小等级徽章。
- 塔类型 sprite 保持不变。
- 后续美术可以添加分等级 sprite 或 shader tint。

HUD 文案：

- 选中源：`Selected Single T1. Pick another Single T1 to merge.`
- 成功：`Merged tower-1 + tower-2 into Single T2.`
- 不兼容：`Area T1 cannot merge with Single T1.`
- 同一座塔：`Select a different tower to merge.`

## 测试

先加测试，再接场景。

核心测试：

- 两个已占用位置的同类型同等级塔，合成为源位置的塔。
- 成功后目标位置清空。
- Registry 移除被消耗 id，并注册合成塔。
- 不同类型失败，且不改变 board 或 registry。
- 不同等级失败，且不改变 board 或 registry。
- 空 source 失败。
- 空 target 失败。
- registry 中缺失 tower 时失败。
- 同一位置失败。

场景测试：

- 点击已占用格会选择合成源，不花费金币。
- 点击兼容已占用格会合成，钱包不变。
- 合成塔出现在第一个选中的格子。
- 目标格变为空。
- 合成后 combat simulation 塔列表重新同步。
- 源已选中时点击空格，正常放置并清除合成源。
- 重开会清除合成源和最后合成结果。

## 实现顺序

1. 添加 `Board.replace_tower()` 和 GUT 测试。
2. 添加 `TowerMergePlacementResult`。
3. 添加 `TowerMergePlacementService` 和核心 GUT 测试。
4. 添加 `BoardView` 合成源状态和点击路由。
5. 添加选择/目标高亮绘制。
6. 添加等级徽章绘制。
7. 添加源选择和成功合成的场景测试。
8. 测试通过后，将 Milestone 1 `二合一合成` 标记完成。

## 替代方案

- 拖拽合成：桌面上更直接，但移动横屏更差，而且需要 pointer capture、拖拽预览和取消状态。
- 专用合成模式按钮：更不容易误触，但会增加额外模式，并和 tower-card 栏竞争。
- 放置到已占用格时自动合成：容易和放置失败混淆，也不允许玩家检查可选目标。

## 风险

- 已占用格点击从放置失败改为选择，会改变一个现有场景测试。应更新它，让它断言新的选择行为，而不是 occupied placement failure。
- Board 和 registry 中替换 source/target id 必须保持一致。mutation 放在核心服务中，并断言失败路径不会出现部分 mutation。
- 等级徽章文本可能让小移动端格子拥挤。只对 `tier > 1` 绘制，并让徽章尺寸绑定 `cell_size`。

## 开放问题

- Prototype 中成功合成是否应永久重置冷却，还是继承被消耗塔中较低的冷却？
- 不兼容目标点击应切换源选择，还是保留旧源并只显示错误？
- 合成成功后，后续是否应为经济节奏添加少量金币消耗？
