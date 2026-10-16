# 实际资源与依赖登记

更新：2026-10-15，候选版本 0.7.0-rc1。此登记对应工程实际接入的资源；下载库存不等于已经进入游戏的内容。

## 本项目制作的内容

| 内容 | 实现与用途 |
|---|---|
| 原创剧情、人物、任务、对白与关卡布局 | 东北抗联题材的原型任务；未复制现成作品的对白或关卡。 |
| 世界基础几何、建筑结构、导航与碰撞 | `scripts/world.gd` 等；与下列外部环境模型、PBR 纹理及 HDRI 组合使用。 |
| NPC 人体与动作 | `scripts/human_model.gd`、`scripts/friendly.gd`、`scripts/guard.gd`；使用本轮 Blender 制作的连续蒙皮人物与既有游戏动作驱动，头脸和手部基础来自下方 CC0 资源；未复用外部人物骨骼动作。 |
| 武器几何、衣袖及运行时持枪动作 | `scripts/weapon_visuals.gd`、`scripts/fp_hands.gd`、`scripts/fps_player.gd`；枪机、弹夹、双手位移与手指姿态、射击、装填、瞄准和晃动由本项目制作，配合下列骨骼手部模型。 |
| 其余程序纹理、草木摆动、水面、飘叶与烟雾 | `scripts/world.gd`、`scripts/weapon_visuals.gd` 及着色器；与外部 PBR 材质并存。 |
| 手枪、装填及受击合成音效 | `scripts/audio_factory.gd`；与下列6项外部录音组合使用。 |
| 中文字体调用 | 通过 `SystemFont` 使用运行电脑的 Microsoft YaHei，Noto Sans CJK SC 为可用时的回退；不打包或转发系统字体文件。 |

## 第三人称人物重建

