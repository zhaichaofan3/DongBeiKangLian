extends SceneTree

var main: Node3D
var evidence := OS.get_environment("FENGHUO_WORLD_EVIDENCE")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures.append(label)

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_world_revision.json"
	for i in 12: await physics_frame
	main.start_new()
	main.set_process(false)
	main.hud.visible = false
	main.player.set_physics_process(false)
	main.player.model.visible = false
	for guard in main.guards: guard.set_physics_process(false)
	for npc in main.story.people.values(): npc.set_physics_process(false)
	for pair in [[Vector3(38,1.6,32),Vector3(45,1.6,32)],[Vector3(38,1.6,44),Vector3(45,1.6,44)],[Vector3(54,1.6,20),Vector3(54,1.6,28)],[Vector3(70,1.6,36),Vector3(64,1.6,36)],[Vector3(54,1.6,51),Vector3(54,1.6,45)]]:
		check(not _ray(pair[0],pair[1]).is_empty(),"Office opaque enclosure blocks the outside view at "+str(pair[0]))
	main.story._set_door(true)
	for i in 3: await physics_frame
	check(main.world._path_segment_clear(Vector3(39,.08,38),Vector3(44,.08,38)),"Opening the existing door leaves a full-width physical entrance")
	for target in [Vector3(100,-1.3,4),Vector3(102,-1.3,14),Vector3(101,-1.3,26)]:
		var water_at = _surface_hit(main.world.water,Vector3(target.x,3,target.z))
		check(water_at!=null and _ray(Vector3(79,1.65,14),water_at+Vector3.UP*.03).is_empty(),"Actual river water is visible from the playable ferry at "+str(target))
	var village: RefCounted = main.world.village_world
	check(village.house_count==12 and village.courtyard_modules.size()==12,"Twelve large supplied courtyard groups form the compact village")
	check(village.scenery.tree_sites.size()>=120 and village.scenery.placements.size()>=25,"Near-field village trees, rocks and working-yard props are populated")
	var road := main.find_child("窄街转入院落的泥辙",true,false) as MeshInstance3D
	var normals: PackedVector3Array = road.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].y>.99,"Village road triangles face the player above ground")
	village.set_phase(2)
	for i in 2: await physics_frame
	var previous: Vector3 = village.START
	for section: Array in village.ROUTE_STOPS:
		for at: Vector3 in section:
			var road_hit = _surface_hit(road,at+Vector3(.017,3,.013))
			var path: PackedVector3Array = village.path(previous,at)
			if road_hit==null or path.is_empty(): print("ROAD DIAGNOSTIC: ",at," hit=",road_hit," path=",path.size())
			check(road_hit!=null and not path.is_empty(),"Visible dirt road and navigation reach "+str(at))
			previous = at
	for i in 2:
		village.set_phase(i)
		check(village.path(village.START,village.EXIT).is_empty(),"Village encounter gate still enforces sequence %d" % i)
	village.set_phase(0)
	await capture("office",Vector3(34,1.7,43),Vector3(54,1.5,36))
	await capture("ferry",Vector3(79,1.7,18),Vector3(102,-.1,14))
	await capture("village-entry",Vector3(1147,1.7,276),Vector3(1147,1.4,250))
	await capture("village-middle",Vector3(1147,1.7,210),Vector3(1143.5,1.3,204))
	await capture("village-north",Vector3(1150.5,1.7,67),Vector3(1150.5,1.3,62))
	main._ensure_opening()
	main.opening.start()
	main.opening.set_process(false)
	main.opening.preview_at("A",29)
	check(main.opening.shot_id=="A-09T" and main.opening.office_showcase_lights.visible,"The opening reaches a dedicated lit telegraph close-up")
	check(main.opening.data.durations_ms.A==68180 and main.opening.data.durations_ms.B==80100,"The complete supplied narration and task timing are retained")
	await _capture_current("telegraph")
	main.opening.finish()
	var film: Node3D = main.village.Journey.new()
	main.village.add_child(film)
	film.initialize(main,main.village)
	var docks: Array[MeshInstance3D] = []
	for node in main.find_children("*","Node3D",true,false):
		if node.get_meta("user_waterfront","")=="dock": docks.append_array(main.world.asset_dressing._meshes(node))
	var clear := true
	var wet := true
	var downstream := true
	var last := Vector3.ZERO
	for i in 311:
		var at := i*.1
		film.sample(at,0)
		var bounds := _bounds(film.boat)
		for dock in docks:
			if bounds.intersects(dock.global_transform*dock.get_aabb()): clear = false
		if at>=8 and at<=27:
			if at>8 and film.boat.global_position.z<last.z-.001: downstream = false
			last = film.boat.global_position
		if i%10==0: wet = wet and _water_under(film.boat.global_position)
	check(clear,"Hull and oars clear every pier mesh through 311 departure, travel and arrival samples")
	check(wet,"Every sampled boat position has actual water underneath")
	check(downstream,"Travel advances along the same downstream direction as the animated current")
	for sample in [[4.8,"boat-boarding"],[12,"boat-downstream"],[30.8,"boat-landing"]]:
		film.sample(sample[0],.016)
		await _capture_current(sample[1])
	film.release()
	film.queue_free()
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"near_trees":village.scenery.tree_sites.size(),"village_props":village.scenery.placements.size(),"renderer":DisplayServer.get_name()}
	FileAccess.open(evidence.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("WORLD REVISION: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	for i in 3: await physics_frame
	quit(0 if failures.is_empty() else 1)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return main.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func _surface_hit(mesh: MeshInstance3D, from: Vector3) -> Variant:
	var origin := mesh.to_local(from)
	var direction := mesh.global_transform.basis.inverse()*Vector3.DOWN
	var faces := mesh.mesh.get_faces()
	for i in range(0,faces.size(),3):
		var hit = Geometry3D.ray_intersects_triangle(origin,direction,faces[i],faces[i+1],faces[i+2])
		if hit!=null: return mesh.to_global(hit)
	return null

func _water_under(at: Vector3) -> bool:
	for mesh: MeshInstance3D in main.find_children("SuppliedRiverWater","MeshInstance3D",true,false):
		if _surface_hit(mesh,at+Vector3.UP*3)!=null: return true
	return false

func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	for mesh: MeshInstance3D in main.world.asset_dressing._meshes(node):
		var bounds := mesh.global_transform*mesh.get_aabb()
		result = bounds if result.size==Vector3.ZERO else result.merge(bounds)
	return result

func _capture_current(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for i in 4: await physics_frame
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors := {}
	for y in range(80,raster.get_height()-80,19):
		for x in range(20,raster.get_width()-20,19):
			var c := raster.get_pixel(x,y)
			colors[Vector3i(c.r*32,c.g*32,c.b*32)] = true
	check(colors.size()>40 and raster.save_png(evidence.path_join(label+".png"))==OK,"Nonblank rendered frame: "+label)

func capture(label: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name()=="headless": return
	main.menu_camera.position = at
	main.menu_camera.environment = main.world.village_world.environment if at.x>900 else null
	main.menu_camera.look_at(target)
	main.menu_camera.make_current()
	await _capture_current(label)
