# S19 日军识别特征 · 2026-10-15

按用户要求在现有日军守卫造型上添加：头盔正前方红色空心圆圈、鼻下左右分开的八字胡。红圈直径约6.2厘米、线宽约6毫米，贴合盔壳曲面；胡须顺着上唇与面部曲面向两侧下方展开。

两个部件均写入可编辑Blender源和游戏GLB，100%绑定Head骨，与转头、瞄准和倒地同步。新增448个三角面；没有另加骨骼或碰撞。只在guard角色显示；侦察员、林工、陆山，以及开场中复用guard基础模型的友军均隐藏这两项。

## 源与修改位置

- `AssetLibrary/characters/field_character/field_character.blend`：可编辑源。
- `GodotProject/assets/characters/field_character.glb`及`provenance.json`：游戏资源及统计/哈希。
- `tools/guard_identity_geometry.py`：红圈和胡须的贴面几何生成。
- `tools/update_guard_identity.py`：对当前源的增量修改与导出。
- `tools/build_field_character.py`：完整重建也调用相同几何生成。
- `GodotProject/scripts/field_character_rig.gd`：按角色显示与隐藏。

## 本轮小步验证

- 源码人物检查和14张渲染共51/51通过，包含蒙皮、装备区分、瞄准、开火、倒地等。
- 已复看日军面部、全身和侦察员面部：红圈与胡须清晰，友军未出现新增特征。
- 发布包人物检查和14张渲染同样51/51通过；复看发布面部、瞄准及倒地，标记和胡须随头部保持贴合。
- 源码完整回归411项通过，另21点支撑/视线与9敌自动通关通过；包括开场敌军显示、友军关闭两项特征的检查。独立发布包回归结果见`release-regression.log`和`validation.json`。
- 旧发布包保留于`ReleaseBackups/20261015-before-guard-identity`；当前包修订为`20261015-guard-identity`，逐文件哈希见`Release/SHA256SUMS.txt`。此前音频正常速度连播属于上一修订证据，本次不重复冒称通过。

本次只完成用户指定的身份造型修改。S32雪地、扶人、S33坡道及声音真人验收仍按原进度接续。
