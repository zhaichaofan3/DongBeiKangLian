"""Blender background: build Tianchi GLBs and render local collected models."""
import json
import math
import pathlib
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

ROOT = pathlib.Path(__file__).resolve().parent
PREVIEWS = ROOT / "previews"
PREVIEWS.mkdir(exist_ok=True)


def empty():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, roughness=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    return m


def setup_camera(center, size, output, terrain=False):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.eevee.taa_render_samples = 32
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output)
    scene.world = bpy.data.worlds.new("Review World")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.25, 0.29, 0.35, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
    data = bpy.data.lights.new("Sun", "SUN")
    data.energy = 2.5
    data.angle = math.radians(12)
    light = bpy.data.objects.new("Sun", data)
    scene.collection.objects.link(light)
    light.rotation_euler = (math.radians(28), math.radians(-28), math.radians(-24))
    camera = bpy.data.objects.new("Overview Camera", bpy.data.cameras.new("Overview Camera"))
    scene.collection.objects.link(camera)
    camera.location = center + Vector((size*0.9, -size*1.15, size*(0.95 if terrain else 0.72)))
    camera.rotation_euler = (center-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = size*1.45
    camera.data.clip_end = size*10 + 100
    camera.data.clip_start = 0.1
    scene.camera = camera
    scene.view_settings.view_transform = "AgX"
    scene.render.film_transparent = False


def geometry_bounds(objects):
    corners = [o.matrix_world @ Vector(c) for o in objects for c in o.bound_box]
    return Vector(tuple(min(c[i] for c in corners) for i in range(3))), Vector(tuple(max(c[i] for c in corners) for i in range(3)))


def fit_camera(objects):
    scene = bpy.context.scene
    camera = scene.camera
    rotation = camera.rotation_euler.to_quaternion().inverted()
    points = [rotation @ (o.matrix_world @ Vector(c) - camera.location)
              for o in objects for c in o.bound_box]
    aspect = scene.render.resolution_x / scene.render.resolution_y
    camera.data.ortho_scale = 2 * max(max(abs(p.x) for p in points),
                                    aspect * max(abs(p.y) for p in points)) * 1.10


def build_terrain():
    empty()
    folder = ROOT / "terrain"
    meta = json.loads((folder / "terrain_metadata.json").read_text(encoding="utf8"))
    heights = np.load(folder / "elevation_m.npy")
    extent = meta["horizontal_extent_m"][0]
    origin = meta["height_origin_m"]
    terrain_mat = material("Illustrative altitude colors - not satellite imagery", (0.3,0.4,0.25))
    tex = terrain_mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(folder / "terrain_color.png"))
    tex.image.pack()
    terrain_mat.node_tree.links.new(tex.outputs["Color"], terrain_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])

    def surface(n, name):
        sample = np.linspace(0, 1023, n)
        index = np.floor(sample).astype(int)
        end = np.minimum(index+1,1023)
        mix = sample-index
        a = heights[index[:,None],index[None,:]]*(1-mix)[None,:]+heights[index[:,None],end[None,:]]*mix[None,:]
        b = heights[end[:,None],index[None,:]]*(1-mix)[None,:]+heights[end[:,None],end[None,:]]*mix[None,:]
        h = a*(1-mix)[:,None]+b*mix[:,None]
        vertices = [(i/(n-1)*extent-extent/2, extent/2-j/(n-1)*extent, float(h[j,i]-origin)) for j in range(n) for i in range(n)]
        faces = [(j*n+i,(j+1)*n+i,(j+1)*n+i+1,j*n+i+1) for j in range(n-1) for i in range(n-1)]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(terrain_mat)
        uv = mesh.uv_layers.new(name="TerrainUV")
        for loop in mesh.loops:
            j,i = divmod(loop.vertex_index,n)
            uv.data[loop.index].uv = (i/(n-1),1-j/(n-1))
        for poly in mesh.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj

    points = [Vector((x/1024*extent-extent/2, extent/2-y/1024*extent,meta["water_elevation_m"]-origin+0.8)) for x,y in meta["lake_outline_pixels"]]
    area = sum(points[i].x*points[(i+1)%len(points)].y-points[(i+1)%len(points)].x*points[i].y for i in range(len(points)))
    if area < 0:
        points.reverse()
    indices = {tuple(v): i for i,v in enumerate(points)}
    tris = [tuple(int(v) if isinstance(v, int) else indices[tuple(v)] for v in tri)
            for tri in tessellate_polygon([points])]
    mesh = bpy.data.meshes.new("OSM_Tianchi_Shoreline")
    mesh.from_pydata(points, [], tris)
    lake = bpy.data.objects.new("Tianchi_Lake_2189m", mesh)
    bpy.context.collection.objects.link(lake)
    mesh.materials.append(material("Heaven Lake water", (0.02,0.13,0.22),0.22))
    lake["source"] = "OpenStreetMap relation 11650508; outline only, no bathymetry"
    lake["elevation_m"] = meta["water_elevation_m"]
    records = []
    for n, filename in [(257,"tianchi_display_lod.glb"),(513,"tianchi_display.glb")]:
        terrain = surface(n, "Changbai_Terrain_"+str(n))
        terrain["source"] = "Mapzen elevation tiles / Tilezen Joerd; see source.json"
        terrain["vertical_exaggeration"] = 1.0
        terrain["height_origin_m"] = origin
        bpy.ops.object.select_all(action="DESELECT")
        terrain.select_set(True)
        lake.select_set(True)
        bpy.context.view_layer.objects.active = terrain
        bpy.ops.export_scene.gltf(filepath=str(folder/filename),export_format="GLB",use_selection=True,export_extras=True,export_animations=False)
        records.append({"file":filename,"terrain_triangles":(n-1)**2*2,"lake_triangles":len(tris),"grid":n,"bytes":(folder/filename).stat().st_size})
        if n==257:
            bpy.data.objects.remove(terrain,do_unlink=True)
    center = Vector((0,0,float(heights.mean()-origin)))
    setup_camera(center, extent, PREVIEWS / "tianchi_overview.png", True)
    bpy.context.view_layer.update()
    fit_camera([terrain, lake])
    bpy.context.scene["README"] = "Tianchi display terrain from public elevation and OSM shoreline. True vertical scale. Illustrative colors, not photogrammetry. No buildings, roads or tourism facilities."
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/"tianchi_display.blend"))
    bpy.ops.render.render(write_still=True)
    lake_center = sum(points,Vector())/len(points)
    camera = bpy.context.scene.camera
    camera.location = lake_center + Vector((6500,-7500,7600))
    camera.rotation_euler = (lake_center-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.ortho_scale = 8200
    bpy.context.scene.render.filepath = str(PREVIEWS / "tianchi_crater.png")
    bpy.ops.render.render(write_still=True)
    (folder/"build-report.json").write_text(json.dumps(records,indent=2),encoding="utf8")
    print("TIANCHI_BUILD_COMPLETE",json.dumps(records),flush=True)


def render_models():
    results = []
    for asset in json.loads((ROOT/"manifest.json").read_text(encoding="utf8"))["assets"]:
        empty()
        bpy.ops.import_scene.gltf(filepath=str(ROOT/asset["entry"]))
        bpy.context.view_layer.update()
        meshes = [o for o in bpy.context.scene.objects if o.type=="MESH"]
        assert meshes, asset["id"]
        lo,hi = geometry_bounds(meshes)
        span = hi-lo
        size = max(span)
        assert size>0 and all(math.isfinite(v) for v in (*lo,*hi))
        center=(lo+hi)/2
        # Keep original model geometry; the review floor is not exported.
        setup_camera(center,size,PREVIEWS/(asset["id"]+".png"))
        fit_camera(meshes)
        bpy.ops.mesh.primitive_plane_add(size=size*8,location=(center.x,center.y,lo.z-size*0.002))
        bpy.context.object.data.materials.append(material("Review floor",(0.16,0.18,0.21)))
        bpy.ops.render.render(write_still=True)
        missing=[im.filepath for im in bpy.data.images if im.source=="FILE" and not im.packed_file and not pathlib.Path(bpy.path.abspath(im.filepath)).exists()]
        results.append({"id":asset["id"],"imported_mesh_objects":len(meshes),"dimensions_source_units":list(span),"missing_images":missing,"preview":"previews/"+asset["id"]+".png"})
        (ROOT/"import-review.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf8")
        print("MODEL_PREVIEW_COMPLETE",asset["id"],len(meshes),list(span),flush=True)


mode = sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "all"
if mode in ("terrain","all"):
    build_terrain()
if mode in ("models","all"):
    render_models()
