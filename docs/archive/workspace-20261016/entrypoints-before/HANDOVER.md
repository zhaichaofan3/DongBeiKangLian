# 新项目接手入口：《烽火回声 · 林海归途》

交接整理日期：2026-10-13（Asia/Shanghai）。这是现有工程的交接入口；新项目应接手 `C:\GameMake` 中的成果，不要重新从空工程制作。

## 按这个顺序阅读

1. [PROGRESS.md](PROGRESS.md)：当前进度、最近检查点和下一步。
2. [AGENTS.md](AGENTS.md)：工作、备份、自动推进和历史记录规则。
3. [完整交接总说明](docs/PROJECT_HANDOVER.md)：现状、目录、系统、资源、验收边界与全部交接附件。
4. [后续 S12–S36 执行清单](docs/handover/NEXT_STEPS.md)：每步输入、动作、交付和验收。
5. [给新项目的首条消息](docs/handover/NEW_PROJECT_PROMPT.md)：可直接复制使用。

截至本次交接，S01–S11 已完成，S12–S36 未开始。P00 是本轮交接文档工作，不计入 36 个游戏步骤。唯一结构化状态源仍是 [production_state.json](docs/production_state.json)。本次请求只完善交接，不开始 S12。

运行当前源码用 [Start-Game.cmd](Start-Game.cmd)。`Release/` 仍是旧 0.6.1 发布基线，不含 S07–S11 新内容。自动接续保持停止；手动接手不需要启动面板。

所有文档、逐文件索引和对话归档可离线阅读。完整迁移需要工程、素材、工具、文档、历史备份与对话对象一起保存，仅复制本页或最近一份 planning 检查点不能恢复整款游戏。
