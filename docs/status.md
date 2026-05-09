# 项目状态

## 当前里程碑

里程碑 1：Playable Prototype 收尾；里程碑 2：MVP 准备已开始。

可玩循环基本已经具备。Prototype 目前剩下的主要决策是塔成长模型：场景级合成交互，还是直接升级。

## 已验证命令

最近检查：2026-05-10。

```bash
cd game
./tools/check-all.sh
./tools/agent-preflight.sh
./tools/check-env.sh
./tools/godot-headless.sh
./tools/test-gut.sh
./tools/check-ui-smoke.sh
./tools/check-gameplay-smoke.sh
```

当前已知测试状态：

- Godot: 4.6.2 stable.
- GUT: 9.6.0.
- GUT 套件：126 个测试通过，708 个断言。
- Native UI smoke：桌面、移动横屏和方形视口通过，截图位于 `ci-artifacts/ui-smoke/native/`。
- Native gameplay smoke：代表性 gameplay scenario 通过，trace、截图和 overlay 位于 `ci-artifacts/gameplay-smoke/native/`。
- Agent preflight：运行 `check-all.sh`、native UI smoke、native gameplay smoke 和 UI smoke 摘要。
- 已知警告：GUT 退出时有来自场景/资源清理的 ObjectDB leaked instances 警告，记录为 TD-007。

## 已实现

- Godot 4.x 项目骨架和 GUT 配置。
- 可测试的 `game/scripts/core/` 规则层。
- 棋盘放置、移除、保留格和路径校验规则。
- 经济钱包、放置费用、击杀奖励和波次清空奖励。
- 敌人路径移动、生命值、死亡事件和漏怪处理。
- 固定 tick 战斗模拟。
- 塔配置、注册表、目标选择、攻击冷却、投射物生成、投射物移动和命中检测。
- 波次生成和波次清空事件。
- 玩家生命、胜利和失败状态。
- 开始场景、主场景、暂停菜单、重开、返回开始、胜利和失败流程。
- 三种基础塔：Single、Area 和 Slow。
- 当前地图的数据驱动关卡路径/style 加载。
- 生成的城市防御地图、道路 guide 产物、UI frame、塔 sprite、敌人 sprite 和攻击特效。
- 覆盖 start-to-main 可玩性、响应式视口、单塔放置和截图产物的 native UI smoke。
- 覆盖放塔、Single 击杀奖励、Area 溅射、Slow 状态、漏怪、胜利和失败的 native gameplay smoke。
- 用于本地 agent 迭代反馈的 agent preflight 和 UI smoke 摘要脚本。
- 面向核心玩法规则、场景/UI 验证和 harness 维护的项目 Codex skills。
- 面向核心玩法和 UI 的功能清单与测试计划文档。

## 开放决策

- Prototype 塔成长模型：合成交互还是直接升级。
- 塔、敌人和波次配置的数据形状。
- 更长波次前，是否需要清理已完成/已击败但仍保留的敌人。
- 生成的 road ribbon 资产是否应变成确定性的运行时/编辑器生成内容。

## 已知风险

- `game/scripts/board/board_view.gd` 很大，混合了输入、布局、渲染、资源加载、HUD 状态和模拟集成。
- 塔和波次数值仍有一部分硬编码在 GDScript 中。
- 测试质量依赖 GUT 加 checklist，而不是行覆盖率。
- 场景测试当前会输出 ObjectDB leak 警告，记录为 TD-007。
- GitHub Pages 发布静态项目页，以及 `/play/` 下的可玩 Godot Web 导出。

## GitHub 自动化

- CI workflow：`.github/workflows/ci.yml`。
- CI 运行 `check-all.sh`、native UI smoke 和 native gameplay smoke。
- CI 将 `ci-artifacts/` 上传为 `godot-check-artifacts` artifact。
- GitHub Pages workflow：`.github/workflows/pages.yml`。
- Pages 来源：GitHub Actions workflow 从 `site/` 加 `_site/play/` 下的 Godot Web 导出进行部署。
- 本地 Web 导出默认输出到 Godot 项目目录外的 `build/web/`。
- 项目 skills 版本化存放在 `.codex/skills/`；本地 Codex runtime 不会自动加载仓库内 skills 时，将它们链接到 `$CODEX_HOME/skills`。

## 下一步最值得做的工作

1. 决定并实现 Prototype 塔成长模型。
2. 将塔、敌人和波次定义推进到数据文件。
3. 在下一个玩法决策后拆分 `BoardView` 职责。
4. 保持 `game/tools/check-all.sh` 作为默认验证命令。
