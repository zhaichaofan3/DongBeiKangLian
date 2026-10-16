extends RefCounted
## Domestic work yards and woodland frame the compact playable courtyards.

var _world: WeakRef
var world: RefCounted:
	get: return _world.get_ref()
var parent: Node3D
var placements: Array[Dictionary] = []
var tree_sites: Array[Vector3] = []
var reserved: Array[Dictionary] = []
var route: Array[Vector3] = []
var shapes: Dictionary = {}

func build(owner_world: RefCounted, container: Node3D) -> void:
	_world = weakref(owner_world)
	parent = container
	var village: RefCounted = world.village_world
	route.append(village.START+Vector3(0,0,9))
	for section: Array in village.ROUTE_STOPS:
		for at: Vector3 in section: route.append(at)
	route.append(village.EXIT)
	# Three village jobs provide believable clusters and distinct encounter edges:
	# unloading at the entrance, household firewood on the street, a northern woodlot.
	for entry in [[1129,242],[1165,242],[1129,158],[1165,158],[1129,74],[1165,74],[1133,285],[1166,285]]:
		_working_edge(Vector3(entry[0],0,entry[1]),placements.size())
	for entry in [[1138,270],[1167,250],[1136,222],[1160,196],[1128,174],[1158,153],[1130,133],[1162,112],[1135,92],[1162,69],[1134,49],[1162,30]]:
		var at := Vector3(entry[0],-.1,entry[1])
		if _available(at,1.6):
			_prop("rock_moss_set_01",at,Vector3(2.8,1.3,2.2),entry[1]*.23,"路肩露岩",true,"rock_moss_set_01_rock0%d" % (placements.size()%4+1))
	# Broken clusters rather than an avenue of identical roadside trees.
	var rng := RandomNumberGenerator.new()
	rng.seed = 19381018
	for attempt in 1600:
		if tree_sites.size()>=180: break
		var at := Vector3(rng.randf_range(1085,1210),0,rng.randf_range(17,287))
		if _route_distance(at)<5 or not _available(at,1.65): continue
		if tree_sites.any(func(other): return other.distance_to(at)<5): continue
		# Keep larger groves around the inhabited core; individual trees remain in yards.
		if absf(at.x-1147)<23 and rng.randf()>.65: continue
		tree_sites.append(at)
		_tree_trunk(at)
	_build_trees(rng)
	# Close rocks and saplings add a readable middle distance to the street views.
	for i in 60:
		var z := rng.randf_range(25,280)
		var center := _route_center(z)
		var at := Vector3(center+(rng.randf_range(17,35) if i%2==0 else -rng.randf_range(17,35)),0,z)
		if not _available(at,1.1): continue
		if i%3==0:
			_prop("pine_sapling_small",at,Vector3(2.1,4.5,2.1),rng.randf()*TAU,"院外幼松",true)
		else:
			_prop("rock_moss_set_01",at-Vector3.UP*.12,Vector3(1.6,.75,1.3),rng.randf()*TAU,"土路边碎岩",true,"rock_moss_set_01_rock0%d" % (i%4+1))

func _route_distance(at: Vector3) -> float:
	var result := INF
	for i in range(1,route.size()):
		var point := Geometry2D.get_closest_point_to_segment(Vector2(at.x,at.z),Vector2(route[i-1].x,route[i-1].z),Vector2(route[i].x,route[i].z))
		result = minf(result,point.distance_to(Vector2(at.x,at.z)))
	return result

func _route_center(z: float) -> float:
	for i in range(1,route.size()):
		if z<=route[i-1].z and z>=route[i].z:
			return lerpf(route[i-1].x,route[i].x,inverse_lerp(route[i-1].z,route[i].z,z))
	return route[0].x