基础头部、眉眼、双手来自 **Quaternius Universal Base Characters Standard**，许可 **CC0 1.0**；[作者页面](https://quaternius.itch.io/universal-base-characters)。使用已下载的 Superhero_Male_FullBody.gltf 与配套皮肤、眼睛、眉毛贴图。重塑脸型并裁接连续头颈，制作普通手和守卫握持手；新制棉衣、绑腿、靴子、帽子/钢盔、背包、腰带和口袋，并绑定13骨游戏骨架。材质按角色区分，原有游戏动作驱动蒙皮，守卫双臂对齐步枪握点。

输出 `assets/characters/field_character.glb`；随模型保存 `CREDITS.md` 和 `provenance.json`。可编辑 `.blend` 与基础资源许可位于工程外 `AssetLibrary/characters/field_character/`。通用基础脸仍偏风格化，角色服装属于本项目题材化设计，未声称已完成全部历史外观考据。

## 第一人称骨骼手部

作者 **para**；来源：[FPS Arms (rigged only)](https://opengameart.org/content/fps-arms-rigged-only)；许可：[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)。实际文件为 `assets/first_person/hand_left.glb` 与 `assets/first_person/hand_right.glb`。

适配：按几何拆分左右手，保留连续手掌/手腕表皮和每只手的24根绑定骨骼；裁去袖口内部的前臂并统一手腕静止坐标。0.6.1 在 Blender 中焊接 UV 接缝处的重复顶点、做一级曲面细分和平滑法线，插值 UV 与蒙皮权重，每顶点保留并归一化最强的4个影响；原颜色贴图、骨骼静止变换和逆绑定矩阵保持原值。每只手20,136个三角形，左手12,389个导出顶点、右手14,134个导出顶点（含 UV 拆分）。

原资源的通用测试动画没有用于游戏；握枪、扣扳机、拉栓和压弹姿态由本项目在运行时驱动。椭圆袖口、翻边、缝线、布扣和曲线衣袖为本项目制作。可编辑工程位于 `AssetLibrary/first_person/field_hands/field_hands.blend`；生成入口为 `tools/refine_fp_hands.py`；来源、转换说明及两份输出 SHA-256 见 `assets/first_person/provenance.json`。细分改善轮廓，不等同于新增写实皮肤雕刻或扫描细节。

## 环境模型、表面与天空

以下21项来自 Poly Haven：12项模型、8项表面纹理组、1项 HDRI，全部为 [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)，平台许可说明见 [Poly Haven License](https://polyhaven.com/license)。模型使用2K贴图及运行时缩放、朝向/落地校正、实例摆放和可见距离配置；部分集合模型选择其中子网格。纹理用于场景材质，HDRI 用于阴天天空与环境反射。它们提供视觉参考与场景表现，不表示每件现代扫描道具都已完成年代考据。

| 资源与原始页面 | 作者 | 实际文件/目录 | 许可说明 |
|---|---|---|---|
| [Dead Tree Trunk](https://polyhaven.com/a/dead_tree_trunk) | Rob Tuytel | 模型：`assets/environment/models/dead_tree_trunk/dead_tree_trunk_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Tree Stump 01](https://polyhaven.com/a/tree_stump_01) | Rob Tuytel | 模型：`assets/environment/models/tree_stump_01/tree_stump_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Fern 02](https://polyhaven.com/a/fern_02) | Rob Tuytel, Rico Cilliers | 模型：`assets/environment/models/fern_02/fern_02_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Rock Moss Set 01](https://polyhaven.com/a/rock_moss_set_01) | Kless Gyzen | 模型：`assets/environment/models/rock_moss_set_01/rock_moss_set_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Wooden Crate 01](https://polyhaven.com/a/wooden_crate_01) | James Ray Cock | 模型：`assets/environment/models/wooden_crate_01/wooden_crate_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Wine Barrel 01](https://polyhaven.com/a/wine_barrel_01) | James Ray Cock | 模型：`assets/environment/models/wine_barrel_01/wine_barrel_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Wooden Bucket 01](https://polyhaven.com/a/wooden_bucket_01) | James Ray Cock | 模型：`assets/environment/models/wooden_bucket_01/wooden_bucket_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Wooden Axe 02](https://polyhaven.com/a/wooden_axe_02) | Ulan Cabanilla | 模型：`assets/environment/models/wooden_axe_02/wooden_axe_02_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Lantern 01](https://polyhaven.com/a/Lantern_01) | Rajil Jose Macatangay | 模型：`assets/environment/models/Lantern_01/Lantern_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Wooden Table 01](https://polyhaven.com/a/WoodenTable_01) | Ethan Place | 模型：`assets/environment/models/WoodenTable_01/WoodenTable_01_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Pine Sapling Small](https://polyhaven.com/a/pine_sapling_small) | Rob Tuytel, Rico Cilliers | 模型：`assets/environment/models/pine_sapling_small/pine_sapling_small_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Vintage Radio Transceiver](https://polyhaven.com/a/vintage_radio_transceiver) | Mateusz Sadek | 模型：`assets/environment/models/vintage_radio_transceiver/vintage_radio_transceiver_2k.gltf` | [CC0-1.0](https://polyhaven.com/license) |
| [Brown Mud Leaves 01](https://polyhaven.com/a/brown_mud_leaves_01) | Rob Tuytel | PBR 纹理组：`assets/environment/textures/brown_mud_leaves_01/` | [CC0-1.0](https://polyhaven.com/license) |
| [Forest Ground 04](https://polyhaven.com/a/forest_ground_04) | Rob Tuytel, Rico Cilliers | PBR 纹理组：`assets/environment/textures/forest_ground_04/` | [CC0-1.0](https://polyhaven.com/license) |
| [Muddy Tracks](https://polyhaven.com/a/muddy_tracks) | Amal Kumar | PBR 纹理组：`assets/environment/textures/muddy_tracks/` | [CC0-1.0](https://polyhaven.com/license) |
| [Pine Bark](https://polyhaven.com/a/pine_bark) | Dimitrios Savva | PBR 纹理组：`assets/environment/textures/pine_bark/` | [CC0-1.0](https://polyhaven.com/license) |
| [Weathered Brown Planks](https://polyhaven.com/a/weathered_brown_planks) | Dimitrios Savva, Rico Cilliers | PBR 纹理组：`assets/environment/textures/weathered_brown_planks/` | [CC0-1.0](https://polyhaven.com/license) |
| [Grey Roof Tiles](https://polyhaven.com/a/grey_roof_tiles) | Rob Tuytel | PBR 纹理组：`assets/environment/textures/grey_roof_tiles/` | [CC0-1.0](https://polyhaven.com/license) |
| [Brick Wall 001](https://polyhaven.com/a/brick_wall_001) | Rob Tuytel, Dimitrios Savva | PBR 纹理组：`assets/environment/textures/brick_wall_001/` | [CC0-1.0](https://polyhaven.com/license) |
| [Rusty Metal 04](https://polyhaven.com/a/rusty_metal_04) | Amal Kumar | PBR 纹理组：`assets/environment/textures/rusty_metal_04/` | [CC0-1.0](https://polyhaven.com/license) |
| [Kloofendal Overcast (Pure Sky)](https://polyhaven.com/a/kloofendal_overcast_puresky) | Greg Zaal | HDRI：`assets/environment/hdris/kloofendal_overcast_puresky/kloofendal_overcast_puresky_2k.hdr` | [CC0-1.0](https://polyhaven.com/license) |

所有组成文件、下载来源和 SHA-256 见 `assets/environment/sources.json`。场景接入见 `scripts/asset_dressing.gd`、`scripts/world.gd`；模型、PBR 表面及 HDRI 的组合与摆放由本项目完成。

## S07 天池远景参考

`assets/opening/tianchi_reference.glb` 从本地库存 `AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display_lod.glb` 原样复制，SHA-256 为 `6cb48b44e743abf97744865079ea7032aadf4a3d70c41c87b621a5ceec8741c7`。由本项目根据公开高程与湖岸轮廓生成，地形 131,072 三角形、湖面 2,030 三角形；S07 在运行时以 0.04 倍缩放供远景和临时站位排演。它不是新制的艺术化天池成品，也未作为可游览地形接入正式任务路线。

- 高程：Mapzen/Terrarium，经 Tilezen/Joerd 分发；[数据署名说明](https://github.com/tilezen/joerd/blob/master/docs/attribution.md)。原始瓦片地址与哈希保存在 [高程来源清单](../AssetLibrary/environment/china_northeast_20261013/terrain/source.json)，按原数据来源保留署名，不统一误标为 CC0。
- 湖岸：© OpenStreetMap contributors；[原湖岸关系](https://www.openstreetmap.org/relation/11650508)，[ODbL 1.0 与署名说明](https://www.openstreetmap.org/copyright)。用于湖面轮廓参考。
- 网格生成、示意配色、缩放和临时岩台为本项目处理。派生文件登记见 [reference_source.json](assets/opening/reference_source.json)。原始来源包未覆盖。当前演出使用另建的艺术化天池；此参考DEM仍随候选包保留但未被镜头使用，来源快照在 `AssetNotices/TerrainReference/`。

## 实际接入音频

以下6个文件位于 `assets/audio/`。采样率及 PCM 格式指派生 WAV 文件；引擎的内部导入格式可不同。

| 文件 | 作者与来源 | 许可 | 修改与用途 |
|---|---|---|---|
| `rifle_arisaka_01.wav` | Ben Jaszczak、Brian Nelson、Kevin Heras、Matthew Nanney；[The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `E_25P.wav` 的 0.513917–3.063917 秒切片；48kHz、单声道、PCM16，尾部淡出，峰值 -6dBFS。源作者标为 Arisaka / .30-06，仅作音色参考，非已考证的原装三八式弹药录音。 |
| `step_grass_01.wav` | [swuing，footstep-grass.wav](https://freesound.org/people/swuing/sounds/38874/)；congusbongus 整理于 [Footsteps on different surfaces](https://opengameart.org/content/footsteps-on-different-surfaces) | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | 包内 `footsteps/grass/0.ogg`；48kHz、单声道、PCM16，峰值 -14dBFS，5ms 首尾淡化，0.243375 秒。当前脚步统一使用这一音色。 |
| `forest_wind_loop.wav` | Blender Foundation / Yo Frankie!；[森林、河流与风环境包](https://opengameart.org/content/ambient-mountain-river-wind-and-forest-and-waterfall) | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `amb_forest.flac` 与 `amb_wind_1.flac` 转48kHz 单声道 PCM16，按 RMS 平衡后72:28混合，400/600ms 交叉淡化、2ms 接缝淡化；循环8.584958秒，RMS约 -28dBFS。 |
| `river_bank_loop.wav` | Blender Foundation / Yo Frankie!；[森林、河流与风环境包](https://opengameart.org/content/ambient-mountain-river-wind-and-forest-and-waterfall) | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `amb_river.flac` 经准备版 `amb_river.ogg` 取前14秒；24kHz、单声道、PCM16，500ms 环接交叉淡化、2ms 端点淡化，目标 RMS -25dBFS；循环13.5秒，河岸区域空间衰减。 |
| `radio_room_loop.wav` | Kresiek The Furry；[Radio Noise](https://opengameart.org/content/radio-noise-1) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `radio_noise_loop.wav` 经准备版 `radio_static.ogg` 取前9秒；24kHz、单声道、PCM16，500ms 环接交叉淡化、2ms 端点淡化，目标 RMS -25dBFS；循环8.5秒，电报房区域空间衰减，断电后停止。 |
| `power_switch_off.wav` | Cleyton Kauffman；[SFX Circuit Breaker](https://opengameart.org/content/sfx-circuit-breaker) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | 原包 `Circuit Breaker/switch off.wav`，使用已转换的48kHz 单声道 PCM16准备版，直接复制；0.923104秒，断电时播放。 |

音频署名另随资源保存在 `assets/audio/CREDITS.md`。原包、页面、许可文件、下载 URL 与原文件 SHA-256 见开发目录 `../AssetLibrary/audio/manifest.json`；52项准备版本映射见 `../AssetLibrary/audio/ready_to_import.json`。原三项游戏文件的精确处理记录见 `../AssetLibrary/audio/game_integration.json`，0.4新增三项见 `../docs/v04_audio_sources.json`。这些清单中未接入的录音不计入本表，尚未添加外部配音或音乐。

## 引擎与第三方依赖

Godot 4.7.2 标准引擎由 **Godot contributors** 提供，采用 MIT 许可；[官方发布](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)。运行包保留 `GODOT_LICENSE.txt` 与引擎内第三方库的完整通知 `GODOT_COPYRIGHT.txt`。

官方标准版下载：[Godot 4.7.2 Windows x64](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip)。

已核对 ZIP SHA-256：
`731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953`

引擎许可原文：

- [LICENSE.txt](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt)
- [COPYRIGHT.txt](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt)

历史参考、资源库存与实际接入分别记录。项目自制部分的许可由项目所有者决定，外部资源继续遵循各自原许可。


## S10–S12实际新增资产（候选包已包含）

D01–D05依次使用木屋场景、Retro Log Cabin、Warehouse、Modular Factory Facade、水力锯木棚。按现有场地缩放、旋转、裁取部件、补屋顶和粗碰撞；D02派生资产继续按CC BY-SA 4.0提供，修改不改变原作者署名。S11摊棚／屏风／茶桌／筐按生活与生产用途摆放。JKM松树重绑叶片与树干材质并缩放，按48米分块共享实例，原许可全文和可编辑派生源随包放在 `AssetNotices/JKM/`。

| 资源 | 作者 | 许可 | 来源 |
|---|---|---|---|
| log_cabin_scene | Poly by Google | [CC-BY-3.0](https://creativecommons.org/licenses/by/3.0/) | https://poly.pizza/m/2gQe0wyzkhb |
| oga_retro-log-cabin | Elegant Crow | [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/) | https://opengameart.org/content/retro-log-cabin |
| warehouse | Lavender Harmony | [CC-BY-3.0](https://creativecommons.org/licenses/by/3.0/) | https://poly.pizza/m/fsxbktzB1zo |
| modular_factory_facade | James Ray Cock | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://polyhaven.com/a/modular_factory_facade |
| oga_medieval-waterpowered-sawmill | Daniel Andersson; submitted by hreikin | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://opengameart.org/content/medieval-waterpowered-sawmill |
| village_market | Quaternius | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://poly.pizza/m/0TsHLxX6CB |
| market_stalls | Quaternius | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://poly.pizza/m/fmHUuX9AS3 |
| chinese_screen_panels | Kirill Sannikov | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://polyhaven.com/a/chinese_screen_panels |
| chinese_tea_table | Kirill Sannikov | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://polyhaven.com/a/chinese_tea_table |
| wicker_basket_01 | Kuutti Siitonen | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | https://polyhaven.com/a/wicker_basket_01 |
| oga_jkms-tree-set | Julius Krischan Makowka (JKM / Julius) | [CC-BY-SA-3.0](https://creativecommons.org/licenses/by-sa/3.0/) | https://opengameart.org/content/jkms-tree-set |

Poly Haven新增纹理 [Wood Chips](https://polyhaven.com/a/wood_chips) 与 [Gravel Road](https://polyhaven.com/a/gravel_road) 沿用CC0，使用2K颜色／法线／粗糙度图；Wood Chips作者eye-candy.xyz，Gravel Road作者Amal Kumar；逐文件来源与哈希见随包 `AssetNotices/extra-ground-textures.json`。

## 艺术化天池与临时合成语音

艺术化天池为本项目另建的程序化火山口、湖面与岩台，非DEM直接派生和1:1复刻。S22/S23补路径、碰撞、湖水、雾和光照。早期29句Windows System.Speech / Microsoft Kangkang临时中文合成声已停用，历史说明保留于 `AssetNotices/Voice/`，源素材留在开发目录。当前历史段使用用户完整录音，B段使用8句用户录音；其余对白保留字幕并静音。没有加入S28/S29未听审候选。

2026-10-15长白山细化：山坡林使用上述JKM松树的现有派生资产 `assets/environment/landscape/far_pine.glb`，按实际山面采样、缩放与分块实例化，保留CC BY-SA 3.0署名和 `AssetNotices/JKM/` 源文件。岩面复用Amal Kumar的CC0 Gravel Road无缝纹理，转为灰色岩屑表现并叠加项目程序化风化与积雪；原图不改写。山体加密、岩台、碎石、低矮植被和岩面着色器为项目生成内容；可编辑山体源仍为 `AssetLibrary/environment/derived/S21/tianchi_artistic.blend`。


## 用户音频 · 2026-10-15

`opening_history_20261015.mp3` 为用户提供的《10月15日.mp3》原样副本，完整用于历史序章，含旁白及配乐。`global_war_music.ogg` 来自用户提供的《战争激昂的背景音乐.aac》，转为 Vorbis 并加首尾淡化，用于菜单、任务序幕及游戏全局，历史段停播。作者和授权名称未随文件提供，不标注为 CC0。原件、加工参数和 SHA-256 保存在 `AssetLibrary/audio/user_20261015/manifest.json`；实际混音听审待完成。
# 第二道门冲锋叫喊（2026-10-15）

用户提供《日军板载冲锋的叫喊音效.mp3》，完整3.448秒，原文件保留，未裁剪或转码。用于木料巷出口守卫转身冲锋，Voice总线播放并避让配乐；来源与SHA-256见`AssetLibrary/audio/bayonet_20261015/manifest.json`，随包副本为`AssetNotices/bayonet-20261015.json`。用户原件未附外部再分发许可声明。刺刀为本项目程序几何，近身步枪复用本项目已有精细步枪，双方角色与双手沿用现有资产及其许可。


## 用户战场音效 · 2026-10-15

用户提供的11个MP3原样接入`assets/audio/user_sfx_20261015/`：拉栓、流水、跑步脚步、单发枪声、三段日军发现敌人语音、爆炸、普通脚步、关门和开门。来源文件与SHA-256逐项保存在`AssetLibrary/audio/field_sfx_20261015/manifest.json`，随包为`AssetNotices/field-sfx-20261015.json`。原件未裁剪或转码，运行时调整总线、音量和触发；流水复制流后循环。作者和许可未随文件提供，不能标为CC0。听感待实际试听。

## 用户人物模型 · 2026-10-15

用户提供《日军模型.rar》《志愿军模型.rar》，内含`3d66.com_22426855.max`、`3d66.com_17309872.max`及各自贴图。作者和再分发许可未随包给出，不标为CC0；文件名保留原始来源线索。原包、MAX和贴图保存在`AssetLibrary/characters/user_models_20261015/`，未改写原件。

经Blender MAX Importer 1.9.2读取几何和UV，重新连接V-Ray贴图、归一化与重新蒙皮，导出`assets/characters/user_soldiers/japanese.glb`和`volunteer.glb`。志愿军包的两个同型人物选取其中一套用于我军，冬装织物转为灰色、添加红星；日军原模型为军帽而非钢盔，红圈与八字胡继续保留。关卡及开场分别按阵营选择人物，林工继续用原模型。NPC接触与握枪手网格沿用前述Quaternius CC0派生成果，玩家第一人称手臂、袖子与武器文件未修改。

转换工具来自https://github.com/nrgsille76/io_scene_max，GPL-2.0-or-later，源码和许可证保存在`tools/third_party/max_importer/`，仅用于开发，不打进游戏。适配Blender源、生成入口和逐模型哈希见`AssetLibrary/characters/user_models_20261015/adapted/`及`assets/characters/user_soldiers/provenance.json`。本轮验收见开发目录`docs/user-models-20261015/`。

后续头手修正：我军手套改为该用户MAX内的原始手部几何与第012号贴图，分别适配放松和握枪姿态；上述保留Quaternius第三人称接触手的描述此后仅适用于日军。陆山取消不兼容的旧额头绷带，保留腿部包扎。玩家第一人称手臂仍未改动；新验收记录位于`docs/user-model-fix-20261015/`。

接续优化保留上述原始手套、贴图与放松姿态；握枪时分别校正左右掌面再弯曲手指，保留厚度与手腕过渡。完整源码、发布及近景接续验收另存于`docs/user-model-fix-final-20261015/`。

本轮对白：用户提供9份MP3，对应姜岚8句，原件、两版木棚台词和SHA-256保存在`AssetLibrary/audio/dialogue_20261015/manifest.json`；8个选用文件原样接入`assets/audio/user_dialogue_20261015/`，未裁剪、变速或合成。旧木棚台词两版均保存作备用，当前选用遵循下述后续替换。随包来源见`AssetNotices/dialogue-20261015.json`；未提供录音的对白暂时静音，旧合成文件不再打包。作者与外部分发许可未随录音提供，不标为CC0。

后续用户指定B5-L06撤离路线和B6-L01木棚台词改用Downloads目录新文件，已覆盖当前选用版本；先前原件继续保留，新增原件与校验位于`AssetLibrary/audio/dialogue_retake_20261015/`。当前选用始终以`assets/audio/user_dialogue_20261015/manifest.json`与随包来源清单为准。

## 用户建筑、98k和水岸 · 2026-10-15

用户提供六份RAR：电报房、伐木场破房子合集、东北农村、98k步枪、渡口和小船、河（可以删掉里面的鱼之类的没用模型）。六包与用户再次提供的Downloads原件逐项SHA-256一致；原件保存在`AssetLibrary/environment/user_expansion_20261015/`，原始MAX、FBX和贴图完整保留。作者及外部分发许可未随包明确提供，不标为CC0。

| 素材 | 实际用途与加工 |
|---|---|
| 电报房 | 双拱顶26×24米建筑，开放西侧入口及两厅通道；任务名册、总闸移入新室内布局 |
| 伐木场破房子合集 | 提取4栋独立建筑，替换林场D01–D05及林工棚的建筑外观；按既有通行范围适配比例，保留粗碰撞 |
| 东北农村 | 使用完整主聚落，保留22组院落、1159个来源对象的原相对位置，合并运行网格；现代配电组、展示地板及聚落外独立样例仍保留在原包 |
| 98k步枪 | 归一化至米制，分别导出枪体、枪栓和弹夹部件；用于玩家、敌军和武装友军，玩家手臂模型保留 |
| 渡口和小船 | 原木栈桥及船桨小船用于林场与村庄两岸，栈桥加入三角碰撞 |
| 河 | 裁取河道、河床、岸石，水面绑定现有动态河流着色器；鱼、独立展示物件及密集植物从游戏派生版排除 |

首批六组素材派生13个游戏GLB在`assets/user_expansion_20261015/`。可编辑Blender源保存在`AssetLibrary/derived/user_expansion_20261015/`，首批生成工具为`tools/build_user_expansion.py`和`build_user_waterfront.py`。本轮另生成`village_complete.glb`替代关卡中的四院拼接，旧派生模型保留；`tools/revise_settlement.py`记录完整村落筛选、树木减面、铁皮屋红字清理和电报房准确门洞裁切。最新来源对象清单在`village-layout.json`，证据在开发目录`docs/settlement_revision_20261015/`。村庄树林复用JKM派生松树，继续保留上述CC BY-SA 3.0来源通知。开场广景结合农村与伐木场，旁白原文、原录音与时长保留。

后续用户提供“栅栏铁丝网.rar”，第七份原包与FBX保存在上述素材库的`fence/`。木桩带刺铁丝网按原型统一比例缩为约2.439米宽、0.8米高、0.744米深的可重复段；林场封闭2处支巷，新完整村落按原建筑表面测量并分段封合无任务支路。原林场实墙与村内院墙遮挡保留，碰撞与低网可见高度一致，原件保留。连同`barbed_wire.glb`和`village_complete.glb`，现保留15个派生GLB入口；铁丝网可编辑源为`barbed_wire.blend`，生成入口为`tools/build_user_fence.py`，尺寸及哈希见`fence-build-manifest.json`。作者和外部分发许可未随包明确提供，不标为CC0。

2026-10-16首关整图重构继续使用这些派生文件：伐木场四栋建筑分布于接头区、检查口、木料场和电报房接近区，村屋派生用于首关到达区外远景；第二关继续使用完整主聚落。土石坡、围墙、车辙、路灯和原木掩体为工程内组合，苔石、蕨类及共享松树沿用已有来源。未重新加工原始RAR、用户音轨或第一人称手部。公开关卡设计参考与实际用途见开发目录docs/first_level_rebuild_20261016/research.md。

同日双人渡河追加：上述木船、栈桥和河道用于登船、顺流漂行和靠岸演出；沈砚、陆山和姜岚使用现有我军人物与程序动作。对岸密林继续复用JKM的far_pine派生松树，以MultiMesh绘制，林地、土路和坡脚石分别沿用forest_ground_04、muddy_tracks和rock_moss_set_01的既有CC0资源与原署名。地形、路径、演出与新字幕为本项目制作；原模型、下载包及用户录音未改写，没有新下载资源。
