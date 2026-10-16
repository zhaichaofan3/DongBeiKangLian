# S31 旁白、对白与字幕同步验收

2026-10-15。根据用户选择，先采用明确标注的本机合成语音，之后可替换演员录音。临时合成声已经接入开场运行时；S28/S29音效和音乐仍待试听，不能把本步结果写成最终声音成品。

## 接入内容

- 历史序章 N01–N15：15句固定旁白，输入与 `docs/narrative/S04/narration_original.txt` 逐字一致，SHA-256 与 S04 记录一致。
- 任务序幕 B1-L01–B6-L02：14句沈砚／姜岚原创对白。
- 29个同名 WAV 放在 `GodotProject/assets/audio/opening_voice/`；`opening_director.gd` 按 cue id 加载，替换同名文件即可换录音，不改台词或镜头时轴。
- 来源：Windows System.Speech / Microsoft Kangkang，本机离线合成。它是排演音频，不是演员录音；目录 README、`synthesis.json` 和 `alignment.json` 保留参数与哈希。
- 旁白 A 为 80.000 秒，任务 B 为 80.100 秒；字幕使用既有 cue 窗口，没有重叠或截断样本。

## 验证

- 临时语音接入专项 8/8：29个文件加载、Voice bus、N01/B1触发、同 cue 不重复、暂停、跳过和离开过场清理。
- 开场状态回归 41/41；S24 对话表演 11/11。
- 全项目回归：Smoke107/107、Linear37/37、Combat PASS、Visual Motion50/50、Story11/11、Character37/37。
- 各项使用 `--qa` 与隔离存档；日志在本目录。技术验证不代表已完成演员听感、发音、情绪表演或最终混音。

## 后续替换边界

本步可以标记完成，因为用户已明确授权先用临时合成声制作。替换演员录音时，按同一 cue id 更新 WAV，重新检查每句时长、字幕、开场 41 项和完整回归；固定旁白文字不可改。S28/S29 听审完成后，再把选定音效和音乐用于 S30，并按听感重新校准 Voice／Music／Ambience 音量。发布包未更新。
