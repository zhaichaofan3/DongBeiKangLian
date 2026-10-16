# 0.3 原型验证记录

日期：2026-10-12（北京时间）。适用于当前源码与 **0.3《林海归途》东北抗联版本**。Godot 4.7.2 stable，Windows，NVIDIA RTX 5060 Laptop，驱动 616.92，OpenGL 3.3 GL Compatibility。

## 本次音频资源更新与发布复测

已实际进入当前 `.pck` 的外部音频只有三项：`assets/audio/rifle_arisaka_01.wav`、`step_grass_01.wav`、`forest_wind_loop.wav`。分别用于步枪单发、草土脚步与森林风循环，均为48kHz单声道PCM16。资源库 `../AssetLibrary` 为工程外库存，其余模型、动作、材质、音乐和音频尚待适配，未随本次音频改动自动进入游戏。手部与人物仍为程序分节低模。

枪声从多发录音中截取一发，时长2.55秒、峰值-6dBFS；脚步0.243秒、峰值-14dBFS；森林风循环8.585秒、RMS约-28dBFS，交叉淡化后首尾PCM样点为0。作者将枪声原录音标为 Arisaka / .30-06，未将其宣称为经过考据的三八式原装弹药录音。作者、许可及加工说明见 `ASSET_SOURCES.md`。

| 本次验证 | 结果 | 证据 |
|---|---|---|
| 音频来源和派生文件完整解码 | 原音频510/510，派生52/52；另3项游戏WAV通过 | `../AssetLibrary/audio/audio_validation.json`、`ready_to_import.json`、`game_integration.json` |
| Godot导入及音频专用源码检查 | PASS，WAV类型/时长/采样率/循环/接缝和其余声音接口 | `../AssetLibrary/audio/godot-import.log`、`godot-audio-check.log` |
| 修改后源码基础检查 | 76/76 | `../AssetLibrary/audio/godot-smoke.log` |
| 正式资源包构建 | 成功，包含三项WAV导入资源 | `../AssetLibrary/audio/release-build.log` |
| 实际exe/pck基础检查 | 76/76 | `../Release/integration.log` |
| 实际exe/pck动作检查 | 41/41 | `../Release/visual-motion.log` |
| 实际exe/pck正常交火整关路线 | PASS，won、生命93、击败5人；自动控制57.083秒 | `../Release/combat-route.log` |
| 实际exe/pck音频专用检查 | PASS，从TEMP启动实际exe，不传`--path` | `../AssetLibrary/audio/release-audio-check.log` |

本次运行 `Build-Game.ps1`、`Test-Game.ps1 -Release`，原有117项基础/动作检查全部通过，另正常交火路线与音频专用检查通过。自动路线时间不代表真人游玩时长。音频变更没有重复GPU截图或性能测试；下方截图和性能数值保留为此前0.3视觉版的历史证据。未完成逐条主观试听或最终耳机混音验收。

## 此前0.3视觉版交付与修复

接回上次连接中断前已保存的视觉代码，并把原 0.2 运行包更新到 0.3：

- 场景静态部件按材质/网格/空间区块合批；程序草木、纹理、分层远山、动态水面、飘叶与炉烟已进入运行包。
- 人物使用程序分节动作；双枪提供枪机、弹夹、双手装填、平滑瞄准、后坐和切枪过渡。这不是完整骨骼/动捕资产。
- 渡口实心墙的可见部分改成低护岸/细栏杆，保留原碰撞与寻路边界；草、落叶、散砾避开栈桥。木船移到岸外且调整吃水，降低水面的过强反光。
- 画质三档、帧率上限、垂直同步、全屏、鼠标灵敏度、音量、武器晃动支持持久化；F3 显示帧率。
- 动作回归纳入统一源码/运行包测试，补强切枪中断和恢复检查点：等待超过原装填剩余时长，确保不会延迟获得弹药，隐藏武器机制也能复位。

## 此前0.3视觉版实测结果

以下为音频更新前的视觉与性能验证记录。基础、交火、动作的运行包同名日志已由上方本次复测更新；GPU截图和性能记录仍属于此前视觉版。

| 验证 | 结果 | 证据 |
|---|---|---|
| 编辑器导入、脚本解析、资源导出 | 成功 | `build.log` |
| 源码基础检查 | 76/76 | `smoke.log` |
| 源码动作检查 | 41/41 | `visual-motion.log` |
| 源码正常交火整关路线 | PASS，won、生命 93、击败 5 人 | `combat-route.log` |
| 实际 exe / pck 基础检查 | 76/76 | `../Release/integration.log` |
| 实际 exe / pck 动作检查 | 41/41 | `../Release/visual-motion.log` |
| 实际 exe / pck 正常交火整关路线 | PASS，won、生命 93、击败 5 人 | `../Release/combat-route.log` |
| 两种窗口尺寸 GPU 渲染 | 源码与运行包均成功，各 16 张场景截图 | 两边的 `render-1280x720.log`、`render-960x540.log` |
| GPU 动作序列 | 41 项行为 + 10 项图片写入，共 51/51 | `visual-motion-render.log`、`verification-captures/motion` |
| 运行包 1080p 三档画质性能 | 均成功，无脚本/资源错误 | `../docs/performance/release-*-1920x1080.json` |

