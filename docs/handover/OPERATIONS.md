# 启动、验证、迁移、备份与恢复

以下命令在工程根目录 `C:\GameMake` 执行。它们是接手操作说明，不表示本轮全部运行过；本轮实际执行结果见 [VALIDATION.md](VALIDATION.md)。

## 本机工具与启动

| 工作 | 入口与依赖 |
|---|---|
| 当前源码体验 | 双击根目录 `Start-Game.cmd`；含开场草案与 S10/S11 新布景 |
| 源码编辑 | `Start-Game.ps1 -Editor`，或 Godot 4.7.2 打开 `GodotProject/project.godot` |
| 旧发布基线 | 双击 `Release/FenghuoEcho.exe`；同目录 PCK、许可、来源说明保留 |
| Godot 定位 | `tools/Find-Godot.ps1` 优先本地 `tools/Godot-4.7.2/`，其次既有系统安装；没有就明确报错 |
| Blender | `Start-Blender.cmd` → `tools/blender-4.5.14-windows-x64/blender.exe` |
| 检查点 Python | 优先 `C:\Program Files\Python311\python.exe`，否则 Blender 附带 Python，再尝试系统 python；见 Save-WorkCheckpoint.ps1 |
| 第三方资源解析库 | `tools/asset_python/`；供特定资源工具使用，不是正式游戏运行依赖 |

Godot `res://` 是 `GodotProject/`。不要直接从 `WorkBackups/.../files/GodotProject` 打开编辑器，因为它会产生缓存甚至改写快照。先复制到独立恢复目录，再核验。

主要操作：WASD 移动、鼠标视角/射击/瞄准、E 互动、R 换弹；完整键位以 [游戏 README](../../GodotProject/README.md) 为准。草案选“开始任务 · 含开场草案”，Esc 暂停，Enter 跳过当前段；直接开始任务可跳过两段。旧存档的任务状态与新任务不同，观摩新路线应选新任务。

## 存档与工程外文件

`project.godot` 设置了自定义 user 目录 `FenghuoEcho`，Windows 通常落在 `%APPDATA%\FenghuoEcho`。`mission.gd` 的正式存档为 `qinglan_checkpoint_v2.json`，QA 使用 `qa_qinglan_checkpoint_v2.json`，画面捕获另用 `capture_qinglan_checkpoint_v2.json`。`presentation.gd` 的设置为 `presentation_v1.cfg`，QA 用 `qa_presentation_v1.cfg`。用户数据不在普通 project 检查点中；迁移玩家进度时要单独复制，不用测试覆盖普通存档。

工作区外历史参考包括桌面的《钢铁风暴》视频、用户曾提到的游戏参考目录 `C:\XboxGames\ssmmzzhh77`、临时目录里的粘贴截图。视频抽帧已在 `docs/reference/`，原视频不是运行依赖。是否仍在本机及完整路径见 [external_references.json](external_references.json)。旧文档中的绝对路径不保证在新机器可用；需要继续参考原件时再复制，并记录来源位置。完整对话导出会保存 attachments 目录中的附件；外部视频/Temp 图并不自动包含于该导出。

## 运行验证时如何选择

| 改动 | 优先检查 | 证据与边界 |
|---|---|---|
| 通用玩法/人物 | `Test-Game.ps1`；需要真实画面时加 `-Capture` | 基础、路线、AI、动作、剧情与人物；脚本会覆盖固定运行日志，先保留已有证据 |
| 开场 | `Test-Opening.ps1 -EvidenceDirectory <新的绝对目录>`；需要截图用 `-Capture`，连续播放用 `-Live -Capture` | 新证据目录，不覆盖 accepted 历史；字幕状态检查不替代正常速度观影 |
| 路线 | `Test-RouteBlockout.ps1 -Case direct/full/skip -EvidenceDirectory <新的绝对目录>` | Case 一次传一个；三次分别用新目录。覆盖入口、救援顺序和实走 |
| 建筑/布景 | 查看 `GodotProject/tests/s10_buildings.gd`、`s11_dressing.gd` 的参数 | 项目专用检查；S11 静态路线不替代最终 AI 动态验收 |
| 真实活动性能 | `Test-CombatPerformance.ps1 -Label <新标签>`；发布检查加 `-Release` | 查实际图像尺寸、AI与玩家射击次数、活动时段和帧时间，敌方0射击不能叫双方交火 |
| 固定机位性能 | `Test-Performance.ps1` | AI暂停场景；只表示固定视角开销 |
| 发布验收 | `Test-Game.ps1 -Release -Capture` | 包在源码目录外运行；仍借用源码中的测试控制器，需要源码可访问 |
| 备份完整性 | `python tools/work_checkpoint.py verify` | 验证最近检查点，或在 verify 后加特定快照路径 |
| 交接文件 | `python tools/verify_handover.py` | 核对本交接文件、相对链接、资源、历史对象、固定旁白与 S11 对照；不运行游戏 |

