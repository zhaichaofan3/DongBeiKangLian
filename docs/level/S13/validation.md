# S13 碰撞通行与 AI 路线验收

日期：2026-10-14；基线：0.6.1；范围：实际源工程 `GodotProject/`。

## 本步改动

- `GodotProject/scripts/world.gd` 的路径端点现在先经过胶囊体清空检查；只有末段无碰撞时才接入人物真实目标点。
- 路径保留 AStar 网格中间点，避免把多个有掩体的格点压缩成一条会穿过敌人或掩体的直线。
- 新增 `GodotProject/tests/s13_navigation.gd`，覆盖巡逻往返、玩家胶囊体路线、栅门、建筑与掩体、陆山护送、增援入口和重复生成。

## 专项验收

`s13_navigation.gd` 最终运行通过 **35/35**：

- 五名初始敌人（`gate_guard`、`yard_guard`、`pier_guard`、`timber_guard`、`office_guard`）均到达巡逻端点并返回出生点。
- 西侧入口、检查口、木料巷、电报房返回、北侧护送、渡口和两条增援路线均通过胶囊体逐段扫掠。
- 三扇路线栅门分别验证关闭时阻挡物理与导航、打开后清除物理与导航。
- D02、D03、D04 建筑外墙及木料掩体、沙袋掩体均阻挡人物胶囊体。
- 陆山在同格、掩体边缘、转角和北侧到渡口四种位置均能跟随到目标附近。
- 两个增援入口可到达压力点，重复 guard ID 会被拒绝，没有重复生成。

专项原始证据：[`s13-navigation/navigation.json`](accepted-final/s13-navigation/navigation.json)、[`s13-navigation/runtime.log`](accepted-final/s13-navigation/runtime.log)。

## 真实路线与回归

- S09 真实输入路线 direct：14/14，通过；修正了渡口北侧导航末段阻挡后重新运行，路线完成并正常撤离。
- 全量 `Test-Game.ps1`：Smoke 107/107、Linear route 37/37、Combat route PASS（9 名敌人击败，状态 won）、Visual motion 50/50、Story moments 11/11、Character model 37/37。
- 全量日志中没有 `SCRIPT ERROR` 或 `ERROR:`；角色模型日志中的数值行是既有验收输出，不是错误。

回归日志：[`smoke.log`](accepted-final/smoke.log)、[`linear-route.log`](accepted-final/linear-route.log)、[`combat-route.log`](accepted-final/combat-route.log)、[`visual-motion.log`](accepted-final/visual-motion.log)、[`story-moments.log`](accepted-final/story-moments.log)、[`character-model.log`](accepted-final/character-model.log)。

## 判断与遗留

S13 范围内没有剩余的穿墙、堵路、巡逻卡住、护送卡住或重复生成问题。S13 只调整通行路径端点和验证，不提前完成 S14 的骨骼、动作和角色差异工作；未更新 Release 发布包。

下一步：S14，逐角色核对骨骼、蒙皮、现有动作和下载动作的适配成本。
