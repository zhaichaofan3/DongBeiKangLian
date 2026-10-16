extends SceneTree
## Isolated character stage; never instantiates the mission or touches a save.
## Run with --qa; set FENGHUO_CHARACTER_CAPTURE_DIR for optional rendered images.

const Human = preload("res://scripts/human_model.gd")
const ROLES := ["scout", "logger", "wounded", "guard"]
const TITLES := ["侦察员", "林场工人", "陆山", "守卫"]
const REQUIRED_BONES := ["Hips", "Chest", "Head", "Thigh0", "Thigh1", "Knee0", "Knee1", "Foot0", "Foot1", "Shoulder0", "Shoulder1", "Elbow0", "Elbow1"]

var stage: Node3D
var camera: Camera3D
var caption: Label
var characters: Array[Node3D] = []
var skeletons: Array[Skeleton3D] = []
var labels: Array[Label3D] = []
var failures: Array[String] = []
var checks := 0
var capture_dir := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		printerr("Run isolated character verification with --qa.")
		quit(2)
		return
	capture_dir = OS.get_environment("FENGHUO_CHARACTER_CAPTURE_DIR")
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	_build_stage()
	for i in ROLES.size():
		var person := Human.new()
		person.build(ROLES[i])
		person.position.x = (i - 1.5) * 1.45
		stage.add_child(person)
		characters.append(person)
		var skeleton := _find_skeleton(person)
		skeletons.append(skeleton)
		var label := Label3D.new()
		label.text = TITLES[i]
		label.font_size = 40
		label.pixel_size = 0.004
		label.position = Vector3(person.position.x, 2.05, 0)
		label.modulate = Color("d1c49e")
		label.no_depth_test = true
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
		labels.append(label)
	await process_frame
	for i in characters.size():
		var person: Node3D = characters[i]
		var skeleton: Skeleton3D = skeletons[i]
		check(person.get("detailed_rig") != null and skeleton != null, ROLES[i] + " uses the imported skin, not the fallback model")
		if skeleton == null:
			continue
		var expected_model := "japanese.glb" if ROLES[i] == "guard" else "field_character.glb" if ROLES[i] == "logger" else "volunteer.glb"
		check(person.detailed_rig.character.scene_file_path.ends_with(expected_model), ROLES[i] + " instantiates the correct supplied model or preserved civilian")
		var has_required := true
		for bone in REQUIRED_BONES:
			has_required = has_required and skeleton.find_bone(bone) >= 0
		check(has_required, ROLES[i] + " has every animated body joint")
		check(_validate_skin_bindings(person), ROLES[i] + " has valid skin weights and bone bindings")
		var correct_equipment := true
		var equipment := ["Cap", "Backpack", "Scarf", "Helmet", "GuardGear", "Bandage", "Hands", "GuardHands", "GuardHelmetMark", "GuardMoustache"]
		if ROLES[i] != "logger":
			equipment = ["Hands", "GuardHands", "Helmet", "GuardHelmetMark", "GuardMoustache"] if ROLES[i] == "guard" else ["Cap", "Bandage", "Hands", "GuardHands", "FriendlyCapStar"]
		for item in equipment:
			var accessory := person.find_child(item, true, false) as Node3D
			var expected: bool = ROLES[i] != "guard" if item in ["Cap", "Backpack", "Scarf", "Hands", "FriendlyCapStar"] else ROLES[i] == "guard"
			if item == "Bandage":
				expected = ROLES[i] == "wounded"
			correct_equipment = correct_equipment and accessory != null and accessory.visible == expected
		check(correct_equipment, ROLES[i] + " shows its correct clothing, headgear and injury equipment")
		_settle(person, 0.0, 30)
		if ROLES[i] != "logger":
			check(_cuff_gap(person) < 0.065, ROLES[i] + " sleeves meet both wrist openings")
		if ROLES[i] in ["scout", "wounded"]:
			var gloves: MeshInstance3D = person.find_child("Hands", true, false)
			var original_gloves := gloves != null
			for surface in gloves.mesh.get_surface_count():
				var material := gloves.get_active_material(surface) as StandardMaterial3D
				original_gloves = original_gloves and material != null and material.resource_name.contains("17309872-012") and material.albedo_texture != null
			check(original_gloves, ROLES[i] + " retains the supplied textured glove geometry")
			for side in 2:
				var hand_bounds := _points_bounds(_hand_points(person, side, true))
				check(hand_bounds.size.y > 0.09 and hand_bounds.size.y < 0.23 and hand_bounds.size.x > 0.05 and hand_bounds.size.x < 0.16, ROLES[i] + " relaxed glove has natural palm and finger proportions: " + str(side))
		if ROLES[i] == "wounded":
			check(_bandage_head_weights(person) == 0, "Lu Shan has no obsolete forehead bandage crossing his cap or eyes")
		var bounds := _skin_bounds(person)
		check(_finite_aabb(bounds) and bounds.size.y > 1.4 and bounds.size.y < 2.15 and bounds.size.x > 0.3 and bounds.size.x < 1.8, ROLES[i] + " has human scale without exploded vertices")
		check(bounds.position.y > -0.18 and bounds.position.y < 0.16, ROLES[i] + " standing footwear stays near the floor")
	if skeletons.has(null):
		await _finish()
		return

	caption.text = "人物重建 · 游戏内实际模型"
	camera.position = Vector3(0, 1.50, -7.4)
	camera.fov = 38
	camera.look_at(Vector3(0, 1.02, 0))
	await _capture("lineup")
	for i in characters.size():
		_focus(i)
		caption.text = TITLES[i] + " · 全身"
		camera.position = Vector3(0.18, 1.17, -3.65)
		camera.fov = 37
		camera.look_at(Vector3(0, 0.95, 0))
		await _capture(ROLES[i] + "_front")
		caption.text = TITLES[i] + " · 面部与服装"
		var head := _bone_position(i, "Head")
		camera.position = head + Vector3(0.22, 0.055, -0.98)
		camera.fov = 32
		camera.look_at(head + Vector3(0, 0.025, -0.025))
		await _capture(ROLES[i] + "_face")
		if ROLES[i] in ["scout", "wounded"]:
			for side in 2:
				var hand_bounds := _points_bounds(_hand_points(characters[i], side))
				var center := hand_bounds.get_center()
				caption.text = TITLES[i] + " · 手掌与袖口"
				camera.position = center + Vector3(0.18, 0.08, -0.54)
				camera.look_at(center)
				await _capture(ROLES[i] + "_hand_" + str(side))
		if ROLES[i] == "wounded":
			caption.text = "陆山 · 头部侧面"
			camera.position = head + Vector3(0.72, 0.08, -0.22)
			camera.look_at(head + Vector3(0, 0.04, 0))
			await _capture("wounded_head_side")

	# Probe the actual imported bones and deformed mesh, not just the legacy drivers.
	_focus(0)
	var scout: Node3D = characters[0]
	var idle_pose := _bone_snapshot(skeletons[0])
	_settle(scout, 2.6, 53)
	check(_changed_bones(skeletons[0], idle_pose) >= 8, "Walking drives imported legs, arms and torso")
	var walk_bounds := _skin_bounds(scout)
	check(_cuff_gap(scout) < 0.065, "Walking keeps sleeves attached to both wrists")
	check(_finite_aabb(walk_bounds) and walk_bounds.size.y > 1.2 and walk_bounds.size.y < 2.2 and walk_bounds.size.x < 1.8, "Walking skin stays finite and attached to its rig")
	check(walk_bounds.position.y > -0.22 and walk_bounds.position.y < 0.20, "Walking stance remains at ground level")
	_focus(0)
	caption.text = "侦察员 · 行走姿态"
	camera.position = Vector3(1.9, 1.2, -3.15)
	camera.fov = 40
	camera.look_at(Vector3(0, 0.92, 0))
	await _capture("walking")

	_focus(3)
	var guard: Node3D = characters[3]
	var idle_guard := _bone_snapshot(skeletons[3])
	var lowered_grip_error := _guard_grip_error()
	guard.set_motion_context(false, 0.0, true)
	_settle(guard, 0.0, 60)
	check(_changed_bones(skeletons[3], idle_guard) >= 4, "Aiming drives imported shoulder and elbow bones")
	check(guard.rifle != null and guard.rifle.is_visible_in_tree(), "Guard retains a visible rifle during aiming")
	var aimed_grip_error := _guard_grip_error()
	check(_cuff_gap(guard) < 0.065, "Aiming keeps sleeves attached to both wrists")
	check(lowered_grip_error < 0.055 and aimed_grip_error < 0.055, "Skinned palms stay within 5.5 cm of both rifle grips while lowered and aiming")
	print("RIFLE GRIP ERROR (m): lowered=", lowered_grip_error, ", aiming=", aimed_grip_error)
	var aimed_pose := _bone_snapshot(skeletons[3])
	guard.fire()
	guard.animate(1.0 / 60.0, 0.0)
	check(_changed_bones(skeletons[3], aimed_pose) >= 2, "Firing recoil reaches the imported body rig")
	_settle(guard, 0.0, 30)
	_focus(3)
	caption.text = "守卫 · 持枪瞄准"
	camera.position = Vector3(1.9, 1.42, -2.85)
	camera.fov = 38
	camera.look_at(Vector3(0, 1.0, -0.12))
	await _capture("guard_aim")
	for person in characters: person.visible = false
	var ally := Human.new()
	ally.build("guard", "ally")
	stage.add_child(ally)
	ally.set_motion_context(false, 0, true)
	_settle(ally, 0, 90)
	check(not ally.find_child("Hands", true, false).visible and ally.find_child("GuardHands", true, false).visible, "Armed friendly selects gripping gloves instead of relaxed fingers")
	check(_cuff_gap(ally) < 0.065, "Armed friendly gloves remain connected to both sleeves")
	caption.text = "我军 · 持枪与手掌"
	camera.position = Vector3(1.15, 1.48, -1.65)
	camera.fov = 35
	camera.look_at(Vector3(0.08, 1.25, -0.22))
	await _capture("friendly_aim_hands")
	for aiming in [false, true]:
		ally.set_motion_context(false, 0, aiming)
		_settle(ally, 0, 90)
		var pose_name := "aim" if aiming else "lowered"
		for side in 2:
			var points := _hand_points(ally, side)
			var grip_point: Vector3 = ally.to_local(ally.rifle.to_global([Vector3(0, -0.042, -0.105), Vector3(0.016, -0.034, 0.055)][side]))
			var nearest := INF
			var farthest := 0.0
			for point in points:
				nearest = minf(nearest, point.distance_to(grip_point))
				farthest = maxf(farthest, point.distance_to(grip_point))
			check(nearest < 0.035 and farthest < 0.14, "Actual friendly glove surface wraps the rifle without extended fingers: %s/%d" % [pose_name, side])
			print("FRIENDLY GLOVE DISTANCE (m): ", pose_name, "/", side, " nearest=", nearest, " farthest=", farthest)
			var center := _points_bounds(points).get_center()
			caption.text = "我军 · 握枪手套与袖口"
			camera.position = center + Vector3(0.25 if side == 1 else -0.25, 0.15, -0.38)
			camera.fov = 36
			camera.look_at(center)
			await _capture("friendly_%s_hand_%d" % [pose_name, side])
	ally.free()

	var wounded: Node3D = characters[2]
	var injury_pose := _bone_snapshot(skeletons[2])
	_focus(2)
	caption.text = "陆山 · 包扎与伤势姿态"
	camera.position = Vector3(1.55, 1.3, -3.05)
	camera.fov = 38
	camera.look_at(Vector3(0, 0.98, 0))
	await _capture("wounded_untreated")
	wounded.set_motion_context(true)
	_settle(wounded, 0.0, 140)
	check(_changed_bones(skeletons[2], injury_pose) >= 4, "Treating Lu Shan changes his imported injury posture")
	var treated_bounds := _skin_bounds(wounded)
	check(_finite_aabb(treated_bounds) and treated_bounds.size.y < 2.15, "Treatment transition keeps clothing and bandages attached")
	caption.text = "陆山 · 治疗后的姿态"
	await _capture("wounded_treated")

	_focus(3)
	var head_before := _bone_position(3, "Head")
	guard.fall()
	_settle(guard, 0.0, 100)
	var head_after := _bone_position(3, "Head")
	var fallen_bounds := _skin_bounds(guard)
	check(head_after.y < head_before.y - 0.55, "Death lowers the imported head and torso onto the ground")
	check(_finite_aabb(fallen_bounds) and fallen_bounds.size.y < 1.10 and fallen_bounds.size.x < 2.4 and fallen_bounds.size.z < 2.2, "Fallen skin remains finite with a horizontal silhouette")
	check(fallen_bounds.position.y > -0.25, "Fallen character has no substantial underground geometry")
	check(_death_arms_converge(), "Death releases prior aiming twists into a consistent relaxed arm pose")
	caption.text = "守卫 · 倒地姿态"
	camera.position = Vector3(1.7, 1.50, -3.4)
	camera.fov = 39
	camera.look_at(Vector3(-0.40, 0.25, 0))
	await _capture("guard_fallen")
	await _finish()

