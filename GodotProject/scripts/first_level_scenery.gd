extends RefCounted
## Working yards stay cleared; regrowth and rock collect along their margins.
const Layout = preload("res://scripts/first_level_layout.gd")
var _world: WeakRef
var w: RefCounted:
	get: return _world.get_ref()
var d: RefCounted
var placements: Array[Dictionary] = []
var tree_sites: Array[Vector4] = []
var shapes: Dictionary = {}

func build(world: RefCounted) -> void:
	_world = weakref(world)
	d = w.asset_dressing
	_hills()
	_arrival()
	_checkpoint()
	_timber()
	_forest_roads()
	_office_edge()
	_ground_cover()

func _prop(asset: String, at: Vector3, size: Vector3, yaw: float, purpose: String, solid: bool = true, piece: String = "", distance: float = 65) -> Node3D:
	var node: Node3D = d._spawn(asset, at, 0, yaw, piece, 0, size, distance)
	node.set_meta("chapter_scenery", purpose)
	placements.append({"asset":asset, "at":at, "purpose":purpose, "solid":solid})
	if solid:
		for mesh: MeshInstance3D in d._meshes(node):
			var key: int = mesh.mesh.get_instance_id()
			if not shapes.has(key): shapes[key] = mesh.mesh.create_trimesh_shape()
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = shapes[key]
			body.add_child(shape)
			mesh.add_child(body)
	return node

func _rock(at: Vector3, size: Vector3, index: int, yaw: float) -> void:
	_prop("rock_moss_set_01", at, size, yaw, "坡脚露岩", true, "rock_moss_set_01_rock0%d" % (index % 4 + 1), 100)

func _logs(at: Vector3, length: float, count: int, yaw: float, title: String) -> void:
	var holder := Node3D.new()
	holder.name = title
	holder.position = at
	holder.rotation.y = yaw
	w.root.add_child(holder)
	# Horizontal cylinders and their shared box rotate together.
	for layer in 3:
		for i in maxi(0, count-layer):
			var log: MeshInstance3D = w.cylinder(title, Vector3.ZERO, .19, length, "bark")
			log.reparent(holder, false)
			log.position = Vector3(0, .19+layer*.34, (float(i)-float(count-layer-1)*.5)*.4)
			log.rotation.z = PI*.5
	var collision: Node3D = w._collision_only_box(title+"碰撞", Vector3.ZERO, Vector3(length, 1.06, count*.4), "bark")
	collision.reparent(holder, false)
	collision.position.y = .53
	placements.append({"asset":"stacked_timber", "at":at, "purpose":title, "solid":true})

func _workbench(at: Vector3, yaw: float) -> void:
	_prop("WoodenTable_01", at, Vector3(1.8,.83,.8), yaw, "林工修整台")
	_prop("wooden_axe_02", at+Vector3(0,.84,0), Vector3(.72,.12,.24), yaw+.2, "手工伐木工具", false)
	_prop("wooden_bucket_01", at+Vector3(.7,0,1), Vector3(.4,.48,.4), -.3, "取水木桶")

func _arrival() -> void:
	_prop("wine_barrel_01", Vector3(6.7,0,272), Vector3(.72,.95,.72), .4, "林工棚储水桶")
	_prop("wooden_bucket_01", Vector3(7.5,0,271), Vector3(.4,.43,.4), -.4, "林工棚取水桶")
	_prop("wicker_basket_01", Vector3(9,.02,268.8), Vector3(.6,.43,.55), .3, "林工杂物筐")
	_prop("wooden_crate_01", Vector3(7.3,0,267.5), Vector3(.9,.7,.7), -.15, "林工干粮箱")
	_logs(Vector3(17.5,0,273), 2.8, 3, PI*.5, "棚旁取暖柴垛")
	_prop("tree_stump_01", Vector3(17.6,0,269.4), Vector3(.75,.53,.72), .7, "棚旁劈柴墩")
	_prop("wooden_axe_02", Vector3(17.6,.54,269.4), Vector3(.65,.13,.23), .8, "劈柴斧", false)
	_prop("dead_tree_trunk", Vector3(6.3,0,292), Vector3(1.2,.6,3.5), .2, "林道边风倒木")
	for at in [Vector3(18.2,0,285),Vector3(5.9,0,283),Vector3(6.1,0,260.5)]:
		_rock(at-Vector3.UP*.12, Vector3(1.3,.8,1.6), placements.size(), at.z*.3)
	for at in [Vector3(18.3,0,295),Vector3(18.4,0,281),Vector3(5.4,0,287)]:
		tree_sites.append(Vector4(at.x,at.y,at.z,8.2))
	_patch(Vector3(7.5,.021,270),Vector2(2.6,4),"wood_chips")
	_patch(Vector3(17,.022,273),Vector2(2,3),"wood_chips")

