# 文件指南

更新于2026-10-16。按用途查找，正式工程和各类原始资料分别存放。

## 游戏与制作

| 内容 | 位置 |
|---|---|
| 正式工程、游戏脚本、测试 | `GodotProject/`，脚本在 `scripts/`，测试在 `tests/` |
| 已选用并适配的游戏资产 | `GodotProject/assets/`，来源见 [ASSET_SOURCES.md](../GodotProject/ASSET_SOURCES.md) |
| 当前试玩包 | `Release/`，运行 `FenghuoEcho.exe` |
| 源码启动、编辑、构建、回归 | 根目录 `Start-Game.*`、`Build-Game.ps1`、`Test-*.ps1` |
| 制作工具和本地引擎 | [tools/README.md](../tools/README.md)，安装原包在 `tools/downloads/` |
| 独立素材适配工程 | `AssetReview/`，预览、修复和导出验证，不参与正式关卡构建 |

表内路径均相对于项目根目录 `C:\GameMake`。

## 素材原件与可编辑源

| 内容 | 位置 |
|---|---|
| 七组用户环境模型原包与解压件 | `AssetLibrary/environment/user_expansion_20261015/` |
| 林场、农村、98k、水岸及铁丝网 Blender 源 | `AssetLibrary/derived/user_expansion_20261015/` |
| 用户日军与我军原包、MAX、贴图和适配源 | `AssetLibrary/characters/user_models_20261015/` |
| 原玩家手部可编辑源 | `AssetLibrary/first_person/field_hands/field_hands.blend` |
| 原始录音和派生音频 | `AssetLibrary/audio/`，本轮实际台词见 [对白替换记录](audio/dialogue_retake_20261015/review.md) |
| 早期采集与备用模型 | [素材库索引](../AssetLibrary/README.md)，按各批清单确认使用状态 |

## 文档、历史与备份

| 内容 | 位置 |
|---|---|
| 当前进度、计划、工作历史 | `PROGRESS.md`、`docs/production_state.json`、`docs/production_plan.md`、`docs/work_history.jsonl` |
| 最新首关重构证据 | `docs/first_level_rebuild_20261016/` |
| 按主题和日期保存的验收 | `docs/level/`、`docs/narrative/`、`docs/audio/` 及日期目录，见 [文档索引](README.md) |
| 本次移动前后文件清单 | [整理报告](maintenance/workspace-20261016/README.md) 中的 CSV 与 JSON |
| 本次归档旧日志和工具实验输出 | `docs/archive/workspace-20261016/logs/`、`tool-artifacts/` |
| 整理前各入口文档 | `docs/archive/workspace-20261016/entrypoints-before/`，保留原文 |
| 上次整理的历史材料 | `docs/archive/workspace-20261015/` |
| 独立检查点 | `WorkBackups/`，`LATEST.txt` 指向最近检查点；范围以各自 `checkpoint.json` 为准 |
| 历史试玩包与恢复现场 | `ReleaseBackups/`、`RestoreChecks/` |
| 完整对话、附件与内容对象 | `ConversationBackups/` |
| 停用 Unity 骨架 | `GameProject/`，不参与当前制作 |

## 后续收纳规则

1. 下载原包、许可、原始录音与可编辑源留在素材库；只把选用并适配完成的资源纳入正式工程。
2. 新测试、导入和构建日志写入对应日期的证据目录。工具工作输出依赖原路径时保留位置并登记，不盲目移动。
3. `docs/archive/` 保存历史；最新结论在当前索引中链接。旧文档中的路径失效时，先查询对应整理清单的 `source` 和 `destination`。
4. 缓存可按明确清单清理。重复的派生自动保存文件仅在独立完整检查点中找到同大小、同 SHA-256 的保留副本后删除；当前 `.blend`、原始包内文件与唯一版本保留。
5. 历史备份、恢复证据、对话对象、许可及来源记录不因版本旧而删除。内容相同但职责不同的源码资产、发布资产与原始素材，也不能直接当作冗余。
6. `.godot/` 和 `__pycache__/` 可重建；本次保留正式工程的已导入资源缓存，仅清理资源预览缓存及清单中明确的临时文件。

本次维护工具 [workspace_maintenance.py](../tools/workspace_maintenance.py) 的操作已写入 [operations.jsonl](maintenance/workspace-20261016/operations.jsonl)，逐项保留原路径、去向、大小和哈希；该批次不会覆盖重跑。2026-10-15的 `Organize-Workspace.ps1` 使用固定历史路径，保留作旧批工具，不用于新一轮整理。
