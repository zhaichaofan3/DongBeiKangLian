"""Download the selected public model files and Tianchi elevation data."""
import concurrent.futures
import hashlib
import json
import math
import re
import struct
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests
from PIL import Image
from research_assets import ROOT, EVIDENCE, fetch, Page

sys.stdout.reconfigure(encoding="utf-8")
MANIFEST = ROOT / "manifest.json"
POLY = [
    ("pagoda_red", "1zS7ucaAd4J", "红色多层塔楼", "Poly by Google", "CC-BY-3.0", "大型视觉地标；泛东亚风格，不能称为东北实景复原"),
    ("pagoda_hall", "d1M5ncMBUDi", "传统殿堂建筑", "Poly by Google", "CC-BY-3.0", "建筑展示或中远景底模，需核对屋顶地域风格"),
    ("pagoda_tower", "eHOI2VgW1ol", "多层佛塔", "Poly by Google", "CC-BY-3.0", "古建筑展示地标，风格化塔楼"),
    ("warehouse", "fsxbktzB1zo", "完整废旧仓库", "Lavender Harmony", "CC-BY-3.0", "林场仓储区的大体块；按1938背景改造设施和标识"),
    ("log_cabin_scene", "2gQe0wyzkhb", "木屋与周边环境整景", "Poly by Google", "CC-BY-3.0", "远景林区聚落底模；并非东北传统民居考据模型"),
    ("village_market", "0TsHLxX6CB", "成组村镇集市", "Quaternius", "CC0-1.0", "成套布景；更换花哨篷布与西式装饰后用于集散区"),
    ("market_stalls", "fmHUuX9AS3", "紧凑摊棚组合", "Quaternius", "CC0-1.0", "填充空地和街边的组合布景底模"),
]
assets = []


def save():
    MANIFEST.write_text(json.dumps({"date": "2026-10-13", "purpose": "个人非商用游戏及文旅展示素材",
                                   "assets": assets}, ensure_ascii=False, indent=2), encoding="utf8")


