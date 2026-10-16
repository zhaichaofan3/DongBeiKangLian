"""Curate verified local assets and publicly listed candidates into a browsable index."""
import hashlib
import html
import io
import json
import math
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys

import requests
from PIL import Image, ImageDraw, ImageFont

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parent


def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf8")


def read(path):
    return json.loads(path.read_text(encoding="utf8"))


corrections = {
    "pagoda_red": ("五层塔楼（偏日式）", "备用", "高耸地标底模。外观偏日式，保留为备用，不作为东北或中国古建代表。"),
    "pagoda_hall": ("三层楼阁（偏日式）", "备用", "原目录称 Pagoda，实物为三层楼阁；屋顶与立面偏日式。原始尺度异常，接入时需重设尺寸。"),
    "pagoda_tower": ("双层圆亭塔（风格化）", "建筑", "红柱绿顶的低面圆亭塔，可作远景点缀；造型简化，不对应具体景点。"),
    "warehouse": ("敞顶仓库结构", "建筑", "带木墙与钢架的大型敞顶仓库。适合作为林场仓储背景底模，屋顶、封闭墙面及年代细节需补齐。"),
    "log_cabin_scene": ("木屋与周边环境整景", "建筑", "木屋、栈台、地面和围栏整景。可作林区聚落底模，属通用木屋，非东北民居复原；需统一尺度。"),
    "village_market": ("成组村镇集市", "布景", "多个布篷摊位组成的整组模型，能快速填充空地；需调整鲜艳篷布与装饰，并校正偏小的原始尺度。"),
    "market_stalls": ("成组果蔬摊棚", "布景", "成组果蔬货架与木制摊棚，适合市场或集散区布景；原始尺度偏小，需按人物高度放大。"),
    "modular_factory_facade": ("砖砌厂房立面模块套件", "建筑", "192 个网格构成的砖墙、门窗与细部模块，可拼大型厂房或仓库。当前是零件展列，需自行组装建筑。"),
    "chinese_screen_panels": ("中式屏风整套", "布景", "带传统纹样的屏风，可填充院内或室内陈设。"),
    "chinese_tea_table": ("中式茶桌", "布景", "适合茶室、民居、院落陈设；小道具，需搭配大型建筑使用。"),
    "wicker_basket_01": ("编织方筐", "布景", "约 38 厘米宽的小筐，适合市场、仓储和生活区的近景点缀。"),
}

manifest = read(ROOT / "manifest.json")
reviews = {a["id"]: a for a in read(ROOT / "import-review.json")}
for asset in manifest["assets"]:
    title, category, notes = corrections[asset["id"]]
    asset.update(title=title, category=category, notes=notes,
                 status="downloaded_blender_and_godot_import_verified",
                 visual_review="2026-10-13; see notes and local preview",
                 preview=reviews[asset["id"]]["preview"],
                 source_dimensions_blender_xyz=reviews[asset["id"]]["dimensions_source_units"])
    assert not reviews[asset["id"]]["missing_images"]
manifest["downloaded_group_count"] = len(manifest["assets"])
manifest["downloaded_model_bytes"] = sum(f["bytes"] for a in manifest["assets"] for f in a["files"])
manifest["game_integration_status"] = "collected_for_selection; not_added_to_main_game"
save_json(ROOT / "manifest.json", manifest)

# Search results and model metadata were saved during collection; retain evidence.
cached = {}
for file in (ROOT / "evidence").iterdir():
    if not file.name.startswith(("sf_", "sketchfab_")) or file.name.endswith("_request.json"):
        continue
    try:
        data = read(file)
    except (ValueError, UnicodeError, IsADirectoryError):
        continue
    for model in data.get("results", [data]):
        if model.get("uid"):
            uid = model["uid"]
            if uid not in cached or len(model.get("description", "")) > len(cached[uid].get("description", "")):
                cached[uid] = model | {"evidence_file": str(file.relative_to(ROOT)).replace("\\", "/")}

