# 工具入口

请从项目根目录执行。运行游戏只需Release包，制作工具不随试玩分发。

## 日常使用

| 工具 | 用途 |
|---|---|
| 根Start-Game.ps1 / Start-Game.cmd | 从源码运行；-Editor进入编辑器 |
| 根Build-Game.ps1 | 导入资源，安全替换发布PCK |
| 根Test-Game.ps1 | 源码完整回归；-Release从源码目录外复测；证据在docs/validation/ |
| Verify-PolishRevision.ps1 | 帽星、低位持枪、室内行走、近战手臂和全屏拖动；支持-Release、-Headless；新批次指定-EvidenceRoot避免覆盖旧证据 |
| Find-Godot.ps1 | 定位Godot 4.7.2 |
| Save-WorkCheckpoint.ps1 / work_checkpoint.py | 更新唯一状态并复制校验检查点，见docs/WORKFLOW.md |
| Organize-Workspace.ps1 | 整理预览；显式-Apply才归档或去重 |

## 模型源

| 工具 | 用途 |
|---|---|
| build_field_character.py | 生成可编辑field_character.blend与游戏GLB |
| build_user_soldiers.py | 把本批用户人物几何与贴图适配到现有13骨动作；读取docs/user-models-20261015内原始导入工程 |
| inspect_user_max_models.py / preview_user_max_models.py | 本批MAX导入检查与候选预览；不是游戏运行入口 |
| finalize_user_models_20261015.py | 仅本批人物替换的源码、发布、第一人称保留和文件完整性汇总 |
| guard_identity_geometry.py | 日军特征和我军帽星几何，绑定头骨 |
| refine_fp_hands.py及手部相关工具 | 第一人称手模型，先核对对应制作记录 |
| 天池、建筑生成工具 | 派生源，先查看对应步骤文档和命令 |

人物生成示例：

```powershell
& .\tools\blender-4.5.14-windows-x64\blender.exe --background --python tools/build_field_character.py
```

## 本轮对白

`integrate_user_dialogue_20261015.py`保存最初9份Music录音并接入8句；`replace_user_dialogue_takes_20261015.py`再应用用户后续Downloads两句替换。需要重新导入时按此顺序执行，不能只运行第一项而覆盖后续选用。原件、当前SHA-256与逐句去向分别保存在AssetLibrary/audio/dialogue_20261015/、dialogue_retake_20261015/及GodotProject/assets/audio/user_dialogue_20261015/manifest.json。

`export_dialogue_list_20261015.py --output docs/audio/dialogue_retake_20261015/Dialogue`导出当前已配音与静音台词；`finalize_user_dialogue_20261015.py`在源码、独立发布回归及真实播放证据均齐备后核对并汇总本轮交付。人物修正结果继续保留于原固定验收目录。

## 历史工具与环境

- `archive_*`、带日期的`finalize_*`、S07草案生成器和旧摘要脚本服务于当时批次，可能有固定路径、旧分镜与检查数量。它们保留历史用途，不能直接覆盖当前正式数据或报告。
- `benchmarks/`、`*-verification/`、`grip-*`、`hands-*`和`checkpoints/`是历史实验材料，按对应文档阅读。
- `Godot-4.7.2/`、`blender-4.5.14-windows-x64/`、`asset_python/`是本地运行环境，不是冗余游戏资源。
- `downloads/`保存原始安装压缩包及校验；原根目录Godot压缩包已归到这里。
- 散落旧日志移至`docs/archive/workspace-20261015/tool-logs/`；仍被旧工具直接读取的日志保留原位。映射见`docs/user-polish-20261015/organization/cleanup.json`。
- 自动接续沿用唯一控制器，日常制作和目录整理不创建或启动新的控制器。
