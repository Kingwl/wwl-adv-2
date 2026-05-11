# 项目状态

## 当前里程碑

里程碑 1：Playable Prototype 已完成；里程碑 2：MVP 准备已开始。

可玩循环已经具备：玩家可以开始、放塔、升级、拆除、战斗、获胜或失败。MVP 目前主线是内容数据化和更长可演示局。

## 已验证命令

最近检查：2026-05-11。

```bash
cd game
./tools/check-all.sh
./tools/agent-preflight.sh
./tools/agent-preflight-full.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-structure.sh
./tools/check-ui-smoke.sh
./tools/check-gameplay-smoke.sh
./tools/check-web-smoke.sh ../build/web-smoke
```

当前已知测试状态：

- Godot: 4.6.2 stable.
- GUT: 9.6.0.
- GUT 套件：205 个测试通过，1414 个断言。
- Native UI smoke：桌面、移动横屏和方形视口通过，截图位于 `ci-artifacts/ui-smoke/native/`。
- Native gameplay smoke：11 个代表性 gameplay scenario 通过，trace、截图、board overlay 和 focus overlay 位于 `ci-artifacts/gameplay-smoke/native/`。
- Web export smoke：Web 导出页面通过本地 HTTP + headless browser 检查，报告和截图位于 `ci-artifacts/web-smoke/`。
- Structural lint：Tree-sitter GDScript 解析 101 个文件，0 个 error，0 个 warning。
- Agent preflight fast：运行 `check-all.sh`，生成 Godot/GUT 结构化日志报告，不运行 native smoke。
- Agent preflight full：运行 fast preflight、native UI smoke、native gameplay smoke 和 UI smoke 摘要。
- 已知警告：GUT 退出时有来自场景/资源清理的 ObjectDB leaked instances 警告，记录为 TD-007。

## 已实现

- Godot 4.x 项目骨架和 GUT 配置。
- 可测试的 `game/scripts/core/` 规则层。
- 棋盘放置、移除、保留格和路径校验规则。
- 经济钱包、放置费用、击杀奖励和波次清空奖励；默认经济配置位于 `game/data/economy/economy.json`。
- 敌人路径移动、生命值、死亡事件和漏怪处理。
- 固定 tick 战斗模拟。
- 塔配置数据文件、注册表、目标选择、攻击冷却、投射物生成、投射物移动和命中检测。
- 波次生成和波次清空事件。
- 玩家生命、胜利和失败状态。
- 开始场景、主场景、暂停菜单、重开、返回开始、胜利和失败流程。
- 五种基础塔：Single、Area、Slow、Flame 和 Poison，定义位于 `game/data/towers/towers.json`，包括建造费用、塔/投射物/命中特效资源引用，并由 `game/data/schemas/towers.schema.json` 和 `check-assets.sh` 校验。
- 点击已放置塔会显示右上角浮动操作菜单，支持直接升级和拆除。
- 塔选择卡组从塔配置自动生成；支持数字键按配置顺序选择塔，`U` 升级选中塔，`X`/`Delete`/`Backspace` 拆除选中塔，`Esc` 优先关闭塔操作菜单再进入暂停。
- 塔升级效果按塔类型和 tier 配置化；普通升级只做数值提升，每次升级必须提升伤害和攻击范围；升级不清空攻击冷却，只会按新攻击间隔钳制剩余冷却。
- 塔操作菜单显示下一次升级预览，包含伤害和范围成长。
- 攻击、防御、伤害类型和种族抗性第一版已进入核心伤害结算；现有五塔的武器形态、攻击类型、伤害类型、攻击模式、投射物速度和视觉资源从塔数据文件加载。
- 通用状态和 DoT 第一版已进入核心战斗：塔 tier 通过 `effects[]` 表达即时伤害、溅射伤害和附加状态；Slow 会作为状态实际降低敌人移动速度，Flame 会施加 Burn DoT，Poison 会施加 Poison DoT，Burn/Poison 类 DoT 可按完整 tick interval 产生携带攻击/伤害类型的 `DamageEvent` 并继续走伤害克制结算。
- 拆除塔会返还 50% 建造和升级累计投入。
- 五种基础塔在棋盘和塔卡中使用生成的圆形塔顶 sprite，运行时按当前目标方向旋转；Flame 塔、Poison 塔和对应命中特效使用本地生成的新素材。
- 当前地图的数据驱动关卡路径/style 加载。
- 敌人定义位于 `game/data/enemies/enemies.json`，包含 speed、health、kill reward、armor/race 和伤害类型抗性 override；波次定义位于 `game/data/waves/waves.json`，按 enemy type 引用敌人配置。
- 生成的城市防御地图、道路 guide 产物、UI frame、塔 sprite、敌人 sprite 和攻击特效。
- 覆盖 start-to-main 可玩性、响应式视口、单塔放置、塔操作菜单和截图产物的 native UI smoke。
- 覆盖放塔、升级/拆除返还、Single 击杀奖励、Area 溅射、Slow 状态、Flame 灼烧 DoT、Poison 中毒 DoT、逐塔视觉目录、漏怪、胜利和失败的 native gameplay smoke。
- 逐塔视觉目录从塔配置自动发现 `visual_test_enabled` 的塔，并为每种塔产出塔本体、投射物飞行中、命中/效果出现后的整屏截图、board crop、focus crop 和辅助线 overlay。
- Tree-sitter structural lint，覆盖 core/scene/render 边界、BoardView 资产加载边界和结构回膨胀 warning 报告。
- `BoardAssetCatalog`，集中管理主棋盘场景的关卡、map style、HUD 图标、敌人 sprite 和特效贴图加载；塔本体、投射物和命中特效资源从 `TowerConfig` 读取。
- `BoardGameSession`，集中管理一局游戏的棋盘、钱包、放置服务、战斗模拟、波次、奖励和胜负 flow；场景测试和 smoke runner 通过 `BoardView.get_session()` 明确访问。
- `BoardLayoutService`、`BoardHudController`、`BoardInputAdapter`、`BoardVisualState` 和 `BoardRenderer`，分别承接主棋盘响应式布局、HUD/overlay 同步、输入路由、表现层动画状态和绘制 adapter。
- `BoardView` 不再保留 session、layout、asset 或 visual state 的兼容镜像字段；场景测试和 smoke runner 通过显式 getter 访问拆出的边界。
- `BoardMapRenderer` 已从 `game/scripts/core/` 迁到 `game/scripts/board/`，core 目录下渲染/资源加载耦合现在由 structural lint 作为 error 阻止。
- `TowerConfig` 的 JSON 加载/原始解析和语义校验已拆到 `TowerDefinitionParser`、`TowerDefinitionValidator`；`TowerConfig` 保留运行时读取 API 和向后兼容委托入口。
- 用于本地 agent 迭代反馈的 agent preflight 和 UI smoke 摘要脚本。
- Godot/GUT 日志结构化报告，输出到 `ci-artifacts/godot-log/report.json` 和 `report.md`。
- Web export smoke，验证 Godot Web 导出页面 canvas 非空且无关键浏览器错误，并作为 Pages 发布前门禁。
- 设计文档已收敛为当前架构聚合文档；历史细分设计归档到 `docs/designs/archive/`。
- 面向核心玩法规则、场景/UI 验证和 harness 维护的项目 Codex skills。
- 面向核心玩法和 UI 的功能清单与测试计划文档。

