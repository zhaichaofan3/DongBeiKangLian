# 仓库精简与首次上传

本轮由用户于2026-10-16明确授权：删除冗余备份及低价值资源，保留必要文字记录，重写README与大阶段历史，并上传至zhaichaofan3/DongBeiKangLian。

## 已执行清理

- 初始扫描：160.061 GiB，160329个文件，遍历无错误。
- 旧检查点/旧发布副本等第一批：清单估算约142.479 GiB。
- 未采用声音与人物集合、重复画面、转储、实验模型等第二批：清单估算约5.557 GiB。清单可能含本轮临时生成后再删除的数据，最终净变化以末尾盘点为准。
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

阶段检查确认1253个运行相关文件保持原始字节、9份迁移模型输入一致，待提交内容无私人备份、缓存目录及常见凭据签名。源码导入、便携构建、源码108项及独立包108项通过，日志为build.log、source-smoke.log、release-smoke.log。远程与收尾结果见下节。

## 最终结果

**整理、上传与验证已完成。** 目录扫描无错误，234份旧检查点已删除，只保留1份完整恢复点；另清除64棵空历史目录树及4.645 GiB临时发布/验证副本。

| 占用 | GiB |
|---|---:|
| 整理前整个目录 | 160.061 |
| 整理后工作文件，含缓存/当前包/一份冷备份 | 13.074 |
| 新增本地Git与LFS对象库 | 5.399 |
| 整理后本地合计 | 18.473 |
| 实际净释放 | 141.588 |

净减少88.46%；3294条删除操作均有记录。字节数和扫描口径见cleanup-result.json、final.json。日志与收尾提交产生的少量文字差异不影响上述三位小数的规模。

- [仓库](https://github.com/zhaichaofan3/DongBeiKangLian)：1864个LFS文件引用、1459个独立对象，共5785928652字节全部在远端确认存在；本地Git LFS fsck通过。
- [试玩发布](https://github.com/zhaichaofan3/DongBeiKangLian/releases/tag/v0.7.0-rc1)：压缩包1338110902字节，服务端SHA-256与本地一致；校验文件已实际下载核对。40个分发文件的清单见release-SHA256SUMS.txt。
- 从GitHub重新克隆到空目录，实际下载并核对509个运行LFS文件；空缓存导入与108项运行检查通过。该验证副本随后删除。
- 当前工作目录源码108项、独立发布108项、空目录克隆108项分别通过。仅按本轮检查记录，不重复声称历史29组/1145项已重跑。
- 重新构建PCK的SHA-256仍为c76fae8ae40cf358458f962f75024d6da2f91c2c5eb84b07ce6f01d3627711a4，与整理前一致。
- 新入口文档的本地链接、固定完整旁白、受保护运行文件、模型输入迁移和常见凭据签名检查通过。

### 首次导入故障

空目录首轮在最初MP3导入附近发生0xc0000005原生异常，未写作成功；失败日志为clone-import-failure-1.log。导入命令原先同时使用`--import`和`--quit`。现移除多余的强制退出，仅使用等待导入完成并自行退出的`--import`；清空失败缓存后，完整导入及108项运行检查通过。此修正针对制作工具，不改游戏逻辑或音频原件；尚不据一次对比断言所有硬件上的引擎崩溃均已解决。

远端、下载和打包结果分别见remote-lfs-validation.json、github-release.json、fresh-clone-validation.json、package-validation.json。当前项目状态以根PROGRESS.md和Git记录为准。
