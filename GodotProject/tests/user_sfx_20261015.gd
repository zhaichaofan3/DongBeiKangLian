extends SceneTree
## Isolated gameplay events; optional captures come from the same running scene.
const AudioFactory = preload("res://scripts/audio_factory.gd")
var main: Node3D
var checks := 0
var failures: Array[String] = []
var evidence := OS.get_environment("FENGHUO_SFX_EVIDENCE")
var captures: Array[String] = []
var details: Array[Dictionary] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	details.append({"label":label, "passed":ok})
	if ok: print("PASS: ", label)
	else: failures.append(label); printerr("FAIL: ", label)

func frames(count: int) -> void:
	for i in count: await process_frame

func capture(name: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(evidence.path_join(name))
	if result == OK: captures.append(name)
	else: failures.append("Capture failed: " + name)

func freeze_guards() -> void:
	for guard in main.guards:
		if is_instance_valid(guard): guard.set_physics_process(false)

func stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
		node.stream_paused = false
		node.stop()
	for child in node.get_children(): stop_audio(child)

func _run() -> void:
	if not evidence.is_empty(): DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_user_sfx_20261015.json"
	await frames(3)
	main.start_new()
	freeze_guards()
	main.player.rotation.y = 0
	await frames(5)
	check(main.player.sounds.rifle == AudioFactory.USER_GUNSHOT and main.player.sounds.pistol == AudioFactory.USER_GUNSHOT, "Both player weapons use the user gunshot")
	check(main.enemy_audio.stream == AudioFactory.USER_GUNSHOT, "Enemy gunfire uses the user gunshot")
	var river: AudioStreamMP3 = main.story.moments.river_audio.stream
	check(river != null and river.data == AudioFactory.USER_RIVER.data and river.loop, "River uses the original MP3 bytes and loops continuously")
	check(not AudioFactory.USER_RIVER.loop and main.story.moments.river_audio.playing, "River loop leaves the shared source unchanged")
	Input.action_press("move_forward")
	await frames(50)
	check(main.player.horizontal_velocity.length() > 3 and main.player.footsteps.stream == AudioFactory.USER_STEP_WALK and main.player.footsteps.playing, "Real walking input plays normal footsteps")
	Input.action_press("sprint")
	await frames(38)
	check(main.player.horizontal_velocity.length() > 5 and main.player.footsteps.stream == AudioFactory.USER_STEP_RUN and main.player.footsteps.playing, "Real sprint input switches to running footsteps")
	await capture("sprint-footsteps.png")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await frames(22)
	check(not main.player.footsteps.playing, "Footsteps stop when the player stops")
	main.player.magazines[0] = 4
	main.player.start_reload()
	check(main.player.sound.stream == AudioFactory.USER_RELOAD and main.player.sound.playing, "Reload plays the user bolt recording")
	await frames(132)
	main.player.fire()
	check(main.player.sound.stream == AudioFactory.USER_GUNSHOT and main.player.sound.playing, "Firing plays the user gunshot")
	await frames(21)
	check(main.player.bolt_sound.playing and main.player.bolt_sound.stream == AudioFactory.USER_RELOAD and main.player.sound.stream == AudioFactory.USER_GUNSHOT, "Rifle bolt sound follows the shot on its own audio layer")
	main.mode = "paused"
	main.audio_mix.update_mix(0)
	check(main.player.bolt_sound.stream_paused, "Pause freezes the rifle bolt recording")
	main.resume()
	main.audio_mix.update_mix(0)
	check(not main.player.bolt_sound.stream_paused, "Resume releases the bolt recording")
	main.player.switch_weapon(1)
	check(not main.player.bolt_pending and not main.player.bolt_sound.playing, "Weapon switching cancels unfinished rifle bolt audio")
	await frames(18)
	main.player.fire()
	check(not main.player.bolt_pending, "Pistol fire does not schedule manual rifle bolt audio")
	check(main.guards.all(func(g): return g.alert_audio.stream in AudioFactory.USER_ALERTS), "All guards use one of the three supplied alert voices")
	var guard = main.guards[0]
	main.linear.enabled = false
	main.player.position = Vector3(34, 0.08, 214)
	guard.position = Vector3(34, 0.08, 206)
	guard.rotation.y = PI
	guard.state = "search"
	guard.sight_memory = 6
	guard.alert_cooldown = 0
	await frames(3)
	guard._physics_process(1.0/60)
	check(guard.state == "combat" and guard.alert_audio.playing, "A searching guard calls out when it sees the player")
	var cooldown: float = guard.alert_cooldown
	guard._physics_process(1.0/60)
	check(guard.alert_cooldown < cooldown, "Continuous sight does not restart the alert voice")
	guard.take_damage(1000)
	check(not guard.alert_audio.playing, "Defeated guard stops speaking")
	for kind in ["door_open", "door_close"]:
		main.play_world_sound(kind, main.player.position)
		var sound: AudioStreamPlayer3D = main.get_node("WorldSound_" + kind)
		await frames(3)
		check(sound.playing and sound.stream == AudioFactory.make_sound(kind) and sound.global_position.is_equal_approx(main.player.position), kind + " plays at the door position")
		main.mode = "paused"
		main.audio_mix.update_mix(0)
		check(sound.stream_paused, kind + " pauses with gameplay")
		main.mode = "melee"
		main.audio_mix.update_mix(0)
		check(not sound.stream_paused, kind + " can continue into the door ambush")
		main.mode = "playing"
	main.artillery.queue_strike(main.player.position + Vector3(3,0,0))
	main.artillery.advance(0.9)
	var explosion: Node3D = main.artillery.events[0].effect
	check(explosion.sound.playing and explosion.sound.stream == AudioFactory.USER_EXPLOSION, "Artillery impact plays the user explosion")
	main.artillery.clear()
	main.player.switch_weapon(0)
	main.player.position = main.START
	main.player.rotation.y = -0.6
	main.player.reset_physics_interpolation()
	await frames(3)
	main.player.take_damage(0)
	check(main.player.damage_flash == 0, "Zero damage does not flash the screen")
	main.player.take_damage(8)
	await frames(2)
	check(main.player.health == 92 and main.hud.damage_edges.size() == 4 and main.hud.damage_edges.all(func(edge): return edge.color.a > 0), "Actual damage flashes all four screen edges")
	await capture("damage-red-edge.png")
	await frames(24)
	check(main.hud.damage_edges.all(func(edge): return is_zero_approx(edge.color.a)), "Damage tint fades away after the brief flash")
	await capture("damage-cleared.png")
	main.start_new()
	freeze_guards()
	await frames(2)
	check(get_nodes_in_group("world_sounds").is_empty() and not main.player.bolt_pending, "Restart clears old door sounds and pending bolt audio")
	check(main.guards.all(func(g): return g.model.find_child("FrenzyOpenMouth", true, false) == null), "Requested mouth overlay has been removed")
	main.story.met_scout = true
	for g in main.guards:
		if g.guard_id in ["gate_guard","gate_guard_2","gate_guard_3","yard_guard","timber_guard","yard_guard_2","yard_guard_3"]: g.take_damage(1000)
	main.linear.opened.assign(["checkpoint"])
	main.linear._sync_gates()
	main.player.position = Vector3(34, 0.08, 124)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	await frames(3)
	main.interact()
	await frames(125)
	check(main.melee.active and main.melee.phase == "struggle", "Second-door charge still reaches the space-key struggle")
	await capture("bayonet-original-face.png")
	main.melee.abort()
	main.mode = "paused"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	stop_audio(main)
	main.queue_free()
	await frames(3)
	OS.delay_msec(150)
	await frames(2)
	var report := {"checks":checks, "failures":failures, "passed":failures.is_empty(), "human_listening":false, "human_playtest":false, "assets":11, "mouth_expression":"removed_by_user_request", "captures":captures, "details":details}
	if not evidence.is_empty(): FileAccess.open(evidence.path_join("validation.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("USER SFX RESULT: ", "PASS" if failures.is_empty() else "FAIL", " | ", checks-failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)
