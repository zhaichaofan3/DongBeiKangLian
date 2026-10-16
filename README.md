# 烽火回声 · 林海归途

东北抗联题材原创单机第一人称游戏。故事发生在1938年深秋的虚构青岚林场与松岭屯，当前版本 **0.7.1-rc1**。使用 **Godot 4.7.2 / GDScript / GL Compatibility**，Windows为当前验证平台。

## 先运行起来

- **只想试玩：**到 [Releases](https://github.com/zhaichaofan3/DongBeiKangLian/releases) 下载Windows试玩包，解压后运行 `FenghuoEcho.exe`，保留同目录的PCK和来源文件。在线包目前为0.7.0-rc1，本轮0.7.1-rc1从下方本机入口或源码运行。
- **本机已有工程：**双击 `Start-Game.cmd`；编辑器入口为 `./Start-Game.ps1 -Editor`。
- **新电脑开发：**安装 [Git LFS](https://git-lfs.com/) 与 [Godot 4.7.2](https://godotengine.org/download/archive/)，再执行：

```powershell
git lfs install
git clone https://github.com/zhaichaofan3/DongBeiKangLian.git
cd DongBeiKangLian
git lfs pull
$env:GODOT_EXE = 'D:\Apps\Godot\Godot_v4.7.2-stable_win64_console.exe'
./Start-Game.ps1 -Editor
```

首次打开会重新导入模型和音频，需要等待。也可直接用Godot打开 `GodotProject/project.godot`。运行游戏不需要Python或Blender；模型制作建议Blender 4.5 LTS，工具脚本使用Python 3.11。环境与构建详情见 [开发指南](docs/DEVELOPMENT.md)。

## 当前内容

**接头林道 → 检查口 → 运输林道 → 木料场 → 装卸林道 → 电报房 → 护送 → 渡口掩护 → 双人顺流渡河 → 密林土路 → 松岭屯三段战斗。**

两段开场分别讲述历史背景和战友任务，历史段新增电报设备特写。首关采用304米纵深的折弯山谷；登船后顺流渡河，对岸沿土路穿过密林。村庄使用原“东北农村”的12组大型院落重新拼接，约3.6米窄街连接三处穿院巷战，分三段推进。保留原剧情、用户录音、第一人称手臂和98k模型。

WASD移动，Shift冲刺，C切换蹲伏（Ctrl按住蹲伏），Q/E按住左右探头，Space跳跃，鼠标射击/瞄准，R装填，F互动，H包扎，J记录，Esc暂停，Enter跳过当前演出。完整操作与存档说明见 [游戏说明](GodotProject/README.md)。

当前是候选版。新增渡河对白仍为字幕，声音听审、连续人物表演与美术观感、完整真人难度及其他硬件兼容性仍待验收。最新状态见 [PROGRESS.md](PROGRESS.md)。

## 文件放在哪里

| 路径 | 内容 |
|---|---|
| `GodotProject/` | 唯一正式工程；`scripts/`逻辑、`assets/`选用资产、`tests/`回归检查 |
| `AssetLibrary/` | 模型编辑源、必要导入输入、原始录音、来源与许可；[资源指南](AssetLibrary/README.md) |
| `tools/` | 引擎定位、模型处理、验证与维护脚本；[工具指南](tools/README.md) |
| `docs/` | [开发](docs/DEVELOPMENT.md)、[设计](docs/DESIGN.md)、[阶段历史](docs/PROJECT_HISTORY.md)、验证与维护记录 |
| `licenses/` | 引擎与第三方许可文件 |
| `Release/` | 本地生成的试玩包，通过GitHub Releases分发，不进入Git |
| `WorkBackups/` | 本地只保留一份整理前恢复点，不进入Git |

导入缓存、软件安装目录、私人对话备份及生成包均不上传。大模型和音频使用Git LFS；网页源码ZIP不能可靠取得完整LFS资产，请按上面的克隆流程操作。

## 开发与验证

```powershell
./Test-Game.ps1          # 全量源码检查，串行执行
./Build-Game.ps1         # 生成 Release/FenghuoEcho.exe 与 .pck
./Test-Game.ps1 -Release # 独立试玩包检查
```

地图、剧情、存档和模型修改入口见 [开发指南](docs/DEVELOPMENT.md)。接手先读本页、`PROGRESS.md`与开发指南；无需恢复旧36步状态或自动面板。后续用Git提交记录修改，以项目阶段和待办更新进度，避免反复复制整个文件夹。

## 来源与使用条件

本项目混合使用不同来源资源，**没有统一的MIT或CC0授权**。作者、来源及条件见 [ASSET_SOURCES.md](GodotProject/ASSET_SOURCES.md)。用户提供的部分素材未附完整外部分发许可，不能据公开仓库推定可商用或自由再授权。

删除清单、保留内容和本轮验证见 [整理记录](docs/maintenance/repository-20261016/README.md)。
