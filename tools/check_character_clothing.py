"""Measure sleeve skinning under a bent-arm pose in the editable source."""
import json
import sys
from pathlib import Path

import bpy

args = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=str(Path(args[0]).resolve()))
coat = bpy.data.objects['Clothing']
rig = next(mod.object for mod in coat.modifiers if mod.type == 'ARMATURE')
for side in range(2):
    for name, angle in [(f'Shoulder{side}', .35), (f'Elbow{side}', .9)]:
        bone = rig.pose.bones[name]
        bone.rotation_mode = 'XYZ'
        bone.rotation_euler.x = angle
bpy.context.view_layer.update()
posed = coat.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
ratios = []
waist_anchors = 0
sleeve_samples = 0
for vertex in coat.data.vertices:
    # In the Blender source, Z is height. This samples the outer sleeve, away
    # from the shoulder cap where a torso blend is intentional.
    if .84 < vertex.co.z < 1.18 and abs(vertex.co.x) > .24:
        sleeve_samples += 1
        for group in vertex.groups:
            if coat.vertex_groups[group.group].name in ['Chest', 'Hips'] and group.weight > .001:
                waist_anchors += 1
for edge in coat.data.edges:
    a, b = [coat.data.vertices[i].co for i in edge.vertices]
    if all(.84 < p.z < 1.18 and abs(p.x) > .19 for p in [a,b]):
        length = (a-b).length
        if length > .001:
            ratios.append((posed.vertices[edge.vertices[0]].co - posed.vertices[edge.vertices[1]].co).length / length)
ratios.sort()
report = {'source':args[0], 'sleeve_samples':sleeve_samples, 'torso_anchored_sleeve_vertices':waist_anchors,
          'edge_samples':len(ratios), 'p95_edge_stretch':ratios[int(len(ratios)*.95)], 'max_edge_stretch':max(ratios),
          'pose_radians':{'shoulder':.35,'elbow':.9},
          'passed':sleeve_samples > 200 and waist_anchors == 0 and max(ratios) < 1.8}
Path(args[1]).parent.mkdir(parents=True, exist_ok=True)
Path(args[1]).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
coat.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
print(json.dumps(report))
