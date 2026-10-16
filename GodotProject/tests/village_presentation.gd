extends SceneTree

var main: Node3D
var evidence := OS.get_environment("FENGHUO_WORLD_EVIDENCE")
var captures: Array[String] = []
var failed := false

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless": quit(2); return
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count: await physics_frame

func capture(label: String) -> void:
	await frames(5)
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors := {}
	for y in range(80,raster.get_height()-50,17):
		for x in range(25,raster.get_width()-25,17):
			var c := raster.get_pixel(x,y)
			colors[Vector3i(c.r*32,c.g*32,c.b*32)] = true
	var ok := colors.size()>45 and raster.save_png(evidence.path_join(label+".png"))==OK
	print("PASS: " if ok else "FAIL: ",label)
	failed = failed or not ok
	captures.append(label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_village_presentation.json"
	await frames(12)
	main.start_new()
	main.set_process(false)
	main.village._arrive()
	main.message_timer = 0
	main.village.set_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	for npc in main.story.people.values(): npc.set_physics_process(false)
	main.player.position = Vector3(1147,.08,274)
	main.player.reset_physics_interpolation()
	await capture("street-standing")
	main.player.crouch_latched = true
	await frames(20)
	await capture("street-crouched")
	main.player.crouch_latched = false
	main.player.position = Vector3(1147,.08,207)
	main.player.rotation.y = PI*.5
	main.player.reset_physics_interpolation()
	await capture("courtyard-door")
	Input.action_press("lean_right")
	await frames(20)
	await capture("courtyard-lean")
	Input.action_release("lean_right")
	main.player.position = Vector3(1143.5,.08,204)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	await frames(20)
	await capture("courtyard-passage")
	main.mode = "paused"
	await frames(3)
	main.hud._show_settings()
	await frames(4)
	main.hud.settings_scroll.scroll_vertical = int(main.hud.settings_scroll.get_v_scroll_bar().max_value)
	await capture("settings-bindings")
	for label: Label in main.hud.find_children("*","Label",true,false):
		if not label.is_visible_in_tree() or not label.text.begins_with("移动 WASD"): continue
		var rect := label.get_global_rect()
		var viewport := Rect2(Vector2.ZERO,root.get_visible_rect().size)
		if not viewport.encloses(rect):
			failed = true
			print("FAIL: Settings bindings fit the viewport: ",rect)
	main.hud.visible = false
	main._ensure_opening()
	main.opening.start()
	main.opening.set_process(false)
	for point in [["A",5,"opening-village"],["A",20,"opening-courtyards"]]:
		main.opening.preview_at(point[0],point[1])
		await capture(point[2])
	main.opening.abort()
	FileAccess.open(evidence.path_join("presentation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"captures":captures,"viewport":str(root.size)},"  "))
	print("VILLAGE PRESENTATION: ","FAIL" if failed else "PASS")
	main.ambience.stop()
	main.player.sound.stop()
	main.enemy_audio.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await frames(3)
	quit(1 if failed else 0)
