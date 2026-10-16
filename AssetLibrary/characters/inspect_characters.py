import json, pathlib, struct, hashlib, base64, urllib.parse, collections
BASE=pathlib.Path(__file__).resolve().parent
records=[]
for p in sorted([*BASE.rglob("*.glb"),*BASE.rglob("*.gltf")]):
 data=p.read_bytes(); binary=None
 if p.suffix.lower()==".glb":
  magic,version,total=struct.unpack_from("<4sII",data);assert magic==b"glTF" and version==2 and total==len(data)
  off=12;j=None
  while off<len(data):
   n,t=struct.unpack_from("<II",data,off);off+=8;chunk=data[off:off+n];off+=n
   if t==0x4e4f534a:j=json.loads(chunk)
   elif t==0x004e4942:binary=chunk
  assert j is not None
 else:j=json.loads(data)
 dependencies=[]; buffers=[]
 for buf in j.get("buffers",[]):
  uri=buf.get("uri")
  if not uri:contents=binary
  elif uri.startswith("data:"):contents=base64.b64decode(uri.split(",",1)[1])
  else:
   dep=(p.parent/urllib.parse.unquote(uri)).resolve();assert dep.is_relative_to(BASE),str(dep);assert dep.exists(),str(dep);contents=dep.read_bytes();dependencies.append(str(dep.relative_to(BASE)).replace("\\","/"))
  assert contents is not None and len(contents)>=buf["byteLength"]
  buffers.append(contents)
 for view in j.get("bufferViews",[]):assert view.get("byteOffset",0)+view["byteLength"]<=len(buffers[view["buffer"]])
 for image in j.get("images",[]):
  uri=image.get("uri","")
  if uri and not uri.startswith("data:"):
   dep=(p.parent/urllib.parse.unquote(uri)).resolve();assert dep.is_relative_to(BASE),str(dep);assert dep.exists(),str(dep);dependencies.append(str(dep.relative_to(BASE)).replace("\\","/"))
 nodes=j.get("nodes",[]);animations=[];skins=[]
 for skin in j.get("skins",[]):
  assert all(0<=i<len(nodes) for i in skin["joints"])
  skins.append({"name":skin.get("name",""),"joint_count":len(skin["joints"]),"joint_names":[nodes[i].get("name",str(i)) for i in skin["joints"]]})
 for a in j.get("animations",[]):
  samplers=a.get("samplers",[]); duration=0
  for s in samplers:
   ac=j["accessors"][s["input"]]
   if ac.get("max"):duration=max(duration,max(ac["max"]))
  for c in a.get("channels",[]):assert c["sampler"]<len(samplers) and c["target"].get("node",0)<len(nodes)
  animations.append({"name":a.get("name",""),"duration_seconds":round(duration,4),"channels":len(a.get("channels",[])),"author_noexport_suffix":a.get("name","").lower().endswith("-noexp")})
 triangle_count=0
 for mesh in j.get("meshes",[]):
  for primitive in mesh.get("primitives",[]):
   if primitive.get("mode",4)==4:
    accessor=j["accessors"][primitive["indices"]] if "indices" in primitive else j["accessors"][primitive["attributes"]["POSITION"]]
    triangle_count+=accessor["count"]//3
 records.append({"path":p.relative_to(BASE).as_posix(),"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),"mesh_count":len(j.get("meshes",[])),"triangle_count":triangle_count,"skins":skins,"animations":animations,"material_count":len(j.get("materials",[])),"image_count":len(j.get("images",[])),"external_dependencies":dependencies,"verification":"glTF structure, buffer sizes, bufferView bounds, skin node references, animation references, external file existence checked; not yet rendered or retargeted in game"})
(BASE/"gltf_inspection.json").write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding="utf8")
m=json.loads((BASE/"manifest.json").read_text(encoding="utf8"))
notes={
 "quaternius_ual1":["43 clips in each GLB, including A_TPose. Root-motion and in-place files duplicate the same 43 action names, not 86 different actions. Verified skin: 65 joints.","Useful: Walk_Loop, Walk_Formal_Loop, Jog_Fwd_Loop, Sprint_Loop, Crouch_Fwd_Loop, Crouch_Idle_Loop, Hit_Chest, Hit_Head, Death01, Pistol_Aim_Down/Neutral/Up, Pistol_Reload, Pistol_Shoot. Gun clips are pistol, not rifle.","Generic humanoid actions require retargeting to final NPC rigs; first-person bolt/reload/grip contact needs weapon-specific authoring."],
 "quaternius_ual2":["43 clips in each animation GLB including A_TPose. Root-motion variant duplicates action names. Verified skin: 65 joints. Female mannequin has 65 joints and no embedded clips.","Useful: ClimbUp_1m, Hit_Knockback, OverhandThrow, Slide_Start/Loop/Exit, LayToIdle, TreeChopping_Loop, Walk_Carry_Loop, Consume. Several combat/fantasy clips are irrelevant to this setting.","UAL1 and UAL2 together have 85 unique clip names, including the shared A_TPose (84 non-T-pose names)."],
 "quaternius_base_characters":["Two full-body male/female characters, each 65 joints, 3 meshes and 7 image entries; 8 eyebrow/hair choices supplied both static and head-rigged. Full-body characters contain no embedded animations.","Detailed textures are included, but these are stylized superhero base bodies, not ready-to-use 1938 Northeast Anti-Japanese United Army uniforms. Clothing, head/skin appearance and equipment require adaptation.","18 glTF files total in this kit: 2 bodies and 16 hair/eyebrow variants. Do not report this as 18 full characters."],
 "godot_tps_player":["56 embedded clips, including author work-in-progress clips tagged -noexp. Skin has 145 joints. Useful gun locomotion: running_aiming, running_gun-cycle, walking_gun-cycle, strafe_back/front/left/right-cycle, AIM-Center/Down/Up, flinch clips.","Model is a science-fiction robot. Use as animation reference/retarget source only for this historical game; robot and arm-cannon clips are not a finished rifle animation set."]}
for a in m["assets"]:
 rec=[r for r in records if r["path"].startswith(a["id"]+"/")]
 a["status"]="downloaded_extracted_gltf_structure_verified_not_integrated"
 a["inspection_file"]="gltf_inspection.json"
 a["model_files"]=[r["path"] for r in rec]
 a["notes"]+=notes.get(a["id"],[])
 for f in a["files"]:f["path"]=f["path"].replace("\\","/")
 a["license_files"]=[p.relative_to(BASE).as_posix() for p in (BASE/a["id"]).rglob("*") if p.is_file() and "license" in p.name.lower()]
(BASE/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
print(json.dumps({"model_files":len(records),"skinned_model_files":sum(bool(r["skins"]) for r in records),"download_bytes":sum(f["bytes"] for a in m["assets"] for f in a["files"]),"total_local_bytes":sum(p.stat().st_size for p in BASE.rglob("*") if p.is_file()),"gltf_dependency_verification":"pass"},indent=2))