selection = [
    ("f8429f52abb14798a5b180541797160b", "天池火山口地形", "文旅地形", "优先", "作者说明采用 ASTER 高程和 Esri 影像，约 51 万三角面，最贴近天池文旅展示方向。"),
    ("20985473ab8743f784c05cd01716fff3", "长白山大型地形", "文旅地形", "优先", "长白山整体山体，约 52 万三角面，可作为另一个大范围地形候选。"),
    ("24e2a51cb75d4e23b11939f55bdfec7c", "吉林长白山白云峰", "文旅地形", "补充", "约 6.9 万三角面，适合长白山山峰展示候选；覆盖范围以作者页面为准。"),
    ("eb129dba5f594b059dfa1444e13f65b1", "长白山鹿鸣河地形", "文旅地形", "补充", "约 6.7 万三角面，可补充山地、河谷展示内容。"),
    ("a18881525cfd4fe882e739c9c7cee752", "传统四合院完整院落", "大型建筑", "优先", "作者说明为北京四合院，含植被和院落；约 59.7 万三角面，适合整体展示。属于北京建筑，不能当作东北实景。"),
    ("ed4ea9eb5f024d989eec182d48fa72d8", "中式八角楼（低面）", "大型建筑", "补充", "仅 7,672 三角面。作者标题包含 Courtyard，但预览是单栋八角楼，不能计作完整四合院。可作街区地标。"),
    ("571eb702c8ba413a9a83843fa5428c4a", "街景建筑与道具套件", "大型建筑", "补充", "约 1.5 万三角面。预览为建筑及道具散件展列，需要组合成街区；造型混合东亚元素，需筛选。"),
    ("d5e673e13b774deba137bd2e99af8e65", "中式街景", "大型建筑", "优先", "约 1.3 万三角面，作为街景候选，需下载后核实尺度、贴图和通行空间。"),
    ("1b055a0bbfc14111b5cc62e5644efffa", "四合院", "大型建筑", "补充", "约 14.2 万三角面，庭院类备选。"),
    ("2998e6b0769d461d8780f16438a1a896", "Siheyuan 四合院", "大型建筑", "补充", "约 1.7 万三角面，较轻的庭院类备选。"),
    ("2f09fe07f72e4f3dbfb0eebabf978788", "古风亭式构件（高面数）", "建筑构件", "备用", "预览是单个亭式构件，并非整片建筑场景；约 150 万三角面，面数很高，仅列为备用。"),
    ("e96e36a7ba2e47028879ec58e4a06f24", "哈尔滨大剧院候选", "东北文旅", "待核对", "作者描述指向哈尔滨大剧院，但标题写作 Zaha Hadid，与描述中的 MAD／马岩松不一致；下载前需核对外形。现代建筑可用于文旅场景。"),
    ("075a0a6251bc4c0492337063c053c979", "东北炕", "特色布景", "补充", "4,452 三角面，地方特色明确的室内小场景元素，适合民居展陈。"),
]

candidates = []
for uid, title, category, priority, notes in selection:
    model = cached[uid]
    images = model.get("thumbnails", {}).get("images", [])
    thumb = min(images, key=lambda v: abs(v["width"] - 640)) if images else {}
    candidates.append({
        "uid": uid, "title": title, "original_title": model["name"], "category": category,
        "priority": priority, "notes": notes, "triangles": model.get("faceCount"),
        "source_url": model.get("viewerUrl", "https://sketchfab.com/3d-models/" + uid),
        "author": model.get("user", {}).get("displayName"),
        "license": model.get("license", {}).get("label"),
        "is_downloadable_on_source": model.get("isDownloadable"),
        "status": "listed_downloadable_login_required_not_downloaded",
        "evidence": model["evidence_file"], "thumbnail_source_url": thumb.get("url"),
        "source_description": model.get("description", ""),
    })

