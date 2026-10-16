extends SceneTree
var main: Node3D
var failures: Array[String]=[]
var checks:=0
var evidence:=OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")
var captures: Array[String]=[]

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures.append(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func _run() -> void:
	main=load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(15)
	main.start_new()
	main.set_process(false)
	for npc in main.story.people.values(): npc.set_physics_process(false)
	for guard in main.guards:
		guard.set_physics_process(false)
		guard.collision_layer=0
	check(main.world.first_level.ready,"First chapter navigation sampled from real colliders")
	var scenery: RefCounted = main.world.first_level.scenery
	var clean_atlas:=load("res://assets/user_expansion_20261015/camp_2_3d66Model-4690991-files-2.jpg")
	check(main.world.first_level.cleaned_camp_surfaces.size()>=8 and main.world.first_level.cleaned_camp_surfaces.all(func(material): return material.albedo_texture==clean_atlas),"All rebuilt camp huts share the atlas with English advertising removed")
	for at in [Vector3(10,0,286),Vector3(34,0,220),Vector3(56,0,166),Vector3(72,0,90),Vector3(34,0,60),Vector3(79,0,14)]:
		check(scenery._hill_height(at.x,at.z)<0,"Distant hill surface stays below playable foundations: "+str(at))
	for at in [Vector3(6.7,.48,272),Vector3(54,.5,230),Vector3(54,.5,141),Vector3(37,.5,57)]:
		var query:=PhysicsShapeQueryParameters3D.new()
		var probe:=SphereShape3D.new(); probe.radius=.5
		query.shape=probe; query.transform.origin=at; query.collision_mask=1
		check(not main.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),"New solid scenery has real contact: "+str(at))
	check(main.START.z==286 and main.linear.POINTS[0].distance_to(main.linear.POINTS[1])==76,"Opening encounters are separated by 76 metres")
	check(not main.world.path(main.START,main.Story.LOGGER).is_empty(),"Scout and optional logger are connected")
	for target in [Vector3(34,.08,194),Vector3(34,.08,118),main.EVAC]:
		check(main.world.path(main.START,target).is_empty(),"Closed first gate blocks all downstream routes: "+str(target))
	for i in 3:
		var p: Vector3=main.linear.POINTS[i]
		var before:=p+Vector3(0,-1.32,3) if i<2 else p+Vector3(-3,-1.32,0)
		var after:=p+Vector3(0,-1.32,-3) if i<2 else p+Vector3(3,-1.32,0)
		check(not main.world._path_segment_clear(before,after),"Closed gate physically blocks movement %d" % i)
		for offset in [-3.5,0,3.5]:
			var side:=Vector3(offset,0,0) if i<2 else Vector3(0,0,offset)
			check(not main.world._path_segment_clear(before+side,after+side),"Gate has no corner shortcut %d/%.1f" % [i,offset])
		main.world.set_route_gate(["checkpoint","yard","river"][i],true)
		await frames(3)
		check(not main.world.path(before,after).is_empty(),"Opened gate connects physical navigation %d" % i)
		if i<2: check(main.world.path(main.START,main.EVAC).is_empty(),"Later locked gate still blocks the ferry")
	main.story._set_door(true)
	await frames(3)
	var unsafe_edges: Array[String]=[]
	for y in main.world.GRID_SIZE.y-1:
		for x in main.world.GRID_SIZE.x-1:
			var a:=Vector2i(x,y)
			if main.world.navigation.is_point_solid(a): continue
			for delta: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN]:
				var b:=a+delta
				if main.world.navigation.is_point_solid(b): continue
				if not main.world._path_segment_clear(main.world.cell_position(a),main.world.cell_position(b)):
					unsafe_edges.append(str(a)+" -> "+str(b))
	check(unsafe_edges.is_empty(),"Every outdoor navigation connection clears the new solid scenery: "+str(unsafe_edges))
	for entry: Vector3 in main.REINFORCEMENT_ENTRIES.slice(0,2):
		check(not main.world.path(entry,main.EVAC).is_empty(),"Pursuit entrance connects to the new ferry: "+str(entry))
	for pair in [[Vector3(6,.08,274),Vector3(0,.08,274)],[Vector3(34,.08,188),Vector3(27,.08,188)],[Vector3(56,.08,176),Vector3(64,.08,176)],[Vector3(72,.08,90),Vector3(80,.08,90)]]:
		check(not main.world._path_segment_clear(pair[0],pair[1]),"Physical berm survives batching at "+str(pair[0]))
	var length:=0.0
	for i in range(1,main.Layout.ROUTE.size()):
		var a: Vector3=main.Layout.ROUTE[i-1]; var b: Vector3=main.Layout.ROUTE[i]
		var path: PackedVector3Array=main.world.path(a,b)
		if path.is_empty():
			for at: Vector3 in [a,b]:
				var q:=PhysicsShapeQueryParameters3D.new(); q.shape=main.player.collider.shape; q.collision_mask=1
				q.transform.origin=at+Vector3.UP*.99
				print("PATH DIAGNOSTIC: ",at," anchor=",main.world._path_anchor(at)," hits=",main.get_world_3d().direct_space_state.intersect_shape(q))
		check(not path.is_empty(),"Main path segment %02d is navigable" % i)
		for j in range(1,path.size()):
			length+=path[j-1].distance_to(path[j])
			if not main.world._path_segment_clear(path[j-1],path[j]): check(false,"Unsafe navigation segment "+str(path[j]))
	check(length>400,"Expanded critical path exceeds 400 metres including office objectives")
	for id in main.initial_roster():
		for at: Vector3 in main.initial_roster()[id]:
			check(main.Layout.contains(at) and main.world._path_segment_clear(at,at),"Guard fixture on free chapter ground: "+id+str(at))
	for pair in [[Vector3(34,1.6,200),Vector3(38,1.6,134)],[Vector3(34,1.6,124),Vector3(46,1.6,38)],[Vector3(14,1.6,276),Vector3(30,1.6,226)]]:
		var hit:=main.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pair[0],pair[1],1))
		check(not hit.is_empty(),"Opaque geography hides future encounter from "+str(pair[0]))
	for wire in main.world.side_wires: check(is_equal_approx(wire.get_child(0).shape.size.y,.8),"Branch wire remains thigh-height")
	main.story.met_scout=true
	main.linear.opened.assign(["checkpoint"])
	main.player.position=Vector3(34,.08,192)
	check(main.linear.target_position().is_equal_approx(Vector3(34,1.4,182)),"First transport hint points down the visible road")
	main.player.position=Vector3(34,.08,183)
	check(main.linear.target_position().is_equal_approx(Vector3(56,1.4,182)),"Transport hint follows the turn instead of pointing through the berm")
	main.linear.opened.assign(["checkpoint","yard"])
	main.player.position=Vector3(34,.08,183)
	check(main.linear.target_position().is_equal_approx(Vector3(56,1.4,182)),"Backtracking retains transport turns after the later gate opens")
	main.player.position=Vector3(71,.08,105)
	check(main.linear.target_position().is_equal_approx(Vector3(72,1.4,76)),"Office approach hint follows the eastern forest road")
	main.start_new()
	check(not main._read_save().is_empty(),"New chapter checkpoint reads back from disk")
	var old: Dictionary=main._snapshot().duplicate(true)
	old.map_revision=4
	old.player.position=[10,.08,86]
	old.story.lu_position=[47,.08,30]
	for id in old.encounter.active:
		var record: Dictionary=old.encounter.active[id]
		for key in ["position","patrol","last_seen"]:
			var at: Array=record[key]
			if at[2]>198: at[2]-=140
			elif at[2]>100: at[2]-=80
	FileAccess.open(main.save_path,FileAccess.WRITE).store_string(JSON.stringify(old))
	var migrated: Dictionary=main._read_save()
	check(not migrated.is_empty() and migrated.player.position[2]==286,"Revision 4 camp save migrates to the expanded entry")
	await legacy_checkpoints()
	main._ensure_opening()
	check(main.opening.data.durations_ms.A==68180 and main.opening.data.durations_ms.B==80100,"Original narration and dialogue timing remains unchanged")
	check(main.opening.BARRAGE.all(func(item): return item.at.z>=122 and item.at.z<170),"Opening barrage follows the relocated timber encounter")
	await capture("arrival",Vector3(10,1.65,288),Vector3(13,1.4,270))
	await capture("checkpoint",Vector3(34,1.65,246),Vector3(35,1.2,218))
	await capture("transport-turn",Vector3(34,1.65,188),Vector3(55,1.2,182))
	await capture("timber-yard",Vector3(34,1.65,165),Vector3(36,1.2,138))
	await capture("office-reveal",Vector3(34,1.65,65),Vector3(47,2,37))
	await capture("arrival-shelter",Vector3(13,1.65,283),Vector3(7.4,1.3,275))
	await capture("checkpoint-workside",Vector3(36,1.65,241),Vector3(52,1.1,231))
	await capture("timber-workside",Vector3(39,1.65,159),Vector3(52,1.1,144))
	await capture("loading-forest",Vector3(72,1.65,101),Vector3(72,1.1,81))
	await capture("office-approach",Vector3(34,1.65,69),Vector3(35,1.1,53))
	await capture("escort-road",Vector3(42,1.65,22),Vector3(64,1.1,22))
	await capture("ferry",Vector3(74,2.4,26),Vector3(88,.1,17))
	await capture("overview",Vector3(160,200,330),Vector3(32,0,158))
	if DisplayServer.get_name()!="headless":
		main.start_with_opening()
		main.opening.set_process(false)
		for sample in [["village-wide","A",5.0],["logging-wide","A",14.0],["timber-barrage","A",38.7],["village-to-camp","A",59.0],["mission-handoff","B",79.6]]:
			main.opening.preview_at(sample[1],sample[2])
			main.opening.camera.reset_physics_interpolation()
			await frames(15)
			await RenderingServer.frame_post_draw
			var path:=evidence.path_join(sample[0]+".png")
			root.get_texture().get_image().save_png(path)
			captures.append(path)
		main.opening.abort()
	FileAccess.open(evidence.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"critical_path_metres":length,"scenery_objects":scenery.placements.size(),"near_trees":scenery.tree_sites.size(),"captures":captures},"\t"))
	print("FIRST LEVEL REBUILD: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await frames(4)
	quit(0 if failures.is_empty() else 1)

func legacy_checkpoints() -> void:
	for phase in 4:
		main.start_new()
		main.set_process(false)
		main.story.met_scout=true
		main.story._set_door(phase>=2)
		main.linear.opened.assign([[],["checkpoint"],["checkpoint","yard"],["checkpoint","yard","river"]][phase])
		main.linear._sync_gates()
		main.stage=[0,0,1,2][phase]
		if phase==3:
			main.story.recruited=true
			main.story.people.lu.following=true
			main.linear.extraction_started=true
			main.linear.extraction_remaining=17.5
		var old: Dictionary=main._snapshot().duplicate(true)
		old.map_revision=4
		old.player.position=[[10,.08,86],[34,.08,54],[53.5,.08,38],[79,.08,14]][phase]
		old.player.magazines=[3,7]
		old.player.reserves=[27,39]
		for id in old.encounter.active:
			for key in ["position","patrol","last_seen"]:
				var at: Array=old.encounter.active[id][key]
				if at[2]>=198: at[2]-=140
				elif at[2]>=100: at[2]-=80
		FileAccess.open(main.save_path,FileAccess.WRITE).store_string(JSON.stringify(old))
		var saved: Dictionary=main._read_save()
		check(not saved.is_empty(),"Revision 4 checkpoint validates at story phase %d" % phase)
		if saved.is_empty(): continue
		main.checkpoint.clear()
		main.continue_checkpoint()
		for guard in main.guards: guard.set_physics_process(false)
		for npc in main.story.people.values(): npc.set_physics_process(false)
		await frames(3)
		check(main.stage==[0,0,1,2][phase] and main.player.magazines==[3,7] and main.player.reserves==[27,39],"Legacy story and ammunition survive disk restore %d" % phase)
		check(main.Layout.contains(main.player.position) and main.world._path_segment_clear(main.player.position,main.player.position),"Legacy restore lands on collision-free new ground %d" % phase)
		check(main.linear.opened==[[],["checkpoint"],["checkpoint","yard"],["checkpoint","yard","river"]][phase],"Legacy gates keep their exact progression %d" % phase)
		if phase==3: check(is_equal_approx(main.linear.extraction_remaining,17.5) and main.story.recruited,"Legacy hold preserves rescued courier and remaining time")
	main.start_new()
	for npc in main.story.people.values(): npc.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)

func capture(label: String,at: Vector3,target: Vector3) -> void:
	if DisplayServer.get_name()=="headless": return
	main.player.model.visible=false
	main.menu_camera.position=at
	main.menu_camera.look_at(target)
	main.menu_camera.current=true
	main.hud.visible=false
	main.menu_camera.reset_physics_interpolation()
	await frames(15)
	await RenderingServer.frame_post_draw
	var path:=evidence.path_join(label+".png")
	root.get_texture().get_image().save_png(path)
	captures.append(path)
