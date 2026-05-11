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
| UI-START-001 | 开始界面 | 标题、crest、装饰框、`Start` 按钮；点击 `Start` 进入主场景；桌面和紧凑视口居中可读。 | GUT 检查入口场景、标题、按钮文本和可点击尺寸；native smoke 通过开始按钮进入主场景，并截图局部面板和全视口开始页。 | `*-start-screen.png`、`*-start-screen-full.png` 和对应 overlay；4x4 visual-review key crops。 | 未覆盖开始界面的其他状态；当前只有默认入口状态。 |
| UI-BOARD-001 | 主棋盘和地图 | 地图加载、道路可见、棋盘缩放后坐标映射正确、hover 可建造空格时显示当前选中塔预览、敌人/塔/血条/攻击反馈可见；Single/Area/Slow/Flame/Poison 圆形塔顶资源居中，运行时按当前目标旋转；每种塔的投射物和命中特效可见。 | GUT 覆盖地图资源、默认路径、圆形塔顶资源尺寸、坐标映射、放置、hover 放置预览显示条件、敌人生成、攻击反馈和 Single/Flame/Poison 资产读取；native UI smoke 覆盖放置预览、一次放塔和敌人生成；native gameplay smoke 通过 `TowerPresentationCatalog` 自动发现逐塔视觉目录，覆盖 Single 放塔、攻击投射物、Flame 灼烧、Poison 中毒和击杀奖励截图。 | `*-tower-placement-preview.png` 和 overlay；UI smoke 整屏截图；gameplay smoke `tower_visual_catalog` 的 `*-tower-ready`、`*-projectile-visible`、`*-impact-effect` focus crop/overlay，以及其他 gameplay scenario board/focus crop。 | 已放置塔、敌人、投射物和命中特效视觉审查依赖 gameplay smoke 的 board/focus crop；尚无像素级 golden baseline。 |
| UI-HUD-001 | HUD 资源栏 | Gold/Lives/Wave 文本和图标可读；放塔扣金币；奖励加金币；漏怪扣生命；波次显示稳定。 | GUT 覆盖初始值和状态更新；native smoke 检查文本、截图非空。 | `*-hud-resources.png` 和 `*-hud-resources-overlay.png`；`report.md` HUD resources checklist。 | 不做像素级居中断言，依赖 crop/overlay 人工审查。 |
| UI-MSG-001 | Status / Hint | 初始提示、选中塔提示、放置成功、放置失败、金币不足、奖励、漏怪、胜负文本；紧凑视口短文本/ellipsis 不遮挡棋盘或塔卡，compact inline 消息行在移动横屏中不贴边拥挤。 | GUT 覆盖 `BoardMessage` 结构化状态码、完整/紧凑文案选择和移动/方形布局边界；native smoke 覆盖放置成功后非法道路格、奖励和漏怪提示。 | `*-status-hint.png`、`*-status-reward.png`、`*-status-leak.png` 和对应 overlay；`report.md` Status/hint checklist；4x4 visual-review key crops。 | 胜负 status 主要由 overlay crop 和 GUT 覆盖；如单独调整胜负 HUD 文案再补状态 crop。 |
| UI-TOWER-001 | 塔选择卡组 | 从 `TowerPresentationCatalog` 自动生成 Single/Area/Slow/Flame/Poison 塔卡；按钮和数字键按 tower id 切塔；选中态；暂停禁用；金币不足禁用；图标、描述、费用和 tooltip；侧栏/底栏响应式布局；右侧竖排塔卡文字不被内部装饰线、宝石或边框干扰。 | GUT 覆盖 presentation catalog、按钮选塔、数字键选塔到第 5 张卡、放置塔类型、金币不足禁用、暂停禁用和响应式布局；native smoke 从 `TowerPresentationCatalog.get_visual_test_tower_specs()` 自动遍历塔卡选中态，并覆盖金币不足禁用视觉状态。 | `*-tower-deck.png`、`*-tower-deck-*-selected.png`、`*-tower-deck-insufficient-gold.png` 和对应 overlay；`report.md` Tower deck checklist；4x4 visual-review key crops。 | 暂停禁用的塔卡视觉由 pause overlay 状态间接覆盖。 |
| UI-ACTION-001 | 塔操作菜单 | 点击已放置塔显示右上角浮动菜单；升级预览显示伤害和范围成长；`Upgrade` 显示费用并按金币/满级禁用；`Remove` 显示返还；`U` 升级，`X`/`Delete`/`Backspace` 拆除；`Esc` 关闭菜单；点击空格/道路、暂停和重开关闭菜单；三种视口不出屏且文字不裁切。 | GUT 覆盖菜单显示、升级预览、升级按钮、拆除按钮、快捷键升级/拆除、Esc 关闭、HUD 和 hint 同步；native smoke 覆盖真实输入打开菜单和关闭菜单。 | `*-tower-action-menu.png` 和 `*-tower-action-menu-overlay.png`；`report.md` Tower action menu checklist。 | 未单独截图满级和金币不足升级按钮状态；如果升级菜单样式复杂化再补状态 crop。 |
| UI-PLACE-001 | 放置输入 | hover 可建造格显示当前选中塔预览；点击可建造格放置当前选中塔；点击已放置塔打开操作菜单；数字键切换放置塔；点击道路格或金币不足时拒绝；金币、status 和 hint 更新。 | GUT 覆盖成功、路径格、占用格直接放置拒绝、金币不足、hover 预览显示条件、已放置塔点击路由、Flame 选塔放置和键盘输入路由；native smoke 通过真实场景输入放置一座塔、打开操作菜单并尝试非法道路格，并生成放置预览 crop。 | 整屏截图、`*-tower-placement-preview.png`、Status/Hint crop、Tower deck crop、Tower action menu crop。 | 未覆盖触摸手势差异；当前只用鼠标事件路径。 |
| UI-MENU-001 | 暂停菜单 | `Menu` 或 `ui_cancel`/`Esc` 打开暂停 overlay；塔操作菜单打开时 `Esc` 先关闭菜单；`Resume` 继续；`Start` 返回开始界面；暂停时塔卡和菜单状态同步。 | GUT 覆盖暂停、恢复、按钮文案、返回开始、状态同步和 Esc 优先级；native smoke 进入暂停状态截图。 | `*-pause-overlay.png` 和 `*-pause-overlay-overlay.png`。 | 暂停状态下塔卡禁用视觉没有单独 tower deck crop；如果禁用样式变化再补。 |
| UI-WIN-001 | 胜利 overlay | 全部波次清空后显示 `Victory`；`Restart` 重开；`Start` 返回开始；status 显示胜利。 | GUT 覆盖胜利状态、overlay 文案和按钮；native smoke 进入胜利 overlay 截图。 | `*-victory-overlay.png` 和 `*-victory-overlay-overlay.png`。 | native smoke 直接调用场景方法进入视觉状态，不模拟完整打通最终波次。 |
| UI-LOSE-001 | 失败 overlay | 生命归零后显示 `Defeat`；`Restart` 重开；`Start` 返回开始；status 显示失败。 | GUT 覆盖失败状态、overlay 文案和按钮；native smoke 进入失败 overlay 截图。 | `*-defeat-overlay.png` 和 `*-defeat-overlay-overlay.png`。 | native smoke 直接调用场景方法进入视觉状态，不模拟完整漏怪到 0 生命。 |
| UI-RESP-001 | 响应式布局 | 桌面、移动横屏、方形/紧凑视口下 HUD、棋盘、塔卡、status/hint 互不遮挡且可读可点；塔卡数量来自配置，底栏按可用宽度换行。 | GUT 覆盖移动横屏、方形底部塔卡、紧凑消息区、第五张塔卡布局和坐标映射；native smoke 覆盖三个固定视口，并自动生成 4x4 visual-review。 | UI smoke 三个视口整屏截图、按配置生成的 crop/overlay、`visual-review/ui-fullscreens-mean4x4-contact.png`、`visual-review/ui-key-crops-mean4x4-contact.png`；gameplay smoke 每个 checkpoint 额外产出 board/focus crop 和辅助线 overlay。 | 未覆盖竖屏手机；如果支持竖屏，需要新增视口和布局契约。 |

## 新增 UI 功能的测试计划要求

新增或大改 UI 功能时，在实现前给出本次变更的验证方案，并在交付前更新上面的矩阵。验证方案至少包含：

- 受影响的 UI 功能 ID，或新增 ID。
- 覆盖哪些视口。
- 覆盖哪些状态和交互。
- 需要新增或修改哪些 GUT 场景测试。
- 需要新增或修改哪些 native smoke 行为、crop、overlay 或 `report.md` checklist。
- 哪些项目仍是人工审查，哪些已经自动化。

如果新增 UI 功能暂时不适合自动化，仍要在矩阵的“当前缺口”里写清楚原因和后续触发条件。
