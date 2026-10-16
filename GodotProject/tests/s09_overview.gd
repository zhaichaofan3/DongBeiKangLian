extends SceneTree
## Documentation camera only. Does not assert traversal or move gameplay actors.
func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	var main: Node3D=load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.hud.visible=false
	var camera:=Camera3D.new()
	main.add_child(camera)
	camera.current=true
	camera.fov=65
	var directory:=OS.get_environment("FENGHUO_S09_EVIDENCE")
	for shot in [
		["overview",Vector3(92,84,126),Vector3(28, 0, 127)],
		["D01-exterior",Vector3(-37,12,89),Vector3(-18,2,67)],
		["D02-D06-life",Vector3(18, 12, 291),Vector3(10, 1, 262)],
		["D03-warehouse",Vector3(36, 12, 231),Vector3(54, 3, 214)],
		["D05-D07-production",Vector3(64, 10, 200),Vector3(53, 2, 132)],
		["D04-north-passage",Vector3(76,12,23),Vector3(49,2,15)]]:
		camera.position=shot[1]
		camera.look_at(shot[2])
		# The elevated plan view alone suppresses distance fog to show all slots.
		main.world.environment.fog_enabled=shot[0]!="overview"
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(shot[0]+".png"))
	print("S09 OVERVIEW: six documentation captures saved")
	main.queue_free()
	await process_frame
	quit()
