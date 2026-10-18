extends SceneTree

const MODELS := ["barbed_wire", "boat", "camp_1", "camp_2", "camp_3", "camp_4", "dock", "kar98k", "office", "river", "village_1", "village_2", "village_3", "village_4", "village_passages"]
var failures: Array[String] = []
var checks := 0

func check(valid: bool, message: String) -> void:
	checks += 1
	if not valid:
		failures.append(message)
		printerr("FAIL: ", message)
	else: print("PASS: ", message)

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func _run() -> void:
	var manifest := OS.get_environment("FENGHUO_DELIVERY_ALIASES")
	var aliases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest))
	var canonical := {}
	for path in aliases.values(): canonical[path] = true
	check(aliases.size() == 126, "All 126 identical texture aliases are accounted for")
	for path in canonical:
		var texture := load(path) as Texture2D
		check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Shared texture loads: " + path.get_file())
	var references := 0
	for model in MODELS:
		var path: String = "res://assets/user_expansion_20261015/" + model + ".glb"
		var packed := load(path) as PackedScene
		check(packed != null, "Playable supplied scene loads: " + model)
		if packed == null: continue
		var scene := packed.instantiate()
		var meshes := scene.find_children("*", "MeshInstance3D", true, false)
		var valid := not meshes.is_empty()
		for node in meshes:
			valid = valid and node.mesh.get_surface_count() > 0
			for surface in node.mesh.get_surface_count():
				var material: Material = node.mesh.surface_get_material(surface)
				if material == null: continue
				for property in material.get_property_list():
					if property.type != TYPE_OBJECT: continue
					var value = material.get(property.name)
					if value is Texture2D:
						valid = valid and not aliases.has(value.resource_path) and ResourceLoader.exists(value.resource_path)
						if canonical.has(value.resource_path): references += 1
		check(valid, "Every mesh and material retains a shipped texture: " + model)
		scene.free()
	check(references > 100, "Playable scenes use shared materials across more than 100 surfaces")
	if OS.get_environment("FENGHUO_DELIVERY_PACK") == "1":
		check(not ResourceLoader.exists("res://assets/user_expansion_20261015/village_complete.glb"), "Unused full-village display model stays outside the player pack")
		var removed := true
		for alias in aliases: removed = removed and not ResourceLoader.exists(alias)
		check(removed, "Duplicate source texture paths are absent from the player pack")
	var main: Node3D = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_delivery_%d.json" % OS.get_process_id()
	root.add_child(main)
	for i in 120:
		await process_frame
		if main.world.is_world_ready(): break
	check(ProjectSettings.get_setting("application/config/name") == "东北抗联 烽火回声" and main.hud.menu_title.text == "东北抗联 烽火回声", "Window and title menu use the requested game name")
	var opening: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/opening/opening.json"))
	check(opening.events.any(func(event): return event.id == "A_TITLE" and event.text == "东北抗联 烽火回声"), "Opening title uses the requested game name")
	main.hud.show_menu("paused")
	check(main.hud.menu_caption.text == "东北抗联 烽火回声", "Pause menu uses the requested game name")
	main.queue_free()
	await process_frame
	print("DELIVERY ASSETS: ", "PASS" if failures.is_empty() else "FAIL", " | checks=", checks)
	quit(0 if failures.is_empty() else 1)
