# 文件管理说明

当前唯一在用工程是`GodotProject/`，当前试玩包是`Release/`。按用途查找，无需翻遍原始素材库。

| 要找的内容 | 位置 |
|---|---|
| 启动、操作、任务路线 | 根README、Release/README.md |
| 最后完成项、下一步、最新备份 | PROGRESS.md、production_state.json |
| 本轮修订证据 | user-polish-20261015/ |
| 最近一次统一测试 | validation/source/、validation/release/；下次测试会更新 |
| 各步骤固定历史证据 | level/Sxx/、audio/、user-revision-20261015/ |
| 目录迁移、去重与哈希 | user-polish-20261015/organization/cleanup.json |
| 旧截图和日志归档 | archive/workspace-20261015/；完全相同的副本由清单指向已有证据 |
| 原始素材、可编辑源 | ../AssetLibrary/；实际选用说明见../GodotProject/ASSET_SOURCES.md |
| 活跃工具 | ../tools/README.md |
| 历史交接目录 | PROJECT_HANDOVER.md、PROJECT_FILE_CATALOG.html，保留其制作日期 |
| 备份与恢复 | WORKFLOW.md、../WorkBackups/LATEST.txt |
| 完整对话与附件 | ../ConversationBackups/ |

## 整理规则

1. 正式游戏资产进入`GodotProject/assets/`；原始下载、来源和Blender源留在`AssetLibrary/`。
2. 测试日志、截图放在`docs/validation/`或带日期的步骤证据目录，不堆在源码和试玩包根目录。
3. `Release/`用于交付。旧验证材料移入文档归档，原位置、最终去向、大小与SHA-256保存在清单中。
4. 只有与保留副本SHA-256相同的重复文件才删除。不同内容先复制、核验后移出原目录。Python字节码缓存和空的编辑器模板目录可重新生成。
5. 不删除原始下载、许可、可编辑源、历史备份、恢复现场和对话原文。停用Unity骨架保留在`GameProject/`，不参与构建。
6. 不随意重命名游戏资产和工具入口；Godot引用、构建和备份工具依赖稳定路径。

原根目录Godot压缩包现位于`tools/downloads/godot-standard-4.7.2.zip`，内容未变；实际运行引擎仍位于`tools/Godot-4.7.2/`。历史文档中的旧路径可查清单。`.godot/`是可重建缓存；本轮保留活跃导入缓存，避免下次打开重新导入全部资产。

推荐维护顺序：修改、专项检查、记录与检查点、完整回归、构建、从源码目录外测试发布包、更新发布清单、最终备份校验。

`tools/Organize-Workspace.ps1`默认仅生成预览，`-Apply`才修改目录。`-IncludeReleaseEvidence`用于明确的历史发布证据整理批次，不在每次构建时自动运行，避免移走当前交付的验收摘要。
