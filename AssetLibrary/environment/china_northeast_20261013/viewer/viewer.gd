extends Node

var folder: String
var entries: Array = []
var world: Node3D
var camera: Camera3D
var model: Node3D
var label: Label
var details: Label
var lake_button: Button
var asset_buttons: Array[Button] = []
var target := Vector3.ZERO
var distance := 17.0
var yaw := 0.70
var pitch := 0.65
var dragging := false
var current_index := 0
var current_center := Vector3.ZERO
var current_scale := 1.0
var rotating := false

func _ready() -> void:
	folder = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	entries = [
		{"title": "长白山天池 · 轻量版", "entry": "terrain/tianchi_display_lod.glb", "notes": "约 14.54 × 14.54 公里 · 公开高程与湖岸\n示意配色，未包含景区设施。"},
		{"title": "长白山天池 · 精细版", "entry": "terrain/tianchi_display.glb", "notes": "约 52.6 万三角面 · 公开高程与湖岸\n适合火山口与山脊展示。"}
	]
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("manifest.json")))
	entries.append_array(manifest["assets"])
	create_ui()
	if "--validate" in OS.get_cmdline_user_args():
		validate_models()
		return
	show_model(0)
	if "--ui-smoke" in OS.get_cmdline_user_args():
		await check_viewer_input()
		return
	if "--capture" in OS.get_cmdline_user_args():
		focus_lake()
		for frame in range(12):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder.path_join("previews/viewer_tianchi.png"))
		print("VIEWER_CAPTURE_COMPLETE")
		get_tree().quit()

func create_ui() -> void:
	var root := HBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei"])
	theme.default_font = font
	theme.default_font_size = 16
	root.theme = theme
	add_child(root)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 330
	root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	label = Label.new()
	label.text = "场景素材浏览器"
	label.add_theme_font_size_override("font_size", 23)
	column.add_child(label)
	var instructions := Label.new()
	instructions.text = "拖动旋转 · 滚轮缩放\nR 恢复全景 · Esc 退出"
	column.add_child(instructions)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in range(entries.size()):
		var button := Button.new()
		button.text = entries[i]["title"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 40
		button.clip_text = true
		button.tooltip_text = button.text
		button.pressed.connect(show_model.bind(i))
		list.add_child(button)
		asset_buttons.append(button)
	details = Label.new()
	details.custom_minimum_size.y = 155
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	lake_button = Button.new()
	lake_button.text = "火山口近看"
	lake_button.pressed.connect(focus_lake)
	column.add_child(lake_button)
	var overview := Button.new()
	overview.text = "恢复全景"
	overview.pressed.connect(reset_view)
	column.add_child(overview)
	var auto_button := CheckButton.new()
	auto_button.text = "自动环绕展示"
	auto_button.toggled.connect(func(value: bool): rotating = value)
	column.add_child(auto_button)
	var container := SubViewportContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202b38")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c3d2e1")
	env.ambient_light_energy = 0.8
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_energy = 1.6
	world.add_child(sun)
	camera = Camera3D.new()
	camera.fov = 45
	camera.near = 0.01
	camera.far = 200
	world.add_child(camera)

func import_model(entry: Dictionary) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(folder.path_join(entry["entry"]), state)
	if error != OK:
		push_error("Import failed: " + str(entry["entry"]) + " code " + str(error))
		return null
	return document.generate_scene(state)

func bounds_of(node: Node3D) -> AABB:
	var bounds := AABB()
	var started := false
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(box) if started else box
		started = true
	return bounds

func show_model(index: int) -> void:
	current_index = index
	if is_instance_valid(model):
		model.free()
	model = import_model(entries[index])
	if model == null:
		details.text = "这个模型未能打开，请查看资源说明。"
		return
	world.add_child(model)
	var bounds := bounds_of(model)
	current_center = bounds.get_center()
	current_scale = 10.0 / maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	model.scale *= current_scale
	model.position -= current_center * current_scale
	details.text = entries[index].get("notes", "")
	for i in range(asset_buttons.size()):
		asset_buttons[i].disabled = i == index
	lake_button.disabled = index > 1
	reset_view()

