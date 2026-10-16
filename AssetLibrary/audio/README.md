# 东北抗联 FPS 音频资源库

采集日期：2026-10-12。已实际下载 23 个资源包/条目，保留原包、解包、来源页面、许可、SHA-256。原资源含 510 个可解码音频文件，共约 25 分钟；其中包含相同表演的不同格式、以及连续多次声音的长录音，不能把 510 理解成 510 个独立声效。另制作 52 个 48kHz 即用派生文件。

## 已接入现有游戏

只修改 `GodotProject/scripts/audio_factory.gd`，导入 `GodotProject/assets/audio/` 中三项：

- `rifle_arisaka_01.wav`：有坂枪声中剪出单发 2.55 秒，峰值 -6 dBFS。原作者 metadata 写的是 Arisaka / .30-06，属于音色参考，不能当作已考证的三八式原装弹药录音。
- `step_grass_01.wav`：草/土脚步 0.243 秒，峰值 -14 dBFS；现有单脚步缓存播放接口继续使用。木板/碎石/雪地变体尚未加入地表识别。
- `forest_wind_loop.wav`：森林和风声组合成 8.585 秒循环，RMS 约 -28 dBFS，600ms 交叉淡化与 2ms 接缝淡化，首尾PCM样点为0。

当前玩家枪声 -12dB、敌人 -16dB、脚步 -21dB、环境 -14dB 的播放器设置继续有效。手枪及装填暂时保留原接口已有声音；没有把1911标成C96。三份 `.wav.import` 明确保留PCM16、关闭额外归一化和压缩。署名已写入游戏音频目录 `CREDITS.md`。

## 索引

- `manifest.json`：全部资源、下载地址、字节数、SHA-256、来源/许可、解码验收及游戏接入映射。
- `audio_index.csv`：510 项原始/解包音频的路径、采样率、声道、时长。
- `audio_validation.json`：逐文件元信息、枪械注释、完整解码结果。
- `firearm_catalog.csv`：56 段枪械录音的人类可读枪型/距离说明，避免只看到 A_42P 这样的代号。
- `ready_to_import/` 与 `ready_to_import.json`：52个派生文件，包含15个历史枪型音色单发切片、24个草/木/碎石/雪地脚步、6个环境声、7个地图/开关/电台/机械声。每个都有原文件和修改记录。
- `game_integration.json`：实际接入3项的来源、修改、增益、时长与校验值。

## 验收

510/510 原音频与 52/52 派生音频通过 ffprobe 读取和 ffmpeg 完整解码；三个游戏WAV也独立完整解码通过。Godot 4.7.2 headless 导入无报错；类型、时长、采样率、单发非循环、循环边界、PCM接缝和原fallback接口检查通过；原游戏 smoke 76/76 通过。日志分别为 `godot-import.log`、`godot-audio-check.log`、`godot-smoke.log`。未做逐条主观试听和耳机混音验收。随后已完成正式资源包重建：运行包基础76/76、动作41/41、正常交火路线和音频专项检查通过；最终包尺寸/Hash见`release_validation.json`，此轮没有重复GPU性能测量。

| 资源 | 音频文件 | 采样率 | 声道 | 总时长 | 许可 |
|---|---:|---|---|---:|---|
| [The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library) | 56 | 96.0k | 2 | 597.5s | CC0-1.0 |
| [Handling Guns](https://opengameart.org/content/handling-guns) | 10 | 44.1k | 2 | 84.1s | CC-BY-SA-3.0 |
| [Gun reload sounds](https://opengameart.org/content/gun-reload-sounds) | 3 | 44.1k | 2 | 3.6s | CC0-1.0 |
| [Q009 weapon sounds](https://opengameart.org/content/q009s-weapon-sounds) | 32 | 44.1k | 1, 2 | 44.1s | CC-BY-SA-3.0 |
| [Ambient mountain, river, wind, forest and waterfall](https://opengameart.org/content/ambient-mountain-river-wind-and-forest-and-waterfall) | 6 | 44.1k | 1, 2 | 50.5s | CC-BY-3.0 |
| [Fantozzi footsteps grass/sand and stone](https://opengameart.org/content/fantozzis-footsteps-grasssand-stone) | 24 | 44.1k | 2 | 8.4s | CC0-1.0 |
| [Footsteps on different surfaces](https://opengameart.org/content/footsteps-on-different-surfaces) | 78 | 44.1k, 48.0k | 1 | 16.6s | CC-BY-3.0 |
| [42 snow and gravel footsteps](https://opengameart.org/content/42-snow-and-gravel-footsteps) | 42 | 44.1k | 2 | 25.6s | CC0-1.0 |
| [Footsteps leather, cloth, armor](https://opengameart.org/content/footsteps-leather-cloth-armor) | 12 | 44.1k | 2 | 2.9s | CC0-1.0 |
| [Cloth swing sounds](https://opengameart.org/content/cloth-swing-sounds) | 1 | 44.1k | 2 | 9.9s | CC-BY-3.0 |
| [Paper pages sounds](https://opengameart.org/content/paper-pages-sounds) | 1 | 44.1k | 2 | 4.5s | CC-BY-3.0 |
| [Opening and closing a map](https://opengameart.org/content/opening-and-closing-a-map-sounds) | 2 | 96.0k | 2 | 3.1s | CC0-1.0 |
| [Creaky light wooden door](https://opengameart.org/content/creaky-light-wooden-door) | 1 | 44.1k | 2 | 6.9s | CC-BY-3.0 |
| [Door open / close set](https://opengameart.org/content/door-open-door-close-set) | 36 | 44.1k, 96.0k | 2 | 36.0s | CC0-1.0 |
| [Super Foley Pack](https://opengameart.org/content/super-foley-pack) | 12 | 44.1k | 2 | 179.4s | CC-BY-3.0 |
| [Stealth in the Woods](https://opengameart.org/content/stealth-music) | 1 | 44.1k | 2 | 152.8s | CC0-1.0 |
| [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | 130 | 44.1k | 2 | 52.2s | CC0-1.0 |
| [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | 52 | 48.0k | 2 | 51.4s | CC0-1.0 |
| [Inventory Sound Effects](https://opengameart.org/content/inventory-sound-effects) | 6 | 44.1k | 2 | 4.2s | CC-BY-3.0 |
| [Mysterious Radio Signal](https://opengameart.org/content/mysterious-radio-signal) | 1 | 44.1k | 1 | 102.5s | CC-BY-3.0 |
| [Radio Noise 1](https://opengameart.org/content/radio-noise-1) | 1 | 8.0k | 1 | 55.2s | CC0-1.0 |
| [SFX Circuit breaker](https://opengameart.org/content/sfx-circuit-breaker) | 2 | 44.1k | 2 | 1.9s | CC0-1.0 |
| [Generator loop](https://opengameart.org/content/generator-loop) | 1 | 44.1k | 1 | 5.4s | CC0-1.0 |

## 使用建议

优先用已接入和ready_to_import中的文件做样板；原枪声WAV多为96kHz/24bit，含多次枪响，不要整段绑定单次开火。原布料、纸张和部分枪机录音包含多次动作，需要按动画事件切开。长环境和音乐更适合OGG，3D点声源优先单声道WAV。所有原资源均保留在本目录，不需要重复从网络下载。