for title, number, author, size, notes in [
    ("中国宫殿建筑群", 14878, "Mikel007", "47 MB", "作者标注 5,147 个对象、835,210 个面，含贴图；适合大场面展示。"),
    ("中国寺庙", 24990, "floppino", "16 MB", "完整寺庙方向的 Blender 工程候选。"),
    ("Wutai Pagoda 风格化塔楼", 25891, "maurishaberle", "16.8 MB", "风格化古塔，可作为地标候选，需核实地域形制。"),
]:
    candidates.append({"title": title, "category": "大型建筑", "priority": "补充", "author": author,
                       "source_url": f"https://www.blendswap.com/blend/{number}",
                       "listed_size": size, "notes": notes,
                       "status": "login_required_not_downloaded"})


def thumbnail(candidate):
    if not candidate.get("thumbnail_source_url"):
        return
    path = ROOT / "previews" / ("candidate_" + candidate["uid"] + ".jpg")
    try:
        if not path.exists():
            response = requests.get(candidate["thumbnail_source_url"], timeout=25)
            response.raise_for_status()
            im = Image.open(io.BytesIO(response.content)).convert("RGB")
            im.thumbnail((640, 480))
            im.save(path, quality=88)
        candidate["thumbnail"] = "previews/" + path.name
        candidate["thumbnail_note"] = "作者页预览图；不是已取得的模型文件"
    except Exception as error:
        candidate["thumbnail_error"] = str(error)


with ThreadPoolExecutor(max_workers=5) as pool:
    list(pool.map(thumbnail, candidates))
save_json(ROOT / "candidates.json", {"checked_date": "2026-10-13", "candidates": candidates})

font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 19)


