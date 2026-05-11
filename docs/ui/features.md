# UI 功能清单

本文档记录当前玩家可见 UI 功能，以及 agent 做 UI 改动时需要同步检查的验证覆盖。

## 维护规则

UI 改动后先检查本文档是否需要更新。以下情况必须更新：

- 新增、删除、重命名或移动可见 UI surface。
- 改变按钮、面板、HUD、卡片、overlay、提示文本或玩家可见状态。
- 改变桌面、移动横屏或方形/紧凑视口的布局行为。
- 改变输入路径、菜单流程、胜负流程或重开/返回开始流程。
- 新增 UI surface 后，新增或调整 `game/tools/ui_smoke_runner.gd` 的 crop/overlay review artifact。
- 改变 `report.md` 人工检查清单或 UI smoke 覆盖边界。

纯内部重构如果不改变玩家可见行为、状态、布局或验证覆盖，可以不改本文档。

## 当前 UI Surface

| Surface | 主要节点或文件 | 玩家功能 | 状态和反馈 | 当前验证覆盖 |
| --- | --- | --- | --- | --- |
| 开始界面 | `game/scenes/start.tscn`, `game/scripts/start_screen.gd` | 显示标题、装饰框、crest 图标和 `Start` 按钮；点击进入主场景。 | 响应式居中布局。 | GUT 检查标题、按钮和入口场景；native smoke 通过开始按钮进入主场景，并生成 `*-start-screen.png` 和 `*-start-screen-overlay.png`。 |
| 主棋盘和地图 | `game/scenes/main.tscn`, `game/scripts/board/board_view.gd` | 显示 baked 地图、道路、可建造区域、已放置塔、敌人、敌人血条和攻击反馈。 | hover 放置预览、非法点击、Single/Area/Slow/Flame/Poison 圆形塔顶按当前目标旋转、投射物/命中特效、敌人行走/死亡动画。 | GUT 覆盖加载、地图资源、圆形塔顶资源、坐标映射、放置、hover 放置预览、敌人/攻击反馈和塔朝向；native smoke 覆盖放置前 tower placement preview、一次放塔和整屏截图；gameplay smoke 通过 `TowerPresentationCatalog` 输出逐塔视觉目录，覆盖每种 `visual_test_enabled` 塔的塔本体、投射物和命中特效 focus crop/overlay。 |
| HUD 资源栏 | `Hud/Gold`, `Hud/Lives`, `Hud/Wave`, `GoldIcon`, `LivesIcon`, `WaveIcon` | 显示金币、生命和波次。 | 放塔扣金币、击杀/清波奖励加金币、漏怪扣生命、波次显示保持可读。 | GUT 覆盖文本和状态更新；native smoke 生成 `*-hud-resources.png` 和 `*-hud-resources-overlay.png`。 |
| Status / Hint | `Hud/Status`, `Hud/Hint`, `BoardMessage` | 显示当前操作提示、选中塔信息、放置失败原因、奖励、漏怪、胜负状态。 | Session 输出结构化消息码、参数、完整文案和紧凑文案；紧凑布局直接使用消息的短文本和 ellipsis，避免覆盖棋盘或塔卡。 | GUT 覆盖结构化消息紧凑文案、移动横屏和方形布局边界；native smoke 生成 `*-status-hint.png`、`*-status-reward.png`、`*-status-leak.png` 及对应 overlay。 |
| 塔选择卡组 | `Hud/TowerDeck` 和从 `TowerPresentationCatalog` 自动生成的 `*TowerButton` | 选择下一次放置的塔：Single、Area、Slow、Flame、Poison；显示图标、描述和费用；按钮和数字键按 tower id 快速切塔。 | 选中态、暂停禁用、金币不足禁用、tooltip、桌面/移动横屏侧栏按配置纵排、方形视口底栏按可用宽度换行；紧凑侧栏选中态使用普通框加金色文字避免装饰压字。 | GUT 覆盖 presentation catalog、按钮选择、数字键选择、禁用、费用、响应式布局和 Poison 第五张塔卡；native smoke 从 presentation catalog 自动遍历选中态并生成 tower deck crop/overlay，另覆盖金币不足禁用状态。 |
| 塔操作菜单 | `Hud/TowerActionPanel`, `Title`, `Preview`, `UpgradeButton`, `RemoveButton` | 点击已放置塔后，在塔右上方显示浮动菜单；可查看下一次升级预览、升级或拆除该塔；`U` 可升级，`X`/`Delete`/`Backspace` 可拆除。 | 菜单 clamp 到视口内；升级预览显示伤害和范围成长；升级按钮显示配置化费用并在金币不足或满级时禁用；拆除按钮显示 50% 累计投入返还；`Esc` 优先关闭该菜单。 | GUT 覆盖点击塔弹出菜单、升级预览、快捷键升级/拆除、关闭和 HUD 同步；native smoke 生成 `*-tower-action-menu.png` 和 overlay。 |
| 放置输入 | `BoardView._unhandled_input`, `handle_board_click`, `try_place_at_grid` | 点击空可建造格放置当前选中塔；点击已放置塔进入塔操作菜单；键盘快捷键路由选塔和塔操作。 | hover 可建造空格时显示当前选中塔的半透明预览；成功放置、路径格拒绝、金币不足拒绝、已放置塔选择，并更新 status、hint 和金币。 | GUT 覆盖成功/失败路径、hover 预览显示条件、已放置塔点击路由、数字键选塔、快捷键升级/拆除和 Esc 关闭菜单；native smoke 截取 `*-tower-placement-preview.png`，并通过真实场景输入放置一座塔、打开塔操作菜单并尝试非法道路格。 |
| 暂停菜单 | `Hud/MenuButton`, `Overlay/Screen` | `Menu` 按钮或 `ui_cancel`/`Esc` 打开暂停 overlay；`Resume` 继续；`Start` 返回开始界面。 | 暂停时塔卡和菜单状态同步，overlay 显示 `Paused`；塔操作菜单打开时 `Esc` 先关闭菜单，再次按下才暂停。 | GUT 覆盖暂停、恢复、返回开始和 Esc 与塔操作菜单优先级；native smoke 生成 `*-pause-overlay.png` 和 `*-pause-overlay-overlay.png`。 |
| 胜利 overlay | `Overlay/Screen` | 全部波次清空后显示 `Victory`，可 `Restart` 或返回 `Start`。 | gameplay 暂停，status 显示胜利文案。 | GUT 覆盖胜利状态、overlay 文案和按钮；native smoke 生成 `*-victory-overlay.png` 和 `*-victory-overlay-overlay.png`。 |
| 失败 overlay | `Overlay/Screen` | 生命归零后显示 `Defeat`，可 `Restart` 或返回 `Start`。 | gameplay 暂停，status 显示失败文案。 | GUT 覆盖失败状态、overlay 文案和按钮；native smoke 生成 `*-defeat-overlay.png` 和 `*-defeat-overlay-overlay.png`。 |
| 响应式布局 | `BoardView.apply_responsive_layout`, `StartScreen._layout` | 桌面、移动横屏和方形/紧凑视口下保持棋盘、HUD、塔卡和提示可读可点。 | 移动横屏使用侧塔卡，方形视口使用底部塔卡和更高 HUD message 区。 | GUT 覆盖移动横屏和方形布局；native smoke 固定覆盖 `1280x720`、`896x414`、`720x720`。 |

