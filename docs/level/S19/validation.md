# S19 角色行为差异验收

日期：2026-10-14；基线：0.6.1。

## 实际改动

- `friendly.gd` 保存角色 ID，并按侦察员、林场工人、陆山的身份提供不同未治疗／治疗移动速度：2.4／2.0／1.8，治疗后的陆山为 2.7。
- `human_model.gd` 给侦察员和林场工人轻微不同站立重心；陆山的伤势姿态随治疗平滑减弱。
- `guard.gd` 明确守卫的巡逻速度、战斗速度、步枪和追踪最后目击点行为档案。

## 专项验证

`s19_role_profiles.gd` 对实际 Friendly、Guard 节点和导入模型执行 **9/9**：

- 四类角色身份和速度层级存在且可读。
- 侦察员与林场工人站立重心不同；未治疗陆山保持伤势姿态，治疗后姿态减弱。
- 守卫保留步枪、巡逻到最后目击点的行为，战斗速度高于巡逻速度，并能进入稳定瞄准姿态。

证据：[`role_profiles.json`](role_profiles.json)、[`role-profiles-runtime-final.log`](role-profiles-runtime-final.log)。

## 路线回归

- 线性路线：**37/37**。
- 战斗路线：**PASS**，9 名敌人击败并正常撤离。

日志：[`linear-route.log`](linear-route.log)、[`combat-route.log`](combat-route.log)。

S19 完成角色差异范围；没有把尚未重定向的通用动作库写成正式接入。下一步为 S20 艺术化天池构图。
