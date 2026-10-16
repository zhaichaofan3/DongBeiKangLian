extends SceneTree

## S11 checks actual imported dressing, placeholder replacement, and route reachability.
## It does not claim a human pacing or final S13 AI acceptance.
var checks: Array[Dictionary] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed": value, "description": description})
	if not value:
		push_error(description)

func _run() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var dressing: Node3D = main.world.asset_dressing.dressing_root
	var slot_counts := {"D05": 0, "D06": 0, "D07": 0, "D08": 0, "D09": 0}
	var purpose_counts: Dictionary = {}
	var source_counts: Dictionary = {}
	for node in dressing.find_children("*", "Node3D", true, false):
		if not bool(node.get_meta("s11_dressing", false)):
			continue
		var slot := str(node.get_meta("s11_slot", ""))
		var purpose := str(node.get_meta("s11_purpose", ""))
		if slot_counts.has(slot):
			slot_counts[slot] += 1
		purpose_counts[purpose] = int(purpose_counts.get(purpose, 0)) + 1
		var source := str(node.name).split("_实物")[0]
		if source in ["village_market", "market_stalls", "chinese_screen_panels", "chinese_tea_table", "wicker_basket_01"]:
			source_counts[source] = int(source_counts.get(source, 0)) + 1
	var source_checks := ["village_market", "market_stalls", "chinese_screen_panels", "chinese_tea_table", "wicker_basket_01"]
	for source in source_checks:
		check(int(source_counts.get(source, 0)) > 0, source + " S11 imported instance exists")
	for slot in ["D05", "D06", "D07", "D08", "D09"]:
		check(int(slot_counts[slot]) > 0, slot + " receives S11 dressing")
	var blockout: RefCounted = main.world.route_blockout
	for id in ["D06_counter", "D07_stock", "D08_screen", "D08_chest", "D09_table"]:
		var body: StaticBody3D = blockout.container.get_node_or_null(id) as StaticBody3D
		var hidden := body != null and bool(body.get_meta("s11_visual_replaced", false))
		check(hidden, id + " placeholder mesh is visually replaced while collision remains")
	# Open the established gates for static reachability samples. The gameplay
	# regression suites still cover the closed-gate mission sequence separately.
	main.linear.opened.assign(["checkpoint", "yard", "river"])
	main.linear._sync_gates()
	var segments := [
		["Z0", Vector3(12, 0, 284), Vector3(14, 0, 268)],
		["Z1", Vector3(34, 0, 200), Vector3(34, 0, 128)],
		["Z2", Vector3(34, 0, 124), Vector3(38, 0, 38)],
		["Z3-return", Vector3(38, 0, 38), Vector3(34, 0, 22)],
		["Z4", Vector3(34, 0, 22), Vector3(67, 0, 22)],
		["Z5", Vector3(67, 0, 22), Vector3(78, 0, 14)]
	]
	var route_report: Array[Dictionary] = []
	for segment in segments:
		var path: PackedVector3Array = main.world.path(segment[1], segment[2])
		var passed := path.size() > 0
		check(passed, str(segment[0]) + " route remains reachable")
		route_report.append({"id": segment[0], "from": [segment[1].x, segment[1].z], "to": [segment[2].x, segment[2].z], "path_points": path.size(), "passed": passed})
	var capture_dir := OS.get_environment("FENGHUO_S11_CAPTURE_DIR")
	if not capture_dir.is_empty():
		await _capture(main, capture_dir)
	var report := {"step": "S11", "all_passed": checks.all(func(item: Dictionary): return item.passed), "checks": checks, "slot_counts": slot_counts, "purpose_counts": purpose_counts, "source_counts": source_counts, "route_segments": route_report, "method": "Headless scene instantiation, imported asset presence, placeholder visual replacement and AStar route samples; captures are near/mid documentation, not a human playtest."}
	var evidence := OS.get_environment("FENGHUO_S11_EVIDENCE")
	if evidence.is_empty():
		evidence = "user://s11_dressing.json"
	var file := FileAccess.open(evidence, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("S11 DRESSING: ", "PASS" if report.all_passed else "FAIL", " | checks=", checks.size())
	main.ambience.stop()
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if report.all_passed else 1)

func _capture(main: Node3D, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	main.hud.visible = false
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 58
	var shots := [
		["D06-life", Vector3(13.8, 5, 284), Vector3(6.5, 1, 278.5)],
		["D05-D07-production", Vector3(63, 7, 201.5), Vector3(52.5, 1.2, 132)],
		["D08-office", Vector3(64.0, 5.5, 46.5), Vector3(59.0, 1.0, 40.5)],
		["D09-shelter", Vector3(14.5, 4.3, 267.5), Vector3(9, 0.9, 262)]
	]
	for shot in shots:
		camera.position = shot[1]
		camera.look_at(shot[2])
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(shot[0] + ".png"))
