extends SceneTree
## Runtime contracts for the S07 rough cut, using an isolated QA save.
var main: Node3D
var checks: Array[Dictionary] = []
var failures := 0
var output_dir := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks.append({"passed":value,"label":label})
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1

func _run() -> void:
	output_dir = OS.get_environment("FENGHUO_OPENING_EVIDENCE")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://qa_opening_s07.json"
	main.start_with_opening()
	var opening: Node3D = main.opening
	opening.set_process(false)
	main.set_process(false)
	check(main.mode=="cinematic" and opening.part=="A","New opening begins with A")
	check(main._read_save().get("opening",{}).get("phase","")=="history","A entry is a valid restorable save")
	var before: Dictionary = main._snapshot()
	opening.advance(4)
	check(opening.current_cue=="N01" and opening.caption.text=="作为中国共产党创建最早、","Fixed opening words appear unaltered")
	opening.set_paused(true)
	var time_before: float = opening.clock
	var actor_before: Transform3D = opening.camera.global_transform
	opening.advance(10)
	check(opening.clock==time_before and opening.camera.global_transform==actor_before,"Pause freezes timeline and camera")
	check(main.mode=="cinematic_paused" and main.ambience.stream_paused,"Pause freezes opening environment audio")
	main.hud.show_menu(main.mode)
	main.hud._show_settings()
	main.resume()
	check(main.mode=="cinematic" and opening.clock==time_before,"Settings/continue return to the same opening")
	opening.preview_at("A",39.0)
	var line: String = opening.caption.text
	opening.preview_at("A",39.2)
	check(opening.shot_id=="A-14" and opening.current_cue=="N13" and opening.caption.text==line,"N13 remains visible through the continuous battle shot")
	opening.preview_at("A",64.0)
	check(opening.current_cue=="N17" and opening.title.text.is_empty(),"New closing subtitle remains over the building glide before title")
	opening.preview_at("A",66.0)
	check(opening.caption.text.is_empty() and not opening.title.text.is_empty(),"Title follows subtitle clearance")
	check(main.stage==0 and main.kills==0 and main.player.magazines==[5,10] and main.player.position.is_equal_approx(main.START),"Cinematic shots do not change gameplay resources or position")
	check(main.story.snapshot()==before.story and main.linear.snapshot()==before.linear,"Cinematic shots do not change story or gates")
	main.start_with_opening()
	opening.set_process(false)
	for i in 9620:
		if not opening.active: break
		opening.advance(1.0/60.0)
	var complete_snapshot: Dictionary = main._snapshot()
	check(opening.seen_shots.size()==27,"All 27 shots are reached by continuous clock playback")
	check(opening.seen_cues.size()==31,"All 17 narration and 14 dialogue cues are reached")
	check(not opening.active and main.mode=="playing" and opening.handoff_count==1,"Full A/B playback commits gameplay once")
	_check_handoff("Full playback")
	var count: int = opening.handoff_count
	opening.finish()
	check(opening.handoff_count==count,"Repeated finish cannot duplicate the mission")
	main.start_with_opening()
	opening.set_process(false)
	opening.last_skip_ms = -1000
	opening.skip("A")
	check(opening.active and opening.part=="B" and not main.story.met_scout,"Skipping A starts B, not gameplay")
	check(main._read_save().get("opening",{}).get("phase","")=="task","B boundary has a valid restorable save")
	opening.skip("A")
	check(opening.part=="B" and opening.active,"Stale/double skip cannot skip the new part")
	opening.last_skip_ms = -1000
	opening.skip("B")
	_check_handoff("Skip A and B")
	check(_without_pose(main._snapshot())==_without_pose(complete_snapshot),"Skip and full playback produce the same mission state")
	main.start_with_opening()
	opening.set_process(false)
	opening.preview_at("A",68.17)
	opening.advance(.02)
	opening.last_skip_ms = -1000
	opening.skip("B")
	_check_handoff("Watch A then skip B")
	main.start_with_opening()
	opening.set_process(false)
	opening.last_skip_ms = -1000
	opening.skip("A")
	opening.preview_at("B",31.5)
	check(opening.title.text.contains("数日后") and opening.caption.text.is_empty(),"Travel time/place card is separate from spoken dialogue")
	for i in 3000:
		if not opening.active: break
		opening.advance(1.0/60.0)
	_check_handoff("Skip A then watch remaining B")
	main.start_with_opening()
	opening.set_process(false)
	opening.preview_at("A",40)
	main.continue_checkpoint()
	check(opening.active and opening.part=="A" and opening.clock==0,"History save resumes at A1")
	opening.set_process(false)
	opening.last_skip_ms = -1000
	opening.skip("A")
	opening.preview_at("B",50)
	main.continue_checkpoint()
	check(opening.active and opening.part=="B" and opening.clock==0,"Task save resumes at B1")
	opening.finish()
	main.continue_checkpoint()
	check(not opening.active and main.mode=="playing" and main.story.met_scout,"Gameplay save does not replay B or reset progress")
	main.start_new()
	var legacy: Dictionary = main._snapshot()
	legacy.erase("opening")
	_write_save(legacy)
	main.continue_checkpoint()
	check(not opening.active and not main.story.met_scout and main.mode=="playing","Legacy gameplay save retains its original briefing state")
	main.start_with_opening()
	opening.set_process(false)
	var bad: Dictionary = main._snapshot()
	bad.opening.phase = "unknown"
	_write_save(bad)
	main.continue_checkpoint()
	check(main.mode=="opening_load_error" and not opening.active,"Unknown opening state is rejected visibly, not treated as complete")
	check(FileAccess.get_file_as_string(main.save_path).contains("unknown"),"Invalid save remains available for diagnosis")
	main.start_with_opening()
	opening.set_process(false)
	var good_path: String = main.save_path
	var good_file := FileAccess.get_file_as_string(good_path)
	main.save_path = "user://s07_missing_parent/checkpoint.json"
	opening.finish()
	check(main.mode=="opening_save_error" and not opening.active,"Failed handoff save leaves a visible retry state")
	check(FileAccess.get_file_as_string(good_path)==good_file,"Failed write preserves previous successful save")
	main.save_path = good_path
	main.retry_opening_save()
	check(main.mode=="playing" and main.has_save(),"Retry saves the prepared gameplay state")
	if DisplayServer.get_name() != "headless":
		await _capture_shots()
	var report := {"step":"S07","scope":"runtime clock/state and optional rendered frame captures; no final animation or voiceover claim","passed":checks.size()-failures,"total":checks.size(),"all_passed":failures==0,"checks":checks}
	if not output_dir.is_empty():
		var file := FileAccess.open(output_dir.path_join("runtime_validation.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
	print("OPENING RESULT: %d/%d passed" % [checks.size()-failures,checks.size()])
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false): sound.stop()
	await process_frame
	# Allow the mixer thread to retire WAV playback before headless shutdown.
	OS.delay_msec(50)
	main.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _check_handoff(context: String) -> void:
	check(main.mode=="playing" and main.stage==0 and main.story.met_scout and not main.story.recruited and not main.story.supply_taken and not main.story.people.lu.treated,context+": briefing complete, task actions untouched")
	check(main.player.position.is_equal_approx(main.START) and is_equal_approx(main.player.rotation.y,-.6) and is_equal_approx(main.player.camera.fov,78) and main.player.camera.current,context+": camera and position align")
	check(main.alive_guard_count()==main.initial_roster().size() and main.kills==0 and main.linear.opened.is_empty() and not main.linear.contact_started and main.player.magazines==[5,10] and main.player.reserves==[35,50],context+": guards, gates and ammunition unchanged")

func _without_pose(snapshot: Dictionary) -> Dictionary:
	var result := snapshot.duplicate(true)
	# The existing encounter random idle facing is not part of the handoff contract.
	for guard in result.encounter.active.values(): guard.erase("yaw")
	return result

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(main.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _capture_shots() -> void:
	main.start_with_opening()
	main.opening.set_process(false)
	var capture_dir := output_dir.path_join("frames")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	for item in main.opening.data.shots:
		main.opening.preview_at(item.part,(float(item.start_ms)+float(item.end_ms))*.0005)
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var error := image.save_png(capture_dir.path_join(item.id+".png"))
		check(error==OK and not image.is_empty(),"Rendered "+item.id)
	main.opening.preview_at("B",79.5)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join("before-handoff.png"))
	main.opening.finish()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join("after-handoff.png"))
