"""Prepare real public elevation + OSM shoreline, with illustrative land colors."""
import json
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "terrain"
source = json.loads((OUT / "source.json").read_text(encoding="utf8"))
tiles = source["tiles"]
x0, y0 = min(t["x"] for t in tiles), min(t["y"] for t in tiles)
z = source["zoom"]
elevation = np.zeros((1024, 1024), dtype=np.float32)
for t in tiles:
    rgb = np.asarray(Image.open(ROOT / t["path"]).convert("RGB"), dtype=np.float32)
    height = rgb[:, :, 0]*256 + rgb[:, :, 1] + rgb[:, :, 2]/256 - 32768
    x, y = (t["x"]-x0)*256, (t["y"]-y0)*256
    elevation[y:y+256, x:x+256] = height

osm = json.loads((ROOT / source["lake_outline_file"]).read_text(encoding="utf8"))
lake = next(e for e in osm["elements"] if e["type"] == "relation" and e["id"] == 11650508)
parts = [[(p["lon"], p["lat"]) for p in m["geometry"]] for m in lake["members"] if m.get("role") == "outer"]
ring = parts.pop(0)
while parts:
    for i, part in enumerate(parts):
        if ring[-1] == part[0]:
            ring += part[1:]
        elif ring[-1] == part[-1]:
            ring += list(reversed(part[:-1]))
        else:
            continue
        parts.pop(i)
        break
    else:
        raise ValueError("Shoreline ways do not form a connected ring")
assert ring[0] == ring[-1]


def pixel(lon, lat):
    x = ((lon+180)/360*2**z-x0)*256
    y = ((1-math.asinh(math.tan(math.radians(lat)))/math.pi)/2*2**z-y0)*256
    return x, y


outline = [pixel(lon, lat) for lon, lat in ring[:-1]]
mask_image = Image.new("L", (1024, 1024), 0)
ImageDraw.Draw(mask_image).polygon(outline, fill=255)
mask = np.asarray(mask_image) > 0
water_height = float(lake["tags"]["ele"])
print("SOURCE_LAKE_HEIGHTS", float(np.min(elevation[mask])), float(np.median(elevation[mask])), float(np.max(elevation[mask])), flush=True)
# The water mesh follows the real shoreline, while submerged DEM samples are
# recessed slightly. Lake bathymetry is not present in this surface dataset.
elevation[mask] = np.minimum(elevation[mask], water_height - 4)
meters_per_pixel = 2*math.pi*6378137*math.cos(math.radians(source["center"]["latitude"]))/(2**z*256)
extent_m = meters_per_pixel*1024
height_origin = 1500.0
np.save(OUT / "elevation_m.npy", elevation)
mask_image.save(OUT / "lake_mask.png")

# Artistic altitude/slope colors, explicitly not satellite photography.
dy, dx = np.gradient(elevation, meters_per_pixel)
slope = np.clip(np.sqrt(dx*dx+dy*dy), 0, 1)
alpine = np.clip((elevation-1950)/470, 0, 1)[..., None]
low = np.array([0.19, 0.28, 0.19])
high = np.array([0.50, 0.47, 0.39])
color = low*(1-alpine)+high*alpine
rock = np.clip((slope-0.25)*1.5, 0, 0.75)[..., None]
color = color*(1-rock)+np.array([0.43,0.42,0.39])*rock
rng = np.random.default_rng(1938)
color += rng.normal(0, 0.012, (1024,1024,1))
color[mask] = [0.035,0.16,0.24]
Image.fromarray((np.clip(color,0,1)*255).astype(np.uint8)).save(OUT / "terrain_color.png")

def geographic(tx, ty):
    return {"longitude": tx / 2**z * 360 - 180,
            "latitude": math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * ty / 2**z))))}


metadata = {"title": "长白山天池 · 公开高程展示样板", "reference_wgs84": source["center"],
            "model_origin_wgs84": geographic(x0 + 2, y0 + 2),
            "bounds_wgs84": {"northwest": geographic(x0, y0), "southeast": geographic(x0 + 4, y0 + 4)},
            "horizontal_extent_m": [extent_m, extent_m], "meters_per_pixel": meters_per_pixel,
            "height_origin_m": height_origin, "water_elevation_m": water_height, "water_display_offset_m": 0.8,
            "elevation_range_m": [float(elevation.min()), float(elevation.max())],
            "lake_outline_pixels": outline, "lake_outline_osm_relation": 11650508,
            "coordinate_note": "Local tangent approximation to Web Mercator at center latitude; x east, Blender y north, z height minus 1500m. Not a surveying product.",
            "color_note": "Altitude/slope-based illustrative colors, not aerial imagery or photogrammetry.",
            "data_source": "Mapzen/AWS elevation-tiles-prod Terrarium; source composition maintained by Tilezen/Joerd",
            "shoreline_source": "OpenStreetMap contributors, relation 11650508; retrieved 2026-10-13",
            "vertical_exaggeration": 1.0, "bathymetry": "Not included; submerged terrain recessed only for visual water separation"}
(OUT / "terrain_metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf8")
print("TIANCHI_PREPARED", round(extent_m/1000, 2), "km per side", flush=True)
