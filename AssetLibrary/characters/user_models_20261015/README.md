# 用户人物模型

2026-10-15用户明确要求替换日军和我军人物，保留玩家第一人称手臂。原始包不改写，转换及适配结果分开保存。

| 位置 | 用途 |
|---|---|
| originals/japanese.rar、volunteer.rar | 用户RAR原样副本 |
| japanese/ | 日军MAX与原始TGA、DDS、JPG、HDR |
| volunteer/ | 志愿军MAX与12张原始PNG |
| adapted/japanese.blend、volunteer.blend | 正式适配源，含贴图、13骨蒙皮及可见附件 |
| adapted/textures/ | 我军灰色织物派生贴图；原始图保留 |
| adapted/build-report.json | 游戏模型哈希、面数及加工说明 |

工具：先用tools/inspect_user_max_models.py读取MAX，再用tools/build_user_soldiers.py生成游戏GLB。Blender入口为tools/blender-4.5.14-windows-x64/blender.exe，转换器及GPL许可证位于tools/third_party/max_importer/。原始场景只由解析器读取，不运行MAX内脚本。

日军原始单体约11,106个三角面，志愿军包为两个人物、合计90,274个三角面。适配时选其中一套志愿军，重新连接颜色贴图、去除静态武器、调整姿势并绑定现有动作。我军使用包内原始手套几何与贴图，分别适配放松和握枪手形；日军接触手继续沿用已有第三人称网格。陆山只保留腿部包扎，旧额头绷带因遮眼而取消。玩家手臂未修改。军帽与冬装按用户模型保留，美术适配不代表全面历史服装考据。

源文件名含3d66来源线索，作者和许可未随包提供，不能声明为CC0。原接入检查见docs/user-models-20261015/review.md，最新头手修正见docs/user-model-fix-20261015/review.md，当前正式路径为GodotProject/assets/characters/user_soldiers/。

接续优化按左右手套各自的掌面方向弯曲握枪手指，避免原始掌面朝向与世界高度压缩叠加后向枪身上方伸出；保留原始手套UV、厚度与放松手形。最新接续验收见docs/user-model-fix-final-20261015/review.md。
