extends SceneTree

var main: Node3D
var evidence: String
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var intro_count := 0
var boat_samples: Array = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_RIVER_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(evidence)
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if value: print("PASS: ",description)
	else:
		failures.append(description)
		push_error(description)

func _frames(count: int) -> void:
	for i in count: await physics_frame

func _prepare() -> void:
	main.start_new()
	for guard in main.guards:
		guard.set_physics_process(false)
		guard.take_damage(1000)
	main.stage = 2
	main.story.met_scout = true
	main.story.recruited = true
	main.story.people.lu.following = true
	main.story.people.lu.position = main.EVAC+Vector3(-2,0,0)
	main.player.position = main.EVAC
	main.linear.opened.assign(main.linear.GATES)
	main.linear._sync_gates()
	main.linear.extraction_started = true
	main.linear.extraction_remaining = 0
	main._save_checkpoint()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_river_journey.json"
	await _frames(12)
	_prepare()
	var before: Dictionary = main._read_save()
	check(not before.is_empty(),"Complete departure checkpoint validates before boarding")
	main.village.depart()
	main.village.set_process(false)
	check(main.village.crossing and main.mode=="crossing","Ferry starts the two-person cinematic")
	var film: Node3D = main.village.journey
	check(is_instance_valid(film.rower.detailed_rig) and is_instance_valid(film.courier.detailed_rig),"Both passengers use the existing skinned friendly models")
	for sample in [[2.7,"boarding"],[4.8,"step-aboard"],[7.5,"seated"],[12.0,"river-wide"],[23.0,"river-onboard"],[30.0,"approaching-bank"],[35.7,"landing"]]:
		main.village.crossing_clock = sample[0]
		film.sample(sample[0],.016)
		await _frames(2)
		boat_samples.append({"time":sample[0],"boat":[film.boat.global_position.x,film.boat.global_position.y,film.boat.global_position.z],"shot":film.shot_id})
		check(film.camera.is_current() and film.camera.global_position.is_finite(),"Cinematic camera owns a finite frame: "+sample[1])
		if sample[0]>=7.5 and sample[0]<=23:
			check(film.rower.global_position.distance_to(film.boat.global_position)<1.3 and film.courier.global_position.distance_to(film.boat.global_position)<1.3,"Both seated passengers travel with the hull: "+sample[1])
		if sample[0]>=7.5 and sample[0]<=30:
			check(_water_under_hull(film.boat),"The hull is above actual river-water geometry: "+sample[1])
		await _capture(sample[1])
	check(Vector3(boat_samples[3].boat[0],0,boat_samples[3].boat[2]).distance_to(Vector3(boat_samples[4].boat[0],0,boat_samples[4].boat[2]))>35,"The boat visibly drifts downstream rather than remaining stationary")
	main.village.set_crossing_paused(true)
	var frozen: float = main.village.crossing_clock
	main.village._process(4)
	check(main.mode=="crossing_paused" and main.village.crossing_clock==frozen and film.water_audio.stream_paused,"Pausing freezes the crossing clock and river sound")
	await _capture("paused")
	main.resume()
	check(main.mode=="crossing" and not film.water_audio.stream_paused,"Resume restores the ferry cinematic")
	check(not main._save_checkpoint() and main._read_save().stage==2,"A mid-river save cannot replace the safe departure checkpoint")
	main.return_to_menu()
	await _frames(2)
	check(not main.village.crossing and main.mode=="briefing" and main.story.people.lu.visible,"Returning to menu cleans up the cinematic and restores gameplay actors")
	main.checkpoint.clear()
	main.continue_checkpoint()
	check(main.stage==2 and not main.village.entered,"Disk-only recovery during crossing resumes the safe departure")
	main.village.depart()
	main.village.set_process(true)
	var supplies: int = main.player.reserves[0]
	var skip := InputEventKey.new()
	skip.physical_keycode = KEY_ENTER
	skip.pressed = true
	main._unhandled_input(skip)
	await _frames(3)
	check(main.village.entered and main.village.approach_active and main.mode=="playing","Skipping hands control to the forest landing, retaining the playable approach")
	check(main.player.position.distance_to(main.village.Forest.LANDING)<1,"Player arrives at the shore, outside the village")
	check(not main.village.can_guard_act("village_0") and main.village.ally_shots==0,"Village combat stays inactive throughout the forest approach")
	check(main.player.reserves[0]==supplies+35,"Crossing grants the existing arrival supplies once")
	main.village.finish_crossing()
	check(main.player.reserves[0]==supplies+35,"Repeated finish cannot duplicate supplies")
	check(not main._read_save().is_empty(),"The landing checkpoint validates the enlarged chapter bounds")
	for guard in main.guards: guard.set_physics_process(false)
	var forest = main.world.village_world.forest
	check(forest.tree_count>1500,"The non-road woodland is densely populated using instanced existing pine models")
	check(forest.road_material.albedo_color.get_luminance()>forest.ground_material.albedo_color.get_luminance()*1.4,"The dirt route has substantially lighter colour than the forest floor")
	check(not main.world.village_world.path(main.village.Forest.LANDING,main.village.VillageWorld.START).is_empty(),"A navigation route connects the landing to the original village")
	check(await _walk(Vector3(1214,.08,436.4),1400),"The player can physically walk back along the landing pier")
	check(main._save_checkpoint() and not main._read_save().is_empty(),"The landing pier supports a valid checkpoint beyond the forest ground edge")
	main.player.rotation.y = PI
	Input.action_press("move_forward")
	for frame in 100:
		await physics_frame
		if main.player.position.z<430: break
	Input.action_release("move_forward")
	check(main.player.position.distance_to(main.village.Forest.LANDING)<1 and main.player.position.y>-.1,"Walking off the pier safely returns to shore without a soft lock")
	await _view("forest-landing",main.player.position+Vector3(0,1.58,0),main.village.Forest.ROAD[1]+Vector3.UP)
	for i in range(1,main.village.Forest.ROAD.size()):
		var at: Vector3 = main.village.Forest.ROAD[i]
		var reached := await _walk(at,1400)
		check(reached,"Real player movement follows the dirt road through bend %d" % i)
		if not reached: break
		if i==3:
			await _view("forest-bend",main.player.position+Vector3(0,1.58,0),main.village.Forest.ROAD[4]+Vector3.UP)
			check(main._save_checkpoint(),"A mid-forest checkpoint is written")
			var position_before: Vector3 = main.player.position
			main.checkpoint.clear()
			main.continue_checkpoint()
			for guard in main.guards: guard.set_physics_process(false)
			check(main.village.approach_active and main.player.position.distance_to(position_before)<.3,"Disk-only loading preserves forest progress instead of replaying the boat")
	check(main.village.intro_seen and not main.village.approach_active and intro_count==1,"The village introduction plays exactly once at the entrance")
	check(main.village.can_guard_act("village_0") and not main.village.can_guard_act("village_4"),"After the introduction only the first village encounter activates")
	check(main._save_checkpoint() and not main._read_save().is_empty(),"The post-introduction checkpoint is valid")
	main.checkpoint.clear()
	main.continue_checkpoint()
	await _frames(3)
	check(not main.village.approach_active and main.village.intro_seen and main.mode=="playing","Loading after the introduction does not repeat the dialogue")
	for guard in main.guards: guard.set_physics_process(false)
	main.village.set_process(false)
	for index in [2,3,5]:
		for side in [-1,1]:
			var at: Vector3 = main.village.Forest.ROAD[index]
			main.player.position = at+Vector3.UP*.1
			main.player.velocity = Vector3.ZERO
			main.player.horizontal_velocity = Vector2.ZERO
			main.player.reset_physics_interpolation()
			await _frames(3)
			var direction: Vector3 = (main.village.Forest.ROAD[index+1]-at).normalized()
			var lateral: Vector3 = Vector3(direction.z,0,-direction.x)*side
			main.player.rotation.y = atan2(-lateral.x,-lateral.z)
			Input.action_press("move_forward")
			Input.action_press("sprint")
			for frame in 150:
				if frame%38==0: Input.action_press("jump")
				if frame%38==1: Input.action_release("jump")
				await physics_frame
			Input.action_release("move_forward")
			Input.action_release("sprint")
			Input.action_release("jump")
			check(main.village.Forest.projection(main.player.position).distance<6,"Visible forest banks prevent sprint-jump shortcuts at bend %d side %d" % [index,side])
	# Earlier village saves continue their encounter without forcing the new route.
	var legacy: Dictionary = main._snapshot().duplicate(true)
	legacy.village.version = 2
	legacy.village.erase("approach_active")
	legacy.village.erase("intro_seen")
	legacy.player.position = [1153,.08,278]
	legacy.story.lu_position = [1149,.08,280]
	legacy.village.ally_position = [1156,.08,276]
	var file := FileAccess.open(main.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	main.checkpoint.clear()
	main.continue_checkpoint()
	check(main.village.entered and not main.village.approach_active and main.village.intro_seen,"Legacy village saves retain the original encounter and skip the new arrival")
	var bad: Dictionary = main.village.snapshot()
	bad.approach_active = true
	check(not main.village.valid_snapshot(bad),"Contradictory forest-introduction flags are rejected")
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"captures":captures,"boat_samples":boat_samples,"forest_trees":forest.tree_count,"renderer":DisplayServer.get_name()}
	FileAccess.open(evidence.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("RIVER JOURNEY: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	forest = null
	main.mode = "paused"
	main.audio_mix.set_process(false)
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false):
			sound.stop()
			sound.stream = null
	await process_frame
	OS.delay_msec(150)
	main.queue_free()
	await _frames(3)
	OS.delay_msec(150)
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _walk(target: Vector3, frames: int) -> bool:
	for frame in frames:
		if main.mode=="dialogue":
			intro_count += 1
			await _capture("village-introduction")
			main.story.choose(0)
		var offset: Vector3 = target-main.player.position
		offset.y = 0
		if offset.length()<.7:
			Input.action_release("move_forward")
			return true
		main.player.rotation.y = atan2(-offset.x,-offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	print("FOREST MOVEMENT BLOCKED: ",main.player.position," target=",target)
	return false

func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label+".png"))
	captures.append(label)

func _water_under_hull(hull: Node3D) -> bool:
	for mesh: MeshInstance3D in main.find_children("SuppliedRiverWater","MeshInstance3D",true,false):
		var local_origin: Vector3 = mesh.to_local(hull.global_position+Vector3.UP*3)
		var faces := mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			if Geometry3D.ray_intersects_triangle(local_origin,Vector3.DOWN,faces[i],faces[i+1],faces[i+2])!=null: return true
	return false

func _view(label: String, at: Vector3, target: Vector3) -> void:
	await _frames(50)
	main.menu_camera.global_position = at
	main.menu_camera.look_at(target)
	main.menu_camera.environment = main.world.village_world.environment
	main.menu_camera.make_current()
	await _frames(3)
	await _capture(label)
	main.player.camera.make_current()
