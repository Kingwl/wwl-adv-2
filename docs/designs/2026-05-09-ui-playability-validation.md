# 设计：UI 可玩性验证

## 状态

Accepted

## 背景

项目已经对核心玩法规则和场景集成有较强的 GUT 覆盖。它也会把可玩的 Godot Web 构建导出到 GitHub Pages 的 `/play/`。

缺失的 harness 层是自动化 UI/可玩性验证。一个场景可以通过单元测试，但仍然渲染出空白棋盘、在常见视口下布局崩坏、输入路由失败，或发布出坏掉的 Web 导出。

单靠 Web 验证不是合适的开发循环。Web 导出会增加较慢的构建步骤，主要验证导出/runtime 打包。日常调试应优先直接运行 Godot desktop/native runtime，因为它更接近项目编辑方式，迭代也快得多。

这个设计定义两层验证：

- Native UI smoke：用于开发的快速本地和 CI 门禁。已由 `game/tools/check-ui-smoke.sh` 实现。
- Web export smoke：用于 Web/Pages 打包的较慢发布门禁。尚未实现。

## 目标

- 提供一个不需要 Web 导出的快速 native UI smoke 命令。
- 覆盖真实场景流程、视口布局、基础输入和一次玩法交互。
- 捕获截图、局部放大 crop、overlay 辅助线图和机器可读报告，供 agent 检查。
- 让 Web smoke 聚焦于导出特有失败：资源缺失、浏览器 runtime 错误、空白 canvas 和 Pages 打包。
- 所有生成产物都放在 `game/` 外。

## 非目标

- 带严格 golden image 比对的完整视觉回归测试。
- 平衡性或策略验证。
- 长时间游玩耐久测试。
- 自定义 Godot engine template 体积优化。
- 替代 GUT 或确定性核心测试。

## 方案

添加一个主要 native smoke 门禁：

```bash
./game/tools/check-ui-smoke.sh
```

native smoke 命令应直接运行 Godot 项目，不做导出。它应在普通 desktop renderer 下执行专用 GDScript runner：

```bash
godot --path game --script res://tools/ui_smoke_runner.gd
```

在 CI Linux 上，用虚拟显示运行：

```bash
xvfb-run -a godot --path game --script res://tools/ui_smoke_runner.gd
```

runner 应该：

1. 为每个必需视口尺寸创建视口。
2. 加载 `res://scenes/start.tscn`。
3. 验证标题和开始按钮存在。
4. 触发开始流程，并验证 `res://scenes/main.tscn` 已加载。
5. 验证棋盘、HUD、tower deck、波次状态、金币和生命标签存在。
6. 推进足够帧数，让布局和初始模拟稳定。
7. 通过场景使用的同一条输入路径，在一个已知可建造格放置一座塔。
8. 短暂推进模拟，并验证棋盘仍可玩。
9. 在 `game/` 外保存整屏截图、关键区域 crop、overlay 辅助线图和报告。
10. 失败时以非零状态退出。

必需 native 视口：

- 桌面：`1280x720`。
- 移动横屏：`896x414`。
- 方形/紧凑：`720x720`。

产物应写入 `ci-artifacts/ui-smoke/native/`：

- `report.json`：通过/失败、视口尺寸、检查项、耗时和失败信息。
- `report.md`：人类可读摘要，包含人工 UI 检查清单、crop/overlay 链接和 overlay 图例。
- `desktop.png`.
- `mobile-landscape.png`.
- `square.png`.
- 每个视口的开始界面、HUD 资源栏、Status/Hint、塔选择卡组、塔选择变体、金币不足状态、奖励/漏怪提示、暂停 overlay、胜利 overlay 和失败 overlay 局部放大 crop。
- 每个局部 crop 对应的 `*-overlay.png`，用于展示 frame/panel、label/button、icon、group rect 和 group centerline。
- `godot.log`.

第一版应使用 smoke 断言，而不是精确像素匹配。空白/损坏输出、节点缺失、无法放置或明显布局崩塌时应失败。

## Web Export Smoke

添加一个次级 Web smoke 命令：

```bash
./game/tools/check-web-smoke.sh
```

这个命令会更慢，应聚焦于导出/部署信心：

1. 使用 `./game/tools/export-web.sh` 导出到 `build/web-smoke/`。
2. 通过本地 HTTP 服务导出产物。
3. 检查 `/`、`/index.wasm` 和 `/index.pck` 返回 HTTP 200。
4. 用 Playwright Chromium 打开页面。
5. 断言 canvas 非空白，且没有关键浏览器错误。
6. 将截图、console log、server log 和 `report.json` 保存到 `ci-artifacts/ui-smoke/web/`。

Web smoke 不应作为默认开发调试路径。它应在发布前，或 Web/export 工具变化时运行。

## CI 集成

runner 稳定后，在 `.github/workflows/ci.yml` 的 `./tools/check-all.sh` 后添加 native UI smoke。

即使失败也上传 `ci-artifacts/`。这样 agent 仍能获取 native 截图和报告。

保持 `.github/workflows/pages.yml` 聚焦于发布。Pages workflow 可以在上传前运行 Web smoke，但 native UI 失败应更早在 CI 中捕获。