func _checkpoint() -> void:
	_logs(Vector3(54,0,230), 5.5, 5, -.06, "待运成材垛")
	_logs(Vector3(42.8,0,249), 4.8, 3, .1, "入口卸料垛")
	_logs(Vector3(55,0,204), 4, 4, PI*.5, "棚后短材垛")
	_workbench(Vector3(54,0,234.5), 0)
	for item in [Vector4(25.8,241,.8,.1),Vector4(26.1,239.9,.65,-.2),Vector4(56,226.5,1,.3),Vector4(56,225.2,.7,-.1)]:
		_prop("wooden_crate_01",Vector3(item.x,0,item.y),Vector3(item.z,.78,item.z),item.w,"装卸周转木箱")
	_prop("wine_barrel_01", Vector3(45,0,252), Vector3(.75,.94,.75), .3, "棚边储桶")
	for at in [Vector3(26,0,214),Vector3(26.3,0,209),Vector3(56.5,0,245.5),Vector3(58,0,201)]:
		_prop("tree_stump_01", at, Vector3(.85,.45,.8), at.z, "采伐后树墩")
	for at in [Vector3(25.4,0,250),Vector3(58,0,232),Vector3(25.2,0,204)]:
		_rock(at-Vector3.UP*.2,Vector3(2.1,1.2,2.4),placements.size(),at.z*.1)
	for at in [Vector3(25.1,0,246),Vector3(58.5,0,248),Vector3(57.8,0,236),Vector3(25.2,0,217)]:
		tree_sites.append(Vector4(at.x,at.y,at.z,9.6))
	_patch(Vector3(53,.021,231),Vector2(5,6),"wood_chips")
	_patch(Vector3(27,.022,227),Vector2(3.5,4.5),"wood_chips")
	_patch(Vector3(44,.021,250),Vector2(4,2.5),"wood_chips")

func _timber() -> void:
	_logs(Vector3(54,0,141), 6, 5, .06, "木料场长材垛")
	_logs(Vector3(49,0,126), 4.4, 4, -.1, "木料场分拣材垛")
	_logs(Vector3(26.5,0,157), 3.5, 3, PI*.5, "西侧短材垛")
	_workbench(Vector3(54.7,0,155), .12)
	_prop("wine_barrel_01", Vector3(56.5,0,153.6), Vector3(.7,.9,.7), -.3, "装卸棚水桶")
	_prop("wooden_crate_01", Vector3(49,0,157), Vector3(1.05,.85,.8), .18, "装卸棚工具箱")
	_prop("wicker_basket_01", Vector3(50.6,0,157.1), Vector3(.6,.46,.55), -.2, "木屑回收筐")
	_prop("dead_tree_trunk", Vector3(58,0,130), Vector3(1.2,.8,5), .08, "待截断原木")
	for at in [Vector3(26,0,148),Vector3(26.3,0,137),Vector3(55.7,0,133)]:
		_prop("tree_stump_01", at, Vector3(.9,.58,.85), at.z*.3, "锯切作业树墩")
	for at in [Vector3(60.3,0,145),Vector3(25.2,0,166),Vector3(25.5,0,125)]:
		tree_sites.append(Vector4(at.x,at.y,at.z,8.7))
	_patch(Vector3(53,.021,141),Vector2(6.5,6),"wood_chips")
	_patch(Vector3(50,.021,155),Vector2(7,3),"wood_chips")
	_patch(Vector3(26.5,.022,147),Vector2(2,7),"wood_chips")

