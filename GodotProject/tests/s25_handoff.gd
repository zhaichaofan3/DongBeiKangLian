extends SceneTree
## S25 camera, departure-route and player-control handoff checks.

var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S25_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._ensure_opening()
	await process_frame
	var opening = main.opening
	opening.set_process(false)
	opening.start("B")
	opening.set_process(false)
	opening.preview_at("B", 24.9)
	await process_frame
	var scout: Node3D = opening.actors["scout"]
	check(opening.shot_id == "B-06" and is_equal_approx(scout.position.y, 26.0) and scout.position.z < 145.5, "B3 exit crosses the level platform toward its departure ramp")
	opening.preview_at("B", 26.8)
	await process_frame
	check(opening.shot_id == "B-07" and scout.position.y < 26.0 and scout.position.y > 24.7, "B4 departure descends on the corrected visible ramp")
	opening.preview_at("B", 79.95)
	await process_frame
	check(opening.shot_id == "B-16" and absf(opening.camera.fov - 78.0) < 0.1, "B16 aligns the cinematic camera to the gameplay FOV")
	check(opening.camera.position.distance_to(Vector3(10, 1.65, 286)) < 0.01, "B16 camera reaches the player handoff anchor")
	opening.advance(0.16)
	check(opening.handoff_state == "transition" and main.mode == "cinematic" and opening.active, "Full playback enters a single locked handoff transition")
	opening.advance(0.11)
	check(opening.fade.color.a > 0.5 and opening.handoff_state == "transition", "Handoff covers the camera cut with a short fade")
	opening.advance(0.12)
	check(not opening.active and opening.handoff_state == "committed" and opening.handoff_count == 1, "Handoff commits once after the fade")
	check(main.mode == "playing" and main.player.camera.current and main.player.position.is_equal_approx(main.START), "Player camera, position and control mode are continuous")
	check(main.story.met_scout and main.stage == 0 and main.kills == 0, "Opening handoff sets briefing state without advancing mission objectives")
	var collisions_off := true
	for body in opening.terrace.find_children("*", "StaticBody3D", true, false): collisions_off = collisions_off and body.collision_layer == 0 and body.collision_mask == 0
	check(collisions_off and not opening.tianchi_environment_root.visible, "Cinematic access and S23 environment are cleared on handoff")
	var passed := true
	for item in checks: passed = passed and item.passed
	DirAccess.make_dir_recursive_absolute(evidence)
	var report := {"step":"S25","status":"done" if passed else "failed","all_passed":passed,"checks":checks,"handoff":{"transition_seconds":opening.HANDOFF_TRANSITION_SECONDS,"final_camera_fov":78.0,"player_anchor":[main.START.x,1.65,main.START.z],"departure_waypoints_used":[[501,26,145.5],[496.5,26,140.5],[497,24.7,135]]},"method":"Headless B6/B7 preview, final camera alignment and timed handoff transition checks."}
	FileAccess.open(evidence.path_join("handoff.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S25 HANDOFF: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
