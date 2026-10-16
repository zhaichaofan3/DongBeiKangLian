# S18 受击、踉跄、倒地与倒地停留验收

日期：2026-10-14；基线：0.6.1。

## 实际改动

`human_model.gd` 在非致命 `flinch()` 上增加短时 `_stagger` 包络和左右交替的胸／骨盆偏转，受击后自动衰减回站立；致命 `fall()` 继续使用原有接地、放下头躯干和释放持枪扭曲的倒地流程。

## 专项验证

`s18_hit_fall.gd` 共 **14/14**：

- 侦察员、林场工人、陆山、守卫四类导入角色均出现可见非致命踉跄，并在 120 帧内回到不扭曲状态。
- 实际守卫非致命受击保持存活和碰撞，随后回到待机。
- 致命受击进入 `dead`、移除碰撞；倒地姿态接地并在停留期间保持稳定；死亡后不再恢复移动。

证据：[`hit-fall.json`](hit-fall.json)、[`hit-fall-runtime-final.log`](hit-fall-runtime-final.log)。

## 回归

- `character_model.gd`：**37/37**。
- `combat_route.gd`：**PASS**，9 名敌人击败并正常进入 `won`。

日志：[`character-model.log`](character-model.log)、[`combat-route.log`](combat-route.log)。

S18 未制作新的起身动作；当前任务中的死亡角色保持倒地，若后续角色状态需要起身，将在具体行为步骤中增加。下一步为 S19。
