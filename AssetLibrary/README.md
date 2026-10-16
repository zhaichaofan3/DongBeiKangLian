# 制作资源库

这里保存制作输入和可编辑源，游戏运行只读取 `GodotProject/assets/`。本轮精简保留当前成果及必要的重新加工输入，删除未采用的整包枪声音库、通用动画集合、第三人称控制器样例及未选用人物变体。

| 路径 | 用途 |
|---|---|
| `derived/user_expansion_20261015/` | 当前建筑、完整农村、98k、船、河道与低网的可编辑Blender源 |
| `environment/user_expansion_20261015/` | 用户原始场景包与MAX/FBX/贴图，`imported/`为必要初次导入Blender输入 |
| `characters/user_models_20261015/adapted/` | 当前日军与我军适配源，`../imported/`为初次导入输入 |
| `characters/field_character/` | 现有程序动作人物源；基础人物库只保留所需模型及依赖 |
| `first_person/field_hands/` | 玩家第一人称手臂编辑源，必须保留 |
| `environment/derived/`、`derived/S10_buildings/` | 天池、地形、建筑等派生源 |
| `environment/models/`、`textures/`、`supplement/` | 已选环境资源及加工输入，按各来源清单识别 |
| `audio/*20261015/` | 用户原录音、对白重录、音效、来源与待听审候选 |

`audio/S28_20261015/`与`S29_20261015/`是声音候选试听材料，保留不等于已采用或验收；本地根Audio-Review.html可打开试听入口。当前实际选用以GodotProject内音频清单为准。

大二进制由Git LFS下载。编辑模型优先打开当前派生源；初次导入工具可能覆盖后续修订，不能直接重跑整批当作最终模型重建。模型外部贴图需一同保留，跨机器打开时检查缺失路径。

来源、署名、许可和具体游戏用途以 [ASSET_SOURCES.md](../GodotProject/ASSET_SOURCES.md) 与各目录清单为准。部分用户包未附明确再分发许可，不能统一标作CC0。目录中的旧README和清单保留当时语境，已删除条目可由本轮清理日志追溯。
