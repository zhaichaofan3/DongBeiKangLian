# 人物建模工具

选用 Blender 4.5.14 LTS（Windows x64），用于现有 Godot 游戏的人物建模、雕刻、拓扑整理、贴图、骨骼绑定和动画制作。免费，无需购买账户。采用便携版，工具和偏好设置均保留在游戏工作目录。

- 启动入口：`C:\GameMake\Start-Blender.cmd`。
- 主程序：`C:\GameMake\tools\blender-4.5.14-windows-x64\blender.exe`。
- 中文界面；新建物体、骨骼等内部名称保持原文，便于脚本与游戏动作映射。
- 原版发布包由清华镜像下载；压缩包与 SHA-256 清单位于 `tools/downloads`，安装记录见 `tools/blender-verification`。

## 后续人物重建

先完整制作和接入一名角色：体型与脸部、年代服装和装备、适合实时游戏的网格与贴图、骨骼和蒙皮，再验证走路、持枪、受击等动作。高精度雕刻保留为制作源文件，导入游戏前整理为性能合适的模型。软件准备完成并不等于人物品质已完成验收。

`.blend` 原工程、高精度与游戏网格、贴图、参考和骨架保存在 `AssetLibrary/characters/<角色>/`；游戏使用 `.glb` 导出到 `GodotProject/assets/characters/<角色>/`。优先使用明确导出的 GLB，让游戏资源与建模源工程分开维护。

0.6 已完成首批连续蒙皮 NPC，源工程在 `AssetLibrary/characters/field_character/field_character.blend`，运行时使用13根骨骼。头脸与手部基础来自已下载的 Quaternius CC0 模型，棉衣和装备由本项目制作。旧分节模型仅保留为加载失败时的备用。第一人称双手仍为独立骨骼 GLB。

Blender 支持后台 Python 操作，可以分批生成与修改网格、材质、骨架和动画，保存 `.blend`，然后批量导出；每一批仍需查看实际外观和游戏内动作。
