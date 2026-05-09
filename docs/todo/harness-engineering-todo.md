# Harness Engineering Todo

这个 backlog 跟踪受 OpenAI Harness Engineering 指导启发的项目基础设施工作：

https://openai.com/zh-Hans-CN/index/harness-engineering/

这个文档用于记录让 agent 更容易检查、验证并安全修改项目的 harness 后续项。当某项变成持久策略时，将它移入 `docs/testing/` 或 `docs/designs/`。

## P0 - 下一批 Harness 工作

- [x] 添加开发期可玩性的 native UI smoke 测试门禁。
  - 设计：`docs/designs/2026-05-09-ui-playability-validation.md`。
  - 不做 Web 导出，直接运行 Godot 项目。
  - 覆盖桌面、移动横屏和方形/紧凑视口。
  - 从开始场景进入主场景，放置一座塔并捕获截图。
  - 在 CI 中上传截图、Godot 日志和报告产物。

- [ ] 添加 Web 导出 smoke 门禁，用于发布信心。
  - 复用同一份设计：`docs/designs/2026-05-09-ui-playability-validation.md`。
  - 导出到 `game/` 外的目录。
  - 通过本地 HTTP 服务导出产物。
  - 用浏览器 runner 打开页面。
  - 断言 canvas 存在、非空白，并且没有关键 console 错误。
  - 把它当作 export/Pages 门禁，而不是默认本地调试循环。

- [ ] 添加 Godot 架构边界 structural lint。
  - 保持 `game/scripts/core/` 独立于场景/UI 节点。
  - 标记直接新增到 `BoardView` 的玩法规则逻辑。
  - 跟踪 `BoardView` 体积/耦合度，避免它无感继续膨胀。
  - 将违规报告为清晰的 CI 失败。

- [x] 添加确定性 gameplay smoke/replay eval 的第一版。
  - 使用脚本化 gameplay scenario 和固定 tick。
  - 产出机器可读结果摘要，包含生命、金币、漏怪、胜负、击杀、波次、状态事件和已过 tick。
  - 为每个 checkpoint 输出整屏截图、board crop 和状态 overlay。
  - 后续如果需要更强回归，再加入批准式 snapshot 对比和长局 replay。

## P1 - 更强的 Agent 反馈

- [ ] 将 Godot 和 GUT 日志解析成 `report.json` 和 `report.md`。
  - 分类错误、警告、测试失败，以及 TD-007 这类已知警告。
  - 将解析后的报告作为 CI artifact 上传。

- [ ] 将塔、敌人和波次配置迁移到带 schema 检查的数据文件。
  - 扩展 `check-assets.sh`，不只校验关卡和 map style 定义。
  - 校验数据文件和运行时资产之间的引用。

- [x] 添加 agent preflight 命令。
  - 运行标准本地门禁。
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
