# UI 测试计划

本文档记录当前 UI 功能的测试计划。`features.md` 说明“有哪些 UI”，本文档说明“这些 UI 应该怎么测”。

## 维护规则

UI 改动后先检查本文档是否需要更新。以下情况必须更新：

- 新增、删除或改变 UI surface、玩家可见状态或交互路径。
- 改变桌面、移动横屏或方形/紧凑视口的布局行为。
- 新增、删除或调整 GUT 场景测试、native UI smoke 行为、crop/overlay 产物或 `report.md` 人工检查清单。
- 将测试覆盖从人工检查迁移到自动化，或新增已知覆盖缺口。

纯样式微调如果不改变测试范围、状态、交互或验证产物，可以不改本文档；但如果发现新的 UI 问题，仍应记录到 `docs/todo/backlog.md`。

## 默认验证命令

常规 UI 改动：

```bash
cd game
./tools/check-ui-smoke.sh
```

非平凡 UI 改动或交付前：

```bash
cd game
./tools/agent-preflight-full.sh
```

只改文档：

```bash
cd game
./tools/check-docs.sh
```

## 默认视口

Native UI smoke 固定覆盖：

- Desktop：`1280x720`。
- Mobile landscape：`896x414`。
- Square/compact：`720x720`。

新增响应式行为时，先判断这三个视口是否足够暴露风险；不足时，用 `UI_SMOKE_VIEWPORTS` 增加调试视口，并考虑把新视口加入长期 smoke。

## 功能测试矩阵

