# S16 走路、跑步、加减速、变向与脚步时序验收

日期：2026-10-14；基线：0.6.1。

## 实际改动

- `fps_player.gd` 将水平速度改为朝目标速度加速／减速，步频和 `walk_clock` 使用实际水平速度；停止时脚步计时器被限制在有效范围。
- `friendly.gd` 和 `guard.gd` 使用同样的水平加速模型，并把实际速度传给 `human_model.gd`，使腿部步幅和真实位移同步。
- 存档恢复和角色重置会清空水平速度，避免恢复后残留滑步。

## 专项验证

[`s16_locomotion.gd`](../../tests/s16_locomotion.gd) 用真实玩家、陆山和守卫 CharacterBody3D 验证 **8/8**：

- 玩家由静止加速到走路速度，松开输入后减速；脚步相位随实际旅行速度增加，停止时计时器有效。
- 陆山由静止加速到护送速度，停止跟随后平滑停下。
- 守卫由静止加速到巡逻速度，到达战斗目标后减速停下。

证据：[`locomotion.json`](locomotion.json)、[`locomotion-runtime-final.log`](locomotion-runtime-final.log)。

## 回归

- 线性路线：**37/37**。
- 战斗路线：**PASS**，9 名敌人击败并进入 `won`。
- 第一人称视觉动作：**50/50**。

证据日志：[`linear-route.log`](linear-route.log)、[`combat-route.log`](combat-route.log)、[`visual-motion.log`](visual-motion.log)。

S16 没有改动武器动作细节；下一步 S17 处理持枪移动、瞄准、开火、装填和受扰恢复。
