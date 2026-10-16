# S11 生活与生产布景去向

更新时间：2026-10-13；基线：0.6.1。

本表是 `docs/level/S08/resource_assignments.md` 中 S11 设计去向的实际接入回执。S11 只增加可读的生活与生产布景；路线网格、任务锚点和粗体积碰撞仍由 S09/S10 保持。

| 资源 | 实际接入位置 | 数量／用途 | 状态 |
|---|---|---|---|
| `village_market` | D06 检查口外侧 | 1；生活摊棚，配两张木凳、两个生活筐和煤油灯 | 已接入 |
| `market_stalls` | D07／D05 共用生产棚 | 1；生产摊台，配周转箱、储桶、木工工具和两层叠放木材 | 已接入 |
| `chinese_screen_panels` | D08 电报房东南、D09 林工棚 | 2；档案区屏风与半遮谈话屏风 | 已接入 |
| `chinese_tea_table` | D09 林工棚 | 1；谈话低桌 | 已接入 |
| `wicker_basket_01` | D06、D08、D09 | 6；生活筐、档案传递筐和补给筐 | 已接入 |
| 既有 `WoodenTable_01`、`wooden_bucket_01`、木材视觉件 | D05 棚内 | 加工桌、取水桶和两组木材 | 已接入 |

布置按 D05、D06、D07、D08、D09 五个槽位登记。`runtime.json` 中的 `purpose_counts` 是运行时实际计数；资源源文件在 `GodotProject/assets/environment/models/s11/`，原始素材库仍保留在 `AssetLibrary/environment/china_northeast_20261013/`。

保留限制：这些小道具没有新增独立物理碰撞；旧体块网格隐藏后仍保留其碰撞和掩体边界。六段路线采样是在检查口、院落和渡口栅门打开的静态可达性检查，不等同于 S13 的 AI 路线、真人节奏或最终发布包验收。