## 当前 Smoke Review Artifact

每个 native smoke 视口生成：

- 整屏截图：`desktop.png`、`mobile-landscape.png`、`square.png`。
- 开始界面：`*-start-screen.png` 和 `*-start-screen-overlay.png`。
- HUD 资源栏：`*-hud-resources.png` 和 `*-hud-resources-overlay.png`。
- Status/Hint：默认、奖励和漏怪状态的 `*-status-*.png` 和 `*-status-*-overlay.png`。
- 塔选择卡组：默认、每个 `visual_test_enabled` 塔的选中态和金币不足状态的 `*-tower-deck*.png` 和 `*-tower-deck*-overlay.png`。
- 塔放置预览：`*-tower-placement-preview.png` 和 `*-tower-placement-preview-overlay.png`。
- 塔操作菜单：`*-tower-action-menu.png` 和 `*-tower-action-menu-overlay.png`。
- Overlay：`*-pause-overlay.png`、`*-victory-overlay.png`、`*-defeat-overlay.png` 和对应 overlay。
- 人工检查清单和链接：`report.md`。

每次 native gameplay smoke 还会生成：

- Board crop 和 overlay：`scenarios/**/desktop-*-board.png`、`desktop-*-overlay.png`。
- Focus crop 和 overlay：`scenarios/**/desktop-*-focus.png`、`desktop-*-focus-overlay.png`。
- 逐塔视觉目录：`tower_visual_catalog` 场景通过 `TowerPresentationCatalog` 从塔配置自动发现每个 `visual_test_enabled` 塔，并分别生成 `*-tower-ready`、`*-projectile-visible` 和 `*-impact-effect` checkpoint。

新增稳定 UI surface 时，优先添加对应的局部 crop 和 overlay。如果该 surface 有关键状态，runner 应能进入至少一个代表状态。

## 已知覆盖边界

- Native smoke 当前不单独截图每种塔实际放置后的棋盘状态，只截图塔卡选中态；实际塔/投射物/命中特效由 gameplay smoke 的逐塔视觉目录覆盖。
- UI smoke 的主棋盘只单独截图放置预览；需要看已放置塔/敌人/投射物贴合时使用 gameplay smoke 的 board crop/overlay。
- 当前没有像素级 golden image baseline；视觉审查依赖 smoke crop、overlay 和人工 checklist。