def download(url, path, md5=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        part = path.with_suffix(path.suffix + ".part")
        with requests.get(url, headers={"User-Agent": "GameMakeAssetResearch/1.0"}, stream=True, timeout=40) as r:
            r.raise_for_status()
            with part.open("wb") as out:
                for chunk in r.iter_content(1024 * 1024):
                    out.write(chunk)
        part.replace(path)
    raw = path.read_bytes()
    if md5:
        assert hashlib.md5(raw).hexdigest() == md5, path
    return {"path": path.relative_to(ROOT).as_posix(), "download_url": url, "bytes": len(raw),
            "sha256": hashlib.sha256(raw).hexdigest()}


def inspect_model(path):
    raw = path.read_bytes()
    if path.suffix == ".glb":
        assert raw[:4] == b"glTF" and struct.unpack_from("<I", raw, 8)[0] == len(raw)
        size = struct.unpack_from("<I", raw, 12)[0]
        doc = json.loads(raw[20:20+size])
    else:
        doc = json.loads(raw)
    triangles = sum(doc["accessors"][p["indices"]]["count"] // 3 if "indices" in p else
                    doc["accessors"][p["attributes"]["POSITION"]]["count"] // 3
                    for m in doc.get("meshes", []) for p in m["primitives"] if p.get("mode", 4) == 4)
    dependencies = [x["uri"] for k in ("buffers", "images") for x in doc.get(k, [])
                    if "uri" in x and not x["uri"].startswith("data:")]
    assert all((path.parent / f).is_file() for f in dependencies), dependencies
    return {"meshes": len(doc.get("meshes", [])), "triangles_unique_meshes": triangles,
            "materials": len(doc.get("materials", [])), "external_dependencies": dependencies}


for aid, uid, title, author, license_, notes in POLY:
    name = "poly_pagoda_detail" if uid == "1zS7ucaAd4J" else "poly_detail_" + uid
    page = fetch(name, "https://poly.pizza/m/" + uid)
    url = re.search(r"https://static.poly.pizza/[a-zA-Z0-9-]+\.glb", page).group()
    path = ROOT / "models" / aid / (aid + ".glb")
    files = [download(url, path)]
    assets.append({"id": aid, "title": title, "source_url": "https://poly.pizza/m/" + uid, "author": author,
                   "license": license_, "notes": notes, "status": "downloaded_structure_verified",
                   "entry": path.relative_to(ROOT).as_posix(), "files": files, "geometry": inspect_model(path)})
    save()
    print("MODEL", aid, files[0]["bytes"], flush=True)

catalog = json.loads((EVIDENCE / "polyhaven_models.json").read_text(encoding="utf8"))
for aid, title, notes in [
    ("modular_factory_facade", "砖砌厂房与仓库立面整套", "可拼大型林场厂房和仓库；需要自行补屋顶、背墙、室内、碰撞和年代适配"),
    ("chinese_screen_panels", "中式屏风整套", "室内空间分隔与陈设"),
    ("chinese_tea_table", "中式茶桌", "电报房／院落展示的辅助道具"),
    ("wicker_basket_01", "编织大筐", "仓储和生活区填充道具")]:
    data = json.loads(fetch("ph_" + aid, "https://api.polyhaven.com/files/" + aid))
    model = data["gltf"]["2k"]["gltf"]
    folder = ROOT / "models" / aid
    filename = Path(urlparse(model["url"]).path).name
    tasks = [(filename, model)] + list(model.get("include", {}).items())

    def one(task):
        rel, data = task
        path = (folder / rel).resolve()
        assert path.is_relative_to(folder.resolve())
        result = download(data["url"], path, data.get("md5"))
        assert result["bytes"] == data["size"]
        if path.suffix.lower() in ("jpg", ".jpg", ".png"):
            with Image.open(path) as im:
                im.verify()
        return result

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        files = list(pool.map(one, tasks))
    assets.append({"id": aid, "title": title, "source_url": "https://polyhaven.com/a/" + aid,
                   "author": ", ".join(catalog[aid].get("authors", {})), "license": "CC0-1.0", "notes": notes,
                   "status": "downloaded_structure_verified", "entry": (folder / filename).relative_to(ROOT).as_posix(),
                   "files": files, "geometry": inspect_model(folder / filename)})
    save()
    print("MODEL", aid, sum(x["bytes"] for x in files), flush=True)

# Four by four public Terrarium elevation tiles covering the Tianchi caldera.
zoom = 13
lon, lat = 128.055, 42.006
cx = int((lon + 180) / 360 * 2**zoom)
cy = int((1-math.asinh(math.tan(math.radians(lat)))/math.pi)/2 * 2**zoom)
tile_inputs = [(x, y) for y in range(cy-2, cy+2) for x in range(cx-2, cx+2)]


def tile(job):
    x, y = job
    url = f"https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{zoom}/{x}/{y}.png"
    result = download(url, ROOT / "terrain/source" / f"{zoom}_{x}_{y}.png")
    with Image.open(ROOT / result["path"]) as im:
        assert im.size == (256, 256)
        im.verify()
    result.update(x=x, y=y, zoom=zoom)
    return result


with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    tiles = list(pool.map(tile, tile_inputs))
terrain = {"center": {"longitude": lon, "latitude": lat}, "zoom": zoom, "tiles": tiles,
           "lake_outline_source": "https://www.openstreetmap.org/relation/11650508",
           "lake_outline_file": "evidence/tianchi_osm.txt",
           "height_decode": "R*256 + G + B/256 - 32768 meters", "model_status": "source_downloaded"}
(ROOT / "terrain/source.json").write_text(json.dumps(terrain, ensure_ascii=False, indent=2), encoding="utf8")
print("TERRAIN_SOURCE", len(tiles), flush=True)
print("COLLECTION_COMPLETE", len(assets), sum(f["bytes"] for a in assets for f in a["files"]), flush=True)
