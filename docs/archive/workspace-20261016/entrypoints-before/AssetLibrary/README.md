# 《烽火回声》资源库

**S11完成后的接手补充：** 下文保留各批次采集/S02盘点时的状态。S07已用天池DEM作开场参考，S10已接入D01–D05派生建筑，S11已接入五类生活生产布景。105条原始记录与最新实际去向统一见 [资源交接表](../docs/handover/RESOURCE_STATUS.md)，不要把下文“本批尚未接入”理解为这些后续工作未做。

**全部资源去向（S02）：** [离线可检索目录](../docs/resources/S02/catalog.html) / [逐项去向表](../docs/resources/S02/resource_routes.md) / [安排与核验报告](../docs/S02-resource-plan.md)。共 85 组已下载来源、3 组本地派生、17 项未下载候选，每项标明实际状态和后续区域。下文采集与接入记录保留原日期语境；本轮只完成盘点和规划。

首批采集日期：2026-10-12。按照“先收齐无需登录资源”的选择，首批已取得 **74 组来源资源**，当时库存约 **1.82 GiB**（含原包、解压、证据与派生文件）。这是为东北抗联单关卡筛选的一批资源，不是整个互联网的穷尽目录。每组可能含多个模型、格式或动作，不能把文件数当成独立成品数。

2026-10-13 新增 **11 组建筑与布景模型**，另制作 **1 套长白山天池地形样板**，提供轻量／精细 GLB 和 Blender 工程。入口：[图片资源目录](environment/china_northeast_20261013/index.html) / [3D 浏览器](environment/china_northeast_20261013/Open-3D-Viewer.cmd) / [说明](environment/china_northeast_20261013/README.md)。下载原模型约 76 MiB；另列 16 项需登录的网上候选，未计入下载库存。本批尚未接入正式关卡。

最终视觉与叙事目标见 [《钢铁风暴》参考方向](../docs/bf1_reference_direction.md)。当前版本仍是可玩原型；下载、导入验证、适配和正式接入是不同完成状态。

## 已经拿到什么

| 分类 | 实际成果 | 本地入口 | 当前状态 |
|---|---|---|---|
| 第一人称手 | 1 组：原始连续蒙皮双手，62 骨骼、8,152 三角面、1024 贴图，1 段 2.25 秒测试动作 | [说明](first_person/README.md) / [清单](first_person/manifest.json) | 0.4 已拆为左右各24骨骼的工作 GLB，并接入自制握持/拉栓/装填姿态；原测试动画未采用 |
| 人物与动作 | 4 组：UAL1/2 合计 **84 个非 T 姿态动作名称**，65 关节男女身体；另有官方 TPS 机器人与56段嵌入动作 | [说明](characters/README.md) / [清单](characters/manifest.json) | 24 个 GLB/glTF 文件结构通过；历史服装与动作重定向待制作 |
| 枪械 | 1 组：Lee Enfield、5,424 三角面、2K 颜色/法线/高光贴图，FBX 与 Blender 源 | [说明](weapons/README.md) / [清单](weapons/manifest.json) | 已验证导入；单整体网格，无骨骼/动作/独立枪机，仅作为工艺参考，不能冒充三八式 |
| 环境 | **45 组**：22个 Poly Haven glTF 模型、14套2K PBR、2个HDRI，另7组树木/锯木棚/木屋/建筑模块 | [检索与适配说明](environment/research.md) / [清单](environment/manifest.json) | 0.4 选用21项（12模型、8表面、1HDRI）；森林轮廓、LOD及年代细节仍需加工 |
| 大型建筑与文旅补充 | **11 组下载模型 + 1 套自制天池地形**：仓库、木屋整景、集市、厂房模块、屏风等；天池覆盖约14.54×14.54公里 | [图片目录](environment/china_northeast_20261013/index.html) / [清单](environment/china_northeast_20261013/manifest.json) | 13个模型入口导入检查通过；地域、年代与尺度适配待接入时完成；偏日式塔楼列为备用 |
| 音频 | **23 组，510 个原音频**，另52个48kHz派生文件：枪声、拉栓、脚步、林风、水声、电台、门与撞击等 | [说明](audio/README.md) / [即用版本](audio/ready_to_import.json) | 所有音频完整解码通过；6项进入0.4，其余待选用与混音 |

