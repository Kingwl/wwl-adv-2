# Design: 资源系统

## Status

Placement, kill rewards, and wave rewards implemented.

## Context

当前已经有 `Board` 和 `BoardView`，点击格子可以直接放塔。下一步需要加入基础经济，让放塔、击杀、过波和后续合成升级都通过统一资源系统记录。

资源系统必须保持可测试，不依赖 Godot 场景树。

## Goals

- 支持单一局内资源：`gold`。
- 支持初始资源、放塔花费、击杀奖励、波次奖励。
- 所有资源变化都返回结构化结果。
- 所有交易都记录原因、数量、余额和引用 id。
- 放塔扣费与 `Board.place_tower()` 通过上层 service 编排，避免 Board 负责经济。
- GUT 测试覆盖正常路径、失败路径和交易记录。

## Non-Goals

- 暂不做局外货币。
- 暂不做多资源系统。
- 暂不做商店刷新、利息、连胜奖励。
- 暂不做数值平衡最终版。

## Resource Model

MVP 只使用一种资源：

```text
gold
```

建议默认值：

| Item | Value |
| --- | ---: |
| Initial gold | 100 |
| Basic tower cost | 25 |
| Default kill reward | 5 |
| Wave clear reward | 20 |

击杀奖励先不按怪物类型写死。敌人或波次系统后续负责决定 `reward_amount`，资源系统只负责把传入的奖励金额入账。怪物类型、稀有度、护甲、速度等差异会在敌人系统设计时再定义。

这些数值先放在核心常量或配置类里，后续迁移到关卡配置资源。

## Core Objects

建议新增：

```text
game/scripts/core/economy/
├── wallet.gd
├── transaction_result.gd
├── transaction_record.gd
└── economy_config.gd

game/scripts/core/placement/
├── tower_placement_service.gd
└── tower_placement_result.gd

game/test/gut/economy/
├── test_wallet.gd
└── test_tower_placement_service.gd
```

## Wallet

`Wallet` 负责资源余额和交易记录。

字段：

```text
gold: int
transactions: Array[TransactionRecord]
```

方法：

```text
can_spend(amount: int) -> bool
spend(amount: int, reason: Reason, reference_id: String = "") -> TransactionResult
earn(amount: int, reason: Reason, reference_id: String = "") -> TransactionResult
```

规则：

- `amount` 必须大于 `0`。
- `spend` 余额不足时失败，不改变余额，不写成功交易。
- `earn` 成功增加余额。
- 所有成功交易都写入 `transactions`。
- 失败结果也要包含当前余额和失败原因。

## Transaction Reasons

交易原因先定义为 enum：

```gdscript
enum Reason {
	STARTING_GOLD,
	PLACE_TOWER,
	KILL_ENEMY,
	CLEAR_WAVE,
	REFUND,
	DEBUG,
}
```

失败原因：

```gdscript
enum FailureReason {
	NONE,
	INVALID_AMOUNT,
	INSUFFICIENT_FUNDS,
}
```

## Transaction Result

`TransactionResult`：

```text
succeeded: bool
failure_reason: FailureReason
reason: Reason
amount: int
balance_before: int
balance_after: int
reference_id: String
message: String
```

## Transaction Record

`TransactionRecord`：

```text
reason: Reason
amount: int
balance_before: int
balance_after: int
reference_id: String
```

`amount` 约定：

- 收入为正数。
- 支出为正数，方向由 `reason` 和 result 上下文表达。

为了减少早期复杂度，不引入负数交易金额。

## Placement Integration

放塔流程不应该由 `Board` 直接扣钱。新增 `TowerPlacementService` 编排：

```text
TowerPlacementService
├── wallet: Wallet
├── board: Board
└── config: EconomyConfig
```

流程：

1. 先校验目标格是否可放置。
2. 再检查资源是否足够。
3. 扣除放塔费用。
4. 调用 `Board.place_tower()`。
5. 如果 Board 放置失败且资源已经扣除，执行 refund。

更保守的实现可以先调用 `Board.can_place_tower()`，再扣费，再放置。当前 `Board` 没有 `can_place_tower()`，所以实现时建议新增纯校验方法，避免扣费后回滚。

`TowerPlacementResult` 包含：

```text
succeeded: bool
placement_result: PlacementResult
transaction_result: TransactionResult
tower_id: String
position: Vector2i
message: String
```

## Scene Integration

`BoardView` 后续不直接调用 `board.place_tower()`，改为调用：

```text
tower_placement_service.try_place_basic_tower(grid_position)
```

HUD 显示：

- 当前 `Gold: N`
- 最近操作状态
- 放塔成本，例如 `Basic tower: 25g`

点击失败时：

- 资源不足显示 `Need 25 gold.`
- 路径/占用失败继续展示 Board 的结构化原因。

## Test Cases

实现前先写 GUT 测试：

### Wallet

- 初始余额正确。
- `earn()` 增加余额并记录交易。
- `spend()` 扣除余额并记录交易。
- 余额不足时 `spend()` 失败且余额不变。
- `amount <= 0` 时交易失败。

### TowerPlacementService

- 资源足够且格子可建造时：扣费、放塔、余额减少。
- 资源不足时：不扣费、不放塔。
- 路径格放置失败时：不扣费、不放塔。
- 已占用格放置失败时：不扣费、不覆盖旧塔。
- 成功放置记录 `PLACE_TOWER` 交易，reference id 是 tower id。

## Roadmap

### Step 1: Wallet Core

- [x] 新增 `Wallet`、`TransactionResult`、`TransactionRecord`。
- [x] 增加 GUT 测试。

完成标准：

- 收入、支出、余额不足、非法数量都有测试。

### Step 2: Placement Service

- [x] 给 `Board` 增加 `can_place_tower()` 或等价校验结果。
- [x] 新增 `TowerPlacementService`。
- [x] 放塔时先校验格子，再扣费，再写 Board。
- [x] 增加 GUT 测试。

完成标准：

- 放塔费用不由 `Board` 或 `BoardView` 直接处理。

### Step 3: HUD Integration

- [x] `BoardView` 使用 `TowerPlacementService`。
- [x] HUD 显示 gold 和放塔成本。
- [x] 点击放塔后更新 gold。
- [x] 资源不足时显示失败反馈。

完成标准：

- 玩家能看到资源变化。
- 资源不足时不能继续放塔。

### Step 4: Enemy/Wave Rewards

- [x] 敌人死亡时调用 `wallet.earn(reward_amount, KILL_ENEMY, enemy_id)`。
- [x] 波次结束时调用 `wallet.earn(CLEAR_WAVE)`。
- [x] 击杀奖励逻辑有 GUT 测试。
- [x] 波次奖励逻辑有 GUT 测试。

完成标准：

- 资源系统可以支撑基础战斗循环和后续波次奖励。

## Open Questions

- 合成是否需要消耗 gold，还是只消耗塔。
- 是否需要出售/回收塔，回收比例是多少。
- 是否需要限制每波前的放塔次数。
