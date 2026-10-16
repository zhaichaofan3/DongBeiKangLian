extends RefCounted
## A playable woodland interval between the river landing and the original village.
const Vegetation = preload("res://scripts/vegetation_batch.gd")

const LANDING := Vector3(1214, .08, 426)
const REST := Vector3(1215.7, .08, 426)
const SCOUT := Vector3(1212, .08, 422)
const ENTRANCE := Vector3(1153, .08, 285)
const ROAD := [LANDING, Vector3(1214,0,416), Vector3(1192,0,401),
	Vector3(1192,0,383), Vector3(1170,0,370), Vector3(1170,0,352),
	Vector3(1183,0,339), Vector3(1173,0,323), Vector3(1163,0,308),
	Vector3(1155,0,296), ENTRANCE, Vector3(1147,0,282)]
const AREA := Rect2(1114, 289, 140, 146)
const PIER_AREA := Rect2(1212.9,435,2.2,2.3)
var tree_count := 0
var road_material: StandardMaterial3D
var ground_material: StandardMaterial3D
var tree_sites: Array[Vector3] = []

static func projection(at: Vector3) -> Dictionary:
	var point := Vector2(at.x,at.z)
	var best := INF
	var result := {"index":0,"point":ROAD[0],"distance":INF}
	for i in range(ROAD.size()-1):
		var a := Vector2(ROAD[i].x,ROAD[i].z)
		var b := Vector2(ROAD[i+1].x,ROAD[i+1].z)
		var t := clampf((point-a).dot(b-a)/(b-a).length_squared(),0,1)
		var nearest := a.lerp(b,t)
		var distance := point.distance_squared_to(nearest)
		if distance < best:
			best = distance
			result = {"index":i,"point":Vector3(nearest.x,.08,nearest.y),"distance":sqrt(distance)}
	return result

static func height_at(at: Vector3) -> float:
	var distance: float = projection(at).distance
	# A steep, visible embankment prevents climbing away through the dense trees.
	var ridge := smoothstep(3.1,5.2,distance)*3.5
	var height := ridge + smoothstep(6,16,distance)*(1.1+sin(at.x*.15)*.45+cos(at.z*.12)*.4)
	var clearing := smoothstep(420,425,at.z)*(1.0-smoothstep(5,12,absf(at.x-LANDING.x)))
	return height*(1.0-clearing)

func build(world: RefCounted, parent: Node3D) -> void:
	ground_material = world.AssetDressing.pbr("forest_ground_04",.24,Color("65775d"))
	road_material = world.AssetDressing.pbr("muddy_tracks",.28,Color("e0c9a4"))
	var terrain := SurfaceTool.new()
	terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := PackedVector3Array()
	for z in range(289,436):
		for x in range(1114,1255):
			var p := Vector3(x,0,z)
			p.y = height_at(p)
			vertices.append(p)
	for z in range(289,435):
		for x in range(1114,1254):
			var index := (z-289)*141+x-1114
			var corners := [vertices[index],vertices[index+1],vertices[index+141],vertices[index+142]]
			for i in [0,1,2,1,3,2]:
				var p: Vector3 = corners[i]
				terrain.set_uv(Vector2(p.x,p.z)*.24)
				terrain.add_vertex(p)
	# Close the visible riverbank edge down to the riverbed.
	for x in range(1114,1254):
		var a := Vector3(x,height_at(Vector3(x,0,435)),435)
		var b := Vector3(x+1,height_at(Vector3(x+1,0,435)),435)
		for p in [a,b,Vector3(a.x,-2.5,a.z),b,Vector3(b.x,-2.5,b.z),Vector3(a.x,-2.5,a.z)]:
			terrain.set_uv(Vector2(p.x,p.y)*.24)
			terrain.add_vertex(p)
	terrain.generate_normals()
	terrain.generate_tangents()
	var ground := MeshInstance3D.new()
	ground.name = "渡河后起伏密林地表"
	ground.mesh = terrain.commit()
	ground.material_override = ground_material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(ROAD.size()-1):
		var a: Vector3 = ROAD[i]
		var b: Vector3 = ROAD[i+1]
		var forward := (b-a).normalized()
		var side := Vector3(forward.z,0,-forward.x)*2.65
		a -= forward*.35
		b += forward*.35
		for p in [a-side,a+side,b+side,a-side,b+side,b-side]:
			road.set_uv(Vector2(p.x,p.z)*.28)
			road.add_vertex(Vector3(p.x,.032,p.z))
	road.generate_normals()
	road.generate_tangents()
	var lane := MeshInstance3D.new()
	lane.name = "引向村口的浅色土路"
	lane.mesh = road.commit()
	lane.material_override = road_material
	parent.add_child(lane)
	_build_trees(world,parent)
	for i in [1,3,5,7]:
		var at: Vector3 = ROAD[i]+Vector3(-6,0,1)
		at.y = height_at(at)-.45
		var stone: Node3D = world.asset_dressing._spawn("rock_moss_set_01",at,0,i*.6,"rock_moss_set_01_rock0%d" % (i%4+1),0,Vector3(2.7,1.6,1.8),100)
		stone.reparent(parent)
	for i in [2,4,6]:
		var at: Vector3 = ROAD[i]+Vector3(5,0,2)
		at.y = height_at(at)+.4
		var log: MeshInstance3D = world.cylinder("密林倒木_%d" % i,at,.38,7,"bark")
		log.rotation.z = PI*.5
		log.rotation.y = .5*i
		log.reparent(parent)
	world._sign("松嶺屯",Vector3(1150,2,286),0)

func _collect(node: Node3D, parent: Transform3D, pieces: Array[Dictionary]) -> void:
	var transform := parent*node.transform
	if node is MeshInstance3D: pieces.append({"mesh":node.mesh,"transform":transform})
	for child in node.get_children():
		if child is Node3D: _collect(child,transform,pieces)

func _build_trees(_world: RefCounted, parent: Node3D) -> void:
	var source := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
	var pieces: Array[Dictionary] = []
	_collect(source,Transform3D.IDENTITY,pieces)
	var bounds := AABB()
	for item in pieces:
		var box: AABB = item.transform*item.mesh.get_aabb()
		bounds = box if bounds.size==Vector3.ZERO else bounds.merge(box)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19381016
	var transforms: Array[Transform3D] = []
	var trunks := StaticBody3D.new()
	trunks.name = "密林真实树干碰撞"
	parent.add_child(trunks)
	var shape := CylinderShape3D.new()
	shape.radius = .3
	shape.height = 3
	for z in range(291,434,3):
		for x in range(1116,1253,3):
			var at := Vector3(x+rng.randf_range(-.8,.8),0,z+rng.randf_range(-.8,.8))
			if projection(at).distance<4.3: continue
			if at.z>420 and absf(at.x-LANDING.x)<10: continue
			at.y = height_at(at)
			tree_sites.append(at)
			var factor := rng.randf_range(11,18)/bounds.size.y
			var offset := -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
			transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*factor),at)*Transform3D(Basis.IDENTITY,offset))
			var collider := CollisionShape3D.new()
			collider.shape = shape
			collider.position = at+Vector3.UP*1.5
			trunks.add_child(collider)
	tree_count = transforms.size()
	Vegetation.build(parent,"上岸后的连续密林",pieces,transforms,Color("879a7a"))
	source.free()
