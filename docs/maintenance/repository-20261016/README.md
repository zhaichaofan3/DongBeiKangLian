# 仓库精简与首次上传

本轮由用户于2026-10-16明确授权：删除冗余备份及低价值资源，保留必要文字记录，重写README与大阶段历史，并上传至zhaichaofan3/DongBeiKangLian。

## 已执行清理

- 初始扫描：160.061 GiB，160329个文件，遍历无错误。
- 旧检查点/旧发布副本等第一批：约142.479 GiB。
- 未采用声音与人物集合、重复画面、转储、实验模型等第二批：约5.557 GiB。
- 退役自动系统、旧步骤状态及一次性汇总工具；旧根设计文档归入docs/archive/design-notes。
- 整理后有效工作文件约13.074 GiB，17178文件。此数不含新建Git对象库；Godot缓存、当前试玩与一份冷恢复点仍在本机。

当前运行代码与选用资产保留；用户原包、必要制作源和原录音保留。9份模型导入输入移入AssetLibrary并逐项核对SHA-256。保留6张地图/过河代表画面，其余历史画面和大型故障转储精简为文字记录。

## 保留与排除

最后整理前恢复点：WorkBackups/20261016-144654-S10-done-f0cbe4，重新校验2170文件、3162203059字节。旧36步状态只存在此冷备份和静态历史摘要中，不再作为当前制作状态。

Git上传Godot源工程、选用资产、制作素材、必要工具和文字记录。Godot缓存、安装工具、生成Release、私人ConversationBackups及本地恢复点均不上传；大二进制使用Git LFS，试玩包单独发布到Releases。

## 证据

| 文件 | 内容 |
|---|---|
| before.json、after-cleanup.json | 前后盘点；不包含Git对象库 |
| backup-plan.json、resource-plan.json、retired-tools-plan.json | 明确删除目标与原因 |
| deletions.jsonl | 实际删除审计 |
| checkpoint-history.json | 旧检查点文字摘要 |
| model-migrations.json、document-migrations.json | 模型/文档迁移路径 |
| protected-files.json、repository-validation.json | 运行文件保护基线与核对结果 |
| import.log、source-smoke.log | 本轮导入与源码检查日志 |

当前运行相关1253文件保持原始字节；9份迁移模型输入一致；待提交内容无私人备份、缓存目录及常见凭据签名。本轮源码导入、便携构建、源码108项及从源码目录外运行的独立包108项通过。日志为build.log、source-smoke.log、release-smoke.log。Git远程、Releases与最终磁盘结果仍在验证中，完成后追加。
