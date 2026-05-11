# Harness Engineering Todo

这个 backlog 跟踪受 OpenAI Harness Engineering 指导启发的项目基础设施工作：

https://openai.com/zh-Hans-CN/index/harness-engineering/

这个文档用于记录让 agent 更容易检查、验证并安全修改项目的 harness 后续项。当某项变成持久策略时，将它移入 `docs/testing/` 或 `docs/designs/`。

## P0 - 下一批 Harness 工作

- [x] 添加开发期可玩性的 native UI smoke 测试门禁。
  - 设计：`docs/designs/test-and-harness-architecture.md`。
  - 不做 Web 导出，直接运行 Godot 项目。
  - 覆盖桌面、移动横屏和方形/紧凑视口。
  - 从开始场景进入主场景，放置一座塔并捕获截图。
  - 在 CI 中上传截图、Godot 日志和报告产物。

- [x] 添加 Web 导出 smoke 门禁，用于发布信心。
  - 复用同一份设计：`docs/designs/test-and-harness-architecture.md`。
  - 导出到 `game/` 外的目录。
  - 通过本地 HTTP 服务导出产物。
  - 用浏览器 runner 打开页面。
  - 断言 canvas 存在、非空白，并且没有关键 console 错误。
  - 把它当作 export/Pages 门禁，而不是默认本地调试循环。
  - 命令：`game/tools/check-web-smoke.sh ../build/web-smoke`；报告：`ci-artifacts/web-smoke/`。

- [x] 添加 Godot 架构边界 structural lint。
  - 保持 `game/scripts/core/` 独立于场景/UI 节点。
  - 保持 `game/scripts/core/` 独立于渲染、贴图和资源加载 adapter。
  - 阻止 `BoardView` 重新持有资产/data 资源路径或直接 `load()` / `preload()`。
  - 要求棋盘场景资产通过 `BoardAssetCatalog` 管理。
  - 用 warning 防止 `BoardView` 体积/函数数量重新膨胀。
  - 将违规报告为清晰的 CI 失败。
  - 命令：`game/tools/check-structure.sh`；报告：`ci-artifacts/structure/report.md`。

- [x] 添加确定性 gameplay smoke/replay eval 的第一版。
  - 使用脚本化 gameplay scenario 和固定 tick。
  - 产出机器可读结果摘要，包含生命、金币、漏怪、胜负、击杀、波次、状态事件和已过 tick。
  - 为每个 checkpoint 输出整屏截图、board crop 和状态 overlay。
  - 后续如果需要更强回归，再加入批准式 snapshot 对比和长局 replay。

## P1 - 更强的 Agent 反馈

- [x] 将 Godot 和 GUT 日志解析成 `report.json` 和 `report.md`。
  - 分类错误、警告、测试失败，以及 TD-007 这类已知警告。
  - 将解析后的报告作为 CI artifact 上传。

- [x] 将本地 agent preflight 拆成 fast/full。
  - `agent-preflight.sh` / `agent-preflight-fast.sh` 只运行项目门禁和日志报告，适合开发迭代。
  - `agent-preflight-full.sh` 额外运行 native UI smoke 和 native gameplay smoke，适合交付前视觉/可玩性证据。

- [x] 将敌人和波次配置迁移到带 schema 检查的数据文件。
  - `check-assets.sh` 已覆盖敌人、波次、经济和塔配置。
  - 校验 wave enemy reference 和 tower visual resource reference。

- [ ] 将 structural lint 的 warning 分阶段收敛成更严格规则。
  - 已按 `docs/designs/scene-ui-architecture.md` 拆出 `BoardView` 的 layout、HUD、input、visual state 和 renderer。
  - 已将 `BoardMapRenderer` 从 `game/scripts/core/` 迁出到场景/渲染 adapter，并把 core 渲染/资源加载耦合收紧为 error。
  - 后续重点是把当前 warning 阈值收紧，并继续防止 adapter 层体积回膨胀。

- [x] 添加 agent preflight 命令。
  - 运行标准本地门禁。
  - fast 入口不运行 native smoke，避免开发过程打断操作。
  - full 入口保留 UI/gameplay smoke 和截图证据。
  - 汇总已改文件、生成产物和已知警告。
  - 相关时打印 Pages 可玩 URL。

- [x] 为专门 agent 工作流添加项目 Codex skills。
  - 核心玩法规则开发。
  - 场景/UI 可玩性验证。
  - Harness、CI、Pages、资产检查和 skill 维护。

## P2 - 稍后

- [ ] 为重要视口添加轻量视觉回归覆盖。
  - 捕获桌面和移动横屏截图。
  - 与已批准 baseline 对比，或至少作为 CI artifact 保留。

- [ ] 当协作超出单人开发时，重新考虑 GitHub branch protection 和 required CI。

- [ ] 只有当下载体积变成产品问题时，再调查 Godot Web runtime 体积。
  - 当前主要体积下限是 Godot Web runtime `index.wasm`。
  - 在定制 engine template 前，优先做资产和 export-preset 清理。
