# WWL Advanced 2D Tower Merge

用于 2D 塔防合成游戏的 Godot 4.x 项目。

## 布局

- `project.godot`：Godot 项目文件。
- `scenes/`：Godot 场景。
- `scripts/`：Godot 场景脚本和可测试的 GDScript 玩法规则。
- `scripts/core/`：与场景节点分离的确定性玩法规则。
- `assets/`：美术、音频、字体和其他导入的游戏资产。
- `addons/gut/`：GUT 测试框架。
- `test/gut/`：GUT 单元和集成测试。
- `test/godot/`：更广泛的 Godot 集成测试记录。
- `tools/`：本地开发脚本。

## 当前 Bootstrap 命令

```bash
./tools/check-all.sh
./tools/agent-preflight.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-docs.sh
./tools/check-assets.sh
./tools/check-ui-smoke.sh
./tools/summarize-ui-smoke.py
./tools/export-web.sh ../build/web
```

Godot 场景启动默认使用 `/Applications/Godot.app/Contents/MacOS/Godot`。可用 `GODOT_BIN=/path/to/Godot` 覆盖。

## 测试策略

这个项目使用 GDScript 优先开发，并用 GUT 测试。玩法规则放在 `scripts/core/`，这样测试不依赖活跃场景、真实帧时间或 UI 状态。

实质性改动默认使用 `./tools/check-all.sh` 验证。

场景、布局、渲染、输入或 UI 资产改动时，使用 `./tools/check-ui-smoke.sh`。它运行 native Godot runtime，捕获桌面/移动横屏/方形截图，并在 `../ci-artifacts/ui-smoke/native/` 下写入报告。

需要一个 agent 交付前总入口时，使用 `./tools/agent-preflight.sh`：它会运行 `check-all.sh`、运行 native UI smoke，并打印 UI smoke 摘要。使用 `./tools/summarize-ui-smoke.py` 可在不重跑 Godot 的情况下重新打印最近一次 smoke 报告。

## Web 导出

Web 导出 preset 存放在 `export_presets.cfg`。本地 Web 导出产物必须位于 Godot 项目目录外：

```bash
./tools/export-web.sh ../build/web
```

脚本会拒绝 `game/` 内的路径，避免导入的导出产物影响 Godot 项目。CI 中 GitHub Pages 会导出到 `_site/play/`。

Web preset 排除了 GUT、测试、工具、原始/生成美术源文件、地图流水线契约、schema 文件和其他非运行时元数据，让 `index.pck` 聚焦于可玩资产。剩余体积下限主要来自 Godot Web runtime `index.wasm`。