运行包测试从系统 TEMP 启动 exe，不传 `--path`；外部测试控制脚本加载的 `res://main.tscn` 和游戏代码来自交付的 `.pck`。测试脚本、日志、截图、Markdown 均从资源包排除。

基础检查覆盖移动/碰撞/视线/命中、门与防夹、对话、补给选择和防重复领取、物资与家书、救援与包扎、跟随/等候、护送和共同撤离、死亡恢复、非法存档、画质切换、设置落盘与无效值恢复。动作检查采用真实玩家输入与计时，检查瞄准插值、枪机与手部变换、弹药结算、切枪取消装填及检查点恢复。

每个测试进程有 60 秒超时，同时检查退出码、错误日志和完成标记。QA/截图/动作验证与正式检查点及画质设置隔离，截图和动作正常完成后清除自己的临时文件。打包先写临时 `.pck`，成功后原子替换正式包。

## 性能对比

1080p，关闭垂直同步与帧率上限，每视角预热 1 秒、采样 3 秒。旧版为保留的 0.2 基线；新版为实际 0.3 运行包均衡档。只暂停玩家与 AI 的物理逻辑，环境渲染继续运行。

| 固定视角 | 0.2 平均 FPS | 0.3 均衡平均 FPS | 绘制调用/帧 | 新版平均帧时 ms | 新版 P99 帧时 ms |
|---|---:|---:|---:|---:|---:|
| 林道接头 | 157.6 | 485.4 | 4242 → 509 | 2.06 | 3.40 |
| 运材场 | 171.1 | 519.5 | 4196 → 444 | 1.92 | 3.04 |
| 电报房 | 193.4 | 505.0 | 3775 → 402 | 1.98 | 3.08 |

三处绘制调用减少约 88%–89%，这是本轮合批优化的直接证据。不同画质档位：

| 运行包画质 | 三视角平均 FPS 范围 | 绘制调用/帧范围 |
|---|---:|---:|
| 性能 | 528–585 | 312–392 |
| 均衡 | 485–519 | 402–509 |
| 画质 | 456–487 | 423–532 |

默认实际游玩为均衡、120 FPS 上限、开启垂直同步，因此游戏中的显示帧率会受设置和显示器刷新率约束。以上为短时固定相机测量，不是完整战斗、真人游戏时长、正式 1% low 或最低配置验收；不同硬件和后台负载会影响结果。

原始报告：[0.2 基线](../docs/performance/baseline-balanced-1920x1080.json)、[0.3 均衡](../docs/performance/release-balanced-1920x1080.json)、[性能档](../docs/performance/release-performance-1920x1080.json)、[画质档](../docs/performance/release-quality-1920x1080.json)。旧包留在 `../tools/benchmarks/fenghuo-0.2.pck` 供复现。

## 画面检查

源码和运行包均生成 1280×720、960×540 两组各八张图：标题、设置、姜岚对话、运材场、电报房、陆山救援、行动记录、渡口。正式交付证据在 `../Release/verification-captures/<尺寸>`。

重点目视核查了 720p 的人物对话/三选项、室内、运材场、渡口，以及 540p 设置/记录/渡口：中文与操作入口可见，设置页没有截断；栈桥不再被地表草穿插，栏杆后能看到木船上沿与水面，远山不再呈光滑球状。动作序列目视检查了步枪瞄准、步枪和驳壳枪装填：枪机、弹夹、手部能显示与运动。人物/手部仍是分节低模，精细皮肤、脸部表演和武器外观仍需进一步制作与考据。

`iteration3` 和没有尺寸子目录的更早截图属于调试历史，最终验收以两组尺寸目录及本轮动作序列为准。

## 复现

工作目录 `C:\GameMake`：

```powershell
./Test-Game.ps1 -Capture
./Build-Game.ps1
./Test-Game.ps1 -Release -Capture
./Test-Performance.ps1 -Release -Quality balanced -Resolution 1920x1080 -Label release
./Test-Performance.ps1 -Release -Quality performance -Resolution 1920x1080 -Label release
./Test-Performance.ps1 -Release -Quality quality -Resolution 1920x1080 -Label release
```

GPU 动作序列用 `tests/visual_motion.gd`、`--qa`、`--fixed-fps 60`，并设置 `FENGHUO_MOTION_CAPTURE_DIR` 与可选的 `FENGHUO_MOTION_SEQUENCE=1`。默认统一动作测试为无窗口模式。

## 运行包与边界

本次音频更新后的 `FenghuoEcho.exe`：180,858,888 字节；`FenghuoEcho.pck`：1,229,872 字节。资源包 SHA-256：

`9C06B52FF9E57807B566C174541E5FE31F98070DE88EF59786F74F91A9737EA8`。

运行exe SHA-256：`AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424`。机器可读构建及验证摘要见 `../AssetLibrary/audio/release_validation.json`。资源包不包含整个AssetLibrary；素材署名随包保存在 `ASSET_SOURCES.md`。


可以离线运行，需保留同名 `.pck` 及随包许可。当前仍未验收真人完整通关、8–12 分钟节奏、最低配置、其他显卡/平台、手柄、完整骨骼动画、历史外观准确性；没有完整配音或音乐。开发模型服务的间歇 502 不影响本地游戏，见 [连接诊断与方案](../docs/connection_diagnosis_2026-10-12.md)。
