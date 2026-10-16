extends SceneTree

var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S31_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed":value,"description":description})
	print("PASS: " if value else "FAIL: ",description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s31_voice_%d.json" % OS.get_process_id()
	main.start_with_opening()
	var opening = main.opening
	opening.set_process(false)
	main.set_process(false)
	check(opening.voice_streams.size()==8 and opening.HISTORY_AUDIO.get_length()>68,"Complete user history MP3 and eight supplied dialogue MP3s load")
	check(main.audio_mix.voice.bus==&"Cinematic","Mixed history recording uses the complete cinematic volume bus")
	opening.preview_at("A",3.1)
	check(opening.current_cue=="N01" and main.audio_mix.voice.playing,"N01 appears over the complete user history recording")
	var stream_a: AudioStream = main.audio_mix.voice.stream
	opening.preview_at("A",3.3)
	check(main.audio_mix.voice.stream==stream_a,"Seeking within one cue does not restart the same voice take")
	opening.set_paused(true)
	check(main.audio_mix.voice.stream_paused,"Cinematic pause freezes the current voice take")
	opening.set_paused(false)
	opening.preview_at("B",2.1)
	check(opening.current_cue=="B1-L01" and main.audio_mix.voice.playing and main.audio_mix.voice.stream!=stream_a,"B1 dialogue replaces the narration take")
	opening.start("B")
	opening.set_process(false)
	var voiced: Array = []
	var silent: Array = []
	var recordings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/user_dialogue_20261015/manifest.json"))
	for cue in opening.data.cues.B:
		opening.preview_at("B", float(cue.start_ms) * 0.001 + 0.05)
		check(opening.current_cue==cue.id and opening.caption.text.ends_with(cue.text),"Subtitle retained: " + str(cue.id))
		if cue.voice_status == "user_supplied_recording":
			voiced.append(cue.id)
			var stream: AudioStream = opening.voice_streams.get(cue.id)
			check(stream!=null and stream.resource_path==cue.audio_source and main.audio_mix.voice.stream==stream and main.audio_mix.voice.playing,"Supplied recording selected: " + str(cue.id))
			var compressed := stream as AudioStreamMP3
			var hasher := HashingContext.new()
			hasher.start(HashingContext.HASH_SHA256)
			hasher.update(compressed.data if compressed != null else PackedByteArray())
			check(hasher.finish().hex_encode()==recordings.clips[cue.id].sha256,"Imported recording bytes match latest supplied take: " + str(cue.id))
			check(float(cue.end_ms-cue.start_ms)*0.001 + 0.01 >= stream.get_length(),"Subtitle covers complete recording: " + str(cue.id))
		else:
			silent.append(cue.id)
			check(not opening.voice_streams.has(cue.id) and not main.audio_mix.voice.playing and main.audio_mix.voice.stream==null,"Unrecorded dialogue is silent without fallback: " + str(cue.id))
	check(voiced.size()==8 and silent.size()==6,"Eight recorded and six silent dialogue cues; no temporary synthesis")
	opening.skip("B")
	check(not main.audio_mix.voice.playing,"Leaving the opening stops the last voice take")
	main.start_with_opening()
	opening.set_process(false)
	opening.preview_at("A",3.1)
	opening.skip("A")
	check(not main.audio_mix.voice.playing and opening.part=="B","Skipping a part clears voice before the next part begins")
	opening.abort()
	for kind in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for sound in main.find_children("*", kind, true, false):
			sound.stream_paused = false
			sound.stop()
	var cleanup_deadline := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < cleanup_deadline: await process_frame
	var passed:=true
	for item in checks: passed=passed and item.passed
	var report={"step":"S31","all_passed":passed,"checks":checks,"voice_count":opening.voice_streams.size(),"voiced_cues":voiced,"silent_cues":silent,"history":"user_supplied_full_mix","task_voice":"user_supplied_missing_lines_silent","listening":"pending"}
	FileAccess.open(evidence.path_join("voice-integration.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("S31 VOICE INTEGRATION: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