func _forest_roads() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 19381017
	# These shoulders are outside the centre of the eight-metre transport roads.
	var shoulders := [Vector4(30.5,30.9,185,194),Vector4(59.1,59.5,173,179),Vector4(30.5,30.9,112,118),Vector4(75.1,75.5,85,101),Vector4(30.5,30.9,47,69)]
	for section: Vector4 in shoulders:
		var z: float = section.z
		while z < section.w:
			var at := Vector3(rng.randf_range(section.x,section.y),0,z)
			if int(z)%3==0:
				tree_sites.append(Vector4(at.x,at.y,at.z,rng.randf_range(6.5,9)))
			else:
				_rock(at-Vector3.UP*.16,Vector3(rng.randf_range(.9,1.5),rng.randf_range(.5,1),rng.randf_range(1,1.7)),placements.size(),rng.randf()*TAU)
			z += rng.randf_range(3.5,5.5)
	for sample: Dictionary in w.first_level.berm_samples:
		if rng.randf() < .2: continue
		var at: Vector3 = sample.at
		var height := rng.randf_range(.65,1.7)
		_rock(at-Vector3.UP*.16,Vector3(height*rng.randf_range(1.5,2.5),height,height*rng.randf_range(1.2,2)),placements.size(),rng.randf()*TAU)
		var normal: Vector3 = sample.normal
		_rock(at+normal*.8-Vector3.UP*.05,Vector3(1.4,.8,1.6),placements.size(),rng.randf()*TAU)
		for i in 2:
			_prop("fern_02",at+Vector3(rng.randf_range(-.8,.8),.02,rng.randf_range(-1,1)),Vector3(.8,.48,.8),rng.randf()*TAU,"坡脚蕨丛",false,"fern_02_%s" % ["a","b","c","d"][rng.randi_range(0,3)],40)
		if rng.randf() < .4:
			var crest: Vector3 = sample.crest
			tree_sites.append(Vector4(crest.x,crest.y,crest.z,rng.randf_range(6,9)))
	for at in [Vector3(34,.019,191),Vector3(56,.019,175),Vector3(72,.019,93),Vector3(34,.019,58)]:
		_patch(at+Vector3(-2.6,0,0),Vector2(1.2,3.5),"brown_mud_leaves_01")
	for at in [Vector3(31,0,115),Vector3(75,0,96),Vector3(31,0,52)]:
		_prop("pine_sapling_small",at,Vector3(1.4,2.7,1.4),at.z,"林缘幼松",false,"",45)

func _office_edge() -> void:
	for z in [-15,0,34,53,76,94]:
		for x in [136,154,176]:
			tree_sites.append(Vector4(x+sin(z)*2,-.25,z+cos(x)*3,11+sin(x+z)*2))
	_logs(Vector3(36.9,0,57),3.2,3,PI*.5,"电报房冬用柴垛")
	_prop("wine_barrel_01",Vector3(37,0,52.5),Vector3(.7,.95,.7),.2,"房侧储水桶")
	_prop("wooden_crate_01",Vector3(37.1,0,50.9),Vector3(.85,.65,.7),-.12,"房侧日用箱")
	for at in [Vector3(31,0,65),Vector3(31,0,29),Vector3(47,0,19.1),Vector3(64,0,25)]:
		_rock(at-Vector3.UP*.15,Vector3(1.1,.72,1.6),placements.size(),at.z)
	for at in [Vector3(39.1,0,62),Vector3(31,0,33),Vector3(43,0,19),Vector3(67,0,25)]:
		tree_sites.append(Vector4(at.x,at.y,at.z,8.4))
	_patch(Vector3(37,.022,57),Vector2(1.8,3),"wood_chips")

func _patch(at: Vector3, size: Vector2, material: String) -> void:
	d._ground_patch("作业与林缘地表_"+material,at,size,w.AssetDressing.pbr(material,.28,Color("adb0a0")),80)

