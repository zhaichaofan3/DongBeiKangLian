# 音频检索记录与缺口

2026-10-12：检索作者官网 Kenney、OpenGameArt。按真实枪声、拉栓/装填、弹壳、草/土/木/雪脚步、布料、纸张、木门、森林风/河流、电台/电器、潜入音乐逐类搜索，实际下载23条目。具体source_url与保存页面见manifest。未宣称穷尽互联网。

## 已找到的重要内容

- Free Firearm Sound Library 原始 CSV 和WAV metadata可识别有坂、莫辛纳甘、Springfield 1917、1911和PPSh，同时也含现代AK/AR等音色；现代项只作素材库存，没有自动套进抗联武器。
- Gary Handling Guns 有 .22WMG 栓动、30-06 bolt/load/accessories、M1911与霰弹枪操作；不能将这些声音标称为三八式精确机械录音。
- Q009含shell弹壳、换弹和爆炸；声音偏游戏化，尚未逐个试听筛入。
- 木板、草土、碎石、雪地、布料、门、纸、电台静电和莫尔斯已有可用来源。

## 暂未下载或需进一步处理

- Kenney `/assets/footstep-sounds` 返回404；已用Fantozzi、多地表脚步、Kenney Impact中的脚步补齐。
- OGA `gunshot-sounds` 有莫辛但页面自述录音设备承受音量欠佳，评论提背景噪音，故改用96kHz/24bit Free Firearm，不重复下载低质候选。
- OGA `forest-bird-sounds` 说明为MP3播放器录制且评论指出底噪，没有优先选用；森林环境来自Blender Foundation。
- OGA JC Sounds Nature Ambient Pack 有26条长环，但页面讨论了购买素材库二次处理的来源问题；本轮采用有明确独立来源的其他素材，未下载。
- `frequency-static-sound-effects` 11段各42MB，内容与已下载电台静电重叠，未整包堆积。
- 尚缺经过考据的三八式拉栓/桥夹装填完整同步组、C96专用操作组、中文抗联/日语敌人配音和适合最终故事节奏的定制音乐。当前Morse是环境素材，不是经过校验的剧情明文电文。

## 范围与判断

文件可解码不等于最终声场质量。所有声音尚需在动作事件、枪口距离、室内/室外混响、总音量与音乐ducking中校准。本轮已将3项实际接入游戏，但没有改任务脚本或玩法。原型的单一脚步流暂不具备按材质切换能力，预备变体已备齐。