def contact(items, name, path_key, caption_key):
    sheet = Image.new("RGB", (1200, math.ceil(len(items) / 3) * 295), (25, 30, 37))
    draw = ImageDraw.Draw(sheet)
    for i, item in enumerate(items):
        x, y = (i % 3) * 400, (i // 3) * 295
        im = Image.open(ROOT / item[path_key]).convert("RGB")
        im.thumbnail((392, 253))
        sheet.paste(im, (x + (392-im.width)//2, y + (253-im.height)//2))
        draw.text((x + 8, y + 260), item[caption_key], font=font, fill="white")
    sheet.save(ROOT / "previews" / name, quality=93)


contact(manifest["assets"], "contact_sheet.jpg", "preview", "title")
contact([c for c in candidates if c.get("thumbnail")], "candidate_contact_sheet.jpg", "thumbnail", "title")

esc = html.escape


def link(label, target, **kwargs):
    return f'<a href="{esc(target, quote=True)}">{esc(label)}</a>'


def local_card(asset):
    triangles = asset["geometry"]["triangles_unique_meshes"]
    return f'''<article class="card" data-group="local"><a href="{asset['preview']}"><img loading="lazy" src="{asset['preview']}" alt="{esc(asset['title'])}"></a>
    <div class="cardbody"><span class="tag">已下载 · {asset['category']}</span><h3>{esc(asset['title'])}</h3>
    <p>{esc(asset['notes'])}</p><small>{triangles:,} 三角面（不计实例重复） · {esc(asset['author'])}</small>
    <nav>{link('模型文件', asset['entry'])}{link('来源页面', asset['source_url'])}</nav></div></article>'''


def candidate_card(c):
    picture = f'<img loading="lazy" src="{c["thumbnail"]}" alt="{esc(c["title"])} · 作者页预览">' if c.get("thumbnail") else '<div class="placeholder">BLENDER 工程候选</div>'
    triangles = f'{c["triangles"]:,} 三角面' if c.get("triangles") else c.get("listed_size", "")
    return f'''<article class="card" data-group="candidate">{picture}<div class="cardbody"><span class="tag pending">尚未下载 · 需登录</span>
    <h3>{esc(c['title'])}</h3><p>{esc(c['notes'])}</p><small>{esc(triangles)} · {esc(c.get('author') or '')}</small>
    <nav>{link('查看作者页面 / 下载入口', c['source_url'])}</nav></div></article>'''


page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>中国与东北 · 大型场景素材库</title><style>
:root{color-scheme:dark;--bg:#10171d;--panel:#1b2630;--fg:#edf3ef;--muted:#a8babd;--accent:#b7d7bc}*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 'Microsoft YaHei',sans-serif}main{max-width:1380px;margin:auto;padding:45px 36px}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}h1{font-size:42px;margin:7px 0 14px;letter-spacing:2px}h2{font-size:27px;margin:0}h3{font-size:20px;margin:12px 0 8px;line-height:1.4}
p{margin:8px 0 16px}.eyebrow{color:var(--accent);letter-spacing:3px;font-size:13px}.lead{color:var(--muted);max-width:840px}.hero{display:grid;grid-template-columns:1.2fr 1fr;background:var(--panel);border-radius:18px;overflow:hidden;margin:30px 0}.hero img{width:100%;height:100%;object-fit:cover}.herotext{padding:32px}.herotext h2{font-size:32px}.stats{display:flex;gap:20px;margin:20px 0;color:var(--accent)}.stats b{font-size:23px;display:block}.stats span{font-size:13px}
nav{display:flex;gap:16px;flex-wrap:wrap;margin-top:18px}nav a{padding:5px 0;font-size:14px}.action{display:inline-block;background:var(--accent);color:#102218;border-radius:8px;padding:10px 20px;font-weight:bold}.sectionhead{margin:38px 0 22px}.sectionhead p{color:var(--muted)}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:22px}.card{background:var(--panel);border:1px solid #30404a;border-radius:13px;overflow:hidden;display:flex;flex-direction:column}.card img{width:100%;height:228px;object-fit:contain;background:#222d38;display:block}.cardbody{padding:22px;flex:1}.card p{color:#cfdbdd;font-size:14px;min-height:70px}.card small{color:var(--muted);font-size:12px}.tag{font-size:12px;color:#b9ddc2}.pending{color:#e9c993}.placeholder{height:228px;background:linear-gradient(140deg,#314544,#1c2836);display:grid;place-items:center;letter-spacing:3px;color:var(--muted)}
.toolbar{display:flex;gap:8px;flex-wrap:wrap;margin:25px 0}button{border:1px solid #3e515e;color:var(--fg);background:#23323d;padding:9px 18px;border-radius:20px;cursor:pointer;font:inherit;font-size:14px}button.active{background:var(--accent);color:#142719}footer{border-top:1px solid #30404a;margin-top:45px;padding-top:20px;color:var(--muted);font-size:13px}code{color:#d6e9d9}[hidden]{display:none!important}@media(max-width:1050px){.grid{grid-template-columns:repeat(2,1fr)}.hero{grid-template-columns:1fr}.hero img{max-height:460px}}@media(max-width:620px){main{padding:22px 16px}.grid{grid-template-columns:1fr}h1{font-size:29px}.herotext{padding:23px}.stats{gap:15px}.card img{height:240px}}
</style><main><div class="eyebrow">烽火回声 / 场景资源采集 / 2026.10.13</div><h1>中国与东北 · 大型场景素材库</h1>
<p class="lead">面向大场景展示、东北环境补景与文旅内容的素材选择页。已保存 11 组下载模型和 1 套天池地形样板；现成四合院、街景与天池候选另列，状态一目了然。</p>
<section class="hero"><a href="previews/tianchi_crater.png"><img src="previews/tianchi_crater.png" alt="天池公开高程样板"></a><div class="herotext"><span class="tag">本地可用 · 两档精度</span><h2>长白山天池</h2><p>依据公开高程与 OpenStreetMap 湖岸制作，山体、火山口、湖面可独立展示。</p><div class="stats"><div><b>14.54 km</b><span>每侧覆盖范围</span></div><div><b>13.3 / 52.6 万</b><span>含湖面的三角面</span></div></div><p class="lead">使用示意配色，未包含景区建筑、观景台或道路设施。适合地形概览与镜头排练，宣传成片仍需完善地表和景点细节。</p>
<a class="action" href="Open-3D-Viewer.cmd">打开 3D 浏览器</a><p><small>如浏览器阻止启动，请在同目录双击 <code>Open-3D-Viewer.cmd</code>。拖动旋转、滚轮缩放，支持自动环绕。</small></p><nav><a href="terrain/tianchi_display_lod.glb">轻量模型 · 4.8 MiB</a><a href="terrain/tianchi_display.glb">精细模型 · 15.3 MiB</a><a href="terrain/tianchi_display.blend">Blender 工程</a><a href="README.md">完整说明</a></nav></div></section>
<div class="toolbar" aria-label="筛选资源"><button class="active" data-filter="all">全部</button><button data-filter="local">已下载模型 · 11 组</button><button data-filter="candidate">网上候选 · 16 项</button></div>
<section data-section="local"><div class="sectionhead"><h2>已下载 · 建筑与布景</h2><p>已完成 Blender 导入、贴图检查和 Godot 导入。原始比例不统一，3D 浏览器会自动调整展示尺寸；正式接入前仍需设定米制尺度与碰撞。</p></div><div class="grid">'''
page += "\n".join(local_card(a) for a in manifest["assets"])
page += '''</div></section><section data-section="candidate"><div class="sectionhead"><h2>网上候选 · 优先补齐大型中式场景</h2><p>以下是作者页面与下载入口，模型文件尚未取得；Sketchfab／BlendSwap 的下载需要登录。图片为作者页预览。优先看天池、四合院和街区三类。</p></div><div class="grid">'''
page += "\n".join(candidate_card(c) for c in candidates)
page += '''</div></section><footer>这是素材选择与展示库，尚未加入正式关卡。来源、作者及使用条件已保存在 <a href="manifest.json">本地清单</a>、<a href="candidates.json">候选清单</a>和 <a href="terrain/source.json">地形来源</a>中。<br>天池地形：Mapzen / Tilezen 公共高程；湖岸：© OpenStreetMap contributors。非测绘成果，非实景摄影测量。<br><a href="previews/contact_sheet.jpg">本地模型总览图</a> · <a href="previews/candidate_contact_sheet.jpg">网上候选总览图</a> · <a href="godot-import-review.json">导入检查结果</a></footer></main>
<script>for(const button of document.querySelectorAll('[data-filter]'))button.addEventListener('click',()=>{for(const b of document.querySelectorAll('[data-filter]'))b.classList.toggle('active',b===button);for(const section of document.querySelectorAll('[data-section]'))section.hidden=button.dataset.filter!=='all'&&button.dataset.filter!==section.dataset.section;});</script></html>'''
(ROOT / "index.html").write_text(page, encoding="utf8")

builds = read(ROOT / "terrain/build-report.json")
for item in builds:
    item["sha256"] = hashlib.sha256((ROOT / "terrain" / item["file"]).read_bytes()).hexdigest()
save_json(ROOT / "terrain/build-report.json", builds)
source = read(ROOT / "terrain/source.json")
source.update(model_status="generated_and_blender_godot_verified", attribution="Mapzen/Terrarium elevation tiles via Tilezen/Joerd; © OpenStreetMap contributors for lake outline", attribution_reference="evidence/elevation_attribution.txt", osm_license="ODbL 1.0", outputs=builds)
save_json(ROOT / "terrain/source.json", source)
print(json.dumps({"local_groups": len(manifest["assets"]), "local_model_bytes": manifest["downloaded_model_bytes"], "candidates": len(candidates), "candidate_thumbnails": sum(bool(c.get("thumbnail")) for c in candidates)}, ensure_ascii=False))