建议分阶段：

1. 实现 `check-ui-smoke.sh`，并先手工/本地运行。
2. 将 native UI smoke 作为必需项目门禁加入 CI。
3. 将 Web smoke 加入 Pages workflow 或独立 publish-check job。
4. 只有当导出回归变常见时，才考虑把 Web smoke 放进常规 CI。

## 失败策略

Native smoke 应在以下情况失败：

- 场景加载失败。
- 必需 UI 节点缺失。
- 截图空白或视口内容尺寸为 0。
- 布局值超出视口边界。
- 无法从开始场景启动。
- 无法通过场景输入路径放置一座塔。
- 出现未明确 allowlist 的新 Godot 错误。

Web smoke 应在以下情况失败：

- Web 导出失败。
- `index.html`、`index.wasm` 或 `index.pck` 的 HTTP 失败。
- 浏览器 canvas 缺失。
- canvas 区域空白。
- 浏览器 `pageerror`。
- 关键 console/runtime 错误，例如 `Uncaught`、`RuntimeError`、`LinkError`、`Failed to fetch`、`404` 或 `Cannot load`。

以下情况不应导致任一门禁失败：

- 已在技术债中跟踪的已知 Godot 警告。
- 不影响加载或渲染的非关键警告。
- 精确截图像素差异。

为已知良性警告维护明确 allowlist。新警告进入 allowlist 前应经过 review。

## 实现形态

预期 native 文件：

- `game/tools/check-ui-smoke.sh`：shell 编排器。
- `game/tools/ui_smoke_runner.gd`：Godot runner，负责加载场景、驱动输入、捕获截图并写报告。
- `game/tools/summarize-ui-smoke.py`：agent 迭代用报告摘要器。
- `game/tools/agent-preflight.sh`：本地 fast 反馈命令，运行项目门禁、Godot/GUT 日志报告和产物摘要。
- `game/tools/agent-preflight-full.sh`：完整交付命令，额外运行 UI smoke、gameplay smoke 和截图产物摘要。
- `docs/testing/gates.md`：实现后记录 native UI smoke 门禁。

预期 Web 文件：

- `game/tools/check-web-smoke.sh`：导出和本地 server 的 shell 编排器。
- `tools/web-smoke/package.json`：如果选择 scoped Node 工具包，固定 Playwright 依赖。
- `tools/web-smoke/check-web-smoke.mjs`：浏览器断言。

Native 命令覆盖项：

- `GODOT_BIN`：Godot 可执行文件。
- `UI_SMOKE_ARTIFACT_DIR`：默认 `ci-artifacts/ui-smoke/native`。
- `UI_SMOKE_VIEWPORTS`：可选，用逗号分隔的调试视口覆盖。

## UI 变更验证流程

新增或大改 UI 功能前，先写简短验证方案，再实现。方案应列出覆盖区域、视口、状态、交互、现有 crop/overlay 是否覆盖新增 surface，以及交付前需要人工检查的截图产物。

新增 UI surface 时，应同步扩展 native smoke 的 review artifact。至少为新面板、HUD 区域或卡片添加一个局部 crop 和 overlay；如果该 surface 有关键状态，runner 应能进入至少一个代表状态。

交付 UI 改动前，检查 `docs/ui/features.md` 和 `docs/ui/test-plan.md` 是否需要更新，运行 `./tools/check-ui-smoke.sh` 或 `./tools/agent-preflight-full.sh`，检查 `report.md`、整屏截图、局部 crop 和 overlay。看到的每个 UI 问题或美观度问题都应单独记录到 `docs/todo/backlog.md`。

Web 命令覆盖项：

- `GODOT_BIN`：Godot 可执行文件。
- `WEB_SMOKE_OUTPUT_DIR`：默认 `build/web-smoke`。
- `WEB_SMOKE_ARTIFACT_DIR`：默认 `ci-artifacts/ui-smoke/web`。
- `WEB_SMOKE_PORT`：可选，调试用固定本地端口。

## 替代方案

- 只用 GUT 场景测试：快速且有用，但无法捕获渲染截图或真实视口行为。
- 只用 Web smoke：能验证发布，但对开发调试来说太慢且太间接。
- 立即使用严格截图 baseline：视觉信号更强，但在 UI 稳定前过于脆弱。
- 只运行已部署 Pages URL：作为部署后检查有用，但比部署前测试本地导出更慢、可操作性更弱。

## 风险

- Native smoke 在 CI 中需要显示后端，Linux 上可能是 `xvfb-run`。
- 如果在渲染稳定前截图，截图检查可能 flaky。
- 如果 runner 扩张太多，可能变成另一套平行测试框架。
- Playwright 会为 Web smoke 增加 Node/browser 依赖。
- console/error allowlist 如果过宽，可能隐藏真实问题。

## 开放问题

- Native UI smoke 是否应进入 `check-all.sh`，还是稳定前保持独立命令？
- Native smoke 应通过坐标、grid helper，还是 public scene method 驱动输入？
- Web smoke 只在 Pages 中运行，还是在 `game/**` 变化时也进入 CI？
- Native runner 最终是否应包含确定性 replay eval，还是 replay 保持为独立 harness？