func _ground_cover() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var angle := i*TAU/5
		var side := Vector3(cos(angle),0,sin(angle))*.024
		var middle := Vector3(sin(angle)*.06,.19+i*.018,cos(angle)*.06)
		var tip := Vector3(sin(angle)*.15,.29+i*.025,cos(angle)*.16)
		w._triangle(surface,-side,side,middle+side*.5,Color.WHITE)
		w._triangle(surface,-side,middle+side*.5,middle-side*.5,Color.WHITE)
		w._triangle(surface,middle-side*.5,middle+side*.5,tip,Color.WHITE)
	surface.generate_normals()
	var rng := RandomNumberGenerator.new(); rng.seed=19381018
	var transforms: Array[Transform3D]=[]
	for attempt in 36000:
		if transforms.size()==3600: break
		var area: Rect2=Layout.AREAS[rng.randi_range(0,Layout.AREAS.size()-1)].grow(-.25)
		var at:=Vector3(rng.randf_range(area.position.x,area.end.x),.02,rng.randf_range(area.position.y,area.end.y))
		if Rect2(39,23,30,26).has_point(Vector2(at.x,at.z)): continue
		if [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN].all(func(offset): return w.first_level._inside(at.x+offset.x*1.7,at.z+offset.y*1.7)): continue
		var excluded:=false
		for footprint: Rect2 in w.first_level.structure_footprints:
			if footprint.grow(.3).has_point(Vector2(at.x,at.z)): excluded=true; break
		for i in range(1,Layout.ROUTE.size()):
			var a: Vector3=Layout.ROUTE[i-1]; var b: Vector3=Layout.ROUTE[i]
			if Geometry2D.get_closest_point_to_segment(Vector2(at.x,at.z),Vector2(a.x,a.z),Vector2(b.x,b.z)).distance_to(Vector2(at.x,at.z))<2.8: excluded=true; break
		if excluded: continue
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.7,1.5)),at))
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.use_colors=true
	multi.mesh=surface.commit(); multi.instance_count=transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_color(i,Color("7c805b").lerp(Color("495a3e"),rng.randf()))
	var grass:=MultiMeshInstance3D.new(); grass.name="首关路肩成簇野草"; grass.multimesh=multi
	grass.material_override=w.materials.reeds; grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.root.add_child(grass)
	w._ground_batches.append(grass)

func _hill_height(x: float, z: float) -> float:
	if x>80 and x<145 and z<112: return -.1
	var clearance := INF
	var at := Vector2(x,z)
	var footprints: Array = Layout.AREAS.duplicate()
	footprints.append_array(w.first_level.structure_footprints)
	for area: Rect2 in footprints:
		var nearest := Vector2(clampf(x,area.position.x,area.end.x),clampf(z,area.position.y,area.end.y))
		clearance = minf(clearance,at.distance_to(nearest))
	var west := exp(-pow((x+37)/27,2))* (18+9*sin(z*.022+.7)+6*sin(z*.053))
	var east := exp(-pow((x-112)/25,2))* (14+7*sin(z*.036)+4*cos(z*.071)) * smoothstep(94,132,z)
	var rear := exp(-pow((z-345)/29,2))* (14+8*sin(x*.043))
	var height := maxf(maxf(west,east),rear)
	var noise := sin(x*.13+z*.08)*cos(z*.11-x*.09)*2
	return maxf(0,height+noise*smoothstep(0,8,height))*smoothstep(5,19,clearance)-.1

func _hills() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-40,377,6):
		for x in range(-94,151,6):
			var points := [Vector3(x,_hill_height(x,z),z),Vector3(x+6,_hill_height(x+6,z),z),Vector3(x+6,_hill_height(x+6,z+6),z+6),Vector3(x,_hill_height(x,z+6),z+6)]
			# Keep every playable foundation and the river completely flat.
			if points.all(func(p): return p.y<.01): continue
			for i in [0,2,1,0,3,2]:
				var p: Vector3 = points[i]
				surface.set_color(Color("7e8875").lerp(Color("afb09d"),clampf(p.y/32,0,1)))
				surface.add_vertex(p)
	surface.generate_normals()
	var ridge := MeshInstance3D.new()
	ridge.name = "林场外围起伏山脊"
	ridge.mesh = surface.commit()
	var material: StandardMaterial3D = w.AssetDressing.pbr("forest_ground_04",.16,Color("b0b8ac"))
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ridge.material_override = material
	ridge.set_meta("blockout_retained",true)
	w.root.add_child(ridge)
