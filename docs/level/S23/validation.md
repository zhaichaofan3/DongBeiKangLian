# S23 天池水雾光照与层次验收

日期：2026-10-14；基线：0.6.1。

## 本步结果

S23 已在开场天池阶段加入可关闭的环境表现层：

- S21 导入湖面复用原始几何，替换为 tianchi_water.gdshader，用开场时钟驱动缓慢宽波、细波和菲涅耳反射，避免叠加第二个水面产生闪烁。
- lake_environment 使用独立环境副本：环境色、胶片色调、低密度高度雾和太阳散射只作用于天池镜头。
- 三层轻量薄雾带和三层低多边形远山作为 S23_Tianchi_Environment 子树，进入天池镜头启用，离开天池镜头关闭。
- 增加天池补光和岩台轮廓光，均限制到视觉层 2，人物在 B1—B6 对话镜头中保持可读。
- S23 子树只在 OpeningDirector 内切换，不进入林场正式关卡；水面、薄雾、远山和两盏灯的数量固定，便于后续性能控制。

实现入口：

- GodotProject/scripts/opening_director.gd
- GodotProject/shaders/tianchi_water.gdshader
- GodotProject/shaders/tianchi_mist.gdshader
- GodotProject/tests/s23_tianchi_environment.gd
- GodotProject/tests/s23_capture.gd

## 实际验证

- runtime-v3.log：Godot 4.7.2 headless 12/12 通过；验证环境树、水面材质、三层薄雾、三层远山、雾参数、人物补光、B1 启用和 A1 关闭。
- render-final3.log：Godot 4.7.2 Compatibility 渲染 S23 CAPTURE: PASS。
- 多镜头截图：render-final3/rim.png、wide.png、environment_wide.png、talk.png、listen.png、briefing.png。截图人工复核确认湖面稳定、人物面部和武器轮廓清楚，远山承担纵深且没有遮挡人物。
- render-final3/captures.json：1280×720，NVIDIA GeForce RTX 5060 Laptop GPU。效果关闭／启用的 90 帧样本中，中位帧耗时约 8.46–8.63 ms，P95 约 8.94–9.00 ms；效果启用时 36 draw calls、14,816 primitives，关闭时 30 draw calls、14,642 primitives。测量为同一冻结镜头的相对开销记录，不替代 S35 的完整场景性能测试。

## 失败与修正

首轮运行保留在 runtime-v1.log：曾使用不兼容的 receive_shadows 属性和旧版雾 shader render mode；已修正为 Godot 4.7.2 可用接口。首轮画面远山对比过强，随后将三层高度调整为 20/30/42 m 并降低色差，最终截图使用修正后版本。

## 边界与下一步

本步完成天池环境表现和多镜头可读性。近景植被细化、人物注视／手势／听话反应归入 S24；正式谈话镜头、队伍起步、下山过渡和玩家接管归入 S25。
