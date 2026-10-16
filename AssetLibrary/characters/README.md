# 人物、人体骨骼与动画资源库

采集日期：2026-10-12。所有条目均为实际下载的作者免费版本；原始压缩包、来源网页与随包许可已保存。没有改动游戏项目。

## 已下载与检查

| 资源 | 实际内容 | 骨骼 / 动作 | 在东北抗联关卡里的用途 |
|---|---|---|---|
| Quaternius Universal Animation Library 1 Standard | 原地和根运动 GLB、Unity FBX | 65关节；每份43段，含T姿态 | 行走、慢跑、冲刺、蹲走、受击、死亡、手枪瞄准/换弹/开火 |
| Quaternius Universal Animation Library 2 Standard | 原地和根运动 GLB、Unity FBX、女模 | 动作GLB每份43段；女模无动作 | 翻越1米、投掷、滑行、倒地起身、扛物走、伐木 |
| Quaternius Universal Base Characters Standard | 男女完整角色、8种眉毛/发型的静态与绑定版本、贴图 | 男女各65关节、3网格；18个glTF中只有2个完整人体 | 人体与手指网格起点，需重新制作棉衣/帽子/装备 |
| Godot 官方 TPS Demo player | GLB、4张PBR贴图、材质、场景/脚本参考 | 145关节、56段，其中29段没有作者的-noexp标记 | 持枪行走/跑步、四向平移、瞄准、受击的重定向参考 |

UAL1+UAL2 去掉原地/根运动重复，合计85个不同动作名称，其中1个是两库共用的 A_TPose，因此为84个非T姿态名称。不要用作者网站全版的120+/130+来表示免费包下载数。

原始下载总字节：194,146,674（约185.15MiB）。含解压文件、原包、记录，总占用约444MiB。完整24个glTF/GLB文件中16个含skin。未把FBX的副本重复计为新增动作。

## 推荐使用入口

- NPC基本动作：`quaternius_ual1/files/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb`
- NPC翻越/投掷等动作：`quaternius_ual2/files/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb`
- 男性基础连续网格：`quaternius_base_characters/files/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Male_FullBody.gltf`
- 女性基础连续网格：同目录 `Superhero_Female_FullBody.gltf`
- 射击移动参考：`godot_tps_player/player/model/player.glb`

`_RM.glb` 是带根位移的版本，其余是原地版本。游戏自身移动角色时应先使用原地版本。所有动作和时长见 `gltf_inspection.json`。

男女Base与UAL使用相同的65个骨骼名称，包含双手5指的分节骨骼。男模14,318三角面，UAL1人体13,744三角面；这是连续蒙皮网格，不是球体/圆柱拼手。但模型风格仍偏风格化，不能等同于《使命召唤7》的写实角色成品。

## 已修复的原资源问题

Base Characters 原始ZIP的两个完整人体glTF存在3处纹理文件名引用错误：引用了不存在的 `T_Eye_Normal_png.png` / `T_Hair_1_Normal_png.png`。已在解压后的副本中改为随包实际存在的 `.png` 名称，原ZIP保持不变；逐项修改及前后SHA-256见 `texture_reference_repairs.json`。

## 实际验证范围

已检查GLB头与长度、glTF JSON、buffer尺寸、bufferView边界、skin关节引用、动画sampler/节点引用，以及所有外部bin/贴图存在性；24个模型文件通过。ZIP通过CRC完整性检查与解压路径检查。文件SHA-256记录在 `manifest.json` / `gltf_inspection.json` / `file_inventory.json`。

尚未在游戏里渲染、进行动画重定向或验收手枪/步枪接触点。原包附有FBX，当前仅存档，没有声称验证FBX导入。Godot TPS保存的是角色子集和参考文件，场景仍有其他项目引用，不是完整可运行示例。

## 接入限制与下一步

1. 先用同骨架Base+UAL替换敌人/队友的分段角色，制作BlendSpace和受击/死亡切换。
2. Base的超级英雄服装和机器人外形不符合1938年东北，应保留人体/动作数据，重新制作或更换历史服装。模型皮肤与脸型也需调整。
3. UAL1免费枪械动作是手枪动作，不能宣称已经得到步枪拉栓、桥夹装填或第一人称双手动画。持步枪的握点、枪托抵肩、左手支撑和换弹需针对枪模调整。
4. Godot TPS机器人骨架与人体骨架不同，不能直接播放；应映射人体主干骨骼、过滤机械骨骼和-noexp工作动作后重定向。
5. Quaternius资源许可CC0；Godot TPS资产CC-BY 3.0，署名 `Juan Linietsky, Fernando Miguel Calabró; Godot Engine contributors`，并保留 `godot_tps_player/LICENSE.md`。

## 候选与下载阻塞

Quaternius Ultimate Modular Characters（11名角色/24动画）：作者页 `https://quaternius.com/packs/ultimatemodularcharacters.html` 链接的Google Drive文件夹能够公开列出角色，但实际下载返回 **Google Drive - Quota exceeded**。已尝试Adventurer、Swat、Animations.fbx和License.txt，均是同一限制，没有把HTML错误页当模型保存，没有绕过限流。候选页面与文件列表保留在 `quaternius_modular/`，未计入已下载资产。

GDQuest Open 3D Mannequin已查到公开来源，但现有两个UAL已覆盖同类基础动作；本次未额外下载重复的旧Godot 3项目。Mixamo等需要登录/选角色/导出的来源没有列成已下载。现阶段仍缺适合抗联年代的写实服装角色与专门的步枪第一人称动作。
