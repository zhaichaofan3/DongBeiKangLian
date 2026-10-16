# 开发指南

## 环境与首次启动

当前验证组合是Windows、Godot 4.7.2、GL Compatibility与内置Jolt物理。安装Git LFS后克隆，运行 `git lfs pull`。模型若只有几行文本，说明LFS内容尚未下载。

引擎定位顺序：环境变量 `GODOT_EXE`、本地 `tools/Godot-4.7.2/`、PATH、WinGet。`GODOT_EXE`指向官方Windows控制台版；标准版EXE放同目录供构建使用。引擎不入库。模型制作使用Blender 4.5 LTS，可通过 `BLENDER_EXE` 指定路径；工具脚本使用Python 3.11。

根目录执行 `./Start-Game.ps1 -Editor`，或在Godot打开 `GodotProject/project.godot`。首次导入会生成 `.godot/`，需要时间和额外磁盘空间。

## 模块地图

场景主要由脚本构建，`main.tscn`是入口，编辑器中未运行时不会展示完整地图。

| 工作 | 主要入口：GodotProject/scripts/ |
|---|---|
| 场景、实体与任务装配 | `world.gd`、`mission.gd` |
| 首关道路、战斗区与碰撞 | `first_level_layout.gd`、`first_level_world.gd`、`first_level_scenery.gd`、`linear_director.gd` |
| 渡河与密林入村 | `river_journey.gd`、`forest_approach.gd` |
| 村庄窄街、院落与战斗分段 | `village_world.gd`、`village_scenery.gd`、`village_director.gd` |
| 开场、对白与任务剧情 | `opening_director.gd`、`story.gd`、`story_moments.gd` |
| 玩家、武器与第一人称手 | `fps_player.gd`、`weapon_visuals.gd`、`fp_hands.gd` |
| 连续土路与山体避让 | `road_surface.gd`、`forest_approach.gd`、`village_world.gd::HILL_INNER` |
| 人物、敌人与战友 | `human_model.gd`、`field_character_rig.gd`、`guard.gd`、`friendly.gd` |
| 声音、设置与界面 | `audio_mix.gd`、`audio_factory.gd`、`presentation.gd`、`hud.gd` |
| 天池、自然与效果 | `tianchi_landscape.gd`、`landscape.gd`、`muzzle_effect.gd`、`explosion_effect.gd` |
| 树林分块、院落合批与画质 | `vegetation_batch.gd`、`village_world.gd::_batch_courtyards`、`presentation.gd`、`world.gd::apply_quality` |

`GodotProject/assets/`放游戏选用资源，`AssetLibrary/`放可编辑源与原件。导出后更新来源，材质贴图和glTF外部依赖必须一同保留。

## 修改模型

优先编辑 `AssetLibrary/derived/user_expansion_20261015/`现有Blender工程，再导出对应 `GodotProject/assets/user_expansion_20261015/` GLB。人物适配源在 `AssetLibrary/characters/user_models_20261015/adapted/`；玩家手部在 `AssetLibrary/first_person/field_hands/`。初次导入模型输入现位于各素材批次的 `imported/`，不再放docs。

批量生成器可能覆盖后续手工修改，运行前阅读输入输出。初次转换脚本不能一键重建最终美术。MAX转换工具位于 `tools/third_party/max_importer/`，开发依赖不打进游戏。工具分类见 [工具说明](../tools/README.md)。

## 检查和构建

```powershell
./Test-Game.ps1
./Build-Game.ps1
./Test-Game.ps1 -Release
```

完整回归含真实移动、射击、剧情、碰撞、存读档、音频与开场检查，需要数分钟。串行执行以免QA存档互相覆盖。局部检查使用 `GodotProject/tests/`对应测试与 `--qa`。默认新结果在被忽略的 `docs/validation/`，里程碑仅保留最终日志和少量代表截图。

构建先导入，再导出临时PCK，成功后替换正式PCK，同时拷贝官方标准运行时及许可。新包先写`validation_pending`并刷新校验清单，避免沿用旧验收；独立包验证后再运行本批次汇总工具写入最终结果。使用 `--export-pack`，无需另装导出模板。试玩包通过GitHub Releases分发。

首次批处理导入使用 `--headless --import` 并等待引擎自行退出，不要额外叠加 `--quit`。本轮修正了这一导入流程，并从空缓存验证通过。

## 存档与调试

正常存档在 `%APPDATA%/FenghuoEcho/`，设置为 `presentation_v1.cfg`，检查点为 `qinglan_checkpoint_v2.json`。测试用独立QA文件。修改任务、过河或村庄状态后检查旧档兼容。F3显示帧率。

首关地图版本仍为5，村庄独立状态版本为4。旧村庄存档按已清阶段迁移到安全入口，林中存档保留原位置；不要通过提升首关地图版本来迁移村庄，以免首关坐标再次偏移。新操作为C切换蹲、Ctrl按住蹲、Q/E按住探头、F互动、H包扎。`courtyard_controls.gd`检查真实穿院移动、头部碰撞、可见性和迁移；`world_revision.gd`检查电报房、水面、下游航线及特写，`village_presentation.gd`供实际画面检查。

Git忽略缓存、软件安装目录、生成包、私人会话与冷备份；大二进制用LFS。恢复与大小控制见 [WORKFLOW.md](WORKFLOW.md)。

## 性能与画质检查

`render_quality.gd`纳入常规回归；有画面运行还会逐树核对分块包围盒。树林使用64米分块，显式局部包围盒；重复大院按84米纵向段合批，原层级及碰撞继续保留。约500米的建筑裁剪避免另一关的细小模型参与当前镜头；远山保留独立背景。默认8倍各向异性过滤，原生分辨率不因画质档位缩小。

`optimization_views.gd`比较八个固定场景的缓慢转头负担，要求真实渲染窗口、1920×1080、无垂直同步/限帧；每处预热1.5秒、实测5秒，读图在计时外。输出环境变量为`FENGHUO_OPTIMIZATION_OUTPUT`，可用`FENGHUO_OPTIMIZATION_QUALITY=0/1/2`选档。这不是实战测试。`combat_route.gd`配合`FENGHUO_COMBAT_PERFORMANCE_OUTPUT`才测真实移动、敌人AI与双方开火，不得传`--fixed-fps`。串行运行，记录窗口焦点和硬件条件；不能混用无画面/固定模拟速度的帧率。

`navigation_budget.gd`对村庄与上岸点做四邻接可达图指纹，输出为`FENGHUO_NAVIGATION_OUTPUT`，旧版参照为`FENGHUO_NAVIGATION_REFERENCE`。导航准备仍有加载成本，主菜单在首关、室内与村庄导航全部准备完毕后开放开始/读档；不要将加载期停顿隐瞒为已消除。

物理后端使用内置Jolt，保留原地形/建筑碰撞。`arrival_budget.gd`测真实上岸后120帧，保持战友碰撞与AI开启；`surface_loading.gd`检查山岭不穿道路、路面/河岸接缝，以及1/3/5发原模型子弹与拇指接触、压入机匣和空夹退出。第一人称原资产不变，动作脚本允许按需求调整。

0.7.2切换物理后端后，导航边缘21格发生变化，坐标与审计见`optimization_20261016/navigation-delta.json`。包必须与已审计源码指纹完全一致，不能继续沿用旧包指纹。`Test-OptimizationPackage.ps1`与`Test-OptimizationRender.ps1`从工程外串行启动独立PCK并捕获完整退出输出，最后由`Record-OptimizationValidation.ps1`核对证据并写包校验。
