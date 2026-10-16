# S24 人物交谈表演验收

日期：2026-10-14；基线：0.6.1。

## 本步结果

S24 沿用 S05 的对白 cue 和现有 S07 时间轴，在 OpeningDirector 内加入双角色表演层：

- B1、B2、B3、B5、B6 的对白 cue 现在会驱动说话者与听话者的不同反应。
- 姜岚保留正式演出角色；沈砚增加一个只属于开场表演的 ally1 副本，第一人称镜头仍显示玩家手部，副本不会进入任务 AI、伤害、背包或控制状态。
- cue 行为包括：看脚下霜面后抬眼、延迟回看、低位指路、手臂小幅手势、呼吸和重心变化、听到关键信息后的短暂停顿。
- B4 行军蒙太奇会隐藏交谈副本；进入林场 B5、B6 时副本切换到 gameplay 视觉层并保持 0.08 m 地面锚点。
- 表演完成后仍由 S25 负责正式侧向镜头、队伍起步、下山和玩家接管；本步没有改变玩家控制权或任务状态。

实现入口：

- GodotProject/scripts/opening_director.gd
- GodotProject/tests/s24_conversation.gd
- GodotProject/tests/s24_capture.gd

## 实际验证

- runtime-v4.log：Godot 4.7.2 headless **11/11 通过**；覆盖 B1-L01、B2-L01、B2-L02、B3-L01、B5-L01、B5-L02，以及岩台／林场站位、B4 隐藏、玩家控制模式和任务状态不变。
- render-v1.log：Godot 4.7.2 Compatibility 多镜头截图 **S23 CAPTURE: PASS**，保留 talk/listen/briefing 等原镜头下的手势和头部变化。
- render-v4.log：S24 QA 侧向取景 **S24 CAPTURE: PASS**；取景脚本只用于检查两个表演实例的空间关系，正式开场镜头仍留给 S25。
- 项目回归：Smoke107/107、Linear37/37、Combat PASS、Visual Motion50/50、Story11/11、Character Model37/37。

## 边界与下一步

S24 完成角色表演节奏与状态；没有把第一人称交接误报为正式双人镜头。下一步 S25：制作谈话镜头、队伍起步、下山过渡和玩家视角接管，确保控制权连续。
