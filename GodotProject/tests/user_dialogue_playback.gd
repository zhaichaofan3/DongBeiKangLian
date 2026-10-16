extends SceneTree

var main: Node3D
var evidence := ""
var measurements: Dictionary = {}
var checks: Array[Dictionary] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_DIALOGUE_PLAYBACK_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed":value,"description":description})
	print("PASS: " if value else "FAIL: ", description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://dialogue_playback_%d.json" % OS.get_process_id()
	main.set_process(false)
	main.start_with_opening()
	var opening = main.opening
	opening.set_process(false)
	opening.start("B")
	var bus := AudioServer.get_bus_index(&"Voice")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 0.5
	AudioServer.add_bus_effect(bus, capture)
	var start := Time.get_ticks_msec()
	var previous := start
	while opening.active and Time.get_ticks_msec() - start < 90000:
		await process_frame
		var now := Time.get_ticks_msec()
		opening.advance(float(now - previous) * 0.001)
		main.audio_mix.update_mix(float(now - previous) * 0.001)
		previous = now
		var samples := capture.get_buffer(capture.get_frames_available())
		for cue in opening.data.cues.B:
			if opening.current_cue != cue.id: continue
			if not measurements.has(cue.id):
				measurements[cue.id] = {"max_rms":0.0,"sample_blocks":0,"screenshot":false}
			var age: float = opening.clock - float(cue.start_ms) * 0.001
			if age > 0.35 and age < float(cue.end_ms - cue.start_ms) * 0.001 - 0.1 and not samples.is_empty():
				var energy := 0.0
				for sample in samples: energy += sample.length_squared() * 0.5
				var rms := sqrt(energy / samples.size())
				measurements[cue.id].max_rms = maxf(measurements[cue.id].max_rms, rms)
				measurements[cue.id].sample_blocks += 1
			if age > 0.7 and not measurements[cue.id].screenshot:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(evidence.path_join(str(cue.id) + ".png"))
				measurements[cue.id].screenshot = true
	var wall_seconds := float(Time.get_ticks_msec() - start) * 0.001
	check(not opening.active and main.mode == "playing", "Continuous B playback completes the gameplay handoff")
	check(wall_seconds > 79.0 and wall_seconds < 90.0, "Playback uses real elapsed time without accelerated audio")
	if "--expect-no-synthetic" in OS.get_cmdline_user_args():
		check(not ResourceLoader.exists("res://assets/audio/opening_voice/B1-L01.wav"), "Release pack excludes unused synthetic speech")
	for cue in opening.data.cues.B:
		var sample: Dictionary = measurements.get(cue.id, {})
		check(sample.get("sample_blocks", 0) > 0 and sample.get("screenshot", false), "Rendered and sampled cue: " + str(cue.id))
		var peak: float = sample.get("max_rms", -1.0)
		check(peak > 0.001 if cue.voice_status == "user_supplied_recording" else peak >= 0.0 and peak < 0.00001,
			("Recorded speech reaches Voice bus: " if cue.voice_status == "user_supplied_recording" else "Unrecorded subtitle has silent Voice bus: ") + str(cue.id))
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("playback.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed":passed,"checks":checks,"wall_seconds":wall_seconds,"measurements":measurements,
		"subjective_listening":"pending","audio_driver":AudioServer.get_driver_name()}, "  "))
	AudioServer.remove_bus_effect(bus, AudioServer.get_bus_effect_count(bus) - 1)
	for kind in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for sound in main.find_children("*", kind, true, false):
			sound.stream_paused = false
			sound.stop()
	await create_timer(0.2).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("USER DIALOGUE PLAYBACK: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	quit(0 if passed else 1)
