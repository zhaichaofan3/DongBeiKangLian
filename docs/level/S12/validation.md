# S12 树林、山体与远景验收

更新时间：2026-10-14（Asia/Shanghai）。本步在 0.6.1 现有路线「检查口 → 木料巷 → 电报房 → 渡口」上增加环境层次，保持玩法碰撞、栅门和导航网格由原 S09/S10 结构负责。

## 接入内容

- `GodotProject/scripts/landscape.gd` 创建岸上远林分块和近/对岸土坡。使用 `far_pine.glb` 的共享网格按 48 米分块实例化；河面矩形 x=88–132.5 不生成树。远林位置只放在岸上区域，并排除对岸小屋和 D01 附近结构。
- `GodotProject/scripts/world.gd` 改善旧程序树：河面范围直接拒绝树干，远岸小屋周边留出视线，草、碎砾和原有路线结构不改变；远山由三方向、多层不规则坡面组成，代替单排直立山墙。
- `GodotProject/scripts/asset_dressing.gd` 接入木屑与碎石 PBR 面：木料巷及返程使用 `wood_chips`，检查口和渡口使用 `gravel_road`。纹理面是视觉层，位于原地面约 2 厘米上方，不新增碰撞。
- `AssetLibrary/environment/derived/S12/far_pine.blend` 是离线修复材质和缩放的可编辑源；`GodotProject/assets/environment/landscape/far_pine.glb` 是导入的游戏资产。原始 JKM 文件没有覆盖。

## 资源去向与限制

| 来源 | 正式去向 | 处理与限制 |
|---|---|---|
| JKM's tree set，`AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/pinetree.obj`、`nadel.tga`、`stamm.jpg` | `far_pine.glb`，由 `landscape.gd` 作为远/中景共享树使用 | 原 OBJ 缺 MTL，S12 重新绑定叶片透明材质、树干材质并统一到 10 米高；只用于远景和中景，未作为近景可碰撞树；来源和许可见 `JKM-GPL.txt`、`JKM-README.txt` 及资产清单 |
| Poly Haven `wood_chips` | `GodotProject/assets/environment/textures/wood_chips/`；木料巷木屑面 | CC0；使用 2K diffuse/normal/roughness，未使用置换图，避免抬高路线 |
| Poly Haven `gravel_road` | `GodotProject/assets/environment/textures/gravel_road/`；检查口和渡口碎石面 | CC0；使用 2K diffuse/normal/roughness，未使用置换图 |
| 现有程序树林、山脊和地表 | `world.gd` 与 `landscape.gd` | 作为已有场景基线继续保留；本步仅修正河面排除、远岸留白和远山层次 |

未接入近景高面数 `pine_roots`，未把候选天池或未下载资源写成已使用；艺术化天池仍由 S20–S23 另行制作。

## 固定机位对照

- 原始对照：[`before-clean/01-forest-start.png`](before-clean/01-forest-start.png)、[`before-clean/05-river.png`](before-clean/05-river.png)、[`before-clean/07-overview.png`](before-clean/07-overview.png)。
- S12 结果：[`after-final/01-forest-start.png`](after-final/01-forest-start.png)、[`after-final/05-river.png`](after-final/05-river.png)、[`after-final/07-overview.png`](after-final/07-overview.png)，完整 7 机位记录在 [`after-final/captures.json`](after-final/captures.json)。
- 画面复核确认河面不再出现新增远林树，远山有前中后层次；木料巷机位保持在通路高度，未使用进入棚顶的临时机位。

## 验收结果

- `s12_landscape.gd`：7/7 通过；远林 placement 目录、分块裁剪、视觉节点、无新增物理体、导航网格及两条路线均通过。结果见 [`final-validation/runtime.json`](final-validation/runtime.json) 和 [`final-validation/console.txt`](final-validation/console.txt)。
- `run_capture.py after-final`：7 个固定机位均生成 1280×720 PNG；记录见 [`after-final/captures.json`](after-final/captures.json)。
- `Test-Game.ps1`：107/107 smoke、37/37 linear route、战斗路线 PASS、50/50 visual motion、11/11 story moments、37/37 character model，详见 `GodotProject/` 对应日志和 [`regression-final/`](regression-final/)；本次未更新 Release 发布包。

## 尚未涵盖

S12 没有完成 AI 路线、真人节奏、最终性能预算、艺术化天池和正式开场。下一游戏步骤是 S13：在本步场景布置稳定后检查玩家/NPC 通行、碰撞、敌人路线、掩体、救援与撤离位置。
