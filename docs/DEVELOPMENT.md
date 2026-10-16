# 开发指南

## 环境与首次启动

当前验证组合是Windows、Godot 4.7.2、GL Compatibility。安装Git LFS后克隆，运行 `git lfs pull`。模型若只有几行文本，说明LFS内容尚未下载。

引擎定位顺序：环境变量 `GODOT_EXE`、本地 `tools/Godot-4.7.2/`、PATH、WinGet。`GODOT_EXE`指向官方Windows控制台版；标准版EXE放同目录供构建使用。引擎不入库。模型制作使用Blender 4.5 LTS，可通过 `BLENDER_EXE` 指定路径；工具脚本使用Python 3.11。

根目录执行 `./Start-Game.ps1 -Editor`，或在Godot打开 `GodotProject/project.godot`。首次导入会生成 `.godot/`，需要时间和额外磁盘空间。

## 模块地图

场景主要由脚本构建，`main.tscn`是入口，编辑器中未运行时不会展示完整地图。

| 工作 | 主要入口：GodotProject/scripts/ |
|---|---|
| 场景、实体与任务装配 | `world.gd`、`mission.gd` |
| 首关道路、战斗区与碰撞 | `first_level_layout.gd`、`first_level_world.gd`、`first_level_scenery.gd`、`linear_director.gd` |
| 渡河与密林入村 | `river_journey.gd`、`forest_approach.gd` |
| 村庄建筑与战斗分段 | `village_world.gd`、`village_director.gd` |
| 开场、对白与任务剧情 | `opening_director.gd`、`story.gd`、`story_moments.gd` |
| 玩家、武器与第一人称手 | `fps_player.gd`、`weapon_visuals.gd`、`fp_hands.gd` |
| 人物、敌人与战友 | `human_model.gd`、`field_character_rig.gd`、`guard.gd`、`friendly.gd` |
| 声音、设置与界面 | `audio_mix.gd`、`audio_factory.gd`、`presentation.gd`、`hud.gd` |
| 天池、自然与效果 | `tianchi_landscape.gd`、`landscape.gd`、`muzzle_effect.gd`、`explosion_effect.gd` |

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

构建先导入，再导出临时PCK，成功后替换正式PCK，同时拷贝官方标准运行时及许可。使用 `--export-pack`，无需另装导出模板。试玩包通过GitHub Releases分发。

首次批处理导入使用 `--headless --import` 并等待引擎自行退出，不要额外叠加 `--quit`。本轮修正了这一导入流程，并从空缓存验证通过。

## 存档与调试

正常存档在 `%APPDATA%/FenghuoEcho/`，设置为 `presentation_v1.cfg`，检查点为 `qinglan_checkpoint_v2.json`。测试用独立QA文件。修改任务、过河或村庄状态后检查旧档兼容。F3显示帧率。

Git忽略缓存、软件安装目录、生成包、私人会话与冷备份；大二进制用LFS。恢复与大小控制见 [WORKFLOW.md](WORKFLOW.md)。
