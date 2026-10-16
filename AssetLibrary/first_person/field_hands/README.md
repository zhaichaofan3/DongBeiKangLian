# 第一人称双手 · 0.6.1

2026-10-13。基础网格和颜色贴图作者 para，CC0-1.0，来源 https://opengameart.org/content/fps-arms-rigged-only 。本项目的拆分、绑定坐标标准化记录保存在 `source/provenance.json`。

`field_hands.blend` 包含左右手控制网格、一级细分修改器、各24骨可编辑骨架及打包颜色贴图。左右手在展示工程中平移摆开；运行时输出保持原有手腕坐标。文件内的左／右皮肤 PNG 为原资源贴图提取副本。

在工程根目录用 Blender 后台运行 `tools/refine_fp_hands.py` 可从 `source` 中的固定输入重新生成网格与工程，输出到 `GodotProject/assets/first_person`。生成器只替换 GLB 的网格数据，保持游戏所用的节点变换和逆绑定矩阵，避免手指弯曲轴变化。`build-report.json` 记录面数与校验值。

衣袖与袖口随动作生成，编辑入口为 `GodotProject/scripts/fp_hands.gd`，不包含在本 Blender 手部文件中。原始未拆分资源仍保存在 `AssetLibrary/first_person/oga_fps_arms/original`。
