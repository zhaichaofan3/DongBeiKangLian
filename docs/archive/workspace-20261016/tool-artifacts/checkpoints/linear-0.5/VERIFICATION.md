# 0.5 线性关卡验证记录

2026-10-12，Windows，Godot 4.7.2 / GL Compatibility。

## 源码与正式游戏包

`Test-Game.ps1` 和 `Test-Game.ps1 -Release -Capture` 均通过。每套包括基础 107/107、线性关卡 37/37、武器动作 43/43、剧情声音 11/11，共 **198 项断言**。正常 AI 完整交火路线两套均通过，消灭全部 9 名敌人、救出陆山并完成掩护撤离，最终状态 won。

线性测试覆盖三门碰撞/寻路/顺序封锁、分段激活、门状态存档恢复、旧档兼容、畸形字段拒绝、缺弹兜底及其存档、解缆计时、暂停/离区/同伴等候停止计时与最终结束条件。

基础叙事测试隔离冻结敌人的碰撞，避免不行动的测试守卫堵住固定行走路线；正常交火测试保留敌人 AI、武器伤害与实体碰撞，并通过连续行走完成新路线及陆山护送，途中不传送。

`Build-Game.ps1` 成功生成正式包。发布验证从临时目录启动 `Release/FenghuoEcho.exe`，没有传入源码 `--path`，游戏脚本与资源由同名 pck 加载；测试控制器仍由工程 tests 目录读取。日志无 SCRIPT ERROR / ERROR。

## 画面检查

标题、设置、交谈、木料巷、电报房、救援、记录、渡口，分别在 **1280×720 和 960×540** 实际输出尺寸截图，共 16 张。检查了总览以及木料巷栅门与路牌、低分辨率渡口解缆提示和行动记录；未发现新增界面元素裁切或相互遮挡。

截图位于 `Release/verification-captures`；这些画面由固定场景布置生成，不代替连续通关验证。

## 交付与证据

- `Release/release_validation.json`：正式 exe/pck 大小、SHA-256、检查数与截图尺寸。
- `GodotProject/source-validation.log`：源码全部回归。
- `Release/release-regression.log`：正式包全部回归与截图运行。
- `Release/integration.log`、`linear-route.log`、`combat-route.log`、`visual-motion.log`、`story-moments.log`：对应专项日志。
- `tools/checkpoints/linear-0.5`：本轮脚本、测试与主要说明的本地保存副本。

## 验证边界

自动控制器精准瞄准的通关不代表真人难度、紧张感或实际游玩时长。未进行新性能测量；历史固定机位或分辨率不符的交火报告不可用来描述本版帧率。画面与人物动作仍是原型，尚未达到《战地1》的视听标准。