func _build_stage() -> void:
	stage = Node3D.new()
	stage.name = "IsolatedCharacterStage"
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("20292f")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c9d1db")
	settings.ambient_light_energy = 0.58
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	stage.add_child(environment)
	var floor_mesh := MeshInstance3D.new()
	var floor_shape := BoxMesh.new()
	floor_shape.size = Vector3(20, 0.08, 20)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("3c4547")
	floor_material.roughness = 0.95
	floor_shape.material = floor_material
	floor_mesh.mesh = floor_shape
	floor_mesh.position.y = -0.041
	stage.add_child(floor_mesh)
	var key := DirectionalLight3D.new()
	key.light_color = Color("fff1dc")
	key.light_energy = 1.5
	key.shadow_enabled = true
	stage.add_child(key)
	key.position = Vector3(-3.0, 5, -4)
	key.look_at(Vector3(0, 0.8, 0))
	var rim := OmniLight3D.new()
	rim.position = Vector3(1.5, 3, 2)
	rim.omni_range = 9
	rim.light_color = Color("b0cce1")
	rim.light_energy = 1.8
	stage.add_child(rim)
	camera = Camera3D.new()
	camera.current = true
	camera.near = 0.03
	stage.add_child(camera)
	var overlay := CanvasLayer.new()
	stage.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(28, 22)
	caption.add_theme_font_size_override("font_size", 23)
	caption.add_theme_color_override("font_color", Color("ece1c3"))
	overlay.add_child(caption)