## 开放决策

- 敌人、波次和经济配置的数据形状第一版已实现；后续多敌人类型分布和长波次平衡仍待决定。
- 初期塔类型和实现批次已记录为 accepted design；火焰塔和毒针塔已进入代码和测试，雷霆塔等后续塔仍待实现。
- 塔机制、效果、状态、DoT 和视觉事件体系已记录为 accepted design；状态/DoT 核心规则、塔 `effects[]` 配置、Flame 灼烧塔和 Poison 毒针塔第一版已实现，雷霆塔和独立视觉事件仍未实现。
- 塔升级机制第一版已实现；未来是否加入分支进化仍待决定。
- 更长波次前，是否需要清理已完成/已击败但仍保留的敌人。
- 生成的 road ribbon 资产是否应变成确定性的运行时/编辑器生成内容。

## 已知风险

- 塔 roster 仍受 `GameTower.Type`、tower schema、工具枚举和若干 tower-type match 绑定，新增塔不是纯数据改动，记录为 TD-011 和 TD-016。
- `TowerConfig` 已拆出 loader/parser/validator，但仍保留默认值、legacy tier/effect fallback 和 UI spec；`BoardRenderer`、`BoardHudController` 和 `test_main_scene.gd` 仍是体积最大的维护点，记录为 TD-012、TD-015 和 TD-017。
- 当前敌人和波次已数据化，但只有三类基础敌人和 prototype 三波；MVP 长局仍缺平衡快照。
- 紧凑视口 status/hint 依赖自由文本解析，文案调整可能破坏 UI 状态同步，记录为 TD-014。
- 测试质量依赖 GUT 加 checklist，而不是行覆盖率。
- 场景测试当前会输出 ObjectDB leak 警告，记录为 TD-007。

## GitHub 自动化

- CI workflow：`.github/workflows/ci.yml`。
- CI 运行 `check-all.sh`、native UI smoke 和 native gameplay smoke；`check-all.sh` 包含关卡、map style、塔配置资产/schema 检查和 Tree-sitter structural lint。
- CI 将 `check-all.log` 解析为 Godot/GUT 结构化报告。
- CI 将 `ci-artifacts/` 上传为 `godot-check-artifacts` artifact。
- GitHub Pages workflow：`.github/workflows/pages.yml`。
- Pages 来源：GitHub Actions workflow 从 `site/` 加 `_site/play/` 下的 Godot Web 导出进行部署。
- Pages 发布前运行 Web export smoke，并上传 `ci-artifacts/web-smoke/` 作为失败证据。
- 本地 Web 导出默认输出到 Godot 项目目录外的 `build/web/`。
- 项目 skills 版本化存放在 `.codex/skills/`；本地 Codex runtime 不会自动加载仓库内 skills 时，将它们链接到 `$CODEX_HOME/skills`。

## 下一步最值得做的工作

1. 继续收口 `TowerConfig`：移出 UI button/visual test spec，并清理已被 `effects[]` 取代的 legacy tier/effect fallback。
2. 在雷霆塔前处理塔 roster 的 `GameTower.Type` 绑定，逐步转向 tower id 驱动。
3. 保持 `game/tools/check-all.sh` 作为默认验证命令。
