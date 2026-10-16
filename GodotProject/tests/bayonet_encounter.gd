extends SceneTree

var main: Node3D
var checks := 0
var failures: Array[String] = []
var output := OS.get_environment("FENGHUO_BAYONET_EVIDENCE")
var capture := DisplayServer.get_name() != "headless"

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); printerr("FAIL: ",label)
	else: print("PASS: ",label)

func frames(n: int) -> void:
	for i in n:
		for guard in main.guards:
			if is_instance_valid(guard): guard.set_physics_process(false)
		await process_frame

func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)

func setup() -> void:
	main.start_new()
	# Previous saves retain their original second-door encounter.
	main.encounter_revision = 1
	main._reset_guards()
	main.story.met_scout = true
	for guard in main.guards:
		if guard.guard_id in ["gate_guard","yard_guard","timber_guard"]: guard.take_damage(1000)
	main.linear.opened.assign(["checkpoint"])
	main.linear._sync_gates()
	main.player.position = Vector3(34, 0.08, 124)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	await frames(2)

func shot(label: String) -> void:
	if not capture or output.is_empty(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func tap() -> void:
	key(KEY_SPACE,true)
	await frames(1)
	key(KEY_SPACE,false)
	await frames(8)

func _run() -> void:
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	await setup()
	check(not main.melee.active,"No ambush before opening the second door")
	main.interact()
	check(main.melee.active and main.melee.phase=="turn" and main.mode=="melee","Second door immediately starts the turn")
	check(main.audio_mix.voice.stream == main.melee.SHOUT and main.audio_mix.voice.playing,"User MP3 plays once at the turn")
	check(is_instance_valid(main.melee.blade),"Rifle carries an actual bayonet mesh")
	check(main._read_save().linear.opened == ["checkpoint"],"Checkpoint remains before second door until success")
	check(not main._save_checkpoint(),"Unfinished grapple cannot overwrite safe checkpoint")
	await frames(25)
	await shot("01-turn")
	var yaw: float = main.melee.enemy.rotation.y
	check(absf(yaw)>0.2,"Enemy visibly rotates from back-facing pose")
	key(KEY_ESCAPE,true)
	await frames(1)
	key(KEY_ESCAPE,false)
	var frozen: float = main.melee.clock
	var voice_position: float = main.audio_mix.voice.get_playback_position()
	await frames(35)
	check(main.mode=="paused" and main.melee.clock==frozen,"Escape freezes the encounter timer")
	check(main.audio_mix.voice.stream_paused and absf(main.audio_mix.voice.get_playback_position()-voice_position)<0.03,"Pause freezes the shout")
	main.hud._show_settings()
	await frames(2)
	main.hud.show_menu(main.mode)
	main.resume()
	check(main.mode=="melee" and not main.audio_mix.voice.stream_paused,"Settings return resumes the same encounter and sound")
	await frames(48)
	await shot("02-charge")
	check(main.melee.enemy.position.distance_to(main.melee.player_mark)<main.melee.starting_position.distance_to(main.melee.player_mark),"Enemy actually advances toward player")
	await frames(45)
	check(main.melee.phase=="struggle","Charge flows into close combat")
	check(main.melee.hands[0].visible and main.melee.hands[1].visible and not main.player.model.visible,"Both grappling hands replace the ordinary gun view")
	await shot("03-struggle")
	var before: int = main.melee.taps
	key(KEY_SPACE,true)
	await frames(1)
	for i in 15: key(KEY_SPACE,true,true)
	await frames(20)
	check(main.melee.taps==before+1,"Holding and keyboard repeat count as only one press")
	key(KEY_SPACE,false)
	await tap()
	check(main.melee.taps==before+2,"A released then repressed space adds a new effort")
	for i in 22:
		if main.melee.phase != "struggle": break
		await tap()
	check(main.melee.phase=="counter" and main.melee.taps>=10,"Repeated physical taps earn the counterattack")
	await frames(32)
	await shot("04-counter")
	await frames(24)
	main.melee.set_paused(true)
	var falling_enemy: Node3D = main.melee.enemy
	var fall_clock: float = main.melee.clock
	await frames(390)
	check(is_instance_valid(falling_enemy) and main.melee.clock==fall_clock,"Long pause during the fall cannot delete the actor or advance animation")
	main.resume()
	await frames(80)
	await shot("05-success")
	check(not main.melee.active and main.mode=="playing","Success returns player control")
	check(main.kills==4 and main.defeated.has("office_guard"),"Counterattack records exactly one guard defeat")
	check(main.player.camera.current and main.player.model.visible and not main.audio_mix.voice.playing,"Camera gun and audio restored after success")
	check(main._read_save().linear.opened == ["checkpoint","yard"],"Successful door and enemy state saved together")
	main.continue_checkpoint()
	main.interact()
	check(not main.melee.active and main.kills==4,"Success survives reload without duplicate encounter or kill")
	await setup()
	main.interact()
	await frames(400)
	await shot("06-failure")
	check(main.mode=="lost" and not main.melee.active,"No taps loses the grapple and exits cleanly")
	main.continue_checkpoint()
	check(main.mode=="playing" and main.player.health>0 and "yard" not in main.linear.opened,"Failure restores healthy player at closed second door")
	main.interact()
	check(main.melee.active,"Retry can trigger the same ambush")
	await frames(120)
	key(KEY_ESCAPE,true)
	await frames(1)
	key(KEY_ESCAPE,false)
	var taps_before: int = main.melee.taps
	key(KEY_SPACE,true)
	key(KEY_SPACE,false)
	await frames(1)
	check(main.melee.taps==taps_before,"Paused input cannot advance effort")
	main.return_to_menu()
	check(main.mode=="briefing" and not main.melee.active and not main.melee.panel.visible,"Menu return cleans camera hands overlay and encounter")
	main.continue_checkpoint()
	main.interact()
	await frames(120)
	main.continue_checkpoint()
	check(main.mode=="playing" and not main.melee.active and "yard" not in main.linear.opened,"Loading during the grapple restores the safe pre-door state")
	main.interact()
	await frames(120)
	main.start_new()
	check(not main.melee.active and main.kills==0 and main.linear.opened.is_empty(),"New task clears an interrupted grapple")
	await setup()
	main.save_path = "user://missing-bayonet-folder/cannot-save.json"
	main.interact()
	check(not main.melee.active and "yard" not in main.linear.opened,"Failed pre-door write leaves the door closed and replayable")
	main.save_path = "user://qa_qinglan_checkpoint_v2.json"
	var legacy: Dictionary = main._snapshot()
	legacy.linear.opened = ["checkpoint","yard"]
	var file := FileAccess.open(main.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy)); file.close()
	main.continue_checkpoint()
	check(main.mode=="playing" and not main.melee.active and "yard" in main.linear.opened,"Older saves beyond the door retain their progress")
	if not output.is_empty():
		var report := FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE)
		report.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty(),"rendered":capture,"human_playtest":false},"\t"))
		print("EVIDENCE: ",output)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("BAYONET ENCOUNTER: ","PASS" if failures.is_empty() else "FAIL"," ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
