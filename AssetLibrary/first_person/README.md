# 第一人称双手

已从作者公开入口下载 [fps arms (rigged only)](https://opengameart.org/content/fps-arms-rigged-only)，作者 para，MakeHuman 基础，CC0。

原包与源文件：`oga_fps_arms/fps_arms.7z`、`oga_fps_arms/original/`。包括两个 Blender 工程、两个 FBX 和 1024×1024 颜色贴图，许可文本与来源网页在同目录。

Godot 实际导入：每个模型 4,600 顶点、8,152 三角面、62 骨骼，skin 绑定 50 骨骼。无动画版 0 动作；测试版仅有一段 2.25 秒的测试动作。这是可编辑的连续蒙皮底模，不是完成的步枪动作包。

验证发现 FBX 未自动找到 `new_diff.png`，测试版还大了十倍。工作副本与修复验证保存在 [AssetReview](../../AssetReview/README.md)，原始下载保持不变。已导出带内嵌贴图的 `AssetReview/ready/fps_arms_textured.glb` 和测试动作版，可直接导入验证；GLB按skin保留50个绑定骨骼，FBX中的62包含辅助/末端骨。

下一步需要袖子、抓握姿态、枪机/装弹接触、关键帧节奏与动作事件；不能仅平移整只手来替代手指变形。关卡里的程序手尚未被本资源替换。
