# 测试门禁

把这些门禁作为 agent 和人类共同遵守的项目级质量契约。

## 必需命令

大多数代码改动：

```bash
cd game
./tools/check-all.sh
```

交付非平凡改动前的 agent preflight：

```bash
cd game
./tools/agent-preflight.sh
```

GitHub Actions 会在 `.github/workflows/ci.yml` 中运行这个项目门禁，然后运行 native UI smoke 门禁。

CI 每次运行都会把完整 `ci-artifacts/` 目录上传为 `godot-check-artifacts` artifact，包括失败运行。

`check-all.sh` 包含对 `game/data/levels` 和 `game/data/map_styles` 的 JSON/schema 校验。

`check-all.sh` 还包含 Tree-sitter structural lint：

```bash
cd game
./tools/check-structure.sh
```

这个命令会解析项目 GDScript，报告写入 `ci-artifacts/structure/`。Tree-sitter 的本地 venv 和 grammar cache 位于 `build/structure-cache/`，不会进入 Godot 项目目录或 CI artifact。

当前 structural lint 会失败的情况：

- `game/scripts/core/` 下新增场景树、输入、节点查找、节点生命周期或 UI 节点依赖。
- `BoardView` 重新持有多个 `res://` 资源路径常量。
- `BoardView` 直接调用 `load()` 或 `preload()` 加载资产。
- `BoardAssetCatalog` 缺失，或 `BoardView` 不再通过它管理棋盘场景资产。

当前 structural lint 会以 warning 跟踪但不阻塞的技术债：

- `BoardView` 仍超过 1200 行，且函数数量偏多。
- `game/scripts/core/maps/BoardMapRenderer` 仍包含渲染和资源加载耦合。

native UI/可玩性 smoke 检查：

```bash
cd game
./tools/check-ui-smoke.sh
```

这个命令不做 Web 导出，直接运行 Godot desktop/native runtime；它会在桌面、移动横屏和方形视口验证 start-to-main 场景流程，通过场景输入路径放置一座塔，并把截图、局部放大 crop、overlay 辅助线图、人工 UI 检查清单和 `report.json` 写入 `ci-artifacts/ui-smoke/native/`。

使用 `./tools/summarize-ui-smoke.py` 可以在不重新运行 Godot 的情况下重新打印最近一次 smoke 报告。

native gameplay smoke 检查：

```bash
cd game
./tools/check-gameplay-smoke.sh
```

这个命令按确定性 gameplay scenario 运行 Godot native runtime。它不替代核心 GUT；它把放塔、Single 击杀奖励、Area 溅射、Slow 状态、漏怪扣生命、清波胜利和生命归零失败这些代表路径连到机器可读 trace，并为每个 checkpoint 输出整屏截图、board crop 和状态 overlay。产物位于 `ci-artifacts/gameplay-smoke/native/`。

仅文档改动：

```bash
cd game
./tools/check-docs.sh
```

## 玩法规则改动

任何合成、战斗、波次、经济、放置、目标选择、敌人移动、敌人生命、玩家生命或胜负规则的改动，都必须包含聚焦的 GUT 测试。

当规则有结构化失败结果时，测试应同时断言成功路径和失败/边界行为。

玩法规则改动前，先定位 `docs/gameplay/test-plan.md` 中对应的 GP 条目。新增玩法功能、改变玩家语义、改变配置形状或改变测试证据时，同步更新 `docs/gameplay/features.md` 和 `docs/gameplay/test-plan.md`。

玩法改动影响玩家可见结果、战斗表现、奖励、漏怪、波次推进或胜负状态时，除 GUT 外运行 `./tools/check-gameplay-smoke.sh`，并检查 `report.md`、scenario 截图、board crop 和 overlay。

## 场景和 UI 改动

场景/UI 改动应把规则断言保留在核心测试中。场景测试应覆盖集成边界：

- 场景可加载。
- 必需节点存在。
- 资源可加载。
- UI 状态反映核心状态。
- 输入到达正确的核心服务。
- 暂停、重开、胜利和失败流程保持玩法状态一致。

新增场景资产、数据加载或 BoardView 集成职责时，不要把新的资源路径和加载逻辑直接塞回 `BoardView`。优先放入 `BoardAssetCatalog` 或新的小型 adapter，并运行 `./tools/check-structure.sh`。

新增或大改 UI 功能前，先写简短验证方案。适用范围包括新增可见 UI 区域、按钮、面板、HUD 状态、弹窗、卡片、菜单，修改布局或响应式行为，修改素材框、字体、图标、按钮状态、可读性，或修改输入流程和可玩路径。

验证方案至少列出：

- 覆盖哪些 UI 区域。
- 覆盖哪些视口：desktop、mobile-landscape、square/compact。
- 覆盖哪些状态：默认、选中、禁用、错误、暂停、胜利、失败等。
- 覆盖哪些交互：点击、放置、切换、返回、重开等。
- 现有 crop/overlay 是否覆盖新增 UI surface；不覆盖时，先扩展 `game/tools/ui_smoke_runner.gd` 的 review crop/overlay。
- 交付前需要人工检查哪些 `report.md` checklist 项和截图产物。

新增 UI surface 时，应同步补对应的 smoke review artifact。新增面板、HUD 区域或卡片后，至少添加一个局部 crop 和 overlay；如果它有关键状态，runner 应能进入至少一个代表状态。

UI 改动后，检查 `docs/ui/features.md` 和 `docs/ui/test-plan.md` 是否需要更新。新增、删除或改变玩家可见 surface、状态、交互、响应式行为、测试覆盖或 UI smoke review artifact 时，必须同步更新。

场景、布局、渲染、输入或 UI 资产改动时，运行 `./tools/check-ui-smoke.sh`，继续前检查摘要、整屏截图、局部 crop、overlay 和 `report.md` 中的人工检查清单。它是 smoke test 和审查辅助，不是像素级视觉回归测试。

检查截图或试玩时发现的每个 UI 问题、可读性问题或美观度问题，都应作为单独 checkbox 记录到 `docs/todo/backlog.md`。不要把多个视觉问题合并成一条，也不要只在最终回复中提到。

## Bug 修复

Bug 修复应新增回归测试：修复前失败，修复后通过。

如果回归只涉及视觉且很难在 GUT 中断言，在最终回复记录手工验证，并在 `docs/todo/backlog.md` 增加后续项。

## 文档改动

文档布局变化时：

- 更新 `docs/README.md`。
- 项目状态变化时更新 `docs/status.md`。
- 设计状态变化时更新 `docs/designs/README.md`。
- 运行 `./tools/check-docs.sh`。

## GitHub Pages

GitHub Pages 由 `.github/workflows/pages.yml` 部署，来源是 `site/` 中的静态文件，以及 `_site/play/` 下的 Godot Web 导出。

本地 Web 导出产物必须位于 Godot 项目目录外。使用：

```bash
cd game
./tools/export-web.sh ../build/web
```

脚本会拒绝 `game/` 内的输出路径。