func _focus(index: int) -> void:
	for i in characters.size():
		characters[i].visible = i == index
		characters[i].position = Vector3.ZERO
		labels[i].visible = false

func _settle(person: Node3D, speed: float, frames: int) -> void:
	for frame in frames:
		person.animate(1.0 / 60.0, speed)
	var skeleton := _find_skeleton(person)
	if skeleton:
		skeleton.force_update_all_bone_transforms()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		result.append(node)
	for child in node.get_children():
		_collect_meshes(child, result)

func _binding_bone(skeleton: Skeleton3D, skin: Skin, index: int) -> int:
	var name := skin.get_bind_name(index)
	if not name.is_empty():
		return skeleton.find_bone(name)
	return skin.get_bind_bone(index)

func _validate_skin_bindings(person: Node3D) -> bool:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(person, meshes)
	var bound_meshes := 0
	var weighted_vertices := 0
	for instance in meshes:
		if instance.skin == null:
			continue
		bound_meshes += 1
		var skeleton := instance.get_node_or_null(instance.skeleton) as Skeleton3D
		if skeleton == null:
			return false
		for binding in instance.skin.get_bind_count():
			var bone := _binding_bone(skeleton, instance.skin, binding)
			if bone < 0 or bone >= skeleton.get_bone_count():
				return false
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or weights.is_empty() or weights.size() != indices.size():
				return false
			var influences: int = weights.size() / vertices.size()
			if influences != 4 and influences != 8:
				return false
			for vertex in vertices.size():
				var total := 0.0
				for slot in influences:
					var offset := vertex * influences + slot
					if not is_finite(weights[offset]) or weights[offset] < 0.0 or indices[offset] < 0 or indices[offset] >= instance.skin.get_bind_count():
						return false
					total += weights[offset]
				if absf(total - 1.0) > 0.02:
					return false
			weighted_vertices += vertices.size()
	return bound_meshes >= 1 and weighted_vertices > 1000

