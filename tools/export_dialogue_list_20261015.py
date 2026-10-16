"""Export the current game dialogue to a local recording script."""

import json
import re
import argparse
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', default='docs/user-revision-20261015')
options = parser.parse_args()
OUT = ROOT / options.output
opening = json.loads((ROOT / "GodotProject/assets/opening/opening.json").read_text(encoding="utf-8-sig"))
runtime = json.loads((ROOT / "docs/user-revision-20261015/render-1280/dialogue-runtime.json").read_text(encoding="utf-8-sig"))
entries = []
for cue in opening["cues"]["B"]:
    entries.append({"id": cue["id"], "speaker": "姜岚" if cue["speaker"] == "scout" else "沈砚", "scene": "天池及任务开场", "text": cue["text"], "delivery": cue["delivery"]})
scenes = {"scout_intro": "林道初次接头", "scout_route": "询问详细路线（更新人数与三十秒目标）", "scout_repeat": "再次询问姜岚", "logger_intro": "向林师傅询问陆山与补给", "logger_repeat": "领取补给后再交谈", "lu_rescue": "电报房初次救援", "lu_untreated": "陆山未包扎时交谈", "lu_treated": "陆山已包扎时交谈", "ending": "共同撤离前的对话", "power": "切断电源", "river": "靠近河岸", "falling_behind": "陆山落在后面", "crossing": "护送穿过北侧通道", "contact": "敌人发现玩家", "cloth": "选择绷带后离开木棚", "departure": "离开接头地点"}
for index, item in enumerate(runtime, 1):
    entries.append({"id": f"G{index:02}", "speaker": item["speaker"], "scene": scenes[item["id"]], "text": item["text"]})
source = (ROOT / "GodotProject/scripts/story_moments.gd").read_text(encoding="utf-8-sig")
for index, (key, literal) in enumerate(re.findall(r'_say\("([^"\n]+)",\s*("(?:\\.|[^"\\])*")\)', source), 1):
    line = json.loads(literal)
    speaker, text = line.split("：", 1)
    entries.append({"id": f"F{index:02}", "speaker": speaker, "scene": scenes[key], "text": text})
source = (ROOT / "GodotProject/scripts/linear_director.gd").read_text(encoding="utf-8-sig")
for index, literal in enumerate(re.findall(r'"陆山：(?:\\.|[^"\\])*"', source), 1):
    line = json.loads(literal)
    speaker, text = line.split("：", 1)
    entries.append({"id": f"D{index:02}", "speaker": speaker, "scene": "渡口解缆", "text": text})
counts = Counter(item["speaker"] for item in entries)
recorded = {c['id'] for c in opening['cues']['B'] if c.get('voice_status') == 'user_supplied_recording'}
for entry in entries:
    entry['recording_status'] = 'supplied_and_integrated' if entry['id'] in recorded else 'silent_pending_recording'
lines = ["# 东北抗联-烽火回声：对话配音清单", "", "日期：2026-10-15。由当前工程中的开场字幕和运行时对白核对导出。", "", f"对白共{len(entries)}条，已接入{len(recorded)}条用户录音，余下{len(entries)-len(recorded)}条保留字幕、暂不发音：" + "；".join(f"{speaker}{amount}条" for speaker, amount in counts.items()) + "。", "", "## 录音约定", "", "每个编号单独录一条干声，开头结尾各留约半秒安静；不加配乐或混响。推荐WAV、48kHz、24bit，单声道即可。编号即文件名，如B1-L01.wav。标点作为停顿，不读出角色名、编号或场景名。", "", "姜岚：沉着、干练，关心战友但不煽情。沈砚：年轻、克制，紧张时语速稍快。陆山：有腿伤、气息偏弱但清楚，包扎后稍稳定。林守义：中年林工，朴实、压低声音。角色性别与具体声线可按现有演员安排。", "", "历史旁白《10月15日.mp3》已经接入，含新增两句，本清单不要求重录。日军板载叫喊、三条发现敌人语音也已提供并接入，无须重复录制。姜岚8句已接入；B5-L06撤离路线与B6-L01木棚台词使用用户后续提供的Downloads新版，先前版本保留备用。未提供录音的对白暂时静音，不回退到临时合成语音。", ""]
for speaker in counts:
    lines.extend([f"## {speaker}（{counts[speaker]}条）", ""])
    for entry in entries:
        if entry["speaker"] != speaker:
            continue
        status = '已接入用户录音' if entry['id'] in recorded else '待录音，当前静音'
        lines.extend([f"### {entry['id']} | {entry['scene']} | {status}", "", entry["text"], ""])
        if entry.get("delivery"):
            lines.extend(["表演提示：" + entry["delivery"], ""])
lines.extend(["## 可选补录（不计入必录数量）", "", "这些是现有对话选项中的人物答句，目前没有独立主角语音触发，需接入后才播放；其余“消耗绷带”等菜单命令不需要配音。", "", "- P01 沈砚：知道了。名单和陆山，都带回来。", "- P02 沈砚：记住了，开始行动。", "- P03 沈砚：谢谢。你也先隐蔽。", "- P04 沈砚：把名册收好，我们一起回山。", "", "家书是可阅读道具，现阶段不要求另录朗读。界面提示、目标、按键说明和计时数字不配音。", ""])
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "dialogue-recording-list.md").write_text("\n".join(lines), encoding="utf-8-sig")
(OUT / "dialogue-recording-list.txt").write_text("\n".join(lines), encoding="utf-8-sig")
(OUT / "dialogue-recording-data.json").write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"clips": len(entries), "roles": counts}, ensure_ascii=False))
