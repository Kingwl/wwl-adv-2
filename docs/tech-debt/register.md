# 技术债登记表

| ID | 区域 | 影响 | 优先级 | 负责人 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| TD-001 | 可测试性 | 玩法规则耦合到 Godot 节点会让单元测试变慢且脆弱。 | High | TBD | Open | 将战斗、合成、经济、波次和 RNG 规则保留在 `scripts/core/`。 |
| TD-002 | 覆盖率 | GDScript 行覆盖率不像 .NET 覆盖率那样直接。 | High | TBD | Open | 用 GUT 测试覆盖 checklist、分支/边界测试和回归测试替代行覆盖率门禁。 |
| TD-003 | 确定性 | 依赖帧率的战斗模拟会制造 flaky 测试和不一致平衡。 | High | TBD | Mitigated | 核心战斗使用固定 tick 模拟；场景集成仍需通过它路由。 |
| TD-004 | 内容数据 | 硬编码敌人/波次数值会让平衡和回归测试变贵。 | Medium | TBD | Closed | 敌人、波次和经济第一版已迁移到 `game/data/`，并纳入 schema/GUT/asset check；长波次和平衡 fixture 是新的后续内容债，不再属于硬编码配置债。 |
| TD-005 | 场景测试 | 过多场景测试会变慢且脆弱。 | Medium | TBD | Open | 大多数断言保留在核心测试；场景测试只用于集成边界。 |
| TD-006 | 敌人生命周期 | 已完成和已击败敌人目前仍保留在 simulation array 中。 | Low | TBD | Open | 当更长波次或 profiling 显示保留敌人影响性能或场景渲染时，再添加清理。 |
| TD-007 | 测试清理 | GUT 场景测试输出 `ObjectDB instances leaked at exit`，让 CI 输出变吵，也可能隐藏未来 leak 回归。 | Medium | TBD | Open | CI 上传 `check-all.log`；检查场景测试和 queued node/resource，移除该警告。 |
| TD-008 | 场景架构 | `BoardView` 曾同时承担 session、layout、HUD、input、visual state 和 renderer 职责。 | Medium | TBD | Mitigated | 兼容字段已清理；场景测试和 smoke runner 通过显式 getter 访问拆出的对象；`check-structure.sh` 继续用行数和函数数量防止回膨胀。 |
| TD-009 | 配置来源 | 若 session 重新内联默认经济或波次配置，会绕过数据门禁并掩盖配置错误。 | Medium | TBD | Closed | `BoardGameSession` 现在从 `EconomyConfig`、`EnemyCatalog` 和 `WaveConfig` 加载 `game/data/economy`、`game/data/enemies` 和 `game/data/waves`，并不再回退到硬编码三波。 |
| TD-010 | 渲染边界 | `BoardMapRenderer` 曾位于 core 目录并包含渲染/资源加载耦合。 | Medium | TBD | Closed | 已迁到 `game/scripts/board/`；core 下渲染和资源加载 API 现在由 `check-structure.sh` 作为 error 阻止。 |
| TD-011 | 塔内容扩展性 | 塔 roster 虽已放入 `towers.json`，但新增塔仍需要改 `GameTower.Type` enum、tower schema、`check-assets.py` 枚举和若干 tower-type match。 | Medium | TBD | Mitigated | `TowerConfig` 已提供 tower id roster/lookup，HUD 按钮、数字键和 smoke 选塔已改走 tower id；剩余核心运行时、schema、asset check 和 renderer fallback 仍绑定 enum。 |
| TD-012 | 塔配置实现 | `TowerConfig` 曾同时承担 JSON 读取、解析、语义校验、默认值、UI button spec 和旧 tier/effect 兼容路径，文件已成为核心配置修改的高风险点。 | Medium | TBD | Mitigated | JSON 解析、语义校验和 UI/smoke presentation spec 已分别移到 `TowerDefinitionParser`、`TowerDefinitionValidator` 和 `TowerPresentationCatalog`；tier stats 只从 `effects[]` 派生，不再支持旧 `splash_radius_cells`、`slow_*` 和顶层 `status_*` fallback。 |
| TD-013 | 经济配置 | 若建塔费用只放在全局经济配置中，不同塔无法独立做建造成本平衡。 | Medium | TBD | Closed | `towers.json` 已增加 per-tower `build_cost`，放置、HUD、退款累计投入、schema 和 smoke 已跟随；`basic_tower_cost` 保留为兼容 fallback/default。 |
| TD-014 | UI 状态同步 | `BoardHudController` 的紧凑 status/hint 曾依赖英文文案前缀和 `get_slice()` 解析，业务文案一变就可能破坏紧凑视口提示。 | Medium | TBD | Closed | `BoardMessage` 现在承载结构化状态码、参数、完整文案和紧凑文案；`BoardGameSession` 写入结构化消息，HUD 直接选择完整/紧凑展示，不再解析英文文案。 |
| TD-015 | 场景测试维护性 | `test_main_scene.gd` 已聚合大量 HUD、输入、布局、流程和视觉接线断言，后续 UI 改动容易形成长文件局部回归和难定位失败。 | Medium | TBD | Open | 按 surface/flow 拆成 fixture helper 和多个场景测试文件；拆分时继续保留场景测试只覆盖集成边界。 |
| TD-016 | 校验规则重复 | tower/enemy/wave enum、effect 规则和 tier 语义同时存在于 JSON schema、`check-assets.py` 和 GDScript validator，存在规则漂移风险。 | Medium | TBD | Open | 明确 schema/Python/GDScript 的职责边界，或从共享声明生成校验常量；至少为新增 tower/effect/enemy 类型建立同步 checklist。 |
| TD-017 | 场景 adapter 体积 | `BoardRenderer` 和 `BoardHudController` 已承接大部分绘制、HUD、塔卡、overlay 和运行时 node 创建逻辑，虽然 `BoardView` 已瘦身，adapter 层仍可能继续膨胀。 | Low | TBD | Open | 后续新增 UI surface 或视觉系统时，优先拆出 tower deck、tower action menu、enemy/projectile rendering 等更小 adapter。 |
