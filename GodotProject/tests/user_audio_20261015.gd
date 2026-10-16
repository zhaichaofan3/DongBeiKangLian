extends SceneTree
## User recording, global music ownership, persistence and continuous panorama.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	evidence = OS.get_environment("FENGHUO_USER_AUDIO_EVIDENCE")
	if "--qa" not in OS.get_cmdline_user_args() or evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks.append({"passed":value,"description":label})
	print("PASS: " if value else "FAIL: ",label)

func count_music() -> int:
	var count := 0
	for player in main.audio_mix.music:
		if player.playing: count += 1
	return count

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(label+".png"))==OK,"Capture "+label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path="user://user_audio_%d.json"%OS.get_process_id()
	main.presentation.settings_path="user://user_audio_%d.cfg"%OS.get_process_id()
	main.set_process(false)
	var mix=main.audio_mix
	check(count_music()==1 and mix.music_key=="user_global_20261015","Menu starts one global music stream")
	check(is_equal_approx(main.presentation.music_volume,.22) and mix.global_music.loop,"Music defaults to 22 percent and loops")
	check(mix.global_music.get_length()>1600,"Entire user background recording is available")
	main.hud.show_menu("briefing")
	main.hud._show_settings()
	var slider=main.hud.settings_panel.find_child("MusicVolume",true,false)
	check(slider!=null,"Settings exposes a background music slider")
	var master: float=AudioServer.get_bus_volume_db(0)
	slider.value=0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Voice")),"Music zero mutes only the music bus")
	slider.value=.31
	mix.update_mix(.1)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")) and is_equal_approx(AudioServer.get_bus_volume_db(0),master),"Restoring music leaves master and narration unchanged")
	var prefs=load("res://scripts/presentation.gd").new()
	prefs.settings_path=main.presentation.settings_path
	prefs.load_preferences()
	check(is_equal_approx(prefs.music_volume,.31),"Music preference survives config reload")
	main.presentation.change("music_volume",.22)
	slider.value=.22
	await capture("settings")
	main.start_with_opening()
	var opening=main.opening
	opening.set_process(false)
	check(count_music()==0 and mix.voice.stream==opening.HISTORY_AUDIO and mix.voice.playing,"A starts the supplied full recording with zero global music streams")
	check(absf(opening.HISTORY_AUDIO.get_length()-opening.data.durations_ms.A*.001)<.05,"History duration covers the full audio without cutting its tail")
	var stream=mix.voice.stream
	opening.advance(7)
	check(mix.voice.stream==stream and not opening.fired_sounds.has("voice_N02"),"Subtitle changes never replay synthetic A narration")
	opening.set_paused(true)
	check(mix.voice.stream_paused,"Pausing A pauses the complete recording")
	opening.advance(1)
	check(opening.clock==7,"Pause preserves camera and subtitle time")
	opening.set_paused(false)
	check(not mix.voice.stream_paused and count_music()==0,"Resuming A keeps global music silent")
	for sample in [{"time":54.0,"name":"glide-start"},{"time":60.5,"name":"glide-middle"},{"time":65.0,"name":"glide-end"}]:
		opening.preview_at("A",sample.time)
		check(opening.shot_id=="A-18" and count_music()==0,"One building shot carries added narration at %.1fs"%sample.time)
		await capture(sample.name)
	opening.preview_at("A",60.0)
	var previous: Vector3=opening.camera.position
	var previous_rotation: Quaternion=opening.camera.quaternion
	opening.advance(1.0/60.0)
	check(previous.distance_to(opening.camera.position)<.1 and previous_rotation.angle_to(opening.camera.quaternion)<.02,"Building camera movement is continuous between frames")
	opening.preview_at("A",66.0)
	check(not opening.title.text.is_empty() and opening.caption.text.is_empty(),"Title appears on the same panorama after the final words")
	opening.skip("A")
	check(count_music()==1 and mix.music_key=="user_global_20261015" and not mix.voice.playing,"Skipping A stops the mixed recording and restores one global score")
	opening.preview_at("B",2.1)
	mix.update_mix(.5)
	check(mix.voice.playing and mix.duck_db< -9.9,"B dialogue automatically lowers global background music")
	opening.set_paused(true)
	check(mix.music[mix.current_slot].stream_paused and mix.voice.stream_paused,"Pausing B immediately pauses music and dialogue")
	main.return_to_menu()
	check(count_music()==1 and not mix.voice.playing,"Leaving paused B releases narration and resumes one menu score")
	main.start_new()
	check(count_music()==1 and mix.music_key=="user_global_20261015","Direct gameplay starts one global score")
	main.start_with_opening()
	opening.set_process(false)
	opening.preview_at("A",68.17)
	opening.advance(.02)
	check(opening.part=="B" and count_music()==1 and mix.voice.stream!=opening.HISTORY_AUDIO,"Natural A completion restores B music and retires history audio")
	opening.finish()
	check(main.mode=="playing" and count_music()==1,"Gameplay handoff preserves one music stream")
	main.continue_checkpoint()
	check(main.mode=="playing" and count_music()==1,"Checkpoint load restores one music stream")
	var passed:=true
	for item in checks: passed=passed and item.passed
	FileAccess.open(evidence.path_join("user-audio.json"),FileAccess.WRITE).store_string(JSON.stringify({"all_passed":passed,"checks":checks,"listening":"pending","history_ms":68180,"history_shots":11,"global_music_default":.22},"  "))
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false): sound.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.presentation.settings_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	await create_timer(.1).timeout
	main.queue_free()
	await process_frame
	print("USER AUDIO: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	quit(0 if passed else 1)
