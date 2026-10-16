extends SceneTree

var main: Node3D
var evidence := OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	if main.get_script()==null or not main.get_script().can_instantiate(): quit(1); return
	root.add_child(main)
	for i in 12: await physics_frame
	main.start_new()
	main.set_process(false)
	main.hud.visible = false
	for label: Label3D in main.find_children("*","Label3D",true,false):
		if label.text.contains("简化结构"): label.visible = false
	for guard in main.guards: guard.set_physics_process(false)
	for person in main.story.people.values(): person.set_physics_process(false)
	main.story._set_door(true)
	main.player.position = Vector3(45.8,.001,38)
	main.player.velocity = Vector3.ZERO
	await physics_frame
	var collision: KinematicCollision3D = main.player.move_and_collide(Vector3(.8,0,0),true)
	if collision!=null: print("ENTRY COLLISION: ",collision.get_collider().get_path()," point=",collision.get_position()," normal=",collision.get_normal())
	var rows := []
	for z in range(23,50):
		var row := ""
		for x in range(38,69):
			row += "." if main.world._path_segment_clear(Vector3(x,.08,z),Vector3(x,.08,z)) else "#"
		rows.append(row)
	FileAccess.open(evidence.path_join("office-occupancy.json"),FileAccess.WRITE).store_string(JSON.stringify({"x":38,"z":23,"rows":rows},"\t"))
	await capture("office-inside",Vector3(48.5,2,38.5),Vector3(60,1.6,32))
	await capture("office-back",Vector3(62,2,28),Vector3(49,1.6,38))
	await capture("hut-clean",Vector3(14, 1.65, 262),Vector3(11, 1.4, 133))
	var village = main.world.village_world
	var report := {"house_count":village.house_count,"wire_count":village.side_wires.size(),"stops":[],"enemies":[]}
	village.set_phase(2)
	await physics_frame
	var previous: Vector3 = village.START
	for section: Array in village.ROUTE_STOPS:
		for at: Vector3 in section:
			var route: PackedVector3Array = village.path(previous,at)
			report.stops.append({"at":[at.x,at.z],"clear":main.world._path_segment_clear(at,at),"path":route.size()})
			previous = at
	for id in main.VillageDirector.ENEMIES:
		var at: Vector3 = main.VillageDirector.ENEMIES[id][0]
		report.enemies.append({"id":id,"clear":main.world._path_segment_clear(at,at),"path":village.path(village.START,at).size()})
	village.set_phase(0)
	report.closed_gate_path = village.path(village.START,village.EXIT).size()
	FileAccess.open(evidence.path_join("village-survey.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	await capture("village-source-wide",Vector3(1230,60,315),Vector3(1125,3,165))
	await capture("village-lane",Vector3(1153,2,270),Vector3(1148,1.7,225))
	await capture("village-bend",Vector3(1143,2,173),Vector3(1141,1.7,135))
	await capture("village-north",Vector3(1147,2,100),Vector3(1147,1.7,48))
	await capture("village-logging-edge",Vector3(1091,5,267),Vector3(1069,1.4,247))
	main.queue_free()
	for i in 3: await physics_frame
	quit()

func capture(label: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	main.player.model.visible = false
	main.menu_camera.position = at
	main.menu_camera.environment = main.world.village_world.environment if at.x>900 else null
	main.menu_camera.look_at(target)
	main.menu_camera.current = true
	for i in 4: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label+".png"))
