extends SceneTree
## Visual/terrain evidence for the short departure insert. QA colliders never ship.
func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s36_departure_%d.json" % OS.get_process_id()
	main.start_with_opening()
	main.opening.set_process(false)
	var opening = main.opening
	for mesh in opening.lake.find_children("S21_Crater_*", "MeshInstance3D", true, false):
		var body := StaticBody3D.new()
		body.collision_layer = 1 << 19
		body.collision_mask = 0
		root.add_child(body)
		body.global_transform = mesh.global_transform
		var shape := CollisionShape3D.new()
		shape.shape = mesh.mesh.create_trimesh_shape()
		body.add_child(shape)
	await physics_frame
	var output := OS.get_environment("FENGHUO_DEPARTURE_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(output)
	var samples := []
	var passed := true
	# Dense samples compare the actor to actual physics surfaces, including QA
	# colliders built from the imported visual mountain, rather than route labels.
	for index in 21:
		opening.preview_at("B", 26.3 + float(index) * .099)
		var feet: Vector3 = opening.actors.scout.global_position
		var floor_ray := PhysicsRayQueryParameters3D.create(feet + Vector3.UP * 2, feet - Vector3.UP * 3, (1 << 19) | 1)
		var floor_hit := root.world_3d.direct_space_state.intersect_ray(floor_ray)
		var sight_ray := PhysicsRayQueryParameters3D.create(opening.camera.global_position, feet + Vector3.UP, (1 << 19) | 1)
		var sight_hit := root.world_3d.direct_space_state.intersect_ray(sight_ray)
		var valid: bool = not floor_hit.is_empty() and absf(floor_hit.position.y - feet.y) < .12 and sight_hit.is_empty()
		passed = passed and valid
		samples.append({"clock":opening.clock,"feet_y":feet.y,"support_y":floor_hit.get("position",Vector3.ZERO).y,"clear_camera":sight_hit.is_empty(),"passed":valid})
	for clock in [26.5, 27.3, 28.1]:
		opening.preview_at("B", clock)
		var actor: Vector3 = opening.actors.scout.global_position
		var ray := PhysicsRayQueryParameters3D.create(actor + Vector3.UP * 100, actor - Vector3.UP * 100, 1 << 19)
		var hit := root.world_3d.direct_space_state.intersect_ray(ray)
		print("DEPARTURE GROUND: ", {"clock":clock,"actor":[actor.x, actor.y, actor.z],"terrain_y":hit.position.y if not hit.is_empty() else null})
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("B07-%.1f.png" % clock))
	print("S36 DEPARTURE: ", "PASS" if passed else "FAIL", " | samples=", samples.size())
	FileAccess.open(output.path_join("terrain-samples.json"),FileAccess.WRITE).store_string(JSON.stringify({"all_passed":passed,"samples":samples,"scope":"B07 visible insert only; outer route continuity and final art not assessed"},"  "))
	opening.abort()
	await create_timer(0.15).timeout
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
