# 《烽火回声》文档索引

更新：2026-10-12。当前制作版本 0.6，工程在 `../GodotProject`，Godot 4.7.2 + GDScript + GL Compatibility。

| 文档 | 用途 |
|---|---|
| [0.6 人物制作记录](v06_production.md) | Blender 连续蒙皮人物、面部与服装重建 |
| [0.5 制作记录](v05_production.md) | 线性路线、分段交战与渡口掩护 |
| [0.4 制作记录](v04_production.md) | 蒙皮双手、选用环境、敌人扩充与小人物对白 |
| [游戏说明](../GodotProject/README.md) | 启动、操作、设置、存档和限制 |
| [当前验证](../GodotProject/VERIFICATION.md) | 当前包的回归与画面检查 |
| [实际素材来源](../GodotProject/ASSET_SOURCES.md) | 已接入素材的作者、许可与改动 |
| [最终视听与叙事方向](bf1_reference_direction.md) | 《钢铁风暴》视频拆解、原创段落与验收目标 |
| [已下载资源](../AssetLibrary/README.md) | 74 组来源及其下载、适配、接入状态 |
| [主 GDD](phase1_preproduction.md) | 前期故事、机制与范围，版本状态以当前制作记录为准 |
| [单人执行方案](phase1_solo_execution.md) | 制作顺序与资源策略 |
| [技术可行性](phase1_mvp_feasibility.md) | 前期系统规划与性能目标 |
| [资产规划](phase1_asset_inventory.md) | 前景、中景、背景的优先级 |
| [历史表达](phase1_history_review.md) | 年代、装备与人物考据边界 |
| [早期画质评估](phase2_visual_quality_assessment.md) | COD7 参考下的工程诊断，最终标杆已更新为 BF1 |
| [0.3 历史验证](v03_verification.md) | 旧版固定机位性能，不能当作当前版本数据 |
| [连接排查](connection_diagnosis_2026-10-12.md) | 开发接口 502 定位；离线游戏不依赖该接口 |

现有单关卡保留 1938 年东北抗联背景与青岚林场故事。新任务共有 9 名敌人，最多 6 名存活；初始 5 名，开启渡口栅门后两批各 2 名追兵。主线改为检查口、木料巷、电报房和渡口四段推进；救出陆山后在船边掩护解缆 12 秒，再共同撤离。

沿用此前的骨骼手部、21 项环境资源和 6 项外部录音；NPC 已使用 Blender 连续蒙皮人物，由现有程序驱动动作；下载的通用角色动画未接入。新增短对白不会锁定镜头或暂停操作。多视角、双人拖扶、完整中文配音和 8–12 分钟节奏仍是后续制作与试玩目标。

工程根目录的 `Test-Game.ps1` 运行基础、动作、剧情状态及正常 AI 通关检查；`-Release -Capture` 从源码目录之外运行正式包并截图。`Test-CombatPerformance.ps1 -Release` 测量实际 AI 交火路线的帧时间。`Test-Performance.ps1` 为固定相机测试，必须与交火数据区别阅读。

`../GameProject` 是停用的 Unity 实验骨架。`../AssetLibrary` 是工程外库存，下载不表示已进入关卡；用户提供的商业游戏包仅作只读参考，没有导入其模型、声音或对白。
