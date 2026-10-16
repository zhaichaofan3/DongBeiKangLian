# 文件、目录和系统说明

路径均相对工程根目录 `C:\GameMake`。本页解释维护关系；每个实际文件的路径、大小与用途见 [逐文件目录](../PROJECT_FILE_CATALOG.md)，含缓存和备份的完整扫描见 [ALL_FILES.jsonl](ALL_FILES.jsonl)。不要按本页简介批量删除任何历史文件。

## 顶层目录

| 目录或文件组 | 内容、地位和接手要求 |
|---|---|
| `GodotProject/` | 当前唯一正式游戏源码、资产、场景、测试和导入设置；编辑此处改变当前源码体验 |
| `AssetLibrary/` | 原始下载包、解压内容、来源清单、候选、加工源与派生；不可用游戏精简文件覆盖原始包 |
| `AssetReview/` | 独立 Godot 素材审查工程，用于查看/渲染模型；不是游戏关卡，不以导入成功证明正式接入 |
| `GameProject/` | 早期 Unity C# 实验骨架；保留历史，不作为当前继续开发入口 |
| `Release/` | 可移动 Windows 0.6.1 发布基线，包括 EXE、PCK、许可、说明、验证与截图；旧包与新源码有差异 |
| `docs/` | 总计划、结构化进度、逐步方案、历史报告、实测证据与本次交接；是接续依据 |
| `tools/` | 项目建模/核验/备份脚本及本地 Blender、Godot、Python 依赖；第三方库不当作游戏代码改写 |
| `WorkBackups/` | 独立检查点；`LATEST.txt` 指向最近完成记录，每份有 `CHECKPOINT.md`、`checkpoint.json`、`files/` |
| `ConversationBackups/` | 完整项目本地对话导出、索引、原始 JSONL、可读 Markdown、引用附件和内容寻址 objects |
| `RestoreChecks/` | S01 等独立恢复核验副本，证明恢复流程；不在这里继续制作或将其冒充主工程 |
| `licenses/` | Godot 引擎许可和版权声明；发布时随包保留 |
| `.auto-resume/` | 暂停开关、claim 回执、锁和事件；临时控制状态，不恢复为启用 |
| `.auto-resume/` | 面板工作进程、故障恢复、停止与中断证据；仅具体证据可显式备份，不恢复开启状态 |
| `.gitignore` | 忽略规则；存在该文件不代表已经有可用 Git 历史，恢复主要依赖检查点 |
| `godot-standard-4.7.2.zip` | 保存的引擎归档；解包前保留原始文件和来源记录 |
| 根目录 `.ps1/.cmd/.vbs` | 启动、构建、验证、自动续步和停止入口，详见操作分册 |

## 正式游戏调用关系

`project.godot` 指向 `main.tscn`，主要世界由 `scripts/world.gd` 装配。场景脚本用 `res://` 访问游戏目录内的资源，不能把仅在 AssetLibrary 中的绝对路径当成可发布游戏依赖。

| 脚本（均在 `GodotProject/scripts/`） | 职责与修改时需要一起核对的文件 |
|---|---|
| `world.gd` | 世界创建、环境、建筑、节点、导航与系统装配；布景变动同时检查 asset_dressing、route_blockout、任务锚点 |
| `asset_dressing.gd` | 既有环境资源与 S11 布景；更新 sources、去向表和碰撞/可达性证据 |
| `route_blockout.gd` | D01–D09 简化体块、碰撞与槽位替换；S11 隐藏外观但保留碰撞的事实在此落实 |
| `linear_director.gd` | 区段、栅门、增援和线性检查点；保持护送回绕通道与旧档迁移 |
| `mission.gd` | 取册、断电、救援、解缆、胜利与游戏存档；改动前列状态矩阵 |
| `story.gd` | 简报、人物对话与故事状态；与 mission 和 opening_director 的接管条件一致 |
| `story_moments.gd` | 行进短对白、补给、包扎、人物小互动；不等同于正式大过场 |
| `opening_director.gd` | S07 两段草案、镜头、字幕、暂停、分段跳过与恢复；接入正式演出时仍保留任务交接契约 |
| `fps_player.gd` | 玩家移动、视角、互动、瞄准、射击和换弹；与手部、武器、音频和 HUD 联动 |
| `fp_hands.gd` | 双手姿态、握持、拉栓和装填；已有细分/袖口成果保留，检查两种武器分别接触 |
| `weapon_visuals.gd` | 武器外观、枪焰、烟气、弹壳等反馈；增强效果留意枪口空间、寿命和回收 |
| `human_model.gd` | 第三人称人物装配与动作驱动，和 field_character_rig 一起阅读 |
| `field_character_rig.gd` | 连续蒙皮人物骨架与程序姿态，当前身体主要 13 骨；不能直接假定适配 65 骨通用动作 |
| `friendly.gd` | 侦察员、林工、陆山交互和跟随/等候；伤情、速度、站位与剧情条件必须一致 |
| `guard.gd` | 敌人巡逻、感知、射击、受击和死亡；建筑、树木与碰撞变化后复查视线和路线 |
| `audio_factory.gd` | 既有录音与合成声音节点；新增音效需补来源、试听、事件同步和混音 |
| `hud.gd` | 中文目标、提示、选择、菜单与暂停显示；字幕不遮重要战斗信息 |
| `presentation.gd` | 画质、帧率、显示、音量、灵敏度等设置；正常设置与 QA 设置隔离 |

## 数据与美术的来源链

