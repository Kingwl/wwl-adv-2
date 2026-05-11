---
name: thumbnail-visual-review
description: 当需要用 thumbnail、缩略图、contact sheet、4x4 或 2x2 降采样图审查截图、smoke 截图、地图视觉、局部 crop、overlay，或需要先用缩略图判断整体再展开细节时使用。
metadata:
  short-description: 缩略图采样和局部展开视觉审查工作流
---

# 缩略图视觉审查

在当前 Godot 仓库中用降采样 contact sheet 先判断整体，再用原图 crop/overlay 验证局部细节。

## 优先阅读

1. 阅读 `AGENTS.md`。
2. 阅读 `docs/status.md`。
3. 阅读 `docs/testing/gates.md` 中 UI smoke、gameplay smoke、level grid audit 和地图视觉采样审查部分。
4. 如果本次也修改场景、UI、布局、输入或 smoke runner，继续遵循 `wwl-godot-scene-harness`。
5. 如果本次也修改验证脚本、门禁、CI 或项目 skill，继续遵循 `wwl-godot-harness-maintainer`。

## 生成审查材料

通用图片 4x4 多算法缩略图/contact sheet：

```bash
python3 .codex/skills/thumbnail-visual-review/scripts/thumbnail_contact_sheet.py path/to/images --out-dir /tmp/thumbnail-visual-review-4x4 --block-size 4 --methods mean median box nearest
```

需要看更细颗粒时，改用 2x2，多算法参数相同：

```bash
python3 .codex/skills/thumbnail-visual-review/scripts/thumbnail_contact_sheet.py path/to/images --out-dir /tmp/thumbnail-visual-review-2x2 --block-size 2 --methods mean median nearest
```

这个脚本只依赖 Pillow，接受图片文件或目录。`--methods` 可用于任意 `--block-size`，输出 `contact-*.png`、`manifest.json` 和 `sampling/<NxN>/` 下的逐图缩略图。输入图片任一边低于 100px 时，脚本会提示这类低分辨率图片可能不需要缩略图审查。它不理解项目 smoke report；需要项目语义 crop、overlay 或固定审查区域时，继续用下面的 Godot 项目工具。

脚本自测：

```bash
python3 .codex/skills/thumbnail-visual-review/scripts/test_thumbnail_contact_sheet.py
```

UI smoke 视觉审查：

```bash
cd game
./tools/check-ui-smoke.sh
```

`check-ui-smoke.sh` 会自动生成 4x4 visual review。只复用最近一次 UI smoke 产物时运行：

```bash
cd game
./tools/generate-ui-visual-review.py --artifact-dir ../ci-artifacts/ui-smoke/native --block-size 4
```

优先检查：

- `ci-artifacts/ui-smoke/native/visual-review/ui-fullscreens-mean4x4-contact.png`
- `ci-artifacts/ui-smoke/native/visual-review/ui-key-crops-mean4x4-contact.png`
- `ci-artifacts/ui-smoke/native/visual-review/<viewport>-crop-atlas-mean4x4.png`
- `ci-artifacts/ui-smoke/native/visual-review/report.md`

地图视觉审查：

```bash
cd game
./tools/check-level-grid-audit.sh
./tools/generate-map-visual-review.py --level res://data/levels/level_005.json --block-size 4
```

如果 4x4 暴露了可疑边缘、路径宽度、贴合或遮挡，再补 2x2：

```bash
cd game
./tools/generate-map-visual-review.py --level res://data/levels/level_005.json --block-size 2
```

优先检查：

- `game/tools/out/map_visual_review/<level>/00-downsample-contact-sheet.png`
- `game/tools/out/map_visual_review/<level>/02-sampling-4x4-contact-sheet.png`
- `game/tools/out/map_visual_review/<level>/01-preview-crop-atlas.png`
- `game/tools/out/map_visual_review/<level>/*-contact.png`

## 审查顺序

1. 先看 4x4 contact sheet，判断整体构图、视口层级、路径/格子语义、遮挡、大块颜色冲突和主要 UI 区域是否错位。
2. UI 审查默认以 `mean4x4` contact 为第一视图；地图审查同时比较 `mean`、`median`、Pillow `BOX` 和 `nearest`。`median` 用来压低纹理噪声，`nearest` 只当对照。
3. 只有在需要判断文字、边缘、sprite 清晰度、碰撞/格子贴合、局部美术细节或可点击区域时，才打开原始 crop、overlay 或 2x2 采样图。
4. 发现 UI 问题、可读性问题或美观度问题时，把每个问题作为独立 checkbox 记录到 `docs/todo/backlog.md`。
5. 最终向用户展示视觉证据时，优先给 4x4 采样图说明整体问题；讨论局部细节时再同时给原图 crop 或 overlay。

## 判断边界

- 不要只凭 4x4 图断言文字可读、边缘贴合、按钮命中区域或像素级对齐。
- 不要把多个视觉问题合并成一个 backlog checkbox。
- 不要提交生成的审查图片，除非用户明确要求把它们作为版本化资产或文档证据。
- 不要因为已有 smoke 通过就跳过人工查看 contact sheet；这些图是审查辅助，不是像素级回归门禁。
