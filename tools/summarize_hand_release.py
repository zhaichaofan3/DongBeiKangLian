"""Collect actual 0.6.1 validation logs and make a labelled render comparison."""
import hashlib
import json
import pathlib
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[1]
RELEASE = ROOT / "Release"
font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 24)
small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 19)
canvas = Image.new("RGB", (1440, 1350), "#18222a")
draw = ImageDraw.Draw(canvas)
draw.text((32, 18), "第一人称双手 · 0.6.1 制作对比", font=font, fill="#edf0eb")
draw.text((32, 60), "继续制作前（上次已保存的动作）", font=small, fill="#aebac0")
draw.text((740, 60), "本轮完善后（正式游戏包实拍）", font=small, fill="#b9d6ac")
rows = [
    ("pistol", "驳壳枪握持：椭圆袖口、缝线与腕部过渡", (580, 340, 1280, 720)),
    ("reload", "步枪压弹：手掌与手指轮廓、翻边袖口", (150, 240, 1010, 707)),
    ("bolt_02_open", "步枪后拉：右手跟随拉柄，布料随手腕弯曲", (420, 250, 1280, 717)),
]
captures = RELEASE / "hand-captures"
for row, (name, title, crop) in enumerate(rows):
    y = 110 + row * 410
    draw.text((32, y), title, font=small, fill="#edf0eb")
    for col, directory in enumerate((ROOT / "tools/grip-final", captures)):
        image = Image.open(directory / (name + ".png")).convert("RGB")
        image = image.crop(crop).resize((680, 369), Image.Resampling.LANCZOS)
        canvas.paste(image, (32 + col * 708, y + 33))
output = ROOT / "docs/hand-refinement-comparison.jpg"
canvas.save(output, quality=94)

markers = {"basic": "SMOKE RESULT", "linear": "LINEAR ROUTE RESULT", "motion": "VISUAL MOTION RESULT",
           "story": "STORY MOMENTS RESULT", "character": "CHARACTER MODEL RESULT"}


def collect(path):
    text = path.read_text(encoding="utf-8-sig")
    assert not re.search(r"^(SCRIPT ERROR|ERROR):", text, re.M), path
    results = {}
    for name, marker in markers.items():
        match = re.search(re.escape(marker) + r": (\d+)/(\d+) passed", text)
        assert match and match[1] == match[2], (path, marker)
        results[name] = int(match[1])
    assert "ACTIVE COMBAT ROUTE: PASS" in text and "state=won" in text
    return results


source = collect(ROOT / "tools/hands-source-regression.log")
release = collect(RELEASE / "hands-regression.log")
capture_log = (RELEASE / "hands-motion-capture.log").read_text(encoding="utf-8-sig")
assert "VISUAL MOTION RESULT: 60/60 passed" in capture_log
assert not re.search(r"^(SCRIPT ERROR|ERROR):", capture_log, re.M)
images = []
for path in sorted(captures.glob("*.png")):
    with Image.open(path) as im:
        assert im.size == (1280, 720)
        images.append({"path": path.relative_to(RELEASE).as_posix(), "width": im.width, "height": im.height})
assert len(images) == 10
sheet = Image.new("RGB", (1280, 1950), "#18222a")
sheet_draw = ImageDraw.Draw(sheet)
for index, capture in enumerate(images):
    x, y = (index % 2) * 640, (index // 2) * 390
    path = RELEASE / capture["path"]
    sheet_draw.text((x + 12, y + 2), path.stem, font=small, fill="#edf0eb")
    with Image.open(path) as im:
        sheet.paste(im.convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (x, y + 30))
sheet.save(captures / "contact-sheet.jpg", quality=90)
report = {
    "date": "2026-10-13", "timezone": "Asia/Shanghai", "version": "0.6.1",
    "scope": "Refined first-person hand meshes, curved wrist sleeves and cuff details; completed prior grip and bolt work",
    "files": [{"path": str(RELEASE / name), "bytes": (RELEASE / name).stat().st_size,
               "sha256": hashlib.sha256((RELEASE / name).read_bytes()).hexdigest()}
              for name in ("FenghuoEcho.exe", "FenghuoEcho.pck")],
    "commands": ["Test-Game.ps1", "Build-Game.ps1", "Test-Game.ps1 -Release",
                 "Release runtime from temporary directory, external visual_motion.gd controller, FENGHUO_MOTION_SEQUENCE=1, 1280x720"],
    "source_checks": source, "release_checks": release, "assertions_per_target": sum(release.values()),
    "combat_route": {"passed_source_and_release": True, "guards_defeated": 9, "state": "won", "human_difficulty_validated": False},
    "hand_capture_run": {"checks": 50, "image_output_checks": 10, "total_passed": 60},
    "captures": images,
    "historical_captures": "verification-captures and character-captures remain from 0.6, dated 2026-10-12; not regenerated in 0.6.1",
    "hand_assets": json.loads((ROOT / "AssetLibrary/first_person/field_hands/build-report.json").read_text(encoding="utf-8")),
    "evidence": ["tools/hands-source-regression.log", "Release/hands-regression.log", "Release/hands-motion-capture.log", "docs/hand-refinement-comparison.jpg"],
    "limitations": ["Stylized model, retained source skin color texture; no new scanned or sculpted skin detail",
                    "Contact checks are tolerance and joint-proxy checks, not full surface collision proof",
                    "No new performance benchmark or human playtest"]
}
(RELEASE / "release_validation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"source_checks": source, "release_checks": release, "total": sum(release.values()),
                  "release_captures": len(images), "comparison": str(output)}, ensure_ascii=False))
