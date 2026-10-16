extends SceneTree
var main: Node3D
var passed := 0
var total := 0

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	total += 1
	if value:
		passed += 1
	print("PASS " if value else "FAIL ", description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_v04_story_moments.json"
	await process_frame
	main.start_new()
	for guard in main.guards:
		guard.set_physics_process(false)
	main.player.set_physics_process(false)
	main.story.moments.set_process(false)
	var moments: Node3D = main.story.moments
	var old_save: Dictionary = main.story.snapshot()
	old_save.erase("moments_seen")
	check(main.story.valid(old_save), "Pre-0.4 story saves remain accepted")
	main.story.restore(old_save)
	check(moments.seen.is_empty(), "Legacy restore initializes optional field dialogue state")
	main.story.met_scout = true
	main.player.position = Vector3(14, 0.08, 274)
	moments._process(2.0)
	check(moments.remaining > 0 and moments.caption.length() > 0 and main.mode == "playing", "Walking dialogue leaves player in live gameplay")
	var capture_path := OS.get_environment("FENGHUO_STORY_CAPTURE_PATH")
	if not capture_path.is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		check(root.get_texture().get_image().save_png(capture_path) == OK, "Live subtitle screenshot saved")
	var remaining: float = moments.remaining
	main.mode = "paused"
	moments._process(30.0)
	check(is_equal_approx(remaining, moments.remaining), "Pause does not consume an unheard subtitle")
	var saved: Dictionary = main.story.snapshot()
	main.story.restore(saved)
	main.resume()
	moments._process(30.0)
	check(moments.caption.is_empty(), "Saved field dialogue is not repeated on restore")
	main.stage = 2
	moments._process(0.1)
	check(not moments.radio_audio.playing and moments.switch_audio.playing, "Cutting power stops room radio and plays switch once")
	saved = main.story.snapshot()
	main.story.restore(saved)
	check(not moments.radio_audio.playing and not moments.switch_audio.playing, "Loading powered-off checkpoint does not replay the switch")
	var invalid := saved.duplicate(true)
	invalid.moments_seen = ["unrecognized"]
	check(not main.story.valid(invalid), "Unknown narrative flags are rejected safely")
	invalid.moments_seen = "departure"
	check(not main.story.valid(invalid), "Invalid narrative flag type is rejected safely")
	var river: AudioStream = moments.river_audio.stream
	check((river is AudioStreamMP3 and river.loop) or (river is AudioStreamWAV and river.loop_mode == AudioStreamWAV.LOOP_FORWARD), "River is a spatial looping stream")
	main.start_new()
	check(moments.seen.is_empty() and moments.radio_audio.playing, "New mission restores radio and fresh dialogue state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	for audio in [main.ambience, main.enemy_audio, main.player.sound, main.player.footsteps, moments.river_audio, moments.radio_audio, moments.switch_audio]:
		audio.stop()
	main.queue_free()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	print("STORY MOMENTS RESULT: %d/%d passed" % [passed, total])
	quit(0 if passed == total else 1)
