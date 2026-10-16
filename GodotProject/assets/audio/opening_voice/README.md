# 临时合成开场语音

2026-10-15新指令：本目录仅保留历史排演素材，不再用于当前游戏，也不打入新版发布包。当前开场只按opening.json中明确标为user_supplied_recording的条目播放用户录音；缺录音台词保留字幕并静音。以下内容为原制作说明。

本目录的 29 个 WAV 来自 2026-10-15 本地 Windows System.Speech / Microsoft Kangkang 排演生成。

- N01–N15：用户指定历史旁白，逐字对应 `docs/narrative/S04/narration_original.txt`。
- B1-L01–B6-L02：S05 的沈砚／姜岚原创任务对白。
- 这是临时合成语音，已按用户选择接入当前本地开场排演；不代表最终演员配音。
- 录音替换接口按 cue id 读取，之后只需替换同名 WAV 并重新验证时长和字幕；不改旁白文字。
- 源生成参数、原始 WAV SHA-256 和处理记录：`AssetLibrary/audio/S31_20261015/synthesis.json`、`alignment.json`。
- 发行前仍需完成真人听感、发音和版权／分发核对；0.7.0-rc1本地候选包已包含这些临时语音。
