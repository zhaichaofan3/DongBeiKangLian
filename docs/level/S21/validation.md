# S21 艺术化天池山体与湖面验收

日期：2026-10-14；基线：0.6.1。

## 本步结果

S21 已完成一个独立的艺术化天池视觉模型：四块连续接缝的环形山体、内湖、向外展开的坡脚，以及西南侧谈话岩台基座。模型按米制抽象构图制作，未把公开高程样板冒充正式地形，也未接入正式任务场景；S22 继续负责可站立岩台、路线、碰撞和场景接入。

| 项目 | 结果 |
|---|---|
| 可编辑源 | `AssetLibrary/environment/derived/S21/tianchi_artistic.blend` |
| 游戏模型 | `GodotProject/assets/opening/tianchi_artistic.glb` |
| 几何规模 | 7,699 顶点、14,400 三角形；四个山体对象各 3,456 三角形 |
| 尺度 | 环形山口目标半径 92 m；湖岸约 49 m；外坡延伸约 172 m；湖面标高 0.4 m；岩台基座顶部约 14 m |
| 远景预览 | `previews/tianchi_far.png` |
| 近景预览 | `previews/tianchi_near.png` |

Blender 源坐标约定为 x、北向、上；Godot 导入后为 x、上、-北向；1 单位等于 1 m。湖面向山体内侧覆盖到约 54 m 半径，避免湖岸边缘出现背景空洞；山体和坡脚采用连续径向环带，外边界保留给 S22 做碰撞裁切和路径整理。

## 实际验证

- Godot 4.7.2 重新导入成功，未再出现 `No loader found for resource`。
- `tests/s21_tianchi.gd` 最终 **7/7 通过**：GLB 加载、四段山体／湖面／岩台存在、整体尺度、湖面与山脊标高、材质、无 S22 碰撞、导入后山体三角形数量。
- Blender 拓扑审计见 `mesh-topology.json`：四段山体、湖面和岩台均无零面积面；山体扇区接缝作为显式边界保留，供 S22 制作碰撞。
- 远近景预览由 `tools/render_s21_previews.py` 从 Blender 源重新渲染。它们是构图和几何预览，不代表正式关卡中的雾、光照、水面材质或人物表演已经完成。

## 失败与修正记录

早期版本曾有两类失败，均保留原始日志而没有覆盖：

1. 首次 Godot 运行时 GLB 尚未建立导入缓存，见 `tianchi-runtime.log` 和 `tianchi-runtime-final.log`；随后执行编辑器导入，生成 `.godot/imported/tianchi_artistic...scn`，最终导入通过。
2. 第一版远景块底部低于零平面，标高检查失败；随后将其改为连续山体和外坡。修前截图与日志保存在 `before-visual-fix/`，最终验证使用 `runtime-v3/tianchi.json`。

## 边界与下一步

本步没有声明正式关卡接入、玩家可行走碰撞、谈话路径、水雾光照或最终材质完成。下一步 S22：以 S20 的西南岩台站位为基准制作平整站立面、到达／离开路线、近景岩石植被和碰撞，并在 Godot 中接入可行走验证。
