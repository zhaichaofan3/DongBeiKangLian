"""Editable artistic crater with continuous shoreline, four ridges and outer slopes.

Coordinates: Blender (x, north, up) -> Godot (x, up, -north), one unit = 1 m.
Original S20 composition is a spatial target, not a real elevation reconstruction.
"""
import bpy
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "AssetLibrary/environment/derived/S21"
GAME = ROOT / "GodotProject/assets/opening"
SOURCE.mkdir(parents=True, exist_ok=True)
GAME.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

def material(name, color, roughness=0.9):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    return mat

rocks = [material("S21_Basalt", (.20,.235,.23)),
         material("S21_Weathered_Rock", (.29,.30,.26)),
         material("S21_Dark_Strata", (.12,.155,.16)),
         material("S21_Heather_Scree", (.25,.265,.20))]
water = material("S21_Deep_Blue_Lake", (.012,.075,.135), .28)
platform_mat = material("S21_Talk_Platform", (.25,.225,.19))

def mesh_object(name, verts, faces, materials):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for mat in materials:
        mesh.materials.append(mat)
    return obj

SEGMENTS = 384
RADII = [44,47,49,51,54,57,60,63,66,69,72,75,78,81,84,87,90,93,96,99,103,108,114,121,130,142,156,172]
RADII = sorted(set(RADII + [(a+b)*.5 for a,b in zip(RADII,RADII[1:])]))

def terrain_vertex(radius, angle):
    # Irregular rim and radial gullies break the circular "bowl" silhouette.
    irregular = 1 + .045*math.sin(angle*3+.8) + .021*math.sin(angle*7-1.2)
    r = radius * irregular
    east, north = math.cos(angle), math.sin(angle)
    x, y = 4 + r*east, 2 + r*north
    crest = 27 + 6*north - 2*east + 3*math.sin(angle*5+.4) + 2*math.sin(angle*11)
    profile = [(44,-2.8),(49,.45),(55,2.0),(66,6.8),(76,14.5),(92,crest),(103,crest*.72),(121,7),(142,-2),(172,-8)]
    for (r0,h0),(r1,h1) in zip(profile,profile[1:]):
        if r0 <= radius <= r1:
            z = h0 + (h1-h0)*(radius-r0)/(r1-r0)
            break
    rough = min(1,max(0,(radius-49)/15)) * min(1,max(0,(158-radius)/22))
    z += rough*(.60*math.sin(angle*23+radius*.10) + .25*math.sin(angle*43-radius*.16) + .10*math.sin(angle*67+radius*.5))
    # Ground rises under the southwest ledge. The detailed walkable top is S22.
    support = math.exp(-(((x+59)/13)**4 + ((y+24)/10)**4))
    z = z*(1-support) + max(z,10.2)*support
    return (x,y,z)

# Adjacent sectors duplicate identical seam vertices, so no cracks are introduced.
sectors = ["East", "North", "West", "South"]
for sector, name in enumerate(sectors):
    verts=[]
    faces=[]
    width=SEGMENTS//4+1
    for radius in RADII:
        for i in range(width):
            angle=math.tau*(sector*(width-1)+i)/SEGMENTS
            verts.append(terrain_vertex(radius,angle))
    for ring in range(len(RADII)-1):
        for i in range(width-1):
            a=ring*width+i
            b=a+1
            c=a+width+1
            d=a+width
            # CCW viewed from above, with a stable diagonal per cell.
            faces.extend([(a,d,c),(a,c,b)])
    obj=mesh_object("S21_Crater_"+name,verts,faces,rocks)
    for poly in obj.data.polygons:
        center=poly.center
        slope=1-poly.normal.z
        band=math.sin(center.z*1.2 + center.x*.06)
        poly.material_index=2 if band < -.80 else 1 if slope > .18 else 3 if center.z > 4 else 0
        poly.use_smooth=True

# Disk extends under the connected shore: the visible edge is the terrain/water
# intersection at about radius 49 m. Its perimeter cannot expose a background gap.
lake_vertices=[(4,2,.4)] + [(4+54*math.cos(math.tau*i/SEGMENTS),2+54*math.sin(math.tau*i/SEGMENTS),.4) for i in range(SEGMENTS)]
lake_faces=[(0,i+1,(i+1)%SEGMENTS+1) for i in range(SEGMENTS)]
mesh_object("S21_Deep_Blue_Lake",lake_vertices,lake_faces,[water])

# Seated ledge base; S22 will add a level top, collision and routes at 14 m.
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3,radius=1,location=(-59,-24,9.2))
platform=bpy.context.object
platform.name="S21_Talk_Platform_Base"
platform.scale=(10.3,6.5,4.8)
platform.data.materials.append(platform_mat)

bpy.context.scene.unit_settings.system="METRIC"
bpy.context.scene.unit_settings.scale_length=1
bpy.context.scene["S21_scope"]="artistic crater visual model; continuous shore and outer slopes; S22 owns platform paths and collision"
bpy.context.scene["S21_coordinates"]="Blender x,north,up; Godot x,up,-north; 1 unit = 1 metre"
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"tianchi_artistic.blend"))
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(GAME/"tianchi_artistic.glb"),export_format="GLB",export_materials="EXPORT")

objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
files=[SOURCE/"tianchi_artistic.blend",GAME/"tianchi_artistic.glb"]
report={
    "step":"S21", "revision":"changbai-refined-v3-20261015",
    "source":"original procedural artistic composition; public DEM retained separately as reference only",
    "coordinates":{"blender":"x,north,up","godot":"x,up,-north","metres_per_unit":1},
    "objects":[o.name for o in objects],
    "vertices":sum(len(o.data.vertices) for o in objects),
    "triangles":sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects),
    "scale":{"rim_radius_m":92,"shore_radius_m_approx":49,"outer_slope_radius_m":172,"lake_level_m":.4,"platform_top_m":14},
    "files":[{"path":f.relative_to(ROOT).as_posix(),"bytes":f.stat().st_size,"sha256":hashlib.sha256(f.read_bytes()).hexdigest()} for f in files],
    "integration":"integrated in OpeningDirector; refined terrain mesh, runtime rock materials and terrain-anchored woodland; S22 owns unchanged route collision"
}
(SOURCE/"manifest.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps(report,ensure_ascii=False))
