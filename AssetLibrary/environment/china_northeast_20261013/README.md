# 中国与东北大型场景资源 · 2026-10-13

本批实际保存 **11 组网上下载模型（76.0 MiB）**，另制作 **1 套长白山天池地形样板**，含精细版、轻量版及可编辑 Blender 工程。另有 **16 项网上候选**，模型文件尚未下载。所有来源和作者信息随文件保存。

## 怎么打开

- 双击 [index.html](index.html)：按图片浏览本地模型、用途和网上候选。
- 双击 [Open-3D-Viewer.cmd](Open-3D-Viewer.cmd)：打开独立的 3D 浏览器。左侧切换模型，拖动旋转，滚轮缩放，支持“火山口近看”和“自动环绕展示”；`R` 恢复全景，`Esc` 退出。
- [天池精细模型](terrain/tianchi_display.glb) / [轻量模型](terrain/tianchi_display_lod.glb) / [Blender 工程](terrain/tianchi_display.blend)。GLB 的地形与湖面是独立对象，贴图内嵌。
- [下载模型总览](previews/contact_sheet.jpg) / [网上候选预览](previews/candidate_contact_sheet.jpg)。后者的图片来自作者页面，不能当作已取得模型。

3D 浏览器使用工作区已有的 Godot 4.7.2，无需另外安装。需保持本目录位于当前 `AssetLibrary/environment/` 下，启动入口才能找到引擎。浏览器只临时调整各模型的显示尺寸，不修改原模型。若单独搬走目录，可在 Godot 4.7 中打开 [viewer/project.godot](viewer/project.godot)。

## 天池样板

| 项目 | 实际内容 |
|---|---|
| 覆盖 | 约 14.54 × 14.54 公里，包含天池和周边山体 |
| 精细版 | 513 × 513 高程顶点网格；含湖面 526,318 三角面，约 15.3 MiB |
| 轻量版 | 257 × 257 高程顶点网格；含湖面 133,102 三角面，约 4.8 MiB |
| 高程 | Mapzen / Tilezen 的 Terrarium 公共高程瓦片，16 张 zoom 13 瓦片 |
| 湖岸 | © OpenStreetMap contributors，relation 11650508，独立水面 |
| 尺度 | 水平为局部米制近似；垂直无夸张；本地高度减去海拔 1500 米 |
| 坐标 | Blender：X 东、Y 北、Z 上；GLB/Godot：X 东、Y 上、负 Z 北；地理原点与范围见 terrain_metadata.json |
| 表现 | 海拔和坡度生成的示意配色，不是卫星贴图或摄影测量 |

模型网格采样间隔约 28 米／57 米，不能将采样间隔理解为原始高程精度。水面参考 OSM 标高 2189 米，显示时抬高 0.8 米，湖内高程下压以避免穿插；没有湖底测深数据。模型适合地形概览、文旅镜头排练及后续场景底座。当前没有观景台、栈道、游客中心、精细植被或碰撞。

高程来源说明见 [Tilezen 原始归属说明](evidence/elevation_attribution.txt)，湖岸来源见 [OpenStreetMap](https://www.openstreetmap.org/relation/11650508)，原数据与派生过程保存在本目录。湖岸数据为 ODbL 1.0；[来源与输出校验](terrain/source.json) 保留了瓦片链接和哈希。

## 下载模型怎么选

| 用途 | 模型 | 当前判断 |
|---|---|---|
| 快速填充空地 | 成组村镇集市、成组果蔬摊棚 | 组合布景可用；篷布风格与尺寸需调整 |
| 林区大体块 | 木屋与周边整景 | 通用木屋，可用作底模；不是东北传统民居复原 |
| 仓储和工业区 | 敞顶仓库结构、砖砌厂房立面模块 | 前者需补屋顶，后者是零件套件，需组装完整建筑 |
| 中式室内陈设 | 屏风、茶桌、编织方筐 | 补充局部细节，不能替代大型建筑 |
| 远景地标 | 双层圆亭塔 | 风格化低面造型，不对应具体景点 |
| 备用 | 五层塔楼、三层楼阁 | 外观偏日式，不作为中国／东北代表建筑 |

本地建筑质量和风格不统一。部分模型的原始尺度相差很大，正式接入需按照人物、门高统一米制尺度，补充碰撞、分块和必要的远景简化。尚未加入游戏正式关卡。

## 最值得继续获取的成品

1. [天池火山口](https://sketchfab.com/3d-models/f8429f52abb14798a5b180541797160b)：作者说明采用 ASTER 高程与 Esri 影像，511,092 三角面，优先用于文旅展示评估。
2. [长白山](https://sketchfab.com/3d-models/20985473ab8743f784c05cd01716fff3)：524,268 三角面，另一种山体范围与配色候选。
3. [完整北京四合院](https://sketchfab.com/3d-models/a18881525cfd4fe882e739c9c7cee752)：596,699 三角面，院落与植被完整，最符合“大型中式建筑方便展示”的方向。
4. [中式街景](https://sketchfab.com/3d-models/d5e673e13b774deba137bd2e99af8e65)：12,820 三角面，可评估街巷整体布景；地域风格需进一步筛选。
5. [中国宫殿建筑群](https://www.blendswap.com/blend/14878)：作者标注 47 MB、835,210 个面、5,147 个对象，含贴图，适合整体展示候选。
6. [哈尔滨大剧院候选](https://sketchfab.com/3d-models/e96e36a7ba2e47028879ec58e4a06f24)：作者描述指向哈尔滨大剧院，但标题与设计者信息不一致；先核对外形。适合另做现代文旅场景。

以上页面标为可下载或提供下载入口，但实际下载需要登录，目前仅保存来源资料和预览。完整 16 项候选见 [candidates.json](candidates.json) 和图片目录。没有把下载失败或仅有网页的素材计入本地库存。

## 验证记录

- 下载文件结构、外部依赖与校验信息：[manifest.json](manifest.json)。
- 11 组原模型均成功导入 Blender，未发现缺失贴图：[import-review.json](import-review.json)。本地预览逐项检查后修正了标题与用途。
- 11 组原模型和 2 个天池 GLB，共 13 个入口均成功通过 Godot 4.7.2 导入检查，失败数为 0：[godot-import-review.json](godot-import-review.json)。
- 独立浏览器实际渲染：[viewer_tianchi.png](previews/viewer_tianchi.png)。游戏性能、正式关卡布局与年代适配属于后续接入工作。
- 浏览器内输入检查：[viewer-input-review.json](viewer-input-review.json)，模型切换、拖动旋转、松手停止、滚轮缩放、返回天池、火山口定位 6 项通过。使用 Godot 输入事件验证；Windows 界面工具因 native pipe 连接失败，未完成操作系统层面的鼠标自动化检查。
- 最终 41 个登记模型文件／依赖与本地目录链接检查无错误：[verification.json](verification.json)。
