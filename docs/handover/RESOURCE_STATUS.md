# 全部资源交接状态与去向

S02 的105条记录作为历史底表保留；本表增加S07/S10/S11的实际接入回执。计划去向不等于实际接入，源模型整包也不等于已使用的精简派生版本。

85组已下载来源 + 3组当时本地派生 + 17项未下载候选。S10新增五份派生建筑另列，不倒改S02数量。每项的详细几何/哈希见 [原盘点](../resources/S02/inventory.json)。

## polyhaven_dead_tree_trunk · Dead Tree Trunk

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/dead_tree_trunk)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；High polygon source asset: decimation/LOD or baking is required before dense realtime placement.
- 本地入口：[AssetLibrary/environment/models/dead_tree_trunk/dead_tree_trunk_2k.gltf](../../AssetLibrary/environment/models/dead_tree_trunk/dead_tree_trunk_2k.gltf)
- 计划去向：正式使用；区域：检查口；林道；用途：近景倒木与道路边界。
- 尺度／适配：长3–4米；保留现有3.1/3.7米实例；自然物无年代冲突；保留细节近景，削减远处面数，不堵主路。
- 后续关联：S12、S13、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_tree_stump_01 · Tree Stump 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/tree_stump_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/tree_stump_01/tree_stump_01_2k.gltf](../../AssetLibrary/environment/models/tree_stump_01/tree_stump_01_2k.gltf)
- 计划去向：正式使用；区域：木料巷；检查口；用途：伐木痕迹与近景层次。
- 尺度／适配：高0.45–0.6米；自然物；统一切面与土壤接触，避免重复朝向。
- 后续关联：S11、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_pine_roots · Pine Roots

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/pine_roots)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；High polygon source asset: decimation/LOD or baking is required before dense realtime placement.
- 本地入口：[AssetLibrary/environment/models/pine_roots/pine_roots_2k.gltf](../../AssetLibrary/environment/models/pine_roots/pine_roots_2k.gltf)
- 计划去向：改造；区域：林道；树林边缘；用途：局部裸露树根。
- 尺度／适配：单簇宽2–4米；原始面数较高；拆局部、减面后少量使用，不以树根替代成熟树林。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_fern_02 · Fern 02

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel, Rico Cilliers](https://polyhaven.com/a/fern_02)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/fern_02/fern_02_2k.gltf](../../AssetLibrary/environment/models/fern_02/fern_02_2k.gltf)
- 计划去向：正式使用；区域：林道；渡口；用途：路边植被。
- 尺度／适配：高0.32–0.65米；植被需与季节一致；保持步行视线，雪地镜头稀疏放置。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_rock_moss_set_01 · Rock Moss Set 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Kless Gyzen](https://polyhaven.com/a/rock_moss_set_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/rock_moss_set_01/rock_moss_set_01_2k.gltf](../../AssetLibrary/environment/models/rock_moss_set_01/rock_moss_set_01_2k.gltf)
- 计划去向：正式使用；区域：林道；渡口；用途：近景岩石。
- 尺度／适配：高0.45–0.8米；按子网格布置；自然物；只选所需岩块，天池裸岩另做材质。
- 后续关联：S12、S22、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_rock_07 · Rock 07

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Jenelle van Heerden](https://polyhaven.com/a/rock_07)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/rock_07/rock_07_2k.gltf](../../AssetLibrary/environment/models/rock_07/rock_07_2k.gltf)
- 计划去向：改造；区域：天池岩台；山路；用途：谈话前景岩块。
- 尺度／适配：长1–3米；自然岩石；重塑接地与可站立顶面，补简化碰撞。
- 后续关联：S22、S23（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wooden_crate_01 · Wooden Crate 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[James Ray Cock](https://polyhaven.com/a/wooden_crate_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_crate_01/wooden_crate_01_2k.gltf](../../AssetLibrary/environment/models/wooden_crate_01/wooden_crate_01_2k.gltf)
- 计划去向：正式使用；区域：木料巷；电报房；渡口；用途：货物与掩体视觉细节。
- 尺度／适配：宽0.8–1.2米；木箱形制通用；去不合年代标识，视觉与实际掩体碰撞一致。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_old_military_crate · Old Military Crate

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Jack Mava](https://polyhaven.com/a/old_military_crate)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；Check and repaint printed labels/markings for the 1930s Northeast China setting.
- 本地入口：[AssetLibrary/environment/models/old_military_crate/old_military_crate_2k.gltf](../../AssetLibrary/environment/models/old_military_crate/old_military_crate_2k.gltf)
- 计划去向：改造；区域：检查口；电报房；用途：岗哨军需物资。
- 尺度／适配：宽0.7–1.1米；重绘外文与部队标识；不把现代扫描标签当作历史实物。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wooden_military_crate · Wooden Military Crate

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Prabhjinder Singh](https://polyhaven.com/a/wooden_military_crate)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；Check and repaint printed labels/markings for the 1930s Northeast China setting.
- 本地入口：[AssetLibrary/environment/models/wooden_military_crate/wooden_military_crate_2k.gltf](../../AssetLibrary/environment/models/wooden_military_crate/wooden_military_crate_2k.gltf)
- 计划去向：改造；区域：木料巷；渡口；用途：军需箱堆。
- 尺度／适配：宽0.8–1.2米；清理年代不明喷字；减面与材质统一后可作成组货物。
- 后续关联：S11、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wine_barrel_01 · Wine Barrel 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[James Ray Cock](https://polyhaven.com/a/wine_barrel_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wine_barrel_01/wine_barrel_01_2k.gltf](../../AssetLibrary/environment/models/wine_barrel_01/wine_barrel_01_2k.gltf)
- 计划去向：正式使用；区域：木料巷；渡口；用途：储水与杂物。
- 尺度／适配：高0.9–1.0米；去酒庄标记，按木桶解释；不默认作为可爆炸物。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_wooden_bucket_01 · Wooden Bucket 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[James Ray Cock](https://polyhaven.com/a/wooden_bucket_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_bucket_01/wooden_bucket_01_2k.gltf](../../AssetLibrary/environment/models/wooden_bucket_01/wooden_bucket_01_2k.gltf)
- 计划去向：正式使用；区域：木料巷；电报房；用途：生活痕迹。
- 尺度／适配：高0.4–0.5米；通用木桶；保持提手比例，不能代替大型布景。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_wooden_ladder · Wooden Ladder

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Miroslav Turura](https://polyhaven.com/a/wooden_ladder)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_ladder/wooden_ladder_2k.gltf](../../AssetLibrary/environment/models/wooden_ladder/wooden_ladder_2k.gltf)
- 计划去向：正式使用；区域：仓库外墙；木料巷；用途：生产工具与垂直构图。
- 尺度／适配：高2.5–3.5米；通用木梯；本轮拟静态布景，不承诺攀爬机制。
- 后续关联：S10、S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wooden_axe_02 · Wooden Axe 02

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Ulan Cabanilla](https://polyhaven.com/a/wooden_axe_02)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_axe_02/wooden_axe_02_2k.gltf](../../AssetLibrary/environment/models/wooden_axe_02/wooden_axe_02_2k.gltf)
- 计划去向：正式使用；区域：木料巷；用途：伐木工具。
- 尺度／适配：长0.6–0.8米；检查斧头样式和握持；伐木演出需单独绑定。
- 后续关联：S11、S19（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_handsaw_wood · Handsaw Wood

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Konrad Sza艂ankiewicz](https://polyhaven.com/a/handsaw_wood)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/handsaw_wood/handsaw_wood_2k.gltf](../../AssetLibrary/environment/models/handsaw_wood/handsaw_wood_2k.gltf)
- 计划去向：正式使用；区域：木料巷；用途：锯木工具。
- 尺度／适配：长0.5–0.8米；手锯样式复核；与工作台组合，不漂浮陈列。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_Lantern_01 · Lantern 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rajil Jose Macatangay](https://polyhaven.com/a/Lantern_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/Lantern_01/Lantern_01_2k.gltf](../../AssetLibrary/environment/models/Lantern_01/Lantern_01_2k.gltf)
- 计划去向：正式使用；区域：检查口；电报房；渡口；用途：视觉引导与暖光点。
- 尺度／适配：高0.3–0.45米；核对油灯细部，动态光源分档限量；网格远距简化。
- 后续关联：S11、S23、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_WoodenTable_01 · Wooden Table 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Ethan Place](https://polyhaven.com/a/WoodenTable_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/WoodenTable_01/WoodenTable_01_2k.gltf](../../AssetLibrary/environment/models/WoodenTable_01/WoodenTable_01_2k.gltf)
- 计划去向：正式使用；区域：电报房；木料巷；用途：任务桌与工作台。
- 尺度／适配：桌高0.76–0.9米；保留任务桌锚点；保持密码本交互位置；禁止装饰侵占既有通道。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_wooden_stool_01 · Wooden Stool 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Kuutti Siitonen](https://polyhaven.com/a/wooden_stool_01)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_stool_01/wooden_stool_01_2k.gltf](../../AssetLibrary/environment/models/wooden_stool_01/wooden_stool_01_2k.gltf)
- 计划去向：正式使用；区域：电报房；生活角落；用途：休息座具。
- 尺度／适配：座高0.42–0.5米；通用木凳；降低细节开销，配合桌高。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wooden_bookshelf_worn · Wooden Bookshelf Worn

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Ulan Cabanilla](https://polyhaven.com/a/wooden_bookshelf_worn)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/wooden_bookshelf_worn/wooden_bookshelf_worn_2k.gltf](../../AssetLibrary/environment/models/wooden_bookshelf_worn/wooden_bookshelf_worn_2k.gltf)
- 计划去向：改造；区域：电报房；用途：文件与背景层次。
- 尺度／适配：高1.6–1.9米；重绘现代书脊与标签；不挡陆山救援路线。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_barrel_stove · Barrel Stove

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[MP](https://polyhaven.com/a/barrel_stove)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/barrel_stove/barrel_stove_2k.gltf](../../AssetLibrary/environment/models/barrel_stove/barrel_stove_2k.gltf)
- 计划去向：改造；区域：工棚；电报房；用途：寒地取暖线索。
- 尺度／适配：高0.8–1.2米；炉体与排烟方式需年代核对；增加烟管，火焰另做。
- 后续关联：S11、S27（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_modular_wooden_pier · Modular Wooden Pier

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Rico Cilliers](https://polyhaven.com/a/modular_wooden_pier)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.
- 本地入口：[AssetLibrary/environment/models/modular_wooden_pier/modular_wooden_pier_2k.gltf](../../AssetLibrary/environment/models/modular_wooden_pier/modular_wooden_pier_2k.gltf)
- 计划去向：改造；区域：渡口；用途：码头视觉替换。
- 尺度／适配：走道净宽2–3米；按实际撤离锚点拼接；模块按需抽取，保持解缆与船边站位；碰撞独立。
- 后续关联：S10、S13、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_pine_sapling_small · Pine Sapling Small

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel, Rico Cilliers](https://polyhaven.com/a/pine_sapling_small)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；High polygon source asset: decimation/LOD or baking is required before dense realtime placement.；Small sapling; does not replace a mature forest tree set. Need mature pine/birch models and wind setup.
- 本地入口：[AssetLibrary/environment/models/pine_sapling_small/pine_sapling_small_2k.gltf](../../AssetLibrary/environment/models/pine_sapling_small/pine_sapling_small_2k.gltf)
- 计划去向：正式使用；区域：检查口林缘；用途：少量高细节近景树。
- 尺度／适配：已有高3.0/3.7米；保持少量；小树不能替代成熟林；源面数极高，先减面和分级，避免密集复制。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_vintage_radio_transceiver · Vintage Radio Transceiver

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Mateusz Sadek](https://polyhaven.com/a/vintage_radio_transceiver)；条件：CC0-1.0。
- 原始说明：glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.；WW2-style field radio: useful for the telegraph room; specific model/year and army markings need historical review or repainting.
- 本地入口：[AssetLibrary/environment/models/vintage_radio_transceiver/vintage_radio_transceiver_2k.gltf](../../AssetLibrary/environment/models/vintage_radio_transceiver/vintage_radio_transceiver_2k.gltf)
- 计划去向：改造；区域：电报房；用途：电台任务道具。
- 尺度／适配：宽约0.93米的现有展示尺度复核；已有接入但型号年份未考证；去不符年代刻度与标记，任务锚点不变。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_brown_mud_leaves_01 · Brown Mud Leaves 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/brown_mud_leaves_01)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：林道；电报房外；用途：落叶地表。
- 尺度／适配：2K贴图；每块覆盖1–3米；匹配秋冬季节；不把材质贴图算成模型。
- 后续关联：S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_forest_ground_04 · Forest Ground 04

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel, Rico Cilliers](https://polyhaven.com/a/forest_ground_04)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：全关卡地面；用途：林土底色。
- 尺度／适配：2K贴图；按实际地面UV密度校准；统一泥土色调，避免大面积纹理重复。
- 后续关联：S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_muddy_tracks · Muddy Tracks

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Amal Kumar](https://polyhaven.com/a/muddy_tracks)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：林道；木料巷；用途：泥辙与通行引导。
- 尺度／适配：2K贴图；小径宽约4米；泥辙符合生产区，但车辆规格不由纹理推断。
- 后续关联：S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_pine_bark · Pine Bark

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Dimitrios Savva](https://polyhaven.com/a/pine_bark)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：树林；用途：树干表面。
- 尺度／适配：2K贴图；按树径校准；针叶树材质；配合合适树冠轮廓，不能独立证明树种。
- 后续关联：S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/world.gd](../../GodotProject/scripts/world.gd)

## polyhaven_japanese_cedar_bark · Japanese Cedar Bark

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Charlotte Baglioni](https://polyhaven.com/a/japanese_cedar_bark)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：材质参考；用途：通用树皮试样。
- 尺度／适配：2K贴图；无模型尺寸；来源名称不等于东北树种；默认不用于地域辨识近景。
- 后续关联：S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wood_trunk_wall · Wood Trunk Wall

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Amal Kumar](https://polyhaven.com/a/wood_trunk_wall)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：工棚；木屋；用途：原木墙体。
- 尺度／适配：2K贴图；圆木直径约0.15–0.25米；适合林区底模；与东北民居形制和保温细节一起校准。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_weathered_brown_planks · Weathered Brown Planks

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Dimitrios Savva, Rico Cilliers](https://polyhaven.com/a/weathered_brown_planks)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：电报房；仓库；渡口；用途：旧木板表面。
- 尺度／适配：2K贴图；按板宽0.1–0.25米校准；保持木板尺度统一，增加用途差异与磨损。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_raw_plank_wall · Raw Plank Wall

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Dimitrios Savva](https://polyhaven.com/a/raw_plank_wall)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：木料巷；工棚；用途：新旧木材差异。
- 尺度／适配：2K贴图；与旧木板同尺度；用于生产区新料，避免整场景同一种材质。
- 后续关联：S11、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_wood_chips · Wood Chips

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[eye-candy.xyz](https://polyhaven.com/a/wood_chips)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：木料巷；锯木棚；用途：木屑堆与加工痕迹。
- 尺度／适配：2K贴图；局部覆盖1–3米；生产用途明确；地面贴片避免闪烁。
- 后续关联：S11、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_grey_roof_tiles · Grey Roof Tiles

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/grey_roof_tiles)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：电报房；院落；用途：灰瓦屋面。
- 尺度／适配：2K贴图；按瓦片0.15–0.25米校准；用于筛选后的建筑，屋顶坡度与檐口另做。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_brick_wall_001 · Brick Wall 001

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Rob Tuytel, Dimitrios Savva](https://polyhaven.com/a/brick_wall_001)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：电报房；厂房；用途：砖墙。
- 尺度／适配：2K贴图；按砖长约0.24米起校；贴图是现代扫描，去不合年代修补细节，尺寸为制作假设。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_rusty_metal_04 · Rusty Metal 04

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Amal Kumar](https://polyhaven.com/a/rusty_metal_04)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：仓库；电报房；用途：铁件与设备旧化。
- 尺度／适配：2K贴图；局部覆盖；只作表面旧化，不据此认定设备年代。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)

## polyhaven_gravel_road · Gravel Road

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Amal Kumar](https://polyhaven.com/a/gravel_road)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：检查口；渡口；用途：碎石路与地面过渡。
- 尺度／适配：2K贴图；路线宽2–4米；与泥地过渡，脚步材质标签在音频步骤接入。
- 后续关联：S12、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_snow_02 · Snow 02

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Rob Tuytel](https://polyhaven.com/a/snow_02)；条件：CC0-1.0。
- 原始说明：2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：过场；区域：历史序章A1；A3；用途：雪地行军镜头。
- 尺度／适配：2K贴图；远近景分级；仅用于明确的冬季镜头；避免与可玩秋季地表混杂。
- 后续关联：S07、S12、S32（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## polyhaven_kloofendal_overcast_puresky · Kloofendal Overcast (Pure Sky)

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Greg Zaal](https://polyhaven.com/a/kloofendal_overcast_puresky)；条件：CC0-1.0。
- 原始说明：2k HDR environment; import into Godot PanoramaSkyMaterial and tune exposure. Forest panorama is lighting/reference, not playable geometry.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：可玩关卡；天池；用途：阴天天光与环境反射。
- 尺度／适配：2K HDRI；无几何尺寸；只用天空与照明，不声明为东北实拍天空。
- 后续关联：S23、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/world.gd](../../GodotProject/scripts/world.gd)

## polyhaven_autumn_forest_01 · Autumn Forest 01

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Andreas Mischok](https://polyhaven.com/a/autumn_forest_01)；条件：CC0-1.0。
- 原始说明：2k HDR environment; import into Godot PanoramaSkyMaterial and tune exposure. Forest panorama is lighting/reference, not playable geometry.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：灯光参考；用途：树林光照试样。
- 尺度／适配：2K HDRI；无几何尺寸；带树木全景不适合作可游玩林区远景；避免树种地域误导。
- 后续关联：S12、S23（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_dims-arboretum · Dim's Arboretum

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Dim](https://opengameart.org/content/dims-arboretum)；条件：CC-BY-3.0。
- 原始说明：Textured mature conifer/tree, vegetation, logs and props. Blender source pack from 2010; inspect packed texture links and convert to glTF. Attribute Dim, source and CC-BY-3.0; identify modifications.；ZIP CRC verified and safely extracted; content is data only and has not been executed.；Read-only Blender DNA inspection: 65 meshes, including Fir (201 vertices / 96 faces), FirSmall (87 / 41), Beech (151 / 101), woodpile and vegetation. These are low-detail branch-card assets suited to mid/far forest; conversion and texture adaptation remain.
- 本地入口：[AssetLibrary/environment/supplement/dims-arboretum/extracted/dim_arboretum.blend](../../AssetLibrary/environment/supplement/dims-arboretum/extracted/dim_arboretum.blend)
- 计划去向：远景；区域：林道两侧；历史序章A1；用途：中远距离树林轮廓。
- 尺度／适配：树高8–15米；按单株缩放；低面枝叶片；转换后修透明、风摆和材质，包内多对象不整包摆场。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_jkms-tree-set · JKM's tree set

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Julius Krischan Makowka (JKM / Julius)](https://opengameart.org/content/jkms-tree-set)；条件：CC-BY-SA-3.0。
- 原始说明：Game-oriented mature pine and deciduous trees with alternate skins, originally made for Quake 3. Selected CC-BY-SA-3.0 from offered license choices. Preserve attribution and share-alike for asset derivatives; check transparency, texture resolution and materials. Useful candidate for mid/far forest, not claimed modern AAA quality.；ZIP CRC verified and safely extracted; content is data only and has not been executed.；OBJ inspection: full-size pine 171 vertices / 113 triangles; five OBJ variants total. Source OBJ files reference missing MTL files. All leaf TGA and bark JPG textures are present; material bindings must be repaired before textured import. Appropriate mainly for distant trees/LOD.
- 本地入口：[AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/pinetree.obj](../../AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/pinetree.obj)；[AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/pinetree_small.obj](../../AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/pinetree_small.obj)；[AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/tree.obj](../../AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/tree.obj)；[AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/tree_small.obj](../../AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/tree_small.obj)；[AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/xmas_tree.obj](../../AssetLibrary/environment/supplement/jkms-tree-set/extracted/models/xmas_tree.obj)
- 计划去向：远景；区域：树林最外层；用途：远处林线与低细节替代。
- 尺度／适配：树高10–18米；逐株校准；OBJ缺MTL，需用现存树皮和叶片图重绑；仅远景。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_birch-tree · Birch Tree

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[AnyRPG; derivative of geekygnome Low Poly Tree](https://opengameart.org/content/birch-tree)；条件：CC0-1.0。
- 原始说明：Source page states 1294 vertices / 1776 triangles. Blender source with birch bark; inspect leaf alpha and convert to glTF. Semi-realistic stylized foliage, not a scanned tree.；Read-only Blender DNA inspection confirms 3 meshes: a ground plane and two 647-vertex, 462-polygon tree meshes. Page aggregate: 1294 vertices / 1776 triangles. Blender 2.81 source; convert and verify leaf transparency.
- 本地入口：[AssetLibrary/environment/supplement/birch-tree/treebirch.blend](../../AssetLibrary/environment/supplement/birch-tree/treebirch.blend)
- 计划去向：改造；区域：林道；山路；用途：白桦辨识点。
- 尺度／适配：树高6–10米；剔除源地面；实测3个外部贴图引用缺失；补齐或重绘并重绑，再检查叶片透明与风摆，不可直接按贴图完整使用。
- 后续关联：S12、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_medieval-waterpowered-sawmill · Medieval Waterpowered Sawmill

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S10已适配并接入D05；原包其他部件不视为全部使用**。
- 来源：[Daniel Andersson; submitted by hreikin](https://opengameart.org/content/medieval-waterpowered-sawmill)；条件：CC0-1.0。
- 原始说明：Timber sawmill shed and waterwheel, useful lumberyard source. Blender format; community comment reports animation but animation existence/usefulness must be inspected before promising it. Rework medieval foundation/style for Northeast China setting.；ZIP CRC verified and safely extracted; content is data only and has not been executed.；Read-only Blender DNA inspection confirms 18 meshes and a bAction named Sawing. No animation playback or Blender export has been performed. Source data is Blender 2.71.
- 本地入口：[AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend](../../AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend)
- 计划去向：改造；区域：木料巷外侧；历史序章A2；用途：锯木棚与水轮生产背景。
- 尺度／适配：棚高4–6米；水轮直径3–4米；重做中世纪基础与装饰；已有Sawing动作仅登记，不保证可直接播放。
- 后续关联：S10、S11、S19（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S10-large-building-integration.md](../../docs/S10-large-building-integration.md)；[docs/level/S10/build_manifest.json](../../docs/level/S10/build_manifest.json)

## oga_retro-log-cabin · Retro Log Cabin

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**S10已适配并接入D02；原包其他部件不视为全部使用**。
- 来源：[Elegant Crow](https://opengameart.org/content/retro-log-cabin)；条件：CC-BY-SA-4.0。
- 原始说明：Cabin with interior and independent doors/windows, 1K/4K textures per source. Selected standard page license conservatively despite relaxed attribution note. Preserve attribution and share-alike for asset derivatives. Re-material/repaint to match historical setting.；ZIP CRC verified and safely extracted; content is data only and has not been executed.
- 本地入口：[AssetLibrary/environment/supplement/retro-log-cabin/extracted/log_cabin/log_cabin.fbx](../../AssetLibrary/environment/supplement/retro-log-cabin/extracted/log_cabin/log_cabin.fbx)
- 计划去向：改造；区域：林场生活区；历史序章A2；用途：可见室内的木屋。
- 尺度／适配：门高1.9–2.1米；屋檐高2.8–3.2米；西式通用木屋；调整屋顶窗格、炉灶与保温细节。
- 后续关联：S10、S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S10-large-building-integration.md](../../docs/S10-large-building-integration.md)；[docs/level/S10/build_manifest.json](../../docs/level/S10/build_manifest.json)

## oga_log-cabin-dae · Log Cabin (DAE)

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[mixxit](https://opengameart.org/content/log-cabin-dae)；条件：CC-BY-3.0。
- 原始说明：Log cabin with internal space in Collada DAE. Convert to glTF; check scale, collision, doors, texture paths. Attribute mixxit, source/license and modifications.；ZIP CRC verified and safely extracted; content is data only and has not been executed.；Collada XML parses correctly. Five referenced image files are present at the declared relative paths.
- 本地入口：[AssetLibrary/environment/supplement/log-cabin-dae/extracted/logcabin/logcabin.dae](../../AssetLibrary/environment/supplement/log-cabin-dae/extracted/logcabin/logcabin.dae)
- 计划去向：改造；区域：林场外围；历史序章A2；用途：另一种木屋外形。
- 尺度／适配：门高1.9–2.1米；统一米制；DAE需转换并检查相对贴图、碰撞与开口；不是东北民居复原。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_modular-building-asset-0 · Nobiax Modular Building Asset

- 分类／库存性质：environment / downloaded_source_group；原记录状态：downloaded_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Yughues (Nobiax)](https://opengameart.org/content/modular-building-asset-0)；条件：CC0-1.0。
- 原始说明：Industrial walls, roof, door/window/pillar modules. Use structural pieces suitable to the period; exclude modern air-conditioning equipment. Check UVs and apply collected PBR materials where needed.；7z structure checked and safely extracted; downloaded content has not been executed.；Archive contains 34 OBJ modules plus matching 34 FBX versions; OBJ estimated triangles range 12–154 per module. OBJ has no MTL binding; source TGA maps are present and decode correctly. Material assignment remains.
- 本地入口：[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/block.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/block.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_door.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_door.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_double_window.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_double_window.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_double_window.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_double_window.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_window_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_window_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_window_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_small_window_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_window_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_window_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_window_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/brick_window_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_door.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_door.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_double_window.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_double_window.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_double_window.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_double_window.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_window_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_window_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_window_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_small_window_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_window_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_window_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_window_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/concrete_window_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/cooling.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/cooling.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/hangar_door.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/hangar_door.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_3.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_brick_3.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_3.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/pillar_concrete_3.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/roof.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/roof.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_3.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_3.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_4.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_4.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_5.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_brick_5.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_1.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_1.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_2.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_2.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_3.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_3.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_4.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_4.obj)；[AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_5.obj](../../AssetLibrary/environment/supplement/modular-building-asset-0/extracted/wall_concrete_5.obj)
- 计划去向：改造；区域：仓库；电报房外；用途：低成本墙体屋顶补件。
- 尺度／适配：按门高2米、层高3米拼接；34组OBJ/FBX是重复格式；修材质，剔除空调等现代设备。
- 后续关联：S10、S13、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## quaternius_ual1 · Universal Animation Library[Standard]

- 分类／库存性质：characters / downloaded_source_group；原记录状态：downloaded_extracted_gltf_structure_verified_not_integrated。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Quaternius](https://quaternius.itch.io/universal-animation-library)；条件：CC0-1.0。
- 原始说明：Standard free release. Original archive retained; source webpage retained. Direct CDN URL is ephemeral; download_url records source upload endpoint.；43 clips in each GLB, including A_TPose. Root-motion and in-place files duplicate the same 43 action names, not 86 different actions. Verified skin: 65 joints.；Useful: Walk_Loop, Walk_Formal_Loop, Jog_Fwd_Loop, Sprint_Loop, Crouch_Fwd_Loop, Crouch_Idle_Loop, Hit_Chest, Hit_Head, Death01, Pistol_Aim_Down/Neutral/Up, Pistol_Reload, Pistol_Shoot. Gun clips are pistol, not rifle.；Generic humanoid actions require retargeting to final NPC rigs; first-person bolt/reload/grip contact needs weapon-specific authoring.
- 本地入口：[AssetLibrary/characters/quaternius_ual1/files/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb](../../AssetLibrary/characters/quaternius_ual1/files/Universal%20Animation%20Library%5BStandard%5D/Unreal-Godot/UAL1_Standard.glb)；[AssetLibrary/characters/quaternius_ual1/files/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard_RM.glb](../../AssetLibrary/characters/quaternius_ual1/files/Universal%20Animation%20Library%5BStandard%5D/Unreal-Godot/UAL1_Standard_RM.glb)
- 计划去向：改造；区域：全部角色；用途：走跑、受击与倒地动作参考。
- 尺度／适配：65关节；按约1.7米角色校准步幅；42个非T姿态名；65骨到13骨需适配，手枪动作不能充作栓动步枪整套动作。
- 后续关联：S14、S15、S16、S17、S18（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## quaternius_ual2 · Universal Animation Library 2[Standard]

- 分类／库存性质：characters / downloaded_source_group；原记录状态：downloaded_extracted_gltf_structure_verified_not_integrated。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Quaternius](https://quaternius.itch.io/universal-animation-library-2)；条件：CC0-1.0。
- 原始说明：Standard free release. Original archive retained; source webpage retained. Direct CDN URL is ephemeral; download_url records source upload endpoint.；43 clips in each animation GLB including A_TPose. Root-motion variant duplicates action names. Verified skin: 65 joints. Female mannequin has 65 joints and no embedded clips.；Useful: ClimbUp_1m, Hit_Knockback, OverhandThrow, Slide_Start/Loop/Exit, LayToIdle, TreeChopping_Loop, Walk_Carry_Loop, Consume. Several combat/fantasy clips are irrelevant to this setting.；UAL1 and UAL2 together have 85 unique clip names, including the shared A_TPose (84 non-T-pose names).
- 本地入口：[AssetLibrary/characters/quaternius_ual2/files/Universal Animation Library 2[Standard]/Female Mannequin/Unreal-Godot/Mannequin_F.glb](../../AssetLibrary/characters/quaternius_ual2/files/Universal%20Animation%20Library%202%5BStandard%5D/Female%20Mannequin/Unreal-Godot/Mannequin_F.glb)；[AssetLibrary/characters/quaternius_ual2/files/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb](../../AssetLibrary/characters/quaternius_ual2/files/Universal%20Animation%20Library%202%5BStandard%5D/Unreal-Godot/UAL2_Standard.glb)；[AssetLibrary/characters/quaternius_ual2/files/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard_RM.glb](../../AssetLibrary/characters/quaternius_ual2/files/Universal%20Animation%20Library%202%5BStandard%5D/Unreal-Godot/UAL2_Standard_RM.glb)
- 计划去向：改造；区域：工人；伤员；战士；用途：搬运、起身、投掷等动作参考。
- 尺度／适配：65关节；按实际移动速度校准；42个非T姿态名；剔除奇幻动作，重定向与脚步接地另验收。
- 后续关联：S14、S16、S18、S19（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## quaternius_base_characters · Universal Base Characters[Standard]

- 分类／库存性质：characters / downloaded_source_group；原记录状态：downloaded_extracted_gltf_structure_verified_not_integrated。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Quaternius](https://quaternius.itch.io/universal-base-characters)；条件：CC0-1.0。
- 原始说明：Standard free release. Original archive retained; source webpage retained. Direct CDN URL is ephemeral; download_url records source upload endpoint.；Fixed broken *_png.png image URI names in extracted glTF to point at the matching .png files already included by the author. Original ZIP is preserved unchanged. See texture_reference_repairs.json.；Two full-body male/female characters, each 65 joints, 3 meshes and 7 image entries; 8 eyebrow/hair choices supplied both static and head-rigged. Full-body characters contain no embedded animations.；Detailed textures are included, but these are stylized superhero base bodies, not ready-to-use 1938 Northeast Anti-Japanese United Army uniforms. Clothing, head/skin appearance and equipment require adaptation.；18 glTF files total in this kit: 2 bodies and 16 hair/eyebrow variants. Do not report this as 18 full characters.
- 本地入口：[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Female_FullBody.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Base%20Characters/Godot%20-%20UE/Superhero_Female_FullBody.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Male_FullBody.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Base%20Characters/Godot%20-%20UE/Superhero_Male_FullBody.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Eyebrows_Female.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Eyebrows_Female.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Eyebrows_Regular.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Eyebrows_Regular.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_Beard.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_Beard.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_Buns.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_Buns.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_Buzzed.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_Buzzed.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_BuzzedFemale.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_BuzzedFemale.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_Long.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_Long.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Origin at 0/glTF (Godot)/Hair_SimpleParted.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Origin%20at%200/glTF%20%28Godot%29/Hair_SimpleParted.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Eyebrows_Female.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Eyebrows_Female.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Eyebrows_Regular.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Eyebrows_Regular.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_Beard.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_Beard.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_Buns.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_Buns.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_Buzzed.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_Buzzed.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_BuzzedFemale.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_BuzzedFemale.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_Long.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_Long.gltf)；[AssetLibrary/characters/quaternius_base_characters/files/Universal Base Characters[Standard]/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/Hair_SimpleParted.gltf](../../AssetLibrary/characters/quaternius_base_characters/files/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20%28Godot%20-Unreal%29/Hair_SimpleParted.gltf)
- 计划去向：正式使用；区域：全部NPC；用途：现有人物头脸与手部基础。
- 尺度／适配：基体65关节；游戏派生13骨；已选用男性基础局部；超英服装不直接接入，女性和发型不算18个独立角色。
- 后续关联：S14、S19、S24（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/assets/characters/provenance.json](../../GodotProject/assets/characters/provenance.json)；[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)

## godot_tps_player · Godot TPS Demo player robot and gun animation reference

- 分类／库存性质：characters / downloaded_source_group；原记录状态：downloaded_extracted_gltf_structure_verified_not_integrated。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Juan Linietsky, Fernando Miguel Calabró; Godot Engine contributors](https://github.com/godotengine/tps-demo)；条件：CC-BY-3.0 (assets); MIT (code)。
- 原始说明：Robot visual design is unsuitable for the 1938 story; use gun hold/aim locomotion as a retargeting and animation-state reference. GLB inspection does not by itself verify retargeting compatibility.；Original materials, 4 PBR texture maps, GLB import settings, player scene and script saved as integration references; the partial example is not a runnable project. Material paths must be relocated when integrating.；56 embedded clips, including author work-in-progress clips tagged -noexp. Skin has 145 joints. Useful gun locomotion: running_aiming, running_gun-cycle, walking_gun-cycle, strafe_back/front/left/right-cycle, AIM-Center/Down/Up, flinch clips.；Model is a science-fiction robot. Use as animation reference/retarget source only for this historical game; robot and arm-cannon clips are not a finished rifle animation set.；29 of 56 embedded clip names do not carry the author -noexp work-in-progress suffix; these are candidate gameplay clips, not all verified final production clips.
- 本地入口：[AssetLibrary/characters/godot_tps_player/player/model/player.glb](../../AssetLibrary/characters/godot_tps_player/player/model/player.glb)
- 计划去向：备用；区域：动画制作参考；用途：持枪移动与动作状态参考。
- 尺度／适配：145关节、56嵌入动作，含27个-noexp；科幻机器人外观不进历史场景；动作重定向先试样，29个非-noexp也非已验收成品。
- 后续关联：S14、S17（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## oga_fps_arms · fps arms (rigged only)

- 分类／库存性质：first_person / downloaded_source_group；原记录状态：downloaded_extracted_godot_import_verified_not_integrated。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[para; MakeHuman base](https://opengameart.org/content/fps-arms-rigged-only)；条件：CC0-1.0。
- 原始说明：4600 imported vertices, 8152 triangles, 62 skeleton bones, 50 skin binds.；No-animation FBX has zero clips; test FBX has one 2.25-second test animation.；FBX material texture missing; test version scale 10x. Fixes restricted to AssetReview work copies.；Requires historical sleeves and weapon-specific first-person grip/bolt/reload animation.
- 本地入口：[AssetReview/ready/fps_arms_textured.glb](../../AssetReview/ready/fps_arms_textured.glb)；[AssetReview/ready/fps_arms_test_scaled_textured.glb](../../AssetReview/ready/fps_arms_test_scaled_textured.glb)
- 计划去向：正式使用；区域：第一人称武器；用途：原始双臂来源与握持基础。
- 尺度／适配：原62骨；工作双手各24骨；原测试动作未采用；当前细分双手为派生输出，袖口和年代衣物由项目制作。
- 后续关联：S17（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/assets/first_person/provenance.json](../../GodotProject/assets/first_person/provenance.json)；[GodotProject/scripts/fp_hands.gd](../../GodotProject/scripts/fp_hands.gd)

## lee_enfield · Bolt action Rifle: Lee Enfield

- 分类／库存性质：weapons / downloaded_source_group；原记录状态：downloaded_extracted_godot_import_verified_not_integrated。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Lucian Pavel](https://opengameart.org/content/bolt-action-rifle-lee-enfield)；条件：CC0-1.0。
- 原始说明：Godot: 5424 triangles, 4607 vertices, one mesh/surface, no skeleton or animations or separate moving-part nodes.；Diffuse 2K auto-bound; normal/specular not auto-bound. AssetReview working copy binds normal; specular is not reused as metallic or roughness.；Lee Enfield geometry is a workflow reference, not an Arisaka replacement. Requires weapon type research and separate moving parts.
- 本地入口：[AssetReview/ready/lee_enfield_display.glb](../../AssetReview/ready/lee_enfield_display.glb)
- 计划去向：备用；区域：武器制作参考；用途：材质、结构与导入工艺参考。
- 尺度／适配：工作预览长约0.929单位，非实枪校准；李恩菲尔德不能冒充三八式；单网格无独立枪机，不计作成套第一人称武器。
- 后续关联：S17（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## the-free-firearm-sound-library · The Free Firearm Sound Library

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Ben Jaszczak; Brian Nelson; Kevin Heras; Matthew Nanney](https://opengameart.org/content/the-free-firearm-sound-library)；条件：CC0-1.0。
- 原始说明：Real firearm prepared SFX. Primary gunshot source; choose bolt-action/period-compatible timbre and synchronize per animation.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：战斗；历史序章A4；用途：枪声主体与远近层。
- 尺度／适配：48kHz工作切片；逐武器选择；已接入1个Arisaka音色；源标.30-06不作原装弹药考据，现代自动武器录音仅备用。
- 后续关联：S26、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/audio_factory.gd](../../GodotProject/scripts/audio_factory.gd)

## handling-guns · Handling Guns

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Gary (fossilrecords.net)](https://opengameart.org/content/handling-guns)；条件：CC-BY-SA-3.0。
- 原始说明：Includes bolt-action rifle mechanics and dry recordings. Credit Guns by Gary; preserve share-alike for modified audio.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：第一人称武器；用途：拉栓与机械动作层。
- 尺度／适配：逐动作切片，短音效单声道；筛选栓动机构并同步动作；保留来源及派生许可说明。
- 后续关联：S17、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## gun-reload-sounds · Gun reload sounds

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[SpringySpringo](https://opengameart.org/content/gun-reload-sounds)；条件：CC0-1.0。
- 原始说明：Airsoft recordings; useful mechanical layers, not historically exact rifle handling.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：机械拟音参考；用途：补充金属与装填细节。
- 尺度／适配：短切片，不直接整段循环；气枪录音不是历史枪械；试听合适时才混为低音量机械层。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## q009s-weapon-sounds · Q009 weapon sounds

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Q009](https://opengameart.org/content/q009s-weapon-sounds)；条件：CC-BY-SA-3.0。
- 原始说明：Gunshots, reloads, shell eject and explosions; stylized supplemental layers.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：战斗；历史序章A4；用途：爆炸和枪声补层。
- 尺度／适配：短效果单声道，按距离分层；偏风格化；裁掉科幻/不符武器录音，炮弹需要独立试听。
- 后续关联：S27、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## ambient-mountain-river-wind-and-forest-and-waterfall · Ambient mountain, river, wind, forest and waterfall

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Blender Foundation](https://opengameart.org/content/ambient-mountain-river-wind-and-forest-and-waterfall)；条件：CC-BY-3.0。
- 原始说明：From Yo Frankie; use forest and water loops, check transitions before game import.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：林道；渡口；天池；用途：森林风与河水环境。
- 尺度／适配：现有森林8.58秒、河水13.5秒循环；已接入森林与河流；天池以高地风为主，不直接套瀑布声。
- 后续关联：S23、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/audio_factory.gd](../../GodotProject/scripts/audio_factory.gd)；[GodotProject/scripts/story_moments.gd](../../GodotProject/scripts/story_moments.gd)

## fantozzis-footsteps-grasssand-stone · Fantozzi footsteps grass/sand and stone

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Fantozzi; prepared by Iwan Gabovitch (qubodup)](https://opengameart.org/content/fantozzis-footsteps-grasssand-stone)；条件：CC0-1.0。
- 原始说明：12 steps in FLAC and OGG; avoid counting alternate formats as unique performances.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：林道；天池岩台；用途：草石脚步变体。
- 尺度／适配：按步态逐个触发，FLAC/OGG不重复计数；与现有脚步音量匹配，走跑节奏由脚部接地事件控制。
- 后续关联：S16、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## footsteps-on-different-surfaces · Footsteps on different surfaces

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[congusbongus and individual contributors listed in included text files](https://opengameart.org/content/footsteps-on-different-surfaces)；条件：CC-BY-3.0。
- 原始说明：Seven surface groups including grass/dirt, gravel, water, wood and metal. Preserve per-file credits in included text files.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：全关卡；用途：按地表切换脚步。
- 尺度／适配：现有草地0.243秒；木地板/水/碎石补选；已接入1个草地脚步；其余待试听，不把7类表面当成已完成混音。
- 后续关联：S16、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/audio_factory.gd](../../GodotProject/scripts/audio_factory.gd)

## 42-snow-and-gravel-footsteps · 42 snow and gravel footsteps

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Corsica_S; extracted by Iwan Gabovitch](https://opengameart.org/content/42-snow-and-gravel-footsteps)；条件：CC0-1.0。
- 原始说明：Snow and gravel useful for northeast outdoor terrain.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：过场；区域：历史序章A3；山路；用途：雪地与碎石行军脚步。
- 尺度／适配：逐脚步采样；按动作同步；优先冬季过场，避免雪地声出现在泥地。
- 后续关联：S28、S30、S32（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## footsteps-leather-cloth-armor · Footsteps leather, cloth, armor

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[HaelDB](https://opengameart.org/content/footsteps-leather-cloth-armor)；条件：CC0-1.0。
- 原始说明：Page offers CC0 and OGA-BY 3.0 alternatives; selected CC0. Soft gain, suitable clothing layers.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：人物移动与谈话；用途：衣料和皮具细声。
- 尺度／适配：轻量事件层，低于对白；筛掉铠甲金属风格；棉衣皮带合适样本后续试听。
- 后续关联：S16、S24、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## cloth-swing-sounds · Cloth swing sounds

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Vinrax](https://opengameart.org/content/cloth-swing-sounds)；条件：CC-BY-3.0。
- 原始说明：Continuous takes in WAV; slice into individual motion cues before use.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：人物转身；倒地；用途：衣料运动拟音。
- 尺度／适配：连续录音先分段；按棉衣重量调整高频，不直接整段触发。
- 后续关联：S18、S24、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## paper-pages-sounds · Paper pages sounds

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Vinrax](https://opengameart.org/content/paper-pages-sounds)；条件：CC-BY-3.0。
- 原始说明：WAV contains separate takes divided by click; slice and remove separators.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：电报房；任务序幕；用途：密码本翻页。
- 尺度／适配：拆分单动作，删除分隔点击声；纸张无明显时代冲突，需与触碰动作同步。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## opening-and-closing-a-map-sounds · Opening and closing a map

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Julie Damsgaard / Spring Spring / Spring Enterprises](https://opengameart.org/content/opening-and-closing-a-map-sounds)；条件：CC0-1.0。
- 原始说明：Two ready cues for maps or documents.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：过场；区域：任务序幕B3；用途：摊开地图交代任务。
- 尺度／适配：开/合两事件；按原创镜头使用，不把有声音当作已有地图动画。
- 后续关联：S05、S24、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## creaky-light-wooden-door · Creaky light wooden door

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[fractilegames](https://opengameart.org/content/creaky-light-wooden-door)；条件：CC-BY-3.0。
- 原始说明：Recorded cabinet door; suitable close creak layer.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：电报房；木屋；用途：轻木门吱响。
- 尺度／适配：短事件，跟随开门速度；原录音为柜门；只作细节层，不能让厚门听感过轻。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## door-open-door-close-set · Door open / close set

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[qubodup](https://opengameart.org/content/door-open-door-close-set)；条件：CC0-1.0。
- 原始说明：Wooden/metal/synthetic doors. Select wood variants for village and telegraph room.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：电报房；仓库；用途：门和栅门开合。
- 尺度／适配：选择木门/适当铁门片段；排除现代合成门声，绑定实际交互事件。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## super-foley-pack · Super Foley Pack

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[dklon](https://opengameart.org/content/super-foley-pack)；条件：CC-BY-3.0。
- 原始说明：Raw multi-take leather, clothing, chest/hand impacts, shuffling and wooden chair sounds; edit before direct event use.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：人物动作；室内；用途：身体受击、衣料与座椅。
- 尺度／适配：多段原录音先切片；筛选真实材质，音量避让对白，不新增未定义暴力表现。
- 后续关联：S18、S24、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## stealth-music · Stealth in the Woods

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Lisboa](https://opengameart.org/content/stealth-music)；条件：CC0-1.0。
- 原始说明：Loopable stealth music candidate; artistic suitability and loop seams not yet auditioned.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：探索音乐候选；用途：潜行氛围试配。
- 尺度／适配：待完整试听与循环点确认；已有下载但未接入；不直接代替抗联宏大序章音乐。
- 后续关联：S29、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## kenney-impact-sounds · Kenney Impact Sounds

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Kenney](https://kenney.nl/assets/impact-sounds)；条件：CC0-1.0。
- 原始说明：130 material impacts; wood/metal/glass layers.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：交火掩体；木料巷；用途：木/金属/玻璃撞击。
- 尺度／适配：短事件分材质；130音效按材质筛选，避免卡通强瞬态，混响按场景处理。
- 后续关联：S27、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## kenney-rpg-audio · Kenney RPG Audio

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Kenney](https://kenney.nl/assets/rpg-audio)；条件：CC0-1.0。
- 原始说明：Equipment/footstep/object sounds; select only realistic period-compatible sounds.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：拟音参考；用途：装备与物件交互候选。
- 尺度／适配：仅取合适短音效；剔除魔法与游戏化提示音，不直接整包接入。
- 后续关联：S28（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## inventory-sound-effects · Inventory Sound Effects

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[artisticdude](https://opengameart.org/content/inventory-sound-effects)；条件：CC-BY-3.0。
- 原始说明：Multiple alternative licenses offered; selected CC-BY 3.0. Six material/object interaction cues.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：整装；任务序幕；用途：布料皮具纸张触碰。
- 尺度／适配：6类物件声音待逐项试听；合适材质用于人物整装，不强加游戏UI提示风格。
- 后续关联：S24、S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## mysterious-radio-signal · Mysterious Radio Signal

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[nicStage (2005); Sam Uncle (2017)](https://opengameart.org/content/mysterious-radio-signal)；条件：CC-BY-3.0。
- 原始说明：Static and Morse code mixture; ambient radio layer only, not a historically verified message. Original contributor credit retained.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：电报房音景参考；用途：静电与电码候选。
- 尺度／适配：分离噪声和可辨电码；来源电码内容未核实，不能当作历史真实通讯。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## radio-noise-1 · Radio Noise 1

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Kresiek The Furry](https://opengameart.org/content/radio-noise-1)；条件：CC0-1.0。
- 原始说明：Real recorded radio static; ambience layer.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：电报房；用途：电台噪声底层。
- 尺度／适配：现有8.5秒循环，随断电停止；已有接入；与对白、任务提示分层，不重复叠播。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/story_moments.gd](../../GodotProject/scripts/story_moments.gd)

## sfx-circuit-breaker · SFX Circuit breaker

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[Cleyton Kauffman](https://opengameart.org/content/sfx-circuit-breaker)；条件：CC0-1.0。
- 原始说明：On and off switch events.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：正式使用；区域：电报房断电；用途：开关反馈。
- 尺度／适配：现有0.923秒短音效；已有接入；视觉开关形制另核对，声音不证明年代。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/scripts/story_moments.gd](../../GodotProject/scripts/story_moments.gd)

## generator-loop · Generator loop

- 分类／库存性质：audio / downloaded_source_group；原记录状态：downloaded_extracted_decode_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[YCbCr](https://opengameart.org/content/generator-loop)；条件：CC0-1.0。
- 原始说明：Low-frequency machinery layer.
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：改造；区域：仓库动力区；电报房外；用途：机器低频底噪。
- 尺度／适配：短距离空间循环；先确认关卡有对应机械；没有机器时不凭空放声，断电后同步停止。
- 后续关联：S28、S30（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## pagoda_red · 五层塔楼（偏日式）

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Poly by Google](https://poly.pizza/m/1zS7ucaAd4J)；条件：CC-BY-3.0。
- 原始说明：高耸地标底模。外观偏日式，保留为备用，不作为东北或中国古建代表。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/pagoda_red/pagoda_red.glb](../../AssetLibrary/environment/china_northeast_20261013/models/pagoda_red/pagoda_red.glb)
- 计划去向：备用；区域：独立参考陈列；用途：塔楼比例与轮廓参考。
- 尺度／适配：不纳入抗联主线尺度；偏日式五层塔，不作中国或东北代表地标。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## pagoda_hall · 三层楼阁（偏日式）

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Poly by Google](https://poly.pizza/m/d1M5ncMBUDi)；条件：CC-BY-3.0。
- 原始说明：原目录称 Pagoda，实物为三层楼阁；屋顶与立面偏日式。原始尺度异常，接入时需重设尺寸。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/pagoda_hall/pagoda_hall.glb](../../AssetLibrary/environment/china_northeast_20261013/models/pagoda_hall/pagoda_hall.glb)
- 计划去向：备用；区域：独立参考陈列；用途：楼阁构造参考。
- 尺度／适配：原尺度异常，若使用需按约10米高度重设；偏日式外观且网格零散；不直接塞入东北主线。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## pagoda_tower · 双层圆亭塔（风格化）

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**库存/规划，未取得后续正式接入回执**。
- 来源：[Poly by Google](https://poly.pizza/m/eHOI2VgW1ol)；条件：CC-BY-3.0。
- 原始说明：红柱绿顶的低面圆亭塔，可作远景点缀；造型简化，不对应具体景点。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/pagoda_tower/pagoda_tower.glb](../../AssetLibrary/environment/china_northeast_20261013/models/pagoda_tower/pagoda_tower.glb)
- 计划去向：远景；区域：历史序章A2远山；外围山脊；用途：通用风格化地标。
- 尺度／适配：高约12米；不做具体景点复原；先核对中式形制并降饱和；不应抢天池主体，必要时撤回备用。
- 后续关联：S10、S12、S32（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## warehouse · 敞顶仓库结构

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S10已适配并接入D03；原包其他部件不视为全部使用**。
- 来源：[Lavender Harmony](https://poly.pizza/m/fsxbktzB1zo)；条件：CC-BY-3.0。
- 原始说明：带木墙与钢架的大型敞顶仓库。适合作为林场仓储背景底模，屋顶、封闭墙面及年代细节需补齐。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/warehouse/warehouse.glb](../../AssetLibrary/environment/china_northeast_20261013/models/warehouse/warehouse.glb)
- 计划去向：改造；区域：木料巷外侧；用途：林场仓储主建筑体块。
- 尺度／适配：初拟高8米、约10×17米占地，按门高复核；敞顶结构需补屋顶、封墙和木构细节，钢架样式需年代筛选。
- 后续关联：S10、S13、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S10-large-building-integration.md](../../docs/S10-large-building-integration.md)；[docs/level/S10/build_manifest.json](../../docs/level/S10/build_manifest.json)

## log_cabin_scene · 木屋与周边环境整景

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S10已适配并接入D01；原包其他部件不视为全部使用**。
- 来源：[Poly by Google](https://poly.pizza/m/2gQe0wyzkhb)；条件：CC-BY-3.0。
- 原始说明：木屋、栈台、地面和围栏整景。可作林区聚落底模，属通用木屋，非东北民居复原；需统一尺度。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/log_cabin_scene/log_cabin_scene.glb](../../AssetLibrary/environment/china_northeast_20261013/models/log_cabin_scene/log_cabin_scene.glb)
- 计划去向：改造；区域：林场外围；历史序章A2；用途：聚落大体块与栈台。
- 尺度／适配：整组占地约20×20米；缩放约0.01仅作草案；原尺寸约2000单位；分离源地面、检查门高，改变通用西式细节。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S10-large-building-integration.md](../../docs/S10-large-building-integration.md)；[docs/level/S10/build_manifest.json](../../docs/level/S10/build_manifest.json)

## village_market · 成组村镇集市

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S11已接入：D06 生活摊棚；未新增独立道具碰撞**。
- 来源：[Quaternius](https://poly.pizza/m/0TsHLxX6CB)；条件：CC0-1.0。
- 原始说明：多个布篷摊位组成的整组模型，能快速填充空地；需调整鲜艳篷布与装饰，并校正偏小的原始尺度。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/village_market/village_market.glb](../../AssetLibrary/environment/china_northeast_20261013/models/village_market/village_market.glb)
- 计划去向：改造；区域：检查口外侧生活区；历史序章A2；用途：多摊位成组布景。
- 尺度／适配：摊棚最高约2.5米；整组约9×10米；原组过小；篷布改旧布色，移除不符东北物产与年代装饰。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[docs/level/S11/runtime.json](../../docs/level/S11/runtime.json)

## market_stalls · 成组果蔬摊棚

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S11已接入：D07/D05 生产摊台；未新增独立道具碰撞**。
- 来源：[Quaternius](https://poly.pizza/m/fmHUuX9AS3)；条件：CC0-1.0。
- 原始说明：成组果蔬货架与木制摊棚，适合市场或集散区布景；原始尺度偏小，需按人物高度放大。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/market_stalls/market_stalls.glb](../../AssetLibrary/environment/china_northeast_20261013/models/market_stalls/market_stalls.glb)
- 计划去向：改造；区域：木料巷边集散区；历史序章A2；用途：物资集散与货架。
- 尺度／适配：最高约2.5米；整组约7.4×7.6米；按成人门高放大，替换鲜艳现代货物；预留主通路。
- 后续关联：S11、S13（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[docs/level/S11/runtime.json](../../docs/level/S11/runtime.json)

## modular_factory_facade · 砖砌厂房立面模块套件

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S10已适配并接入D04；原包其他部件不视为全部使用**。
- 来源：[James Ray Cock](https://polyhaven.com/a/modular_factory_facade)；条件：CC0-1.0。
- 原始说明：192 个网格构成的砖墙、门窗与细部模块，可拼大型厂房或仓库。当前是零件展列，需自行组装建筑。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/modular_factory_facade/modular_factory_facade_2k.gltf](../../AssetLibrary/environment/china_northeast_20261013/models/modular_factory_facade/modular_factory_facade_2k.gltf)
- 计划去向：改造；区域：电报房外侧；仓库背景；用途：砖砌厂房与墙体层次。
- 尺度／适配：按层高3–3.5米组装；目标占地约12×24米；源为192网格展列而非成楼；挑选时期合适门窗，补屋顶背面与碰撞。
- 后续关联：S10、S13、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S10-large-building-integration.md](../../docs/S10-large-building-integration.md)；[docs/level/S10/build_manifest.json](../../docs/level/S10/build_manifest.json)

## chinese_screen_panels · 中式屏风整套

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S11已接入：D08/D09 屏风；未新增独立道具碰撞**。
- 来源：[Kirill Sannikov](https://polyhaven.com/a/chinese_screen_panels)；条件：CC0-1.0。
- 原始说明：带传统纹样的屏风，可填充院内或室内陈设。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/chinese_screen_panels/chinese_screen_panels_2k.gltf](../../AssetLibrary/environment/china_northeast_20261013/models/chinese_screen_panels/chinese_screen_panels_2k.gltf)
- 计划去向：正式使用；区域：电报房生活角；历史序章A2室内；用途：中式室内辨识细节。
- 尺度／适配：高约1.6米；民居陈设参考；不设在普通战斗通道正中，先统一旧化。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[docs/level/S11/runtime.json](../../docs/level/S11/runtime.json)

## chinese_tea_table · 中式茶桌

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S11已接入：D09 谈话低桌；未新增独立道具碰撞**。
- 来源：[Kirill Sannikov](https://polyhaven.com/a/chinese_tea_table)；条件：CC0-1.0。
- 原始说明：适合茶室、民居、院落陈设；小道具，需搭配大型建筑使用。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/chinese_tea_table/chinese_tea_table_2k.gltf](../../AssetLibrary/environment/china_northeast_20261013/models/chinese_tea_table/chinese_tea_table_2k.gltf)
- 计划去向：正式使用；区域：林场生活区；历史序章A2；用途：生活陈设。
- 尺度／适配：高约0.5米、宽约0.84米；低桌需匹配坐姿与环境，不将现代茶室布局整套搬入战地。
- 后续关联：S11、S24（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[docs/level/S11/runtime.json](../../docs/level/S11/runtime.json)

## wicker_basket_01 · 编织方筐

- 分类／库存性质：architecture / downloaded_source_group；原记录状态：downloaded_blender_and_godot_import_verified。
- 当前接入：**S11已接入：D06/D08/D09 六个生活/传递/补给筐；未新增独立道具碰撞**。
- 来源：[Kuutti Siitonen](https://polyhaven.com/a/wicker_basket_01)；条件：CC0-1.0。
- 原始说明：约 38 厘米宽的小筐，适合市场、仓储和生活区的近景点缀。
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/models/wicker_basket_01/wicker_basket_01_2k.gltf](../../AssetLibrary/environment/china_northeast_20261013/models/wicker_basket_01/wicker_basket_01_2k.gltf)
- 计划去向：正式使用；区域：集市；仓储；电报房；用途：物资与生活小道具。
- 尺度／适配：宽约0.38米、高约0.12米；编织细节可用；仅近景点缀，重复放置使用简化版本。
- 后续关联：S11、S35（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[docs/level/S11/runtime.json](../../docs/level/S11/runtime.json)

## derived_field_character · 四类 NPC 可编辑人物与游戏输出

- 分类／库存性质：derived / local_derived_group；原记录状态：本地派生，见来源说明。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[本项目制作；上游作者见来源组]()；条件：派生遵循上游来源条件；原创建模部分见项目来源记录。
- 原始说明：
- 本地入口：[AssetLibrary/characters/field_character/field_character.blend](../../AssetLibrary/characters/field_character/field_character.blend)；[GodotProject/assets/characters/field_character.glb](../../GodotProject/assets/characters/field_character.glb)
- 计划去向：正式使用；区域：侦察员；伐木工；陆山；守卫；用途：当前四类NPC工作源。
- 尺度／适配：13骨；按实测静止尺寸校准；已有连续蒙皮；脸型差异、服装细节、走跑倒地谈话按后续步骤完善。
- 后续关联：S14、S15、S16、S17、S18、S19、S24（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/assets/characters/provenance.json](../../GodotProject/assets/characters/provenance.json)；[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)

## derived_field_hands · 0.6.1 细分双手与可编辑源

- 分类／库存性质：derived / local_derived_group；原记录状态：本地派生，见来源说明。
- 当前接入：**S02记录已选用部分或派生接入；本轮只核对文件，不重做运行验收**。
- 来源：[本项目制作；上游作者见来源组]()；条件：派生遵循上游来源条件；原创建模部分见项目来源记录。
- 原始说明：
- 本地入口：[AssetLibrary/first_person/field_hands/field_hands.blend](../../AssetLibrary/first_person/field_hands/field_hands.blend)；[GodotProject/assets/first_person/hand_left.glb](../../GodotProject/assets/first_person/hand_left.glb)；[GodotProject/assets/first_person/hand_right.glb](../../GodotProject/assets/first_person/hand_right.glb)
- 计划去向：正式使用；区域：第一人称；用途：0.6.1细分双手与袖口工作源。
- 尺度／适配：左右手各24骨；每手20136三角；保持当前握点；关节代理通过不代表全部表面接触验收。
- 后续关联：S17（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[GodotProject/assets/first_person/provenance.json](../../GodotProject/assets/first_person/provenance.json)；[GodotProject/scripts/fp_hands.gd](../../GodotProject/scripts/fp_hands.gd)

## derived_tianchi_dem · 长白山天池公开高程参考样板

- 分类／库存性质：derived / local_derived_group；原记录状态：本地派生，见来源说明。
- 当前接入：**S07开场已使用DEM参考远景；艺术化天池及正式谈话场景未完成**。
- 来源：[本项目制作；上游作者见来源组](https://www.openstreetmap.org/relation/11650508)；条件：派生遵循上游来源条件；原创建模部分见项目来源记录。
- 原始说明：
- 本地入口：[AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.blend](../../AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.blend)；[AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.glb](../../AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.glb)；[AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display_lod.glb](../../AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display_lod.glb)
- 计划去向：备用；区域：天池构图参考；文旅地形概览；用途：公开高程样板。
- 尺度／适配：约14.54×14.54公里；非新场景最终尺度；两档GLB计为同一派生套件；缺岩台路径碰撞，S20–S23另做艺术化火山口湖。
- 后续关联：S20、S21、S22、S23（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：[docs/S07-opening-rough-cut.md](../../docs/S07-opening-rough-cut.md)

## candidate_f8429f52abb14798a5b180541797160b · 天池火山口地形

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[riyabidaye](https://sketchfab.com/3d-models/heaven-lake-china-north-korea-f8429f52abb14798a5b180541797160b)；条件：CC Attribution-NonCommercial-ShareAlike。
- 原始说明：作者说明采用 ASTER 高程和 Esri 影像，约 51 万三角面，最贴近天池文旅展示方向。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：天池构图参考；用途：获取后评估火山口整体展示。
- 尺度／适配：未下载，实际尺寸未知；网页称ASTER高程/Esri影像；约51万三角是页面值，不代替本地样板与自制场景。
- 后续关联：S20（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_20985473ab8743f784c05cd01716fff3 · 长白山大型地形

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[李延权](https://sketchfab.com/3d-models/changbai-mountain-20985473ab8743f784c05cd01716fff3)；条件：CC Attribution。
- 原始说明：长白山整体山体，约 52 万三角面，可作为另一个大范围地形候选。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：长白山远景参考；用途：获取后评估山体范围。
- 尺度／适配：未下载，实际尺寸未知；约52万三角为页面值；需核对纹理、坐标与轮廓。
- 后续关联：S20（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_24e2a51cb75d4e23b11939f55bdfec7c · 吉林长白山白云峰

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[tangbinbin](https://sketchfab.com/3d-models/none-24e2a51cb75d4e23b11939f55bdfec7c)；条件：CC Attribution-NonCommercial-ShareAlike。
- 原始说明：约 6.9 万三角面，适合长白山山峰展示候选；覆盖范围以作者页面为准。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：历史序章远山；用途：白云峰山峰候选。
- 尺度／适配：未下载，实际尺寸未知；作者标吉林长白山；覆盖范围和贴图真实性需取得后核实。
- 后续关联：S12、S20（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_eb129dba5f594b059dfa1444e13f65b1 · 长白山鹿鸣河地形

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[tangbinbin](https://sketchfab.com/3d-models/none-eb129dba5f594b059dfa1444e13f65b1)；条件：CC Attribution-NonCommercial-ShareAlike。
- 原始说明：约 6.7 万三角面，可补充山地、河谷展示内容。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：山路过渡远景；用途：鹿鸣河河谷候选。
- 尺度／适配：未下载，实际尺寸未知；仅可作为地域参考；不能把网页预览当可用关卡地形。
- 后续关联：S12、S20（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_a18881525cfd4fe882e739c9c7cee752 · 传统四合院完整院落

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[andertan](https://sketchfab.com/3d-models/traditional-chinese-siheyuan-courtyard-a18881525cfd4fe882e739c9c7cee752)；条件：CC Attribution。
- 原始说明：作者说明为北京四合院，含植被和院落；约 59.7 万三角面，适合整体展示。属于北京建筑，不能当作东北实景。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：历史序章家园；独立建筑展示；用途：完整院落优先候选。
- 尺度／适配：未下载；目标门高约2米，入手后核对；北京四合院不等于东北民居；高面数需分块和简化。
- 后续关联：S10、S32（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_ed4ea9eb5f024d989eec182d48fa72d8 · 中式八角楼（低面）

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[BlackBirb](https://sketchfab.com/3d-models/ancient-chinese-courtyard-house-ed4ea9eb5f024d989eec182d48fa72d8)；条件：CC Attribution。
- 原始说明：仅 7,672 三角面。作者标题包含 Courtyard，但预览是单栋八角楼，不能计作完整四合院。可作街区地标。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：序章外围地标；用途：低面八角楼候选。
- 尺度／适配：未下载，实际尺寸未知；预览为单楼非完整四合院；地域形制需核对。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_571eb702c8ba413a9a83843fa5428c4a · 街景建筑与道具套件

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[xzal139](https://sketchfab.com/3d-models/none-571eb702c8ba413a9a83843fa5428c4a)；条件：CC Attribution。
- 原始说明：约 1.5 万三角面。预览为建筑及道具散件展列，需要组合成街区；造型混合东亚元素，需筛选。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：序章街区；用途：街景散件候选。
- 尺度／适配：未下载，按模块校准；混合东亚风格；取得后只选时期和地域合适部分。
- 后续关联：S10、S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_d5e673e13b774deba137bd2e99af8e65 · 中式街景

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[Pasha](https://sketchfab.com/3d-models/none-d5e673e13b774deba137bd2e99af8e65)；条件：CC Attribution。
- 原始说明：约 1.3 万三角面，作为街景候选，需下载后核实尺度、贴图和通行空间。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：序章村街；关卡外围；用途：中式街景优先候选。
- 尺度／适配：未下载，实际尺寸未知；核对门高、店招和街巷通行；不能把整景预览计作下载。
- 后续关联：S10、S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_1b055a0bbfc14111b5cc62e5644efffa · 四合院

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[jameshong0810](https://sketchfab.com/3d-models/none-1b055a0bbfc14111b5cc62e5644efffa)；条件：CC Attribution。
- 原始说明：约 14.2 万三角面，庭院类备选。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：序章家园；用途：庭院候选。
- 尺度／适配：未下载，实际尺寸未知；院落布局与东北年代关系待核对，主线不等待该下载。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_2998e6b0769d461d8780f16438a1a896 · Siheyuan 四合院

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[Baoyuai02](https://sketchfab.com/3d-models/none-2998e6b0769d461d8780f16438a1a896)；条件：CC Attribution。
- 原始说明：约 1.7 万三角面，较轻的庭院类备选。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：序章家园；用途：轻量院落候选。
- 尺度／适配：未下载，实际尺寸未知；较低面数仅为网页指标，碰撞与贴图未知。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_2f09fe07f72e4f3dbfb0eebabf978788 · 古风亭式构件（高面数）

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[wangjiabing](https://sketchfab.com/3d-models/none-2f09fe07f72e4f3dbfb0eebabf978788)；条件：CC Attribution。
- 原始说明：预览是单个亭式构件，并非整片建筑场景；约 150 万三角面，面数很高，仅列为备用。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：造型参考；用途：亭式构件参考。
- 尺度／适配：未下载；页面约150万三角；单构件面数过高，非大片建筑场景；不作为近期接入前提。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_e96e36a7ba2e47028879ec58e4a06f24 · 哈尔滨大剧院候选

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[Ninh Phạm](https://sketchfab.com/3d-models/none-e96e36a7ba2e47028879ec58e4a06f24)；条件：CC Attribution-NonCommercial-ShareAlike。
- 原始说明：作者描述指向哈尔滨大剧院，但标题写作 Zaha Hadid，与描述中的 MAD／马岩松不一致；下载前需核对外形。现代建筑可用于文旅场景。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：独立现代文旅展示；用途：哈尔滨大剧院候选。
- 尺度／适配：未下载；页面约109万三角；现代建筑不进1938年任务；标题与作者描述冲突，先核对建筑身份。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_075a0a6251bc4c0492337063c053c979 · 东北炕

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：listed_downloadable_login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[高自广](https://sketchfab.com/3d-models/none-075a0a6251bc4c0492337063c053c979)；条件：CC Attribution。
- 原始说明：4,452 三角面，地方特色明确的室内小场景元素，适合民居展陈。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：民居室内；历史序章A2；用途：东北炕优先候选。
- 尺度／适配：未下载；取得后按人体坐卧尺度校准；地域意象明确；核对灶炕连接、材质及年代细节。
- 后续关联：S11（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_blendswap_14878 · 中国宫殿建筑群

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[Mikel007](https://www.blendswap.com/blend/14878)；条件：待来源页核对。
- 原始说明：作者标注 5,147 个对象、835,210 个面，含贴图；适合大场面展示。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：独立建筑展示；序章远景参考；用途：宫殿建筑群候选。
- 尺度／适配：未下载；页面835210面不是三角数；5147对象会增加管理成本；宫殿不生硬置入林场，需地域与叙事理由。
- 后续关联：S10、S32（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_blendswap_24990 · 中国寺庙

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[floppino](https://www.blendswap.com/blend/24990)；条件：待来源页核对。
- 原始说明：完整寺庙方向的 Blender 工程候选。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：建筑形制参考；用途：中国寺庙候选。
- 尺度／适配：未下载，尺寸与复杂度未知；取得后核实完整度、地方风格和年代；不作为主线必须项。
- 后续关联：S10（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_blendswap_25891 · Wutai Pagoda 风格化塔楼

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：login_required_not_downloaded。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[maurishaberle](https://www.blendswap.com/blend/25891)；条件：待来源页核对。
- 原始说明：风格化古塔，可作为地标候选，需核实地域形制。
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：远景地标参考；用途：风格化古塔候选。
- 尺度／适配：未下载，尺寸与复杂度未知；Wutai命名不意味着东北地标，先核对形制。
- 后续关联：S10、S12（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## candidate_mauser_c96 · Mauser C96

- 分类／库存性质：candidate / web_candidate_not_downloaded；原记录状态：not_downloaded_login_required_user_deferred。
- 当前接入：**未下载候选；本地无成品模型，不计库存**。
- 来源：[AizekParker](https://sketchfab.com/3d-models/mauser-c96-99fcb70e141d4387b2e7b92e1b5b6f89)；条件：CC-BY-4.0。
- 原始说明：{'title': 'Mauser C96', 'author': 'AizekParker', 'source_url': 'https://sketchfab.com/3d-models/mauser-c96-99fcb70e141d4387b2e7b92e1b5b6f89', 'license': 'CC-BY-4.0', 'status': 'not_downloaded_login_required_user_deferred', 'page_claims': {'triangles_approx': 10000, 'texture_size': '4K'}}
- 本地入口：无本地模型入口；不把预览页作为模型。
- 计划去向：备用；区域：第一人称武器候选；用途：C96近景枪模候选。
- 尺度／适配：未下载；页面约1万三角/4K；旧武器清单中的另1项候选，非本轮新增下载；骨骼、活动件与动画仍未知。
- 后续关联：S17（原计划归属；S10/S11已完成部分按上述回执识别）。
- 证据：无正式接入证据。

## S10额外派生建筑链

| 槽位 | 原源 | 可编辑源 | 游戏输出 |
|---|---|---|---|
| D01 | [AssetLibrary/environment/china_northeast_20261013/models/log_cabin_scene/log_cabin_scene.glb](../../AssetLibrary/environment/china_northeast_20261013/models/log_cabin_scene/log_cabin_scene.glb) | [AssetLibrary/derived/S10_buildings/D01.blend](../../AssetLibrary/derived/S10_buildings/D01.blend) | [GodotProject/assets/environment/buildings/D01.glb](../../GodotProject/assets/environment/buildings/D01.glb) |
| D02 | [AssetLibrary/environment/supplement/retro-log-cabin/extracted/log_cabin/log_cabin.fbx](../../AssetLibrary/environment/supplement/retro-log-cabin/extracted/log_cabin/log_cabin.fbx) | [AssetLibrary/derived/S10_buildings/D02.blend](../../AssetLibrary/derived/S10_buildings/D02.blend) | [GodotProject/assets/environment/buildings/D02.glb](../../GodotProject/assets/environment/buildings/D02.glb) |
| D03 | [AssetLibrary/environment/china_northeast_20261013/models/warehouse/warehouse.glb](../../AssetLibrary/environment/china_northeast_20261013/models/warehouse/warehouse.glb) | [AssetLibrary/derived/S10_buildings/D03.blend](../../AssetLibrary/derived/S10_buildings/D03.blend) | [GodotProject/assets/environment/buildings/D03.glb](../../GodotProject/assets/environment/buildings/D03.glb) |
| D04 | [AssetLibrary/environment/china_northeast_20261013/models/modular_factory_facade/modular_factory_facade_2k.gltf](../../AssetLibrary/environment/china_northeast_20261013/models/modular_factory_facade/modular_factory_facade_2k.gltf) | [AssetLibrary/derived/S10_buildings/D04.blend](../../AssetLibrary/derived/S10_buildings/D04.blend) | [GodotProject/assets/environment/buildings/D04.glb](../../GodotProject/assets/environment/buildings/D04.glb) |
| D05 | [AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend](../../AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend) | [AssetLibrary/derived/S10_buildings/D05.blend](../../AssetLibrary/derived/S10_buildings/D05.blend) | [GodotProject/assets/environment/buildings/D05.glb](../../GodotProject/assets/environment/buildings/D05.glb) |

资源登记的尺寸、三角面和原音频解码结果是S02当时测量。本轮未重新试听、评估全部年代细节或测各模型性能。完整注册文件列表与游戏映射保存在 resource_status.json，逐文件目录也关联到资源ID。
