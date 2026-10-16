# 工具说明

从项目根目录运行。Godot、Blender及本机Python依赖目录不进入Git，安装方法见 [开发指南](../docs/DEVELOPMENT.md)。

## 日常入口

| 工具 | 用途 |
|---|---|
| 根 `Start-Game.ps1` | 运行游戏，`-Editor`编辑器 |
| 根 `Build-Game.ps1` | 导入与安全替换PCK，并拷贝运行时与许可 |
| 根 `Test-Game.ps1` | 完整回归，`-Release`验证独立包，必须串行 |
| `Find-Godot.ps1` | GODOT_EXE、本地工具、PATH或WinGet定位引擎 |
| `Verify-RiverJourney.ps1` | 渡河、密林、存档与跳过专项，支持-Release、-Headless与-EvidenceRoot |
| `Verify-PolishRevision.ps1`及其他Verify工具 | 对应专项画面与交互检查，运行前查看参数 |

## 模型制作

| 工具 | 输入与注意事项 |
|---|---|
| `build_user_soldiers.py` | 从用户人物批次`imported/`适配动作；可能覆盖现有人物 |
| `build_user_expansion.py`、`build_user_waterfront.py`、`build_user_fence.py` | 从场景批次`imported/`生成初版；最终村庄和棚屋另由`revise_settlement.py`修订 |
| `revise_settlement.py` | 完整原农村、棚屋贴图及电报房处理；运行前读当前源版本 |
| `build_field_character.py`、`guard_identity_geometry.py` | 基础人物与头部特征 |
| `refine_fp_hands.py` | 玩家手部源加工，修改后检查持枪与拉栓 |
| `build_s10_buildings.py`、`build_s12_landscape_assets.py`、`build_s21_tianchi.py` | 现有建筑、自然和天池源生成；名称保留历史编号，不代表当前步骤状态 |
| `third_party/max_importer/` | MAX开发转换插件，保留其许可证 |

用Blender `--background --python tools/对应脚本.py`运行模型脚本。当前派生Blender源优先于初版批量生成器，先核对输出，避免覆盖后续改造。

## 音频与历史工具

用户对白原件、重录版和当前选用文件各有清单。带日期的 `integrate_*`、`replace_*`与`prepare_s*`是特定批次制作工具，可能读取原机器Downloads/Music路径，不能当作新电脑安装步骤；新电脑运行游戏无需重做导入。当前声音候选仍待听审。

旧自动调度器、全量检查点、旧步骤生成器和只服务一次的汇总脚本已退役删除。保留的检查/导入脚本仍可能有历史输出路径，先阅读后使用。

## 本轮维护

`repository_maintenance.py`生成目录大小清单，`verify_repository.py`校验受保护运行文件、模型迁移及待提交内容。`Apply-RepositoryCleanup.ps1`、`prepare_repository_cleanup.py`与`organize_project_records.py`是本轮一次性整理工具，不应重复执行迁移或删除。审计见docs/maintenance/repository-20261016。

`publish_repository.py`通过Git凭据管理器访问本项目GitHub仓库，不保存凭据。生成包放Releases，当前源与素材放Git/LFS。