动作计数排除了 UAL 的 T 姿态和原地/根运动格式重复。TPS 机器人 56 段中有 27 段带作者 `-noexp` 工作标记，29 段不带该标记；它们不等于56个可直接用于抗联人物的完成动作。下载包不含付费 PRO/Source 内容。

## 已实际接入 0.4

- 左右连续蒙皮手及定制指骨姿态，来源和修改见 `GodotProject/assets/first_person/provenance.json`。
- 21项环境模型、表面与天光资源，完整映射见 `GodotProject/assets/environment/sources.json`。
- 栓动步枪单发、草土脚步、森林风循环，及新增河水循环、电台底噪和断电开关声，共6项外部音频。

音频在 `GodotProject/assets/audio/`；原三项加工见 [接入映射](audio/game_integration.json)，新增三项见 [0.4 音频记录](../docs/v04_audio_sources.json)，完整署名见 [游戏素材来源](../GodotProject/ASSET_SOURCES.md)。有坂源录音元数据标注 `.30-06`，仅作音色参考，不称为已考证的原装三八式弹药录音。

本轮交付结果见 [当前验证](../GodotProject/VERIFICATION.md) 和 [发布摘要](../Release/release_validation.json)。人物通用动作和 Lee Enfield 未接入。未做全库逐条主观试听；自动解码和采样连续性不能代替最终听感。

## 可编辑源与验证工程

- [AssetReview](../AssetReview/README.md)：隔离的 Godot 导入和渲染工程，包含修复贴图/尺度后的工作副本与预览。已导出3个带内嵌贴图的GLB到 `AssetReview/ready/` 并重新导入验证；它不是新的正式关卡。
- [角色骨骼与动作实际名称](characters/gltf_inspection.json)：选择和重定向动作时使用。
- [环境下载验证](environment/verification.json)：202个下载文件，0错误；[补充资源验证](environment/supplement_verification.json) 记录105个模型/图像检查。
- [音频检索](audio/audio_index.csv)、[枪声索引](audio/firearm_catalog.csv)：避免反复翻压缩包。
- [总索引](manifest.json)：汇总各分类清单和状态；[文件复核](verification.json)：复查登记文件是否存在及哈希匹配。

`original/`、`originals/`、原 ZIP/7Z 保留原样；可用副本和修复记录单独存放。不同 FBX/GLB/Blend 格式不重复计为不同模型。不要把整个库复制进 `GodotProject`，仅把选用并适配完成的资源纳入发布。

## 明确还缺什么

1. **目标型号的近景枪模与成套第一人称动作。** C96候选有10k三角/4K PBR，但Sketchfab要求登录，依用户选择暂缓；[候选页](https://sketchfab.com/3d-models/mauser-c96-99fcb70e141d4387b2e7b92e1b5b6f89)。当前已取得的手与栓动枪不共享一套成品装填动作，需要分离枪机、建接触点并制作动作。
2. **抗联与敌军的年代服装、伤员互动与面部表演。** 通用基础人体和通用动作只能解决一部分制作工作。
3. **近景成熟树林和统一场景。** 新收的低面树可用于远景；扫描树根/倒木适合近处局部，整片树林仍需统一树冠、风摆、LOD和地面层次。
4. **最终中文对白、音乐、空间混音及战斗粒子调校。** 不能把无关素材全部堆入正式游戏。

参考方案仍以 **60–90 秒、约20×30米的“林道—木棚—扶伤员”质量样板** 作为后续动作与场景验收单位。本轮先把已适配资源和敌人扩充接入现有关卡；成对救援与分视角演出尚未完成，见 [0.4 制作记录](../docs/v04_production.md)。
