# S15 站立、呼吸、转身、起步与停止验收

日期：2026-10-14；基线：0.6.1。

## 实际改动

在 [`human_model.gd`](../../scripts/human_model.gd) 中将转身量拆成目标值 `_turn_target` 与实际值 `turn_amount`。角色收到新的转身速度时，实际胸部／头部偏转以指数平滑追踪，避免从站立直接跳到最大侧倾；原有呼吸、动作速度混合和贴地修正保留。

## 专项验证

[`s15_motion_transitions.gd`](../../tests/s15_motion_transitions.gd) 对侦察员、林场工人、陆山和守卫分别执行：120 帧站立呼吸、30 帧起步、45 帧停止、30 帧正向转身和 30 帧反向转身，共 **24/24** 通过。

- 四类角色呼吸幅度均有界且持续。
- 四类角色从站立进入运动时动作量连续增加，停止后回到稳定低值。
- 转身响应连续，首个采样间隔没有瞬时跳变，反向转身也平滑。

原始专项结果：[`motion_transitions.json`](motion_transitions.json)；运行日志：[`motion-transitions-runtime.log`](motion-transitions-runtime.log)。

## 回归

- `visual_motion.gd`：**50/50**，枪械和第一人称动作未受影响。
- `character_model.gd`：**37/37**，四类导入蒙皮、贴地、握枪、治疗过渡和倒地通过。
- 两份日志没有 `SCRIPT ERROR` 或 `ERROR:`。

S15 没有开始 S16 的走跑步幅、速度和坡道校准；下一步为 S16。
