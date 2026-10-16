extends Node3D
## Converts the game's procedural joint motion to the authored Blender skin.
## Driver and bind transforms are evaluated locally, so build() also works
## before the actor enters the SceneTree.

const MODEL_PATH := "res://assets/characters/field_character.glb"
const SOLDIER_MODELS := {
	"guard": "res://assets/characters/user_soldiers/japanese.glb",
	"scout": "res://assets/characters/user_soldiers/volunteer.glb",
	"wounded": "res://assets/characters/user_soldiers/volunteer.glb",
	"ally": "res://assets/characters/user_soldiers/volunteer.glb",
}
const REQUIRED_BONES := ["Hips", "Chest", "Head", "Thigh0", "Thigh1", "Knee0", "Knee1", "Foot0", "Foot1", "Shoulder0", "Shoulder1", "Elbow0", "Elbow1"]

static var _materials: Dictionary = {}
var skeleton: Skeleton3D
var character: Node3D
var has_guard_hands := false
var model_path := MODEL_PATH
var _driver_root: Node3D
var _drivers: Dictionary = {}
var _bind_corrections: Dictionary = {}
var _bone_rest: Array[Transform3D] = []
var _parents: Array[int] = []
var _skeleton_from_model := Transform3D.IDENTITY

func prepare(character_role: String, gripping_hands: bool = false) -> bool:
	model_path = SOLDIER_MODELS.get(character_role, MODEL_PATH)
	if not ResourceLoader.exists(model_path): return false
	var scene := load(model_path) as PackedScene
	if scene == null: return false
	character = scene.instantiate() as Node3D
	if character == null: return false
	add_child(character)
	skeleton = _find_skeleton(character)
	if skeleton == null: return false
	for bone_name in REQUIRED_BONES:
		if skeleton.find_bone(bone_name) < 0:
			push_warning("Field character is missing bone %s; using the built-in model." % bone_name)
			return false
	has_guard_hands = character.find_child("GuardHands", true, false) != null
	_prepare_role(character, character_role, gripping_hands or character_role == "guard")
	return true

func bind(driver_root: Node3D, drivers: Dictionary) -> void:
	_driver_root = driver_root
	var model_from_skeleton := _relative_transform(skeleton, driver_root)
	_skeleton_from_model = model_from_skeleton.affine_inverse()
	for bone in skeleton.get_bone_count():
		_bone_rest.append(skeleton.get_bone_rest(bone))
		_parents.append(skeleton.get_bone_parent(bone))
		var bone_name := skeleton.get_bone_name(bone)
		if drivers.has(bone_name):
			var driver: Node3D = drivers[bone_name]
			_drivers[bone] = driver
			var driver_bind := _relative_transform(driver, driver_root)
			var bone_bind := model_from_skeleton * skeleton.get_bone_global_rest(bone)
			_bind_corrections[bone] = driver_bind.affine_inverse() * bone_bind
	sync_pose()

func set_gripping_hands(value: bool) -> void:
	var grip := character.find_child("GuardHands", true, false) as Node3D
	var relaxed := character.find_child("Hands", true, false) as Node3D
	if grip != null: grip.visible = value
	if relaxed != null: relaxed.visible = not value or not has_guard_hands

func sync_pose() -> void:
	if skeleton == null or _driver_root == null: return
	var global_poses: Dictionary = {}
	for bone in _drivers:
		var driver: Node3D = _drivers[bone]
		global_poses[bone] = _skeleton_from_model * _relative_transform(driver, _driver_root) * _bind_corrections[bone]
	for bone in skeleton.get_bone_count():
		var global_pose := _global_pose(bone, global_poses)
		var parent := _parents[bone]
		var pose := global_pose if parent < 0 else _global_pose(parent, global_poses).affine_inverse() * global_pose
		skeleton.set_bone_pose_position(bone, pose.origin)
		skeleton.set_bone_pose_rotation(bone, pose.basis.get_rotation_quaternion())
		skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())

func _global_pose(bone: int, poses: Dictionary) -> Transform3D:
	if poses.has(bone): return poses[bone]
	var parent := _parents[bone]
	var pose := _bone_rest[bone] if parent < 0 else _global_pose(parent, poses) * _bone_rest[bone]
	poses[bone] = pose
	return pose

func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != ancestor:
		if current is Node3D: result = current.transform * result
		current = current.get_parent()
	return result

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null: return found
	return null

func _prepare_role(node: Node, character_role: String, gripping_hands: bool) -> void:
	if node is AnimationPlayer:
		node.autoplay = ""
		node.stop()
	if node is Node3D:
		match String(node.name):
			"FriendlyCapStar": node.visible = character_role in ["scout", "wounded", "ally"]
			"Cap", "Backpack", "Scarf": node.visible = character_role != "guard"
			"Helmet", "GuardGear", "GuardHelmetMark", "GuardMoustache": node.visible = character_role == "guard"
			"Bandage": node.visible = character_role == "wounded"
			"GuardHands": node.visible = gripping_hands
			"Hands": node.visible = not gripping_hands or not has_guard_hands
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var material := node.get_active_material(surface) as StandardMaterial3D
			if material == null: continue
			var material_name := material.resource_name.to_lower()
			# Keep the authored face and fabric texture maps. Neutral cloth maps
			# receive role-specific coat and wool tints on copied materials.
			var is_coat := material_name.contains("coat")
			var is_wool := material_name.contains("wool")
			var is_brows := material_name.contains("brows")
			if not is_coat and not is_wool and not is_brows: continue
			var key := "%s/%s" % [character_role, material.get_instance_id()]
			if not _materials.has(key):
				var copy := material.duplicate() as StandardMaterial3D
				var tint := Color("7c8083")
				if character_role == "logger": tint = Color("625951")
				elif character_role == "guard": tint = Color("817954")
				if is_wool:
					tint = Color("505559")
					if character_role == "logger": tint = Color("46433d")
					elif character_role == "guard": tint = Color("4d503f")
				if is_brows: tint = Color("433b32")
				copy.albedo_color = tint
				_materials[key] = copy
			node.set_surface_override_material(surface, _materials[key])
	for child in node.get_children(): _prepare_role(child, character_role, gripping_hands)
