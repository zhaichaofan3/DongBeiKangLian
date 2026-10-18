# 工具说明

从项目根目录运行。Godot、Blender及本机Python依赖目录不进入Git，安装方法见 [开发指南](../docs/DEVELOPMENT.md)。

## 日常入口

| 工具 | 用途 |
|---|---|
| 根 `Start-Game.ps1` | 运行游戏，`-Editor`编辑器 |
| 根 `Build-Game.ps1` | 导入与安全替换PCK，并拷贝运行时与许可 |
| 根 `Package-Game.ps1` | 将已验证运行包制作为Windows中文安装版与免安装版，说明源在`docs/player/` |
| `configure_delivery_assets.gd` | Godot运行；新增/修改场景贴图后重算原图SHA-256与导入参数一致的共用资源和导出清单，普通构建无需重复运行 |
| `audit_player_pack.py` | 读取Godot PCK v4并核对每项MD5；可对比保留贴图逐字节一致性 |
| `verify_size_release.py` | 0.7.3资源/名称/首关/村庄/渡河/开场/导航及画质专项，串行；不代替全量回归 |
| `verify_distribution.py` | 校验下载、解压、独立QA安装/运行/卸载，保护已有玩家安装、快捷方式与存档 |
| 根 `Test-Game.ps1` | 完整回归，`-Release`验证独立包，必须串行 |
| `Find-Godot.ps1` | GODOT_EXE、本地工具、PATH或WinGet定位引擎 |
| `Verify-RiverJourney.ps1` | 渡河、密林、存档与跳过专项，支持-Release、-Headless与-EvidenceRoot |
| `Verify-PolishRevision.ps1`及其他Verify工具 | 对应专项画面与交互检查，运行前查看参数 |
| `Test-OptimizationPackage.ps1` | 0.7.2的9组独立包专项，捕获完整退出日志 |
| `Test-OptimizationRender.ps1` | 0.7.2的8组有画面包检查，串行测1080p画质、地图、压弹、上岸、导航与实战 |
| `Record-OptimizationValidation.ps1` | 0.7.2的33组源码、9组独立包专项与有画面结果汇总；必须先完成对应验证 |
| `Record-CourtyardValidation.ps1` | 历史0.7.1的31组验证汇总；不可用于当前包 |

## 模型制作

| 工具 | 输入与注意事项 |
|---|---|
| `build_user_soldiers.py` | 从用户人物批次`imported/`适配动作；可能覆盖现有人物 |
| `build_user_expansion.py`、`build_user_waterfront.py`、`build_user_fence.py` | 从场景批次`imported/`生成初版；最终村庄和棚屋另由`revise_settlement.py`修订 |
| `revise_settlement.py` | 完整原农村、棚屋贴图及电报房处理；运行前读当前源版本 |
| `build_courtyard_passages.py` | 从现有`village_4.blend`派生双侧门大院，不覆盖原模型；用于窄街穿院路线 |
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

`package_game.py`核对既有运行包验收并生成精简玩家包，`verify_distribution.py`实际解压、安装、运行和卸载测试；`publish_distribution.py`只上传已通过本地安装验证且哈希一致的产物，先创建草稿并核对GitHub接收的文件摘要，再公开发布。后者属于发布操作，仅在用户授权发行时运行，不替换已公开版本。安装工具来源见`installer/README.md`。

`Verify-RepositoryBuild.ps1`验证便携构建和独立包；`verify_fresh_clone.py`为本轮空目录远端下载、素材哈希、首次导入及运行验证入口，输出使用固定日期目录，已有验证副本时不得直接覆盖。
