extends SceneTree
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""
var render := false

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S27_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	render = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func check(passed: bool, message: String) -> void:
	checks.append({"passed":passed,"description":message})
	print("PASS: " if passed else "FAIL: ",message)

func capture(label: String) -> void:
	if not render: return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(label+".png"))==OK,"Rendered "+label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s27_%d.json" % OS.get_process_id()
	root.add_child(main)
	await physics_frame
	main.start_new()
	main.player.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	var art = main.artillery
	art.set_process(false)
	# Raised fixtures isolate distance and wall occlusion from the production terrain.
	main.player.position = Vector3(30, 30, 200)
	var guard = main.guards[0]
	guard.position = Vector3(32.5, 30, 200)
	var far_guard = main.guards[1]
	far_guard.position = Vector3(38, 30, 200)
	var origin := Vector3(30, 30, 200)
	var id: int = art.queue_strike(origin)
	art.advance(0.81)
	check(id>0 and main.player.health==100 and guard.health==75,"Default artillery is cosmetic and cannot change actor health")
	art.clear()
	art.queue_strike(origin,5,35,true)
	art.advance(0.5)
	check(main.player.health==100 and art.events[0].effect.projectile.visible,"Flight lead-in displays a shell without early damage")
	art.advance(0.31)
	check(main.player.health<75 and 75.0-guard.health < 100.0-main.player.health and guard.health<75 and far_guard.health==75,"Real blast uses distance falloff and leaves the out-of-radius guard untouched")
	var health_after: float = main.player.health
	var count_after: int = art.impact_count
	var effect = art.events[0].effect
	check(effect.flash.visible and effect.light.light_energy>0 and effect.sound.playing,"Impact flash, short light and preview explosion audio start together")
	art.advance(0.1)
	check(main.player.health==health_after and art.impact_count==count_after,"A shell applies damage exactly once across multiple frames")
	check(guard.model._flinch>0,"Nearby guard receives a hit reaction through its normal damage path")
	art.advance(0.3)
	check(not effect.flash.visible and effect.light.light_energy==0 and effect.dust[0].visible,"Flash clears before the expanding dust and smoke")
	await process_frame
	var dust_at: Vector3 = effect.dust[7].position
	main.mode="paused"
	art._process(1)
	check(effect.dust[7].position==dust_at and (effect.sound.stream_paused or not effect.sound.playing),"Pause freezes shell time, smoke and explosion audio")
	main.mode="playing"
	art.advance(5)
	check(art.events.is_empty() and not is_instance_valid(effect),"Completed shells reclaim every transient visual and audio node")

	var wall := StaticBody3D.new()
	wall.collision_layer=1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(0.25,4,4)
	collider.shape=shape
	wall.add_child(collider)
	main.add_child(wall)
	wall.position=Vector3(32, 31, 200)
	main.player.position=Vector3(34, 30, 200)
	guard.position=Vector3(39, 30, 200)
	await physics_frame
	await physics_frame
	health_after=main.player.health
	art.queue_strike(origin,5,35,true)
	art.advance(0.81)
	check(main.player.health==health_after,"Solid world collision shields the player from a nearby blast")
	art.clear()
	wall.free()
	main.player.position=Vector3(40, 30, 200)
	for i in 6: art.queue_strike(origin)
	check(art.events.size()==6 and art.queue_strike(origin)==-1,"Artillery rejects a seventh active shell instead of scheduling invisible damage")
	main.mode="cinematic"
	check(art.queue_strike(origin,5,35,true)==-1,"Gameplay artillery cannot be requested during cinematic playback")
	art._process(0.1)
	check(art.events.is_empty(),"Leaving gameplay clears queued shells")
	main.mode="playing"
	art.queue_strike(origin)
	main.start_new()
	check(art.events.is_empty(),"Restart removes pending artillery")
	art.set_process(false)
	art.queue_strike(origin)
	main.continue_checkpoint()
	check(art.events.is_empty(),"Checkpoint restore removes pending artillery")

	main.start_with_opening()
	main.opening.set_process(false)
	for guard_node in main.guards: guard_node.set_physics_process(false)
	var opening=main.opening
	var before: Dictionary=main._snapshot()
	opening.preview_at("A",37.55)
	check(opening.blasts[2].projectile.visible and not opening.blasts[2].flash.visible,"A4 samples the authored incoming shell before impact")
	await capture("A12-incoming")
	opening.preview_at("A",38.03)
	check(opening.blasts[2].flash.visible and opening.fired_sounds.has("blast_2"),"A4 impact uses the same explosion with one timed sound event")
	check(opening.actors.enemy1._flinch>0 or opening.actors.ally2._flinch>0,"Nearby cinematic actors react without using gameplay damage")
	await capture("A12-impact")
	await process_frame
	opening.set_paused(true)
	await process_frame
	check(opening.blasts[2].sound.stream_paused,"Pause reaches an initialized impact audio playback")
	opening.set_paused(false)
	opening.preview_at("A",38.4)
	check(not opening.blasts[2].flash.visible and opening.blasts[2].stones[0].visible,"A4 progresses from short flash to flying debris")
	await capture("A12-debris")
	opening.preview_at("A",38.85)
	await capture("A13-dust")
	opening.preview_at("A",39.4)
	await capture("A13-smoke")
	opening.preview_at("A",40.4)
	await capture("A14-distant-front")
	var far_puff = opening.blasts[3].dust[9]
	print("FAR PUFF: ",{"world":far_puff.global_position,"screen":opening.camera.unproject_position(far_puff.global_position),"visible":far_puff.is_visible_in_tree(),"scale":far_puff.scale,"color":far_puff.material_override.albedo_color,"age":opening.blasts[3].age})
	opening.preview_at("A",39.705)
	check(opening.distant_flashes[3].visible,"Authored distant fireline pulses inside the history timeline")
	await capture("A14-fireline")
	check(main._snapshot().player==before.player and main._snapshot().story==before.story and main._snapshot().kills==before.kills,"Cinematic barrage leaves player resources, story and combat state unchanged")
	opening.set_paused(true)
	var paused_age: float=opening.blasts[3].age
	opening.advance(1)
	print("PAUSE EVIDENCE: ", {"age":opening.blasts[3].age,"before":paused_age,"paused":opening.paused,"audio_playing":opening.blasts[2].sound.playing,"audio_paused":opening.blasts[2].sound.stream_paused})
	check(opening.blasts[3].age==paused_age and (opening.blasts[2].sound.stream_paused or not opening.blasts[2].sound.playing),"Cinematic pause freezes explosion visual and sound together")
	opening.set_paused(false)
	opening.skip("A")
	var cleared:=true
	for blast in opening.blasts: cleared=cleared and not blast.visible and not blast.sound.playing
	check(cleared and opening.part=="B","Skipping history stops all artillery before the conversation")
	opening.abort()
	var passed:=true
	for item in checks: passed=passed and item.passed
	FileAccess.open(evidence.path_join("artillery.json"),FileAccess.WRITE).store_string(JSON.stringify({"step":"S27","all_passed":passed,"checks":checks,"rendered":render,"scope":"Actual opening integration plus isolated real gameplay damage and wall fixtures; no automatic mission barrage added."},"  "))
	print("S27 ARTILLERY: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	await process_frame
	var settle_until := Time.get_ticks_msec()+150
	while Time.get_ticks_msec()<settle_until: await process_frame
	quit(0 if passed else 1)
