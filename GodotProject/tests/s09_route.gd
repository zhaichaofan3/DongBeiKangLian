extends "res://tests/combat_route.gd"
## Actual input movement and combat. No position assignment, forced damage or gate unlock.
var case_id := "direct"
var evidence := ""
var checks: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var sample_frame := 0
var peak_guards := 0
var opening_seconds := 0.0
var entry_gates: Array = []

func check(value: bool, message: String) -> void:
	checks.append({"passed":value,"description":message})
	if not value:
		failed = true
		push_error(message)

func _run() -> void:
	evidence = OS.get_environment("FENGHUO_S09_EVIDENCE")
	case_id = OS.get_environment("FENGHUO_S09_CASE")
	main = load("res://main.tscn").instantiate()
	if main.get_script()==null or not main.get_script().can_instantiate():
		main.free()
		quit(2)
		return
	root.add_child(main)
	await process_frame
	main.save_path = "user://qa_s09_"+case_id+".json"
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if case_id == "direct":
		main.start_new()
	else:
		main.start_with_opening()
		if case_id == "skip":
			main.opening.skip("A")
			# Respect the real key debounce; do not alter its timestamp.
			OS.delay_msec(360)
			main.opening.skip("B")
		else:
			for frame in 10000:
				if not main.opening.active: break
				await process_frame
				opening_seconds += main.get_process_delta_time()
			check(main.opening.seen_shots.size()==28 and main.opening.seen_cues.size()==31 and absf(opening_seconds-148.48)<.15,"Full opening plays all 28 shots and 31 cues through actual process")
		check(not main.opening.active and main.opening.handoff_count==1 and main.story.met_scout,"Opening hands off once with briefing complete")
	entry_gates = main.linear.opened.duplicate()
	check(main.mode=="playing" and entry_gates.is_empty() and main.alive_guard_count()==5,"Every entry starts with five guards and all three gates closed")
	await _capture("Z0-start",Vector3(6.5, 1.8, 278.5))
	if case_id == "direct":
		await _walk(Vector3(12, 0, 284))
		main.interact()
		choose("brief")
	if case_id != "full":
		await _route(Vector3(14, 0, 268))
		main.interact()
		choose("ammunition" if case_id=="direct" else "medicine")
		check(main.story.supply_choice != "none","Optional logger supply reachable")
		await _capture("Z0-shelter",Vector3(11, 1.5, 133))
	await _route(Vector3(34, 0, 200))
	await _clear_gate("checkpoint")
	await _capture("Z1-warehouse",Vector3(54, 4, 213))
	await _route(Vector3(34, 0, 128))
	await _clear_gate("yard")
	if case_id=="direct":
		await _walk(Vector3(34, 0, 130))
		main.interact()
		check(main.story.supply_taken,"Timber lane medicine pickup remains reachable")
	await _capture("Z2-production",Vector3(54, 2.5, 132))
	await _route(Vector3(34, 0, 124))
	main.interact()
	check("yard" in main.linear.opened,"Two gates opened by normal guard conditions")
	await _win_grapple()
	if case_id=="direct":
		var before: Dictionary = main._snapshot()
		check(main._save_checkpoint(),"Mid-route save succeeds")
		main.continue_checkpoint()
		check(main.linear.opened==before.linear.opened and main.player.magazines==before.player.magazines and main.story.supply_taken,"Mid-route restore preserves gates, inventory and medicine pickup")
	await _route(Vector3(38,0,38))
	await _walk(Vector3(39.3,0,38))
	main.interact()
	check(main.story.door_open,"Office west door opens through normal interaction")
	await _walk(Vector3(46,0,38))
	if case_id=="skip":
		await _walk(Vector3(46,0,30))
		await _walk(Vector3(48.8,0,30))
		main.interact()
		choose("rescue_treat")
		check(main.story.recruited and main.stage==0,"Rescue can precede both mission objects")
		await _walk(Vector3(50,0,30))
	await _walk(Vector3(50,0,38))
	await _walk(Vector3(50,0,34))
	await _walk(Vector3(52,0,34))
	main.interact()
	check(main.stage==1,"Roster interaction reachable")
	await _walk(Vector3(52,0,36))
	await _walk(Vector3(58,0,36))
	await _capture("Z3-office",Vector3(59,1,41))
	await _walk(Vector3(58,0,30))
	main.interact()
	check(main.stage==2,"Power interaction reachable")
	if case_id!="skip":
		await _walk(Vector3(50,0,30))
		await _walk(Vector3(48.8,0,30))
		main.interact()
		choose("rescue" if case_id=="full" else "rescue_treat")
	check(main.story.recruited and main.story.people.lu.treated==(case_id!="full"),"Selected treated/untreated rescue is preserved")
	await _route(Vector3(38,0,38))
	await _wait_for_lu()
	await _capture("Z3-west-return",main.story.people.lu.position+Vector3.UP)
	await _route(Vector3(34,0,22))
	await _wait_for_lu()
	await _capture("Z4-north-escort",Vector3(54,4,10))
	await _route(Vector3(67,0,22))
	await _wait_for_lu()
	main.interact()
	check("river" in main.linear.opened,"River gate opens after objects and rescue")
	await _route(main.EVAC)
	await _wait_for_lu()
	await _capture("Z5-south-approach",Vector3(78, 1.5, 50))
	for frame in 3600:
		if failed or main.linear.can_evacuate(): break
		_combat()
		await physics_frame
	check(main.linear.can_evacuate() and main.story.people.lu.position.distance_to(main.EVAC)<5.5,"Courier follows west exit and north route and completes twelve-second extraction")
	main.interact()
	choose("finish")
	check(main.mode=="won" and main.player.health>0,"Mission ends in won with player alive")
	check(peak_guards<=6 and main.reinforcement_next>=2 and main.reinforcement_next<=4,"Reinforcements respect six-live-guard cap; evacuation does not require final wave kills")
	if case_id=="full": check(main.story.supply_choice=="none" and not main.story.people.lu.treated,"No optional supply or treatment is required to finish")
	var report := {"step":"S09","case":case_id,"all_passed":not failed,"checks":checks,"opening_seconds":opening_seconds,"gameplay_seconds":main.elapsed,"health":main.player.health,"kills":main.kills,"peak_live_guards":peak_guards,"reinforcements_dispatched":main.reinforcement_next,"final_mode":main.mode,"trace":trace,"method":"Actual movement input, real AI and physics, precise automatic aim; not a human pacing/difficulty measurement. No actor teleport or forced unlock in this route."}
	FileAccess.open(evidence.path_join("route.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("S09 ROUTE ",case_id,": ","PASS" if not failed else "FAIL"," | checks=",checks.size()," | seconds=",main.elapsed)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	# Let the audio thread retire playback references before this fast headless
	# controller exits (real play does not quit immediately on reaching the end).
	main.mode = "paused"
	_stop_audio(main)
	main.queue_free()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(1 if failed else 0)

func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
		node.stream_paused = false
		node.stop()
	for child in node.get_children(): _stop_audio(child)

func choose(action: String) -> void:
	if failed: return
	for i in main.story.choices.size():
		if main.story.choices[i].action==action:
			main.story.choose(i)
			return
	check(false,"Missing expected dialogue action: "+action)

func _wait_for_lu() -> void:
	if failed: return
	for frame in 2400:
		if main.player.position.distance_to(main.story.people.lu.position)<2.65: return
		_combat()
		await physics_frame
	check(false,"Courier did not catch up at "+str(main.player.position))

func _combat() -> void:
	super._combat()
	peak_guards = maxi(peak_guards,main.alive_guard_count())
	sample_frame += 1
	if sample_frame%30==0:
		var p: Vector3 = main.player.position
		var lu: Vector3 = main.story.people.lu.position
		trace.append({"seconds":main.elapsed,"player":[p.x,p.y,p.z],"lu":[lu.x,lu.y,lu.z],"gates":main.linear.opened.duplicate(),"stage":main.stage,"recruited":main.story.recruited})

func _capture(id: String, target: Vector3) -> void:
	if failed or DisplayServer.get_name()=="headless": return
	var old_rotation: Vector3 = main.player.camera.global_rotation
	main.player.camera.look_at(target)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(id+".png"))
	main.player.camera.global_rotation = old_rotation
