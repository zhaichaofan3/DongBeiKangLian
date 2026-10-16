extends SceneTree
## Exercise persisted UI settings against actual playback routes and transitions.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""
var captures: Array[String] = []

func _initialize() -> void:
	evidence = OS.get_environment("FENGHUO_AUDIO_SETTINGS_EVIDENCE")
	if "--qa" not in OS.get_cmdline_user_args() or evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed":value,"description":description})
	print("PASS: " if value else "FAIL: ", description)

func frames(count: int = 3) -> void:
	for i in count: await process_frame

func slider(node_name: String) -> HSlider:
	return main.hud.settings_panel.find_child(node_name, true, false) as HSlider

func muted(bus: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))

func gain(bus: StringName) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))

func effective_gain(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	var result := 1.0
	for i in AudioServer.bus_count:
		if AudioServer.is_bus_mute(index): return 0.0
		result *= db_to_linear(AudioServer.get_bus_volume_db(index))
		if index == 0: return result
		index = AudioServer.get_bus_index(AudioServer.get_bus_send(index))
	return -1.0

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	await RenderingServer.frame_post_draw
	var file_name := label + ".png"
	check(root.get_texture().get_image().save_png(evidence.path_join(file_name)) == OK, "Capture " + label)
	captures.append(file_name)

func freeze() -> void:
	main.set_process(false)
	main.player.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	main.hud.set_process(false)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.save_path = "user://audio_settings_%d.json" % OS.get_process_id()
	main.presentation.settings_path = "user://audio_settings_%d.cfg" % OS.get_process_id()
	freeze()
	var prefs = main.presentation
	var mix = main.audio_mix
	main.hud.show_menu("briefing")
	main.hud._show_settings()
	await frames()
	check(slider("MusicVolume") != null and slider("SfxVolume") != null and slider("DialogueVolume") != null and slider("CinematicVolume") != null, "Settings exposes all four requested volume controls")
	check(is_equal_approx(prefs.music_volume, .22) and prefs.sfx_volume == 1 and prefs.dialogue_volume == 1 and prefs.cinematic_volume == 1, "Existing music default is preserved and new controls default to full volume")
	var master: float = gain(&"Master")
	slider("MusicVolume").value = 0
	check(muted(&"Music") and not muted(&"Voice") and not muted(&"Weapons"), "Music zero leaves speech and effects audible")
	slider("MusicVolume").value = .32
	slider("SfxVolume").value = 0
	check(muted(&"Weapons") and muted(&"Foley") and muted(&"Ambience") and not muted(&"Music") and not muted(&"Voice"), "Effects zero independently mutes weapons, footsteps and environment")
	slider("SfxVolume").value = .55
	slider("DialogueVolume").value = 0
	check(muted(&"Voice") and not muted(&"Weapons") and not muted(&"Music"), "Dialogue zero independently mutes speech")
	slider("DialogueVolume").value = .73
	slider("CinematicVolume").value = 0
	check(muted(&"Cinematic") and is_equal_approx(effective_gain(&"Voice"), master * .73) and effective_gain(&"Music") > 0, "Cinematic mute has no effect on ordinary menu or gameplay routes")
	slider("CinematicVolume").value = .40
	check(slider("SfxVolume").get_parent().get_node("Percent").text == "55%", "Slider percentage updates with the preference")
	check(is_equal_approx(gain(&"Master"), master), "Category changes preserve master volume")
	var loaded = load("res://scripts/presentation.gd").new()
	loaded.settings_path = prefs.settings_path
	loaded.load_preferences()
	check(is_equal_approx(loaded.music_volume,.32) and is_equal_approx(loaded.sfx_volume,.55) and is_equal_approx(loaded.dialogue_volume,.73) and is_equal_approx(loaded.cinematic_volume,.40), "All four slider preferences survive reload from disk")
	await capture("settings-volumes")
	var viewport_rect := Rect2(Vector2.ZERO, main.hud.root.size)
	check(viewport_rect.encloses(main.hud.actions.get_child(0).get_global_rect()) and viewport_rect.encloses(main.hud.menu_title.get_global_rect()), "Settings title and fixed return button stay inside the viewport")
	check(main.hud.settings_scroll.get_global_rect().encloses(slider("CinematicVolume").get_global_rect()), "All four volume controls are visible without scrolling")
	main.hud.settings_scroll.scroll_vertical = 10000
	await frames()
	check(main.hud.settings_scroll.scroll_vertical > 0, "Long settings page can scroll to the remaining controls")
	await capture("settings-controls")
	main.hud.actions.get_child(0).pressed.emit()
	check(not main.hud.settings_scroll.visible and main.mode == "briefing", "Return closes the settings page without starting a task")
	main.start_new()
	freeze()
	mix.update_mix(.1)
	mix.play_voice(load("res://scripts/audio_factory.gd").make_wind())
	mix.update_mix(.5)
	check(is_equal_approx(gain(&"Weapons"),.55) and is_equal_approx(gain(&"Foley"),.55) and is_equal_approx(gain(&"Ambience"),.55 * db_to_linear(-3)), "Dialogue ducking preserves the user's effect gain across updates")
	check(is_equal_approx(gain(&"Music"),.32 * db_to_linear(-10)) and is_equal_approx(gain(&"Voice"),.73), "Music ducking combines with music preference while speech retains its own gain")
	check(main.guards.all(func(guard): return guard.alert_audio.bus == &"Voice"), "All three enemy discovery recordings use dialogue volume")
	check(main.player.sound.bus == &"Weapons" and main.player.bolt_sound.bus == &"Foley" and main.player.footsteps.bus == &"Foley" and main.story.moments.river_audio.bus == &"Ambience", "Actual gun, bolt, footstep and river players use effect categories")
	main.start_with_opening()
	freeze()
	var opening = main.opening
	opening.set_process(false)
	check(mix.voice.playing and mix.voice.bus == &"Cinematic" and is_equal_approx(effective_gain(mix.voice.bus), master * .40), "Complete history recording uses cinematic volume exactly once")
	prefs.change("dialogue_volume",0)
	prefs.change("music_volume",0)
	check(effective_gain(mix.voice.bus) > 0 and not mix.music[0].playing and not mix.music[1].playing, "History mixed narration survives separate dialogue and music mute with no extra score")
	prefs.change("cinematic_volume",0)
	check(effective_gain(mix.voice.bus) == 0 and effective_gain(opening.shot_audio.bus) == 0 and effective_gain(main.ambience.bus) == 0, "Cinematic zero mutes the complete history scene including extra effects")
	opening.preview_at("A",12.0)
	opening.set_paused(true)
	main.hud.show_menu(main.mode)
	main.hud._show_settings()
	await frames()
	var clock_before: float = opening.clock
	var stream_before: AudioStream = mix.voice.stream
	var playback_before: float = mix.voice.get_playback_position()
	slider("CinematicVolume").value = .4
	slider("MusicVolume").value = .32
	slider("DialogueVolume").value = .73
	mix.update_mix(2)
	await frames()
	check(mix.voice.stream_paused and opening.clock == clock_before and mix.voice.stream == stream_before and absf(mix.voice.get_playback_position()-playback_before) < .05, "Changing sliders during pause does not resume, seek or restart the recording")
	check(is_equal_approx(effective_gain(mix.voice.bus),master*.4), "Cinematic slider applies immediately while paused")
	await capture("settings-paused-opening")
	main.hud.actions.get_child(0).pressed.emit()
	main.resume()
	check(not mix.voice.stream_paused and opening.clock == clock_before, "Resume retains cinematic time after settings changes")
	opening.preview_at("B",2.1)
	mix.update_mix(.5)
	check(mix.voice.bus == &"Voice" and is_equal_approx(effective_gain(mix.voice.bus),master*.73*.4), "Task dialogue combines dialogue and cinematic volume")
	check(is_equal_approx(effective_gain(&"Music"),master*.32*.4*db_to_linear(-10)) and is_equal_approx(effective_gain(opening.step_audio.bus),master*.55*.4), "Task music and footsteps combine their category with cinematic volume")
	prefs.change("dialogue_volume",0)
	check(effective_gain(mix.voice.bus) == 0 and effective_gain(&"Music") > 0, "Dialogue mute in task cinematic leaves its music audible")
	prefs.change("dialogue_volume",.73)
	prefs.change("cinematic_volume",0)
	check(effective_gain(&"Voice") == 0 and effective_gain(&"Music") == 0 and effective_gain(&"Foley") == 0, "Cinematic zero mutes all layers of the task introduction")
	opening.skip("B")
	check(main.mode == "playing" and not opening.active and is_equal_approx(effective_gain(&"Voice"),master*.73) and effective_gain(&"Music") > 0, "Skipping the opening immediately restores gameplay audio despite cinematic mute")
	mix.play_voice(opening.HISTORY_AUDIO)
	check(mix.voice.bus == &"Voice" and effective_gain(mix.voice.bus) > 0, "Non-cinematic voice playback uses dialogue volume after the handoff")
	main.start_with_opening()
	freeze()
	opening.set_process(false)
	opening.set_paused(true)
	main.return_to_menu()
	check(not opening.active and not mix.voice.playing and effective_gain(&"Music") > 0 and AudioServer.get_bus_send(AudioServer.get_bus_index(&"Voice")) == &"Master", "Leaving a paused opening restores menu routing immediately")
	main.start_new()
	freeze()
	mix.update_mix(.5)
	check(is_equal_approx(effective_gain(&"Weapons"),master*.55) and is_equal_approx(gain(&"Voice"),.73), "Starting another game keeps user category settings and normal routing")
	var config := ConfigFile.new()
	config.set_value("presentation","music_volume",.17)
	config.save(prefs.settings_path)
	loaded = load("res://scripts/presentation.gd").new()
	loaded.settings_path = prefs.settings_path
	loaded.load_preferences()
	check(is_equal_approx(loaded.music_volume,.17) and loaded.sfx_volume == 1 and loaded.dialogue_volume == 1 and loaded.cinematic_volume == 1, "Old configuration without new keys keeps its music level and safe full-volume defaults")
	config.set_value("presentation","sfx_volume","invalid")
	config.set_value("presentation","dialogue_volume",-5)
	config.set_value("presentation","cinematic_volume",5)
	config.set_value("presentation","music_volume",INF)
	config.save(prefs.settings_path)
	loaded = load("res://scripts/presentation.gd").new()
	loaded.settings_path = prefs.settings_path
	loaded.load_preferences()
	check(loaded.sfx_volume == 1 and loaded.dialogue_volume == 0 and loaded.cinematic_volume == 1 and is_equal_approx(loaded.music_volume,.22), "Invalid and nonfinite config values fall back; out-of-range numeric values are clamped")
	main.hud.show_menu("paused")
	main.hud._show_settings()
	slider("MasterVolume").value = 0
	check(effective_gain(&"Voice") == 0 and effective_gain(&"Music") == 0 and effective_gain(&"Weapons") == 0, "Existing master mute still silences every category")
	slider("MasterVolume").value = .65
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs.settings_path))
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false):
			sound.stream_paused = false
			sound.stop()
	main.queue_free()
	await frames()
	OS.delay_msec(150)
	await frames()
	var passed := checks.all(func(item): return item.passed)
	FileAccess.open(evidence.path_join("audio-settings.json"),FileAccess.WRITE).store_string(JSON.stringify({"all_passed":passed,"checks":checks,"captures":captures,"human_listening":"pending"},"  "))
	print("AUDIO SETTINGS: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	quit(0 if passed else 1)