| ID | UI 功能 | 必测状态和交互 | 自动化覆盖 | 人工审查产物 | 当前缺口 |
| --- | --- | --- | --- | --- | --- |
| UI-START-001 | 开始界面 | 标题、crest、装饰框、`Start` 按钮；点击 `Start` 进入主场景；桌面和紧凑视口居中可读。 | GUT 检查入口场景、标题、按钮文本和可点击尺寸；native smoke 通过开始按钮进入主场景。 | `*-start-screen.png` 和 `*-start-screen-overlay.png`。 | 未覆盖开始界面的其他状态；当前只有默认入口状态。 |
| UI-BOARD-001 | 主棋盘和地图 | 地图加载、道路可见、棋盘缩放后坐标映射正确、敌人/塔/血条/攻击反馈可见；Single/Area/Slow 圆形塔顶资源居中，运行时按当前目标旋转。 | GUT 覆盖地图资源、默认路径、圆形塔顶资源尺寸、坐标映射、放置、敌人生成、攻击反馈和 Single 塔朝向；native UI smoke 覆盖一次放塔和敌人生成；native gameplay smoke 覆盖 Single 放塔、攻击投射物和击杀奖励截图。 | UI smoke 整屏截图；gameplay smoke `place_single_tower` 和 `single_tower_kill_reward` board crop/overlay。 | UI smoke 没有棋盘局部 overlay；棋盘视觉审查目前依赖 gameplay smoke board crop。 |
| UI-HUD-001 | HUD 资源栏 | Gold/Lives/Wave 文本和图标可读；放塔扣金币；奖励加金币；漏怪扣生命；波次显示稳定。 | GUT 覆盖初始值和状态更新；native smoke 检查文本、截图非空。 | `*-hud-resources.png` 和 `*-hud-resources-overlay.png`；`report.md` HUD resources checklist。 | 不做像素级居中断言，依赖 crop/overlay 人工审查。 |
| UI-MSG-001 | Status / Hint | 初始提示、选中塔提示、放置成功、放置失败、金币不足、奖励、漏怪、胜负文本；紧凑视口短文本/ellipsis 不遮挡棋盘或塔卡。 | GUT 覆盖状态文本和移动/方形布局边界；native smoke 覆盖放置成功后非法道路格、奖励和漏怪提示。 | `*-status-hint.png`、`*-status-reward.png`、`*-status-leak.png` 和对应 overlay；`report.md` Status/hint checklist。 | 胜负 status 主要由 overlay crop 和 GUT 覆盖；如单独调整胜负 HUD 文案再补状态 crop。 |
| UI-TOWER-001 | 塔选择卡组 | Single/Area/Slow 三张卡；选中态；暂停禁用；金币不足禁用；图标、描述、费用和 tooltip；侧栏/底栏响应式布局。 | GUT 覆盖选塔、放置塔类型、金币不足禁用、暂停禁用和响应式布局；native smoke 覆盖 Single 默认、Area 选中、Slow 选中和金币不足禁用视觉状态。 | `*-tower-deck.png`、`*-tower-deck-area-selected.png`、`*-tower-deck-slow-selected.png`、`*-tower-deck-insufficient-gold.png` 和对应 overlay；`report.md` Tower deck checklist。 | 暂停禁用的塔卡视觉由 pause overlay 状态间接覆盖；如塔卡禁用样式复杂化再补专用 crop。 |
| UI-PLACE-001 | 放置输入 | 点击可建造格放置当前选中塔；点击道路格、占用格或金币不足时拒绝；金币和 status 更新。 | GUT 覆盖成功、路径格、占用格、金币不足；native smoke 通过真实场景输入放置一座塔并尝试非法道路格。 | 整屏截图、Status/Hint crop、Tower deck crop。 | 未覆盖触摸手势差异；当前只用鼠标事件路径。 |
| UI-MENU-001 | 暂停菜单 | `Menu` 或 `ui_cancel` 打开暂停 overlay；`Resume` 继续；`Start` 返回开始界面；暂停时塔卡和菜单状态同步。 | GUT 覆盖暂停、恢复、按钮文案、返回开始和状态同步；native smoke 进入暂停状态截图。 | `*-pause-overlay.png` 和 `*-pause-overlay-overlay.png`。 | 暂停状态下塔卡禁用视觉没有单独 tower deck crop；如果禁用样式变化再补。 |
| UI-WIN-001 | 胜利 overlay | 全部波次清空后显示 `Victory`；`Restart` 重开；`Start` 返回开始；status 显示胜利。 | GUT 覆盖胜利状态、overlay 文案和按钮；native smoke 进入胜利 overlay 截图。 | `*-victory-overlay.png` 和 `*-victory-overlay-overlay.png`。 | native smoke 直接调用场景方法进入视觉状态，不模拟完整打通最终波次。 |
| UI-LOSE-001 | 失败 overlay | 生命归零后显示 `Defeat`；`Restart` 重开；`Start` 返回开始；status 显示失败。 | GUT 覆盖失败状态、overlay 文案和按钮；native smoke 进入失败 overlay 截图。 | `*-defeat-overlay.png` 和 `*-defeat-overlay-overlay.png`。 | native smoke 直接调用场景方法进入视觉状态，不模拟完整漏怪到 0 生命。 |
| UI-RESP-001 | 响应式布局 | 桌面、移动横屏、方形/紧凑视口下 HUD、棋盘、塔卡、status/hint 互不遮挡且可读可点。 | GUT 覆盖移动横屏、方形底部塔卡、紧凑消息区和坐标映射；native smoke 覆盖三个固定视口。 | 三个视口整屏截图和 12 组 crop/overlay。 | 未覆盖竖屏手机；如果支持竖屏，需要新增视口和布局契约。 |

## 新增 UI 功能的测试计划要求

新增或大改 UI 功能时，在实现前给出本次变更的验证方案，并在交付前更新上面的矩阵。验证方案至少包含：

- 受影响的 UI 功能 ID，或新增 ID。
- 覆盖哪些视口。
- 覆盖哪些状态和交互。
- 需要新增或修改哪些 GUT 场景测试。
- 需要新增或修改哪些 native smoke 行为、crop、overlay 或 `report.md` checklist。
- 哪些项目仍是人工审查，哪些已经自动化。

如果新增 UI 功能暂时不适合自动化，仍要在矩阵的“当前缺口”里写清楚原因和后续触发条件。
