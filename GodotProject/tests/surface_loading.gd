extends SceneTree
## Visual geometry and loading contacts; companion functional tests run real inputs.

const Forest = preload("res://scripts/forest_approach.gd")
var main: Node3D
var checks := 0
var failures: Array[String] = []
var output := OS.get_environment("FENGHUO_SURFACE_LOADING_OUTPUT")
var face_cache := {}

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(valid: bool, label: String) -> void:
	checks += 1
	if not valid:
		failures.append(label)
		push_error(label)
	else: print("PASS: ",label)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_surface_loading_%d.json" % OS.get_process_id()
	root.add_child(main)
	for i in 120:
		await process_frame
		if main.world.is_world_ready(): break
	check(main.world.is_world_ready(),"World finishes preparation before testing")
	if OS.get_environment("FENGHUO_SURFACE_NO_SHADOW")=="1": main.world.sunlight.shadow_enabled = false
	main.start_new()
	main.set_process(false)
	main.village.set_process(false)
	main.player.set_physics_process(false)
	main.player.set_process(false)
	for actor in main.guards+main.story.people.values(): actor.set_physics_process(false)
	main.hud.visible = false
	var hills: MeshInstance3D = main.find_child("环村山岭",true,false)
	var faces := hills.mesh.get_faces()
	var blocked := 0
	for i in range(1,Forest.ROAD.size()):
		for side in [-2.0,0.0,2.0]:
			var start: Vector3 = Forest.ROAD[i-1]+Vector3(side,1.6,0)
			var end: Vector3 = Forest.ROAD[i]+Vector3(side,1.6,0)
			for triangle in range(0,faces.size(),3):
				if Geometry3D.segment_intersects_triangle(start,end,hills.to_global(faces[triangle]),hills.to_global(faces[triangle+1]),hills.to_global(faces[triangle+2]))!=null: blocked += 1
	check(blocked==0,"Background mountain triangles never cross the woodland road at eye height")
	var lane: MeshInstance3D = main.find_child("引向村口的浅色土路",true,false)
	var vertices: PackedVector3Array = lane.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size()==(Forest.ROAD.size()-1)*6,"Joined road has one strip per segment with no extended overlapping ends")
	var normals: PackedVector3Array = lane.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var faces_up := true
	for normal in normals:
		if normal.y<.99: faces_up = false
	check(faces_up,"Woodland dirt road faces upward and remains visible above its ground")
	var above := true
	for vertex in vertices:
		if Forest.projection(vertex).distance<2.7 and vertex.y<=Forest.height_at(vertex): above = false
	check(above,"Visible road is above the playable terrain throughout its bends")
	var forest_ground: MeshInstance3D = main.find_child("渡河后起伏密林地表",true,false)
	var village_ground: MeshInstance3D = main.find_child("村庄山谷地面",true,false).get_child(0)
	var village_lane: MeshInstance3D = main.find_child("窄街转入院落的泥辙",true,false)
	var ground_overlaps := 0
	var road_overlaps := 0
	var gaps := 0
	for i in range(1,40):
		var segment := 9 if i<20 else 10
		var at: Vector3 = Forest.ROAD[segment].lerp(Forest.ROAD[segment+1],float(i%20)/20)
		for side in [-1.0,0.0,1.0]:
			var point := at+Vector3(side,0,0)
			var woods := surface_heights(forest_ground,point)
			var village := surface_heights(village_ground,point)
			if not woods.is_empty() and not village.is_empty() and absf(woods[0]-village[0])<.005: ground_overlaps += 1
			var layers := surface_heights(lane,point).size()+surface_heights(village_lane,point).size()
			if layers>1: road_overlaps += 1
			if layers==0: gaps += 1
	check(ground_overlaps==0,"Forest and village visible ground never share the entry ground plane (samples=%d)" % ground_overlaps)
	check(road_overlaps==0,"Village entry has a single dirt road layer (overlaps=%d)" % road_overlaps)
	check(gaps==0,"The shared road join has no visible gaps (gaps=%d)" % gaps)
	var join_clear := true
	for z_offset in [-.08,.08]:
		for x_offset in [-1.2,-.6,0,.6,1.2]:
			var point: Vector3 = Forest.ROAD[-1]+Vector3(x_offset,0,z_offset)
			if surface_heights(lane,point).size()+surface_heights(village_lane,point).size()!=1: join_clear = false
	check(join_clear,"Both sides of the narrowed village road seam contain exactly one road layer")
	for river in main.find_children("*","Node3D",true,false):
		if river.get_meta("user_waterfront","")!="river": continue
		var bank: MeshInstance3D = river.find_child("SuppliedRiverBank_2",true,false)
		check((bank.global_transform*bank.mesh.get_aabb()).end.y<-.025,"Imported riverbank does not share the ground plane")
	for dock in main.find_children("*","Node3D",true,false):
		if dock.get_meta("user_waterfront","")=="dock":
			check(dock.position.y>=.035,"Pier decking is lifted above the overlapping shore")
	await capture_view("forest-landing",Forest.ROAD[1],Forest.ROAD[2]+Vector3.UP*1.6)
	await capture_view("forest-village-bend",Forest.ROAD[8],Forest.ROAD[10]+Vector3.UP*1.6)
	await capture_view("village-entry-approach",Forest.ROAD[9],Forest.ROAD[-1]+Vector3.UP*.35)
	await capture_view("village-entry-join",Forest.ENTRANCE,Vector3(1147,.1,278))
	await capture_view("village-entry-ground",Vector3(1153,.08,291),Vector3(1154,0,288))
	await capture_view("ferry-surface",Vector3(79,.08,14),Vector3(88,0,18))

	main.player.position = Vector3(14,.08,276)
	main.player.camera.environment = null
	main.player.camera.rotation = Vector3.ZERO
	main.player.rotation = Vector3.ZERO
	main.player.model.position = main.player.WeaponVisuals.HIP_POSITIONS[0]
	main.player.model.rotation = main.player.WeaponVisuals.HIP_ROTATION
	main.player._animate_mechanism(1)
	await capture("rifle-support")
	var rig: Dictionary = main.player.weapon_rigs[0]
	check(rig.rounds.get_child_count()==5,"Original supplied cartridges animate as five independent meshes")
	for count in [1,3,5]:
		main.player.WeaponVisuals.prepare_reload(rig,count)
		var visible := 0
		for round in rig.rounds.get_children():
			if round.visible: visible += 1
		check(visible==count,"Loading shows only the actual %d required rounds" % count)
		var first_height := 0.0
		for t in [.39,.50,.60,.65]:
			main.player.reload_timer = (1-t)*main.player.WEAPONS[0].reload
			main.player._animate_mechanism(1)
			var top := -INF
			for round: MeshInstance3D in rig.rounds.get_children():
				if round.visible:
					var bounds: AABB = rig.root.global_transform.affine_inverse()*round.global_transform*round.mesh.get_aabb()
					top = maxf(top,bounds.end.y)
			if t==.39: first_height = top
			if t==.60:
				var thumb: Vector3 = rig.left.position+rig.left.basis*rig.left.loading_contact()
				check(thumb.distance_to(Vector3(0,top,.018))<.016,"Loading thumb contacts the actual top cartridge, count=%d" % count)
			if t==.65:
				check(top<.055 and top<first_height-.012,"Cartridges move below the receiver before the clip withdraws, count=%d" % count)
			if count==5: await capture("reload-%02d" % roundi(t*100))
		main.player.reload_timer = .27*main.player.WEAPONS[0].reload
		main.player._animate_mechanism(1)
		check(rig.clip.visible and rig.clip.position.y>.1,"Empty clip lifts away after loading, count=%d" % count)
		if count==5: await capture("reload-empty-clip")
	main.player.reload_timer = 0
	main.player._animate_mechanism(1)
	check(not rig.clip.visible,"Clip is hidden after the completed reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"},"  "))
	print("SURFACE LOADING: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	quit(0 if failures.is_empty() else 1)

func surface_heights(instance: MeshInstance3D, at: Vector3) -> Array[float]:
	var id := instance.get_instance_id()
	if not face_cache.has(id): face_cache[id] = instance.mesh.get_faces()
	var faces: PackedVector3Array = face_cache[id]
	var from := instance.to_local(at+Vector3.UP*8)
	var to := instance.to_local(at-Vector3.UP*.1)
	var heights: Array[float] = []
	for i in range(0,faces.size(),3):
		var hit = Geometry3D.segment_intersects_triangle(from,to,faces[i],faces[i+1],faces[i+2])
		if hit!=null:
			var height: float = instance.to_global(hit).y
			if heights.is_empty() or absf(height-heights[-1])>.001: heights.append(height)
	return heights

func capture_view(label: String, at: Vector3, target: Vector3) -> void:
	main.player.position = at
	main.player.rotation = Vector3.ZERO
	main.player.camera.look_at(target)
	main.player.reset_physics_interpolation()
	main.player.camera.environment = main.world.village_world.environment if at.x>900 else null
	await capture(label)

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(output)
	for i in 2: await process_frame
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	check(not raster.is_empty() and raster.save_png(output.path_join(label+".png"))==OK,"Rendered capture: "+label)
