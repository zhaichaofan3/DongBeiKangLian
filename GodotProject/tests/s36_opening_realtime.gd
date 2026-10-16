extends SceneTree
## Normal-time complete opening on the release PCK; not a benchmark or listening verdict.
func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	var directory := OS.get_environment("FENGHUO_OPENING_EVIDENCE")
	if directory.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s36_realtime_%d.json" % OS.get_process_id()
	main.start_with_opening()
	Engine.max_fps = 60
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var started := Time.get_ticks_msec()
	var frames := 0
	var elapsed := 0.0
	var isolated := true
	var captures := {}
	var last_part := ""
	while main.opening.active and Time.get_ticks_msec() - started < 180000:
		await process_frame
		frames += 1
		elapsed += main.get_process_delta_time()
		if main.opening.active:
			isolated = isolated and main.kills == 0 and main.stage == 0 and main.player.magazines == [5,10] and main.player.position.is_equal_approx(main.START) and not main.story.recruited
			if main.opening.part != last_part:
				last_part = main.opening.part
				print("REALTIME PART: ", last_part)
			var shot_id: String = main.opening.shot_id
			if shot_id in ["A-11","A-16","A-18","B-06","B-07","B-16"] and not captures.has(shot_id):
				var midpoint: float = (main.opening.shot.start_ms + main.opening.shot.end_ms) * .0005
				if main.opening.clock >= midpoint:
					await RenderingServer.frame_post_draw
					captures[shot_id] = root.get_texture().get_image().save_png(directory.path_join(shot_id + ".png")) == OK
	var wall_seconds := (Time.get_ticks_msec() - started) * .001
	var expected: float = (main.opening.data.durations_ms.A + main.opening.data.durations_ms.B) * .001 + main.opening.HANDOFF_TRANSITION_SECONDS
	var passed: bool = not main.opening.active and main.mode == "playing" and main.opening.handoff_count == 1 and main.opening.seen_shots.size() == 27 and main.opening.seen_cues.size() == 31 and isolated and main.story.met_scout and absf(elapsed - expected) < .25 and absf(wall_seconds - elapsed) < 1.5 and ProjectSettings.get_setting("application/config/version") == "0.7.0-rc1"
	var report := {"all_passed":passed,"version":ProjectSettings.get_setting("application/config/version"),"method":"Rendered real _process playback at normal speed, 60fps cap, no seeking or fixed-fps simulation; screenshots are diagnostic only, not performance samples","frames":frames,"elapsed_game_seconds":elapsed,"wall_seconds":wall_seconds,"expected_seconds":expected,"mission_isolated":isolated,"handoffs":main.opening.handoff_count,"shots":main.opening.seen_shots,"cues":main.opening.seen_cues,"ended_playing":main.mode == "playing","temporary_voice_count":main.opening.voice_streams.size(),"captures":captures,"human_listening":"pending","human_playtest":"pending"}
	FileAccess.open(directory.path_join("live_playback.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("S36 REALTIME OPENING: ", "PASS" if passed else "FAIL", " | wall_seconds=", wall_seconds)
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false): sound.stop()
	await create_timer(.2).timeout
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
