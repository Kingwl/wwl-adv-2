# Design: 游戏流程 UI

## Status

Implemented for the playable prototype.

## Context

当前游戏场景已经可以放塔、出怪、攻击、漏怪、胜利和失败。流程 UI 需要区分开始界面和游戏内菜单，避免 BoardView 同时承担入口页和游戏状态。

## Goals

- 项目入口是单独的 `start.tscn`。
- 开始界面显示标题 `WWL 大冒险 2`。
- 点击开始后切换到游戏场景 `main.tscn`。
- 游戏中可以打开菜单，并暂停战斗。
- 菜单支持继续和返回开始界面。
- 胜利和失败时自动显示结算面板，并暂停战斗。
- 胜利/失败面板支持重开和返回开始界面。
- 这些流程属于场景 UI，不改变核心战斗规则。

## Rules

场景切换规则：

```text
start.tscn --Start--> main.tscn
main.tscn --Menu/Start--> start.tscn
main.tscn --Victory/Start--> start.tscn
main.tscn --Defeat/Start--> start.tscn
```

BoardView 维护游戏场景内状态：

```text
PLAYING
MENU
WON
LOST
```

暂停规则：

- `MENU`、`WON`、`LOST` 都设置 `gameplay_paused = true`。
- `PLAYING` 设置 `gameplay_paused = false`。
- `_process(delta)` 在 `gameplay_paused == true` 时不推进 `CombatSimulation`。
- 暂停时不处理棋盘点击输入。

## UI Structure

新增开始场景：

```text
StartScreen (Control)
├── Backdrop (ColorRect)
├── Title (Label)
└── StartButton (Button)
```

游戏场景保留：

```text
Hud/MenuButton
Overlay/Screen
Overlay/Screen/Backdrop
Overlay/Screen/Panel
Overlay/Screen/Panel/Title
Overlay/Screen/Panel/Message
Overlay/Screen/Panel/PrimaryButton
Overlay/Screen/Panel/SecondaryButton
```

按钮行为：

- 开始界面：`Start` 进入 `main.tscn`。
- 暂停菜单：Primary = `Resume`，Secondary = `Start`。
- 胜利界面：Primary = `Restart`，Secondary = `Start`。
- 失败界面：Primary = `Restart`，Secondary = `Start`。

键盘行为：

- `ui_cancel` 在游戏中打开暂停菜单。
- `ui_cancel` 在暂停菜单中继续游戏。

## Test Coverage

场景测试覆盖：

- 主场景包含 menu button 和 overlay 节点。
- 项目入口配置为 `res://scenes/start.tscn`。
- 开始场景显示 `WWL 大冒险 2` 和 `Start` 按钮。
- 游戏场景直接进入 `PLAYING`。
- 暂停菜单暂停敌人移动。
- 暂停菜单继续后敌人继续移动。
- 暂停菜单提供返回开始界面入口。
- 失败时显示 Defeat 面板并暂停。
- 失败面板提供返回开始界面入口。
- 胜利时显示 Victory 面板并暂停。
- 胜利面板提供返回开始界面入口。

## Follow-Ups

- 增加更完整的结算统计。
- 增加设置入口，例如音量和速度。
- 真机移动端补安全区布局。
