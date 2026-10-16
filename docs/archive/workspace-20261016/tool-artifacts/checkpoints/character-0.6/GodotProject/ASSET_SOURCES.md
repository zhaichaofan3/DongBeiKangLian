# 实际资源与依赖登记

更新：2026-10-12，原型版本 0.6。此登记对应工程实际接入的资源；下载库存不等于已经进入游戏的内容。

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

适配：按几何拆分左右手，保留连续手掌/手腕表皮和每只手的24根绑定骨骼；裁去袖口内部的前臂并统一手腕静止坐标，保留 UV、法线、蒙皮权重及原颜色贴图。每只手3356个三角形、1922个顶点。原资源的通用测试动画没有用于游戏；握枪、扣扳机、拉栓和压弹姿态由本项目在运行时驱动。来源、转换说明及两份输出 SHA-256 见 `assets/first_person/provenance.json`。

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