性能目标依赖机器、分辨率、画质、实际交火和渲染模式。S01 机器记录为 Ryzen 7 H 260、约32GB、RTX5060 Laptop；单次样本差异不能直接报告为优化收益。新机器先重新测量。

## 构建注意事项

`Build-Game.ps1` 先导入并生成临时 PCK，校验后替换发布 PCK，并复制引擎、许可和说明。它会改变 `Release/`，因此制作时必须先保存带 `IncludeRelease` 的旧包检查点，再构建、测试源码和发布包、更新来源/版本，收尾再保存带新包的检查点。

本轮没有调用构建工具。不要只为确认“可执行文件存在”重打包旧基线。S36 统一解决内部 0.6 与发布 0.6.1 的版本差异，并给新发布确定明确版本。

## 检查点操作

完整规则以 [WORKFLOW.md](../WORKFLOW.md) 为准。`-StepId` 可以是 P00，`-NextStepId` 必须是 S01–S36；上次交接曾把 NextStepId 写 P00 被拒绝，未写入状态。文档任务继续用 P00，下一游戏步骤填 S12，并在 NextAction 写明仍在整理什么。

开工范式（真的开始 S12 时才运行）：

```powershell
.\tools\Save-WorkCheckpoint.ps1 -StepId S12 -Status in_progress `
  -Summary '开始树林山体与远景制作' -NextStepId S12 `
  -NextAction '锁定路线视线和固定机位，安排树木山体资源' -Scope project
```

收尾范式：明确本轮实际产物路径后，通过 `-ExtraPaths` 纳入工程外源、生成工具、日志、图像及验收；`done` 必须用 `-Evidence` 指向已经存在的证据。不能直接照抄还不存在的未来证据路径。只改文档用 planning；改 Godot 用 project；改发布包加 IncludeRelease。默认范围不会替你保存整个原素材库。

成功必须有正式快照目录、清单与 SHA-256，且 LATEST/实时状态一致。`.pending-*` 不是恢复点。备份失败先查磁盘、路径、读取错误和锁；确认锁内进程已结束后才处理那个锁文件，不能删除备份目录“解锁”。

只在实时进度三份文件写入中断时用 `python tools/work_checkpoint.py recover-records`；它会先保留现场，再从校验通过的快照恢复 PROGRESS、状态和工作历史，不恢复游戏资产。游戏回退应复制到独立目录后逐项选取，先保存未备份改动。

## 换项目、换目录或换电脑

1. 同一电脑只新开项目/对话时，让新项目指向现有 `C:\GameMake`。阅读 [新项目首条消息](NEW_PROJECT_PROMPT.md)，先核对而不是新建空工程。
2. 搬走整个项目时，复制根入口、GodotProject、AssetLibrary、AssetReview、GameProject、docs、tools、licenses、Release、WorkBackups、ConversationBackups 与原始引擎包。RestoreChecks 和 tools/checkpoints 是历史恢复证据，完整交接也保留。不要仅复制本次文档包。
3. `.godot` 与 `__pycache__` 可重新生成，但 `.import`、`.uid`、`.blend`、原始包和证据图不是同类缓存。索引保留这些差异；本轮未清理任何文件。
4. `.auto-*` 不迁入“开启”状态；只需要历史时复制具体中断证据。不要复制旧进程锁后据此判断新机器存在工作进程。
5. 检查 Python/Godot/Blender、磁盘空间和外部用户数据。根启动器大多使用相对目录；部分生成脚本和历史清单含 `C:\GameMake`。搜索并逐项核对活跃脚本路径，不全局替换原始历史内容。
6. `ConversationBackups/LATEST.json` 目前存绝对 manifest 路径；移根目录后依据 [HISTORY_INDEX.md](HISTORY_INDEX.md) 中相对路径查找同一快照，再只更新实时指针，不篡改旧 manifests/objects。历史全文里的原绝对路径保留溯源意义。
7. `docs/auto_resume_config.json` 的 seed_thread_ids 指向原机器本地记录。对话副本可离线读，但不会自动成为新机器应用内部的同名对话；手动接手不依赖这些 ID。
8. 对比全文件索引、必要资源路径和备份清单；运行交接校验与适当游戏检查后，保存新环境的验收记录。不要把旧机器结果改名成新测量。

## 历史导出与自动接续

只导出本地历史可执行 `python tools/auto_resume.py export`，不会打开面板或派发制作。导出源仅限工作目录为本项目的本机记录；导出当前仍在工作的对话会形成当时快照，不包含它之后尚未发生的消息。需要最终回复后的完整归档，可在该对话结束后再次导出。

开启自动化用根面板，停止用 F8/停止按钮/Stop-Auto-Resume.cmd。明确连接失败会保存并恢复；10分钟无进展或工具运行30分钟阈值以配置为准。当前工作对话禁止自建其他对话、任务或子代理，迁移由已获用户启用的唯一控制器管理。需要细节时读 [AUTO_RESUME.md](../AUTO_RESUME.md)，不要试运行自动派发来验证文档。