func _skin_bounds(person: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(person, meshes)
	var bounds := AABB()
	var initialized := false
	var to_local := person.global_transform.affine_inverse()
	for instance in meshes:
		var transforms: Array[Transform3D] = []
		var skeleton := instance.get_node_or_null(instance.skeleton) as Skeleton3D
		if instance.skin != null and skeleton != null:
			skeleton.force_update_all_bone_transforms()
			for binding in instance.skin.get_bind_count():
				var bone := _binding_bone(skeleton, instance.skin, binding)
				transforms.append(to_local * skeleton.global_transform * skeleton.get_bone_global_pose(bone) * instance.skin.get_bind_pose(binding))
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var weights := PackedFloat32Array()
			var indices := PackedInt32Array()
			if not transforms.is_empty():
				weights = arrays[Mesh.ARRAY_WEIGHTS]
				indices = arrays[Mesh.ARRAY_BONES]
			var influences: int = weights.size() / maxi(1, vertices.size())
			for vertex in vertices.size():
				var point := Vector3.ZERO
				if influences > 0:
					for slot in influences:
						var offset := vertex * influences + slot
						point += (transforms[indices[offset]] * vertices[vertex]) * weights[offset]
				else:
					point = to_local * instance.global_transform * vertices[vertex]
				if not initialized:
					bounds = AABB(point, Vector3.ZERO)
					initialized = true
				else:
					bounds = bounds.expand(point)
	return bounds

func _finite_aabb(bounds: AABB) -> bool:
	return bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.length() < 5

func _points_bounds(points: PackedVector3Array) -> AABB:
	if points.is_empty(): return AABB()
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points: bounds = bounds.expand(point)
	return bounds

func _hand_points(person: Node3D, side: int, at_rest: bool = false) -> PackedVector3Array:
	var hand := person.find_child("Hands", true, false) as MeshInstance3D
	if not hand.visible: hand = person.find_child("GuardHands", true, false)
	var skeleton := hand.get_node(hand.skeleton) as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	var transforms: Array[Transform3D] = []
	var side_bind := -1
	for binding in hand.skin.get_bind_count():
		var bone := _binding_bone(skeleton, hand.skin, binding)
		if skeleton.get_bone_name(bone) == "Elbow%d" % side: side_bind = binding
		var pose := skeleton.get_bone_global_rest(bone) if at_rest else skeleton.get_bone_global_pose(bone)
		transforms.append(person.global_transform.affine_inverse() * skeleton.global_transform * pose * hand.skin.get_bind_pose(binding))
	var points := PackedVector3Array()
	for surface in hand.mesh.get_surface_count():
		var arrays := hand.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences: int = weights.size() / vertices.size()
		for vertex in vertices.size():
			var point := Vector3.ZERO
			var side_weight := 0.0
			for slot in influences:
				var offset := vertex * influences + slot
				point += transforms[indices[offset]] * vertices[vertex] * weights[offset]
				if indices[offset] == side_bind: side_weight += weights[offset]
			if side_weight > 0.9: points.append(point)
	return points

func _bandage_head_weights(person: Node3D) -> float:
	var bandage := person.find_child("Bandage", true, false) as MeshInstance3D
	var skeleton := bandage.get_node(bandage.skeleton) as Skeleton3D
	var total := 0.0
	for surface in bandage.mesh.get_surface_count():
		var arrays := bandage.mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for index in indices.size():
			if skeleton.get_bone_name(_binding_bone(skeleton, bandage.skin, indices[index])) == "Head": total += weights[index]
	return total

func _bone_snapshot(skeleton: Skeleton3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		result.append(skeleton.get_bone_pose(bone))
	return result

func _changed_bones(skeleton: Skeleton3D, before: Array[Transform3D]) -> int:
	var count := 0
	for bone in mini(skeleton.get_bone_count(), before.size()):
		if not skeleton.get_bone_pose(bone).is_equal_approx(before[bone]):
			count += 1
	return count

func _bone_position(index: int, name: String) -> Vector3:
	var skeleton: Skeleton3D = skeletons[index]
	skeleton.force_update_all_bone_transforms()
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin

func _guard_grip_error() -> float:
	var person: Node3D = characters[3]
	var skeleton: Skeleton3D = skeletons[3]
	skeleton.force_update_all_bone_transforms()
	var grips := [Vector3(0, -0.042, -0.105), Vector3(0.016, -0.034, 0.055)]
	var maximum_error := 0.0
	for side_index in 2:
		var side := -1.0 if side_index == 0 else 1.0
		# The authored palm is rigidly weighted to the elbow bone. Convert its
		# model-space rest point through the imported bone basis before posing.
		var palm_rest := Vector3(side * 0.243, 1.055, 0) + Vector3(side * 0.027, -0.288, -0.015)
		var bone := skeleton.find_bone("Elbow%d" % side_index)
		var skeleton_from_model := skeleton.global_transform.affine_inverse() * person.global_transform
		var palm := skeleton.global_transform * skeleton.get_bone_global_pose(bone) * skeleton.get_bone_global_rest(bone).affine_inverse() * skeleton_from_model * palm_rest
		var target: Vector3 = person.rifle.global_transform * grips[side_index]
		maximum_error = maxf(maximum_error, palm.distance_to(target))
	return maximum_error

func _cuff_gap(person: Node3D) -> float:
	var clothing := person.find_child("Clothing", true, false) as MeshInstance3D
	if clothing == null or clothing.skin == null: return INF
	var skeleton := clothing.get_node(clothing.skeleton) as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	var minimum := [INF, INF]
	var targets: Array[Vector3] = []
	var transforms: Array[Transform3D] = []
	for side in 2:
		var index := skeleton.find_bone("Elbow%d" % side)
		var point := Vector3((-1.0 if side == 0 else 1.0) * .270, .823, 0)
		point = skeleton.global_transform.affine_inverse() * person.global_transform * point
		targets.append(skeleton.global_transform * skeleton.get_bone_global_pose(index) * skeleton.get_bone_global_rest(index).affine_inverse() * point)
	for binding in clothing.skin.get_bind_count():
		transforms.append(skeleton.global_transform * skeleton.get_bone_global_pose(_binding_bone(skeleton, clothing.skin, binding)) * clothing.skin.get_bind_pose(binding))
	for surface in clothing.mesh.get_surface_count():
		var arrays := clothing.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var influences: int = weights.size() / vertices.size()
		for vertex in vertices.size():
			var point := Vector3.ZERO
			for slot in influences:
				var offset := vertex * influences + slot
				point += (transforms[indices[offset]] * vertices[vertex]) * weights[offset]
			for side in 2:
				minimum[side] = minf(minimum[side], point.distance_to(targets[side]))
	return maxf(minimum[0], minimum[1])

func _death_arms_converge() -> bool:
	# Compare two real entry states so an inherited aiming twist cannot pass
	# merely because its vertices still happen to fit inside a broad AABB.
	var lowered := Human.new()
	lowered.build("guard")
	stage.add_child(lowered)
	_settle(lowered, 0.0, 30)
	lowered.fall()
	_settle(lowered, 0.0, 100)
	var other := _find_skeleton(lowered)
	var consistent := other != null
	if other != null:
		for name in ["Shoulder0", "Shoulder1", "Elbow0", "Elbow1"]:
			var a := skeletons[3].get_bone_pose_rotation(skeletons[3].find_bone(name))
			var b := other.get_bone_pose_rotation(other.find_bone(name))
			consistent = consistent and a.angle_to(b) < 0.08
	lowered.free()
	return consistent

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	if DirAccess.make_dir_recursive_absolute(capture_dir) != OK:
		check(false, "Character capture directory can be created")
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	check(not screenshot.is_empty() and screenshot.save_png(capture_dir.path_join(label + ".png")) == OK, "Character image saved: " + label)

func _finish() -> void:
	stage.queue_free()
	await process_frame
	print("CHARACTER MODEL RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