func _available(at: Vector3, radius: float) -> bool:
	if _route_distance(at)<1.8+radius: return false
	for patrol: Array in world.root.VillageDirector.ENEMIES.values():
		var nearest := Geometry2D.get_closest_point_to_segment(Vector2(at.x,at.z),Vector2(patrol[0].x,patrol[0].z),Vector2(patrol[1].x,patrol[1].z))
		if nearest.distance_to(Vector2(at.x,at.z))<radius+1.8: return false
	for gate: Vector3 in world.village_world.GATES:
		if absf(at.z-gate.z)<4: return false
	for item in reserved:
		if at.distance_to(item.at)<radius+item.radius: return false
	var probe := CylinderShape3D.new()
	probe.radius = radius
	probe.height = 3.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.transform.origin = Vector3(at.x,2,at.z)
	query.collision_mask = 1
	return parent.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _prop(asset: String, at: Vector3, size: Vector3, yaw: float, purpose: String, solid: bool = true, piece: String = "") -> Node3D:
	var node: Node3D = world.asset_dressing._spawn(asset,at,0,yaw,piece,0,size,105)
	node.reparent(parent)
	node.set_meta("village_purpose",purpose)
	placements.append({"asset":asset,"at":at,"purpose":purpose})
	if solid:
		reserved.append({"at":at,"radius":maxf(size.x,size.z)*.5})
		for mesh: MeshInstance3D in world.asset_dressing._meshes(node):
			var key := mesh.mesh.get_instance_id()
			if not shapes.has(key): shapes[key] = mesh.mesh.create_trimesh_shape()
			var body := StaticBody3D.new()
			var collision := CollisionShape3D.new()
			collision.shape = shapes[key]
			body.add_child(collision)
			mesh.add_child(body)
	return node

func _working_edge(at: Vector3, index: int) -> void:
	if not _available(at,2.5): return
	var yaw := .08 if index%2==0 else PI*.5
	var holder := Node3D.new()
	holder.name = "村民冬用柴垛"
	holder.position = at
	holder.rotation.y = yaw
	parent.add_child(holder)
	for layer in 3:
		for i in 4-layer:
			var log: MeshInstance3D = world.cylinder("待用劈柴",Vector3.ZERO,.18,2.8,"bark")
			log.reparent(holder,false)
			log.position = Vector3(0,.18+layer*.31,(i-(3-layer)*.5)*.38)
			log.rotation.z = PI*.5
	var collision: Node3D = world._collision_only_box("柴垛碰撞",Vector3.ZERO,Vector3(2.8,.95,1.55),"wood")
	collision.reparent(holder,false)
	collision.position.y = .475
	reserved.append({"at":at,"radius":1.8})
	placements.append({"asset":"stacked_timber","at":at,"purpose":"村民冬用柴垛"})
	_prop("tree_stump_01",at+Vector3(2.1,0,.5),Vector3(.72,.5,.72),.4,"劈柴墩")
	_prop("wooden_axe_02",at+Vector3(2.1,.51,.5),Vector3(.65,.14,.22),-.3,"手工劈柴斧",false)
	_prop("wicker_basket_01",at+Vector3(-1.8,0,.9),Vector3(.7,.5,.65),.3,"院旁收柴筐")
	_prop("wooden_bucket_01",at+Vector3(-1.9,0,-.8),Vector3(.45,.5,.45),-.2,"村民取水桶")
	world.asset_dressing._ground_patch("柴场踩踏土",at+Vector3(0,.026,0),Vector2(3.7,2.5),world.AssetDressing.pbr("wood_chips",.3,Color("b9a88c")),110)

func _tree_trunk(at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "村内松树树干"
	body.position = at+Vector3.UP*1.5
	var collision := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = .24
	cylinder.height = 3
	collision.shape = cylinder
	body.add_child(collision)
	parent.add_child(body)
	reserved.append({"at":at,"radius":1.4})

func _build_trees(rng: RandomNumberGenerator) -> void:
	var source := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
	var pieces: Array[Dictionary] = []
	world.village_world._collect(source,Transform3D.IDENTITY,pieces)
	var bounds: AABB = world.asset_dressing._bounds(source)
	var transforms: Array[Transform3D] = []
	for at in tree_sites:
		var scale := rng.randf_range(7,12)/bounds.size.y
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),at)*Transform3D(Basis.IDENTITY,-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)))
	for item in pieces:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = item.mesh.duplicate()
		for i in instances.mesh.get_surface_count():
			var mat := instances.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
			if mat==null: continue
			mat.albedo_color = Color("7b8862")
			mat.roughness = 1
			if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold = .45
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			instances.mesh.surface_set_material(i,mat)
		instances.instance_count = transforms.size()
		for i in transforms.size(): instances.set_instance_transform(i,transforms[i]*item.transform)
		var trees := MultiMeshInstance3D.new()
		trees.name = "村内院落与街边松林"
		trees.multimesh = instances
		parent.add_child(trees)
	source.free()
