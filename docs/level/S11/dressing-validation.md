# S11 生活与生产布景验收

更新时间：2026-10-13；基线：0.6.1。

## 实际改动

- 在 `GodotProject/scripts/asset_dressing.gd` 增加 S11 布景构建：D06 生活摊棚，D07/D05 生产摊台，D08 档案屏风，D09 谈话桌与半遮屏风，以及筐、木料、工具、桶和煤油灯。
- 在 `GodotProject/scripts/world.gd` 的场景构建顺序中调用 S11 布景。
- 在 `GodotProject/scripts/route_blockout.gd` 隐藏 D06–D09 和 D05 的占位网格，保留原有 `StaticBody3D` 碰撞；节点以 `s11_visual_replaced` 标记。
- 导入五类实际资源：`village_market`、`market_stalls`、`chinese_screen_panels`、`chinese_tea_table`、`wicker_basket_01`。

## 本轮证据

- `docs/level/S11/runtime.json`：21 项检查全部通过。
- `docs/level/S11-headless.log`：Godot 4.7.2 无头实例化通过，`S11 DRESSING: PASS | checks=21`。
- `docs/level/S11-capture.log`：运行时捕获通过，同样为 21 项。
- `docs/level/S11/D06-life.png`、`D05-D07-production.png`、`D08-office.png`、`D09-shelter.png`：四张生活／生产布景近中景证据图。
- `docs/level/S11/runtime.json` 的 Z0、Z1、Z2、Z3-return、Z4、Z5 六段开放门路线采样均 `passed: true`；D05–D09 五个槽位均有布景，五类导入资源均出现。
- 实际去向回执见 [`resource-destinations.md`](resource-destinations.md)。

## 验收边界

本步验证的是场景实例化、资源存在、占位外观替换和静态路线可达性。它没有宣称 S13 的 AI 通行、真人行进时长、最终性能、正式音画或 Release 发布包已验收。
