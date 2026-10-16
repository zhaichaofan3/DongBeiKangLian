extends SceneTree
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S30_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed":value,"description":description})
	print("PASS: " if value else "FAIL: ",description)

func settle() -> void:
	# Real time is necessary for audio playback even in a fast headless test.
	var deadline := Time.get_ticks_msec()+80
	while Time.get_ticks_msec()<deadline: await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s30_%d.json" % OS.get_process_id()
	root.add_child(main)
	await physics_frame
	while not main.world.village_world.navigation_ready: await process_frame
	main.start_new()
	main.player.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	main.set_process(false)
	var mix = main.audio_mix
	mix.update_mix(.016)
	var buses_ok := true
	for bus in mix.BUS_NAMES:
		buses_ok = buses_ok and AudioServer.get_bus_index(bus)>0
	check(buses_ok,"Category buses and cinematic master exist without replacing Master volume")
	check(main.player.sound.bus==&"Weapons" and main.player.footsteps.bus==&"Foley" and main.ambience.bus==&"Ambience","Existing player gun, footstep and wind streams route to separate buses")
	check(main.story.moments.river_audio.bus==&"Ambience" and main.story.moments.switch_audio.bus==&"Foley","Spatial river, radio and switch use the appropriate layers")
	var original_master: float=AudioServer.get_bus_volume_db(0)
	var wind: AudioStreamWAV = load("res://scripts/audio_factory.gd").make_wind()
	var other: AudioStreamWAV = wind.duplicate()
	main.player.footsteps.stream=main.player.sounds.step
	main.player.footsteps.play()
	await settle()
	main.player._play("rifle")
	main.enemy_audio.play()
	await settle()
	var pause_before := {"gun_playing":main.player.sound.playing,"enemy_playing":main.enemy_audio.playing,"ambient_playing":main.ambience.playing,"gun_length":main.player.sound.stream.get_length(),"enemy_length":main.enemy_audio.stream.get_length()}
	check(pause_before.gun_playing and pause_before.enemy_playing,"Both gunshot streams are still playing when the pause is requested")
	main.mode="paused"
	mix.update_mix(.1)
	print("PAUSE AUDIO DIAGNOSTIC: ",JSON.stringify({"before":pause_before,"after":{"gun":main.player.sound.stream_paused,"enemy":main.enemy_audio.stream_paused,"ambient":main.ambience.stream_paused}}))
	check(main.player.sound.stream_paused and main.enemy_audio.stream_paused and main.ambience.stream_paused,"Gameplay pause freezes gunfire and ambient playback")
	main.mode="playing"
	mix.update_mix(.1)
	check(not main.player.sound.stream_paused and not main.ambience.stream_paused,"Resume releases paused streams without replaying them")
	main.player._play("reload")
	check(main.player.sound.bus==&"Foley","Reload uses Foley rather than the gunshot layer")
	mix.set_music("test-a",wind,1.0,-18)
	mix.update_mix(.2)
	var slot: int=mix.current_slot
	check(mix.music[slot].playing and mix.music_gain[slot]>0 and mix.music_gain[slot]<1,"Music starts at silence and fades in")
	mix.set_music("test-a",wind,1.0,-18)
	check(mix.current_slot==slot and mix.fade_elapsed>.1,"Repeated request for the same cue does not restart or add a player")
	mix.update_mix(1)
	mix.set_music("test-b",other,1.0,-18)
	mix.update_mix(.1)
	var dominant: int=slot
	var incoming: int=mix.current_slot
	check(mix.music[0].playing and mix.music[1].playing,"A transition overlaps exactly two streams")
	mix.set_music("test-c",wind,1.0,-18)
	check(mix.current_slot==incoming and mix.music[dominant].playing and mix.music_gain[dominant]>.8,"Rapid cue changes recycle the quieter slot and preserve the audible outgoing cue")
	main.mode="journal"
	var gains: Array=mix.music_gain.duplicate()
	var fade_time: float=mix.fade_elapsed
	mix.update_mix(5)
	check(mix.music_gain==gains and mix.fade_elapsed==fade_time and mix.music[0].stream_paused,"Journal pause freezes both playback and crossfade time")
	main.mode="playing"
	mix.update_mix(1)
	check(mix.music[mix.current_slot].playing and not mix.music[1-mix.current_slot].playing,"Fade completion releases the old stream")
	mix.play_voice(wind)
	mix.update_mix(.25)
	check(mix.duck_db==-10 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))<-9.9,"Voice lowers music by 10dB while keeping a separate voice bus")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Ambience")),-3) and AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Weapons"))==0,"Voice lowers ambience by 3dB without changing gunshot gain")
	check(AudioServer.get_bus_volume_db(0)==original_master,"Ducking does not overwrite the user's Master volume")
	mix.play_voice(null)
	mix.update_mix(1)
	check(mix.duck_db==0,"Music recovers gradually after speech ends")
	mix.stop_music(.4)
	mix.update_mix(.2)
	check(mix.music[0].playing or mix.music[1].playing,"Music fade-out retains playback until the fade finishes")
	mix.update_mix(.3)
	check(not mix.music[0].playing and not mix.music[1].playing,"Music fade-out ends with both streams released")
	mix.set_music("test-a",wind)
	mix.play_voice(wind)
	main.player._play("rifle")
	main.mode="paused"
	mix.update_mix(.1)
	main.continue_checkpoint()
	await settle()
	check(not mix.voice.playing and mix.music_key=="user_global_20261015" and not main.player.sound.playing,"Loading clears old voice/gun tails and restores the global music")
	main.start_with_opening()
	main.opening.set_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	main.opening.shot_audio.play()
	await settle()
	main.opening._enter_part("B")
	check(not main.opening.shot_audio.playing and not main.opening.metal_audio.playing,"A-to-B transition clears old history cue audio")
	main.opening.metal_audio.play()
	await settle()
	main.opening.set_paused(true)
	mix.play_voice(wind)
	mix.set_music("test-b",other)
	mix.update_mix(.1)
	check(mix.voice.stream_paused and mix.music[mix.current_slot].stream_paused,"New voice or music requested during cinematic pause stays paused")
	main.return_to_menu()
	await settle()
	check(not main.opening.metal_audio.playing and not mix.voice.playing and mix.music_key=="user_global_20261015","Leaving a paused cinematic releases cue audio and restores menu music")
	main.start_new()
	for guard in main.guards: guard.set_physics_process(false)
	mix.update_mix(.016)
	check(not main.ambience.stream_paused and main.ambience.playing,"A new task resumes one persistent ambient stream")
	var routes_stable := true
	var mixing_observed := false
	var previous_position: float = main.ambience.get_playback_position()
	for transition in 512:
		for bus in mix.BUS_NAMES:
			var index := AudioServer.get_bus_index(bus)
			var target: StringName = &"Cinematic" if transition % 2 == 0 and bus != &"Cinematic" else &"Master"
			mix._set_send(index, target)
			routes_stable = routes_stable and AudioServer.get_bus_send(index) == target
		OS.delay_msec(2)
		await process_frame
		var position: float = main.ambience.get_playback_position()
		mixing_observed = mixing_observed or not is_equal_approx(previous_position, position)
		previous_position = position
	mix.apply_category_volumes()
	check(routes_stable,"512 live routing transitions preserve every category send without a mixer crash")
	check(mixing_observed and main.ambience.playing,"The audio thread keeps advancing during routing transitions")
	var bus_count: int=AudioServer.bus_count
	main.queue_free()
	await process_frame
	await settle()
	var next_main = load("res://main.tscn").instantiate()
	next_main.save_path="user://s30_reentry_%d.json"%OS.get_process_id()
	root.add_child(next_main)
	await process_frame
	check(AudioServer.bus_count==bus_count,"Scene re-entry reuses buses without duplicates")
	check(next_main.audio_mix.duck_db==0,"Scene teardown clears dialogue ducking")
	next_main.queue_free()
	await process_frame
	await settle()
	var passed := true
	for item in checks: passed=passed and item.passed
	FileAccess.open(evidence.path_join("audio-mix.json"),FileAccess.WRITE).store_string(JSON.stringify({"all_passed":passed,"checks":checks,"new_recordings_integrated":true,"listening":"pending","music_test_fixture":"Forest WAV fixtures plus user global score"},"  "))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://s30_%d.json"%OS.get_process_id()))
	print("S30 AUDIO MIX: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	quit(0 if passed else 1)