| 领域 | 编辑源 → 生成工具 → 游戏使用文件 |
|---|---|
| NPC | `AssetLibrary/characters/field_character/field_character.blend`；`tools/build_field_character.py` → `GodotProject/assets/characters/field_character.glb` 与运行时角色姿态 |
| 双手 | `AssetLibrary/first_person/field_hands/field_hands.blend`；`tools/refine_fp_hands.py` → `GodotProject/assets/first_person/hand_left.glb`、`hand_right.glb`；provenance 保留来源 |
| 建筑 | 原始模型 → `tools/build_s10_buildings.py` → `AssetLibrary/derived/S10_buildings/D01.blend` 至 D05 → `GodotProject/assets/environment/buildings/`；尺寸/碰撞见 S10 build_manifest |
| S11 道具 | 原批次 models → `GodotProject/assets/environment/models/s11/` → asset_dressing 的布景节点；数量与位置见 S11 resource-destinations |
| 天池参考 | 公开高程及 terrain/source.json → terrain 下 Blender 与两档 GLB；只在 S07 作参考，正式艺术化天池另保存目录 |
| 音频 | `AssetLibrary/audio/manifest.json` / 原始文件 → `ready_to_import.json` 与 48kHz 派生 → 游戏 `assets/audio/`；以实际映射确定哪些已用 |
| 开场 | S04/S05 原文与对白 → S06 storyboard → `tools/build_s07_opening_data.py` → 游戏开场数据与 opening_director；生成前检查脚本可能覆盖的输出 |

## 文档目录内部

- `docs/production_plan.md`：目标和 S01–S36 定义；`production_state.json`：状态；`work_history.jsonl`：逐次追加历史。`PROGRESS.md` 由工具生成，不手改。
- `docs/baselines/S01_20261013/`：基线、机器信息、已知问题、性能与恢复核验。带 `verified` 的数据和首次失败记录用途不同。
- `docs/resources/S02/`：105 资源清单、离线目录、几何检查与去向。这里的状态固定在 S02，当前补充见本次 resource_status。
- `docs/narrative/S03–S07/`：接口契约、旁白、对白、分镜、草案数据、运行与渲染/真实播放结果；accepted 与 earlier failed 记录保留原名称。
- `docs/level/S08–S11/`：路线调查与地图、资源区域安排、体块贯通、大型建筑和生活生产布景证据。
- `docs/reference/`：参考视频抽帧/拼图等；原始外部视频另有路径，不等于已内置项目。
- `docs/v04*`、`docs/v06/`、`v05_production.md`、`v061_hands.md` 等：版本历史、截图和制作依据；不是当前待办唯一来源。
- `docs/recovery/`：故障恢复交接与中断核对；`docs/auto_*`：自动控制器配置、协议和历史测试。
- `docs/handover/`：本次交接分册与核验；全文件索引不替代备份哈希清单。

## 工具与验证文件

`tools/build_*` 会生成或覆盖指定制作输出；不要为“看看能不能运行”就无目的执行建模脚本。`inspect_*`、`audit_*`、`survey_*` 是调查入口，但部分也会输出证据文件，先读参数和写入路径。`tools/checkpoints/` 是较早版本的人工源码副本，不是当前 WorkBackups 协议；保留历史，不复制进主工程覆盖新功能。

`tools/continuation/` 中：history.py 只负责本地历史发现与导出；protocol.py 是通信接口；supervisor.py 是派发/恢复调度；panel.py 是面板和停止控制；save_interruption.ps1 保存中断现场。读取这些脚本不授权运行面板或发送任务。

游戏 `tests/` 包含基础、人物、持枪、剧情、开场、路线、建筑、布景和性能检查。具体函数名、类、资源引用和文件职责已编入 [CODE_ENTRYPOINTS.md](CODE_ENTRYPOINTS.md)；调用参数以当前脚本为准。

## 文件后缀怎么理解

| 类型 | 处理方式 |
|---|---|
| `.gd` / `.cs` / `.py` / `.ps1` / `.cmd` / `.vbs` | 分别为当前游戏、旧 Unity、制作工具或启动控制代码，先确定所属目录 |
| `.blend` / `.blend1` | 可编辑 Blender 工程 / Blender 自动备份；源文件不因已有 GLB 就可以丢弃 |
| `.glb` / `.gltf` / `.bin` / `.fbx` / `.obj` / `.mtl` | 模型及外部依赖；glTF 的纹理和 bin 必须一起迁移 |
| `.png/.jpg/.exr/.hdr` | 可能是纹理、HDRI、参考或验收截图，按所属资源判断，不能一律当缓存 |
| `.wav/.ogg/.flac/.mp3` | 原始或处理后音频；下载、完整解码、试听、接入是不同环节 |
| `.import` / `.uid` | Godot 导入选项及脚本标识，需要随源码保留；与 `.godot/` 生成缓存不同 |
| `.godot/` / `__pycache__/` | 可重建缓存；全文件索引记录其存在，恢复时通常由工具重建 |
| `.json/.jsonl/.csv/.md/.html` | 清单、数据、历史、说明或可视目录；需查看 schema/所属步骤，不以扩展名判断是否可删 |
| `.log` | 实际执行记录，可能包含失败诊断；验收引用的日志必须备份，普通运行日志与正式证据区分 |
| `.exe/.dll/.pyd` | 引擎/工具运行库或发布程序，结合所属目录和许可保留 |
| `.zip/.7z` 等原包 | 原始库存与可复现来源；不可自动清理或覆盖 |

资源格式的通用说明不是艺术质量鉴定；未在本轮打开观察的模型、图片、动画或音频，不写成新验收通过。