func reset_view() -> void:
	target = Vector3.ZERO
	distance = 17.0
	yaw = 0.70
	pitch = 0.65
	update_camera()

func focus_lake() -> void:
	if current_index > 1:
		return
	var meta = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("terrain/terrain_metadata.json")))
	var center := Vector2.ZERO
	for point in meta["lake_outline_pixels"]:
		center += Vector2(point[0], point[1])
	center /= meta["lake_outline_pixels"].size()
	var extent: float = meta["horizontal_extent_m"][0]
	var original := Vector3(center.x / 1024.0 * extent - extent / 2.0, float(meta["water_elevation_m"]) - float(meta["height_origin_m"]), center.y / 1024.0 * extent - extent / 2.0)
	target = (original - current_center) * current_scale
	distance = 5.7
	pitch = 0.75
	update_camera()

func update_camera() -> void:
	camera.position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at(target, Vector3.UP)

func _process(delta: float) -> void:
	if rotating:
		yaw += delta * 0.12
		update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_R:
			reset_view()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance * (0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 1.0, 65.0)
			update_camera()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.006, 0.05, 1.52)
		update_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

func validate_models() -> void:
	var report: Array = []
	var failures := 0
	for entry in entries:
		var imported := import_model(entry)
		var result := {"file": entry["entry"], "loaded": imported != null}
		if imported != null:
			world.add_child(imported)
			var bounds := bounds_of(imported)
			result["meshes"] = imported.find_children("*", "MeshInstance3D", true, false).size()
			result["dimensions"] = [bounds.size.x, bounds.size.y, bounds.size.z]
			result["valid"] = bounds.size.is_finite() and bounds.size.length() > 0 and result["meshes"] > 0
			imported.free()
		else:
			result["valid"] = false
		if not result["valid"]:
			failures += 1
		report.append(result)
		print("MODEL_CHECK ", entry["entry"], " ", result["valid"])
	var output := FileAccess.open(folder.path_join("godot-import-review.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info()["string"], "models": report, "failures": failures}, "  "))
	output.close()
	get_tree().quit(0 if failures == 0 else 1)

func send_click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame

func check_viewer_input() -> void:
	for frame in range(4):
		await get_tree().process_frame
	await send_click(asset_buttons[6].get_global_rect().get_center())
	var checks := {"model_button_switch": current_index == 6}
	var point := Vector2(850, 440)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	var before_yaw := yaw
	var motion := InputEventMouseMotion.new()
	motion.position = point + Vector2(70, 0)
	motion.relative = Vector2(70, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await get_tree().process_frame
	checks["drag_rotates"] = not is_equal_approx(yaw, before_yaw)
	press.pressed = false
	Input.parse_input_event(press)
	await get_tree().process_frame
	checks["release_stops_drag"] = not dragging
	var before_distance := distance
	var wheel := InputEventMouseButton.new()
	wheel.position = point
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await get_tree().process_frame
	checks["wheel_zooms"] = distance < before_distance
	await send_click(asset_buttons[0].get_global_rect().get_center())
	checks["terrain_button_switch"] = current_index == 0
	await send_click(lake_button.get_global_rect().get_center())
	checks["crater_button_focus"] = distance < 6.0
	for frame in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder.path_join("previews/viewer_tianchi.png"))
	var output := FileAccess.open(folder.path_join("viewer-input-review.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"method": "Godot Input.parse_input_event; not OS-level automation", "checks": checks}, "  "))
	output.close()
	var failed := false
	for passed in checks.values():
		failed = failed or not passed
	print("VIEWER_INPUT_CHECK ", JSON.stringify(checks))
	get_tree().quit(1 if failed else 0)
