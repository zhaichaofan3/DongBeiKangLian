extends Node3D
## Authored skinned characters driven by the existing gameplay motion rig.
## Procedural meshes remain a fallback if the imported asset is unavailable.

const DetailedRig = preload("res://scripts/field_character_rig.gd")

static var _mesh_cache: Dictionary = {}
static var _cloth_material: StandardMaterial3D
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var feet: Array[Node3D] = []
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var head: Node3D
var hips: Node3D
var chest: Node3D
var rifle: Node3D
var clock := 0.0
var role := ""
var treated := false
var aiming := false
var turn_amount := 0.0
var _turn_target := 0.0
var _gait := 0.0
var _motion := 0.0
var _aim := 0.0
var _talk := 0.0
var _recoil := 0.0
var _flinch := 0.0
var _stagger := 0.0
var _stagger_sign := 1.0
var _death_time := -1.0
var _injury_pose := 0.0
var _surfaces: Dictionary = {}
var detailed_rig: Node3D

func build(character_role: String, appearance_role: String = "") -> void:
	role = character_role
	clock = float(get_instance_id() % 137) * 0.071
	_stagger_sign = -1.0 if get_instance_id() % 2 == 0 else 1.0
	_injury_pose = 1.0 if role == "wounded" else 0.0
	if _build_detailed_model(appearance_role):
		animate(0, 0)
		return
	var coat := Color("7c8083")
	if role == "logger": coat = Color("625951")
	elif role == "guard": coat = Color("817954")
	var seam := coat.darkened(0.24)
	var fold := coat.lightened(0.07)
	var skin := Color("c09f82")
	var skin_shadow := Color("9f7d65")
	var leather := Color("352f29")
	var wool := Color("505559") if role != "guard" and role != "logger" else Color("3c443c")
	var steel := Color("454d49")
	var linen := Color("b5b49b")
	hips = _joint(self, "Hips", Vector3(0, 0.86, 0))
	chest = _joint(hips, "Chest", Vector3(0, 0.18, 0))
	# Structured shoulders, gathered waist and padded coat hem.
	_loft(chest, Vector3.ZERO, [Vector3(-0.23,0.227,0.144), Vector3(-0.18,0.233,0.149), Vector3(-0.08,0.216,0.137), Vector3(0.04,0.219,0.148), Vector3(0.22,0.237,0.157), Vector3(0.30,0.247,0.139), Vector3(0.35,0.184,0.115)], coat, 14)
	_box(chest, Vector3(0,-0.12,0), Vector3(0.454,0.054,0.299), leather)
	_box(chest, Vector3(0,-0.12,-0.156), Vector3(0.050,0.046,0.018), Color("87866f"))
	_box(chest, Vector3(0,0.13,-0.158), Vector3(0.027,0.34,0.013), seam)
	for side in [-1.0, 1.0]:
		_box(chest, Vector3(side*0.119,0.14,-0.153), Vector3(0.127,0.125,0.019), fold)
		_box(chest, Vector3(side*0.119,0.19,-0.167), Vector3(0.136,0.024,0.011), seam)
		_box(chest, Vector3(side*0.119,0.084,-0.165), Vector3(0.112,0.005,0.007), seam)
		_box(chest, Vector3(side*0.145,-0.19,-0.145), Vector3(0.10,0.036,0.015), seam)
		_box(chest, Vector3(side*0.086,0.315,-0.122), Vector3(0.10,0.073,0.036), wool, Vector3(0,0,side*0.24))
	for y in [0.266, 0.187, 0.102, 0.016]:
		_oval(chest, Vector3(0,y,-0.171), Vector3(0.014,0.016,0.010), leather, 8)
	for y in [-0.044,0.028,0.254]:
		for side in [-1.0,1.0]:
			_box(chest, Vector3(side*0.122,y,-0.146), Vector3(0.18,0.003,0.007), seam)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var thigh := _joint(hips, "Thigh%d" % i, Vector3(side*0.118,-0.005,0))
		legs.append(thigh)
		_loft(thigh, Vector3.ZERO, [Vector3(-0.035,0.103,0.106), Vector3(-0.11,0.102,0.109), Vector3(-0.25,0.082,0.089), Vector3(-0.37,0.071,0.078), Vector3(-0.397,0.075,0.080)], coat, 10)
		_box(thigh, Vector3(side*0.087,-0.19,0), Vector3(0.006,0.23,0.094), seam)
		var knee := _joint(thigh, "Knee%d" % i, Vector3(0,-0.39,0))
		knees.append(knee)
		_loft(knee, Vector3.ZERO, [Vector3(0.025,0.075,0.080), Vector3(-0.08,0.079,0.081), Vector3(-0.19,0.068,0.068), Vector3(-0.33,0.052,0.058)], wool, 10)
		for wrap in 6:
			var y := -0.082 - wrap * 0.039
			var radius := 0.077 - wrap * 0.004
			_loft(knee, Vector3.ZERO, [Vector3(y,radius,radius+0.005), Vector3(y-0.022,radius-0.001,radius+0.004)], coat.darkened(0.10+(wrap%2)*0.035), 10)
		if role == "wounded" and i == 0:
			for wrap in 4:
				var y := -0.105 - wrap * 0.024
				var radius := 0.081 - wrap * 0.001
				var cloth := linen.darkened(0.05 if wrap % 2 == 0 else 0.12)
				_loft(knee, Vector3.ZERO, [Vector3(y,radius,radius+0.010), Vector3(y-0.017,radius-0.001,radius+0.009)], cloth, 12)
		var foot := _joint(knee, "Foot%d" % i, Vector3(0,-0.355,0))
		feet.append(foot)
		_loft(foot, Vector3(0,-0.014,-0.045), [Vector3(-0.086,0.081,0.153), Vector3(-0.067,0.086,0.153), Vector3(-0.026,0.080,0.145), Vector3(0.028,0.059,0.083)], leather, 12)
		_loft(foot, Vector3(0,-0.014,-0.045), [Vector3(-0.087,0.083,0.154), Vector3(-0.073,0.084,0.155)], Color("222624"), 12)
		for lace in 3:
			_box(foot, Vector3(0,0.007-lace*0.011,-0.083-lace*0.017), Vector3(0.077,0.006,0.009), wool)
		var arm := _joint(chest, "Shoulder%d" % i, Vector3(side*0.243,0.29,0))
		arms.append(arm)
		_loft(arm, Vector3.ZERO, [Vector3(0.025,0.082,0.091), Vector3(-0.045,0.096,0.100), Vector3(-0.15,0.081,0.087), Vector3(-0.265,0.066,0.070), Vector3(-0.28,0.067,0.068)], coat, 10)
		var elbow := _joint(arm, "Elbow%d" % i, Vector3(0,-0.275,0))
		elbows.append(elbow)
		_loft(elbow, Vector3.ZERO, [Vector3(0.027,0.069,0.071), Vector3(-0.045,0.072,0.075), Vector3(-0.16,0.057,0.061), Vector3(-0.244,0.050,0.052)], coat, 10)
		_loft(elbow, Vector3.ZERO, [Vector3(-0.21,0.055,0.057), Vector3(-0.245,0.054,0.055)], seam, 10)
		_loft(elbow, Vector3(0,-0.273,0), [Vector3(0.032,0.035,0.039), Vector3(-0.016,0.042,0.030), Vector3(-0.070,0.039,0.026), Vector3(-0.082,0.022,0.020)], skin, 10)
		_oval(elbow, Vector3(-side*0.042,-0.284,-0.007), Vector3(0.037,0.076,0.041), skin_shadow, 8)
		for finger in 3:
			_box(elbow, Vector3(-0.022+finger*0.020,-0.337,-0.026), Vector3(0.003,0.022,0.004), skin_shadow)
	_loft(chest, Vector3(0,0.345,0), [Vector3(-0.012,0.088,0.080), Vector3(0.079,0.076,0.071)], skin, 12)
	_loft(chest, Vector3(0,0.34,0), [Vector3(-0.034,0.137,0.113), Vector3(0.033,0.129,0.104)], wool, 12)
	_box(chest, Vector3(-0.081,0.222,-0.163), Vector3(0.080,0.21,0.027), wool, Vector3(0,0,-0.10))
	head = _joint(chest, "Head", Vector3(0,0.478,-0.005))
	_loft(head, Vector3.ZERO, [Vector3(-0.082,0.046,0.063), Vector3(-0.068,0.068,0.081), Vector3(-0.040,0.088,0.093), Vector3(-0.005,0.103,0.104), Vector3(0.029,0.108,0.107), Vector3(0.065,0.104,0.108), Vector3(0.103,0.103,0.104), Vector3(0.136,0.094,0.099), Vector3(0.166,0.073,0.078)], skin, 24)
	for side in [-1.0,1.0]:
		_oval(head, Vector3(side*0.111,0.024,-0.004), Vector3(0.036,0.070,0.038), skin_shadow, 8)
		_oval(head, Vector3(side*0.045,0.044,-0.103), Vector3(0.047,0.011,0.008), Color("50473d"), 10)
		_oval(head, Vector3(side*0.045,0.044,-0.108), Vector3(0.012,0.010,0.004), Color("252f2c"), 8)
		_box(head, Vector3(side*0.046,0.065,-0.103), Vector3(0.048,0.009,0.009), wool, Vector3(0,0,side*0.09))
		_box(head, Vector3(side*0.067,-0.005,-0.094), Vector3(0.030,0.005,0.006), skin_shadow, Vector3(0,0,side*0.25))
	_loft(head, Vector3(0,0.003,-0.107), [Vector3(-0.009,0.019,0.020), Vector3(0.010,0.018,0.028), Vector3(0.036,0.011,0.013), Vector3(0.052,0.009,0.006)], skin.darkened(0.04), 12)
	_box(head, Vector3(0,-0.036,-0.094), Vector3(0.054,0.007,0.006), Color("795e51"))
	if role == "guard":
		_loft(head, Vector3(0,0.15,0.009), [Vector3(-0.065,0.167,0.167), Vector3(-0.050,0.169,0.169), Vector3(-0.016,0.145,0.150), Vector3(0.052,0.118,0.123), Vector3(0.088,0.059,0.063), Vector3(0.097,0.010,0.011)], steel, 18)
		for side in [-1.0,1.0]:
			_box(head, Vector3(side*0.103,-0.014,0.01), Vector3(0.012,0.156,0.018), leather, Vector3(0.21,0,side*-0.12))
		_box(head, Vector3(0,-0.084,-0.034), Vector3(0.17,0.014,0.027), leather)
		_build_rifle(chest, leather, steel)
		for side in [-1.0,1.0]:
			_box(chest, Vector3(side*0.163,-0.11,-0.191), Vector3(0.109,0.115,0.068), leather)
			_box(chest, Vector3(side*0.163,-0.060,-0.225), Vector3(0.114,0.024,0.010), leather.lightened(0.14))
	else:
		_loft(head, Vector3(0,0.147,0.009), [Vector3(-0.035,0.121,0.122), Vector3(0.007,0.124,0.119), Vector3(0.050,0.114,0.108), Vector3(0.074,0.088,0.083), Vector3(0.081,0.052,0.051)], wool, 20)
		_oval(head, Vector3(0,0.119,-0.067), Vector3(0.257,0.017,0.204), wool, 20)
		_box(head, Vector3(0,0.181,-0.081), Vector3(0.005,0.053,0.009), wool.lightened(0.12))
		if role in ["scout", "wounded", "ally"]: _build_cap_star()
		_box(chest, Vector3(0,0.035,0.218), Vector3(0.293,0.340,0.151), leather)
		_box(chest, Vector3(0,0.189,0.235), Vector3(0.304,0.045,0.166), leather.lightened(0.12))
		for side in [-1.0,1.0]:
			_box(chest, Vector3(side*0.100,0.078,0.305), Vector3(0.034,0.252,0.014), wool)
			_box(chest, Vector3(side*0.174,0.176,-0.154), Vector3(0.032,0.29,0.019), leather, Vector3(0,0,side*0.16))
		_oval(chest, Vector3(0,0.243,0.233), Vector3(0.373,0.116,0.146), wool, 12)
		for side in [-1.0,1.0]:
			_box(chest, Vector3(side*0.101,0.27,0.233), Vector3(0.025,0.071,0.151), leather)
	if role == "wounded":
		_box(head, Vector3(0,0.083,-0.105), Vector3(0.215,0.032,0.015), linen)
		_box(head, Vector3(-0.052,0.083,-0.115), Vector3(0.035,0.022,0.005), Color("816a59"))
		_box(chest, Vector3(0.029,0.123,-0.182), Vector3(0.029,0.390,0.018), linen, Vector3(0,0,-0.61))
		_box(chest, Vector3(-0.054,0.068,-0.197), Vector3(0.235,0.065,0.094), linen, Vector3(0,0,0.08))
	_flush_meshes()
	animate(0, 0)

func _build_cap_star() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0, 0.187, -0.111)
	for i in 10:
		surface.add_vertex(center)
		for index in [i, (i + 1) % 10]:
			var angle: float = PI * 0.5 + index * PI / 5.0
			var radius: float = 0.025 if index % 2 == 0 else 0.0105
			surface.add_vertex(center + Vector3(cos(angle), sin(angle), 0) * radius)
	surface.generate_normals()
	var star := MeshInstance3D.new()
	star.name = "FriendlyCapStar"
	star.mesh = surface.commit()
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("c3231b")
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	star.material_override = red
	head.add_child(star)

func _build_detailed_model(appearance_role: String = "") -> bool:
	var rig := DetailedRig.new()
	if not rig.prepare(role if appearance_role.is_empty() else appearance_role, role == "guard"):
		rig.free()
		return false
	detailed_rig = rig
	rig.name = "DetailedCharacter"
	add_child(rig)
	hips = _joint(self, "Hips", Vector3(0, 0.86, 0))
	chest = _joint(hips, "Chest", Vector3(0, 0.18, 0))
	head = _joint(chest, "Head", Vector3(0, 0.478, -0.005))
	var drivers := {"Hips": hips, "Chest": chest, "Head": head}
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var thigh := _joint(hips, "Thigh%d" % i, Vector3(side * 0.118, -0.005, 0))
		var knee := _joint(thigh, "Knee%d" % i, Vector3(0, -0.39, 0))
		var foot := _joint(knee, "Foot%d" % i, Vector3(0, -0.355, 0))
		var arm := _joint(chest, "Shoulder%d" % i, Vector3(side * 0.243, 0.29, 0))
		var elbow := _joint(arm, "Elbow%d" % i, Vector3(0, -0.275, 0))
		legs.append(thigh)
		knees.append(knee)
		feet.append(foot)
		arms.append(arm)
		elbows.append(elbow)
		for joint in [thigh, knee, foot, arm, elbow]: drivers[String(joint.name)] = joint
	if role == "guard":
		_build_rifle(chest, Color("352f29"), Color("454d49"))
		_flush_meshes()
		# Optional rifle bone can support an authored gun in a later asset.
		drivers["Rifle"] = rifle
	rig.bind(self, drivers)
	return true

func _sync_detailed_model() -> void:
	if detailed_rig != null: detailed_rig.sync_pose()

func set_armed(value: bool) -> void:
	if value and rifle == null:
		_build_rifle(chest, Color("352f29"), Color("454d49"))
	if rifle != null: rifle.visible = value
	if detailed_rig != null: detailed_rig.set_gripping_hands(value)

func _build_rifle(parent: Node3D, wood: Color, metal: Color) -> void:
	rifle = _joint(parent, "Rifle", Vector3(0.135,0.196,-0.257))
	var supplied := (load("res://assets/user_expansion_20261015/kar98k.glb") as PackedScene).instantiate()
	supplied.name = "SuppliedKar98k"
	supplied.scale = Vector3.ONE * .75
	supplied.position = Vector3(0, -.008, -.04)
	rifle.add_child(supplied)
	for part in supplied.find_children("Clip_*", "MeshInstance3D", true, false): part.visible = false

func set_motion_context(is_treated: bool, yaw_rate: float = 0, is_aiming: bool = false) -> void:
	treated = is_treated
	_turn_target = clampf(yaw_rate * 0.06, -0.14, 0.14)
	aiming = is_aiming

func hand_position(index: int) -> Vector3:
	if index < 0 or index >= elbows.size(): return global_position
	# The procedural hand is the short continuation below each elbow driver.
	return elbows[index].to_global(Vector3(0, -0.285, -0.02))

func pose_hand(index: int, target_global: Vector3, pole: Vector3 = Vector3.ZERO) -> void:
	if index < 0 or index >= arms.size(): return
	var target: Vector3 = chest.to_local(target_global)
	var shoulder: Vector3 = arms[index].position
	var palm_local := Vector3(0, -0.285, -0.02)
	var offset := target - shoulder
	var upper_length := elbows[index].position.length()
	var lower_length := palm_local.length()
	var distance := clampf(offset.length(), 0.035, upper_length + lower_length - 0.002)
	var direction := offset.normalized()
	var pole_vector := pole if pole.length_squared() > 0.001 else Vector3((-1.0 if index == 0 else 1.0) * 0.28, -0.92, 0.1)
	var pole_orthogonal := (pole_vector - direction * pole_vector.dot(direction)).normalized()
	var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var elbow_at := shoulder + direction * along + pole_orthogonal * height
	var reached_target := shoulder + direction * distance
	var upper_basis := _limb_basis(elbow_at - shoulder, Vector3.BACK)
	var lower_basis := _limb_basis(reached_target - elbow_at, Vector3.UP)
	arms[index].basis = upper_basis
	elbows[index].basis = upper_basis.inverse() * lower_basis

func fire() -> void:
	_recoil = 1.0

func flinch() -> void:
	_flinch = 1.0
	_stagger = 1.0

func fall() -> void:
	_death_time = 0.0

func animate_death(delta: float) -> void:
	if _death_time < 0: return
	_death_time = minf(_death_time + delta, 1.15)
	var t := smoothstep(0.0, 0.95, _death_time)
	# Only the visual pelvis falls: physics, hit tests and navigation are untouched.
	hips.position.y = lerpf(0.86, 0.22, t)
	hips.rotation.z = lerpf(0.0, 1.50, t)
	hips.rotation.x = lerpf(0.0, -0.22, t)
	chest.rotation.x = lerpf(chest.rotation.x, -0.17, minf(1, delta * 6))
	head.rotation.z = lerpf(head.rotation.z, 0.28, minf(1, delta * 6))
	var arm_blend := 1.0 - exp(-delta * 6.0)
	for i in 2:
		legs[i].rotation.x = lerp_angle(legs[i].rotation.x, -0.12+i*0.40, minf(1,delta*7))
		knees[i].rotation.x = lerpf(knees[i].rotation.x, -0.36-i*0.22, minf(1,delta*6))
		# Release all three axes of the grip solver. Retaining its wrist roll
		# would leave an arm raised after the rest of the body hits the ground.
		var relaxed_arm := Quaternion.from_euler(Vector3(0.23 + i * 0.30, 0, 0))
		var relaxed_elbow := Quaternion.from_euler(Vector3(0.6, 0, 0))
		arms[i].quaternion = arms[i].quaternion.slerp(relaxed_arm, arm_blend)
		elbows[i].quaternion = elbows[i].quaternion.slerp(relaxed_elbow, arm_blend)
	if rifle != null:
		# Let a shouldered rifle settle across the chest as the arms release it.
		rifle.position = rifle.position.lerp(Vector3(0.135, 0.17, -0.257), arm_blend)
		rifle.quaternion = rifle.quaternion.slerp(Quaternion.from_euler(Vector3(-0.23, 0, 0)), arm_blend)
	_sync_detailed_model()

func animate(delta: float, speed: float, talking: bool = false) -> void:
	if _death_time >= 0:
		animate_death(delta)
		return
	clock += delta
	var blend := 1.0 - exp(-delta * 10.0)
	turn_amount = lerpf(turn_amount, _turn_target, 1.0 - exp(-delta * 9.0))
	_motion = lerpf(_motion, minf(speed / 2.5, 1.0), blend)
	_talk = lerpf(_talk, 1.0 if talking else 0.0, blend)
	var aim_blend := 1.0 - exp(-delta * (7.5 if aiming else 6.0)) if role == "guard" else blend
	_aim = lerpf(_aim, 1.0 if aiming else 0.0, aim_blend)
	_recoil = move_toward(_recoil, 0, delta * 7)
	_flinch = move_toward(_flinch, 0, delta * 4)
	_stagger = move_toward(_stagger, 0, delta * 3.4)
	var injury_target := 0.0
	if role == "wounded":
		injury_target = 0.32 if treated else 1.0
	_injury_pose = lerpf(_injury_pose, injury_target, 1.0 - exp(-delta * 3.2))
	var injury := _injury_pose
	var idle_injury := injury * (1.0 - _motion * 0.72)
	var stagger_pose := _stagger * (0.72 + 0.28 * sin(clock * 10.0))
	var role_posture := 0.0
	if role == "scout": role_posture = -0.012
	elif role == "logger": role_posture = 0.022
	_gait += delta * (4.7 + minf(speed,3.5)*1.3) * minf(_motion*4.0,1.0)
	var breath := sin(clock * 1.75)
	hips.rotation = Vector3(-stagger_pose*0.055,sin(_gait)*0.045*_motion,sin(_gait)*0.037*_motion+idle_injury*0.045+_stagger_sign*stagger_pose*0.035)
	chest.position.y = 0.18 + breath * 0.0035 - idle_injury * 0.014
	chest.rotation = Vector3(-0.035*_motion+injury*0.055+idle_injury*0.075+role_posture-_flinch*0.12-stagger_pose*0.16,-sin(_gait)*_motion*0.07,-turn_amount-injury*0.038+_stagger_sign*stagger_pose*0.10)
	head.rotation = Vector3(breath*0.012+_talk*sin(clock*3.4)*0.035+idle_injury*0.035,sin(clock*0.63)*0.028+turn_amount*0.5+_talk*sin(clock*1.25)*0.065,injury*0.04)
	for i in 2:
		var wave := sin(_gait + i * PI)
		var stride_scale := 1.0 - injury * 0.35 if i == 0 else 1.0
		legs[i].rotation = Vector3(wave*0.49*_motion*stride_scale,0,0.035 if i == 0 else -0.035)
		var injured_knee := 0.16 if i == 0 else 0.025
		knees[i].rotation.x = -maxf(0,-wave)*0.80*_motion*stride_scale-injury*injured_knee
		feet[i].rotation.x = -(legs[i].rotation.x + knees[i].rotation.x)*0.85 + wave*0.10*_motion + (0.08 if i == 0 else 0.0)*idle_injury
		var side := -1.0 if i == 0 else 1.0
		arms[i].rotation = Vector3(-wave*0.30*_motion,0,side*0.095)
		elbows[i].rotation = Vector3(0.10+maxf(0,wave)*0.20*_motion,0,0)
	# Keep the supporting boot on the floor as knees bend. This operates only
	# on the visual rig and avoids the floating "running mannequin" silhouette.
	var lowest_sole := 0.0
	for i in 2:
		var foot_transform := legs[i].transform * knees[i].transform * feet[i].transform
		for sole in [Vector3(-0.084,-0.100,-0.198),Vector3(0.084,-0.100,-0.198),Vector3(-0.084,-0.100,0.110),Vector3(0.084,-0.100,0.110)]:
			lowest_sole = minf(lowest_sole, (hips.basis * (foot_transform * sole)).y)
	hips.position.y = 0.008 - lowest_sole
	if rifle != null and rifle.visible:
		arms[1].rotation.x = lerpf(0.40,0.33,_aim)-_recoil*0.07
		arms[1].rotation.z = -0.10
		arms[0].rotation.x = lerpf(0.70,1.15,_aim)
		arms[0].rotation.z = 0.56
		elbows[1].rotation.x = lerpf(1.30,1.80,_aim)
		elbows[0].rotation.x = lerpf(0.80,0.45,_aim)
		rifle.position = Vector3(0.135,lerpf(0.065,0.205,_aim),-0.257+_recoil*0.040)
		rifle.rotation.x = lerpf(-0.23,0.015,_aim)+_recoil*0.065
		chest.rotation.x += -_aim*0.035+_recoil*0.018
		if detailed_rig != null and detailed_rig.has_guard_hands:
			# Raise the stock toward the shoulder with a soft start/stop. Keep
			# the support arm within reach as the barrel moves slightly forward.
			var raised := smoothstep(0.0, 1.0, _aim)
			rifle.position = Vector3(lerpf(0.105, 0.110, raised), lerpf(0.085, 0.365, raised), lerpf(-0.257, -0.290, raised) + _recoil * 0.024)
			rifle.rotation = Vector3(lerpf(-0.23, 0.0, raised) + _recoil * 0.065, 0, lerpf(0.015, 0.0, raised))
			head.rotation.x -= raised * 0.08
			head.rotation.z -= raised * 0.045
			_pose_guard_grip()
	else:
		arms[1].rotation.x += _talk*(0.38+sin(clock*2.1)*0.10)
		arms[1].rotation.z += _talk*0.14
		elbows[1].rotation.x += _talk*(0.70+sin(clock*2.1+0.8)*0.14)
		elbows[1].rotation.y = _talk*sin(clock*1.8)*0.12
		if role == "wounded":
			arms[0].rotation = Vector3(lerpf(0.18,0.48,idle_injury),0,0.05)
			elbows[0].rotation = Vector3(0.16,0,lerpf(0.56,1.70,idle_injury))
	_sync_detailed_model()

func _pose_guard_grip() -> void:
	# Both palms follow the actual gun, including low ready and recoil. The
	# elbow pole keeps the arms bent down/out instead of splayed sideways.
	var grips := [Vector3(0, -0.042, -0.105), Vector3(0.016, -0.034, 0.055)]
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var palm_local := Vector3(side * 0.027, -0.288, -0.015)
		var target: Vector3 = rifle.transform * grips[i]
		var shoulder := arms[i].position
		var offset := target - shoulder
		var upper_length := elbows[i].position.length()
		var lower_length := palm_local.length()
		var distance := clampf(offset.length(), 0.035, upper_length + lower_length - 0.002)
		var direction := offset.normalized()
		var tucked := smoothstep(0.0, 1.0, _aim)
		var elbow_out := lerpf(0.34, 0.20 if i == 0 else 0.28, tucked)
		var pole := Vector3(side * elbow_out, -0.92, 0.10)
		pole = (pole - direction * pole.dot(direction)).normalized()
		var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
		var height := sqrt(maxf(0.0, upper_length * upper_length - along * along))
		var elbow_at := shoulder + direction * along + pole * height
		var reached_target := shoulder + direction * distance
		var upper_basis := _limb_basis(elbow_at - shoulder, Vector3.BACK)
		# The authored fingers curl toward local -Z. The support palm faces up;
		# the firing palm faces inward toward the stock's right side.
		var palm_back: Vector3 = rifle.basis * (Vector3.DOWN if i == 0 else Vector3.RIGHT)
		var lower_basis := _limb_basis(reached_target - elbow_at, palm_back)
		lower_basis = lower_basis * Basis(Quaternion(palm_local.normalized(), Vector3.DOWN))
		arms[i].basis = upper_basis
		elbows[i].basis = upper_basis.inverse() * lower_basis

func _limb_basis(toward_hand: Vector3, back_hint: Vector3) -> Basis:
	var y := -toward_hand.normalized()
	var z := back_hint - y * back_hint.dot(y)
	if z.length_squared() < 0.0001:
		z = Vector3.BACK - y * Vector3.BACK.dot(y)
	z = z.normalized()
	var x := y.cross(z).normalized()
	return Basis(x, y, x.cross(y).normalized())

func _joint(parent: Node3D, title: String, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = title
	joint.position = at
	parent.add_child(joint)
	return joint

func _surface(parent: Node3D) -> SurfaceTool:
	if not _surfaces.has(parent):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[parent] = surface
	return _surfaces[parent]

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, color: Color) -> void:
	surface.set_color(color)
	surface.set_normal(na)
	surface.add_vertex(a)
	surface.set_normal(nc)
	surface.add_vertex(c)
	surface.set_normal(nb)
	surface.add_vertex(b)

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color, rotation_euler: Vector3 = Vector3.ZERO) -> void:
	var surface := _surface(parent)
	var basis := Basis.from_euler(rotation_euler)
	var half := size * 0.5
	var faces := [
		[Vector3(-1,-1,-1),Vector3(-1,1,-1),Vector3(1,1,-1),Vector3(1,-1,-1),Vector3.FORWARD],
		[Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1),Vector3(-1,-1,1),Vector3.BACK],
		[Vector3(-1,-1,1),Vector3(-1,1,1),Vector3(-1,1,-1),Vector3(-1,-1,-1),Vector3.LEFT],
		[Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(1,1,1),Vector3(1,-1,1),Vector3.RIGHT],
		[Vector3(-1,1,-1),Vector3(-1,1,1),Vector3(1,1,1),Vector3(1,1,-1),Vector3.UP],
		[Vector3(-1,-1,1),Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,-1,1),Vector3.DOWN]]
	for face in faces:
		var normal: Vector3 = basis * face[4]
		var a: Vector3 = at + basis * (face[0] * half)
		var b: Vector3 = at + basis * (face[1] * half)
		var c: Vector3 = at + basis * (face[2] * half)
		var d: Vector3 = at + basis * (face[3] * half)
		_triangle(surface,a,b,c,normal,normal,normal,color)
		_triangle(surface,a,c,d,normal,normal,normal,color)

func _loft(parent: Node3D, at: Vector3, rings: Array, color: Color, sides: int = 12) -> void:
	var surface := _surface(parent)
	var sorted := rings.duplicate()
	sorted.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)
	for ring_index in sorted.size() - 1:
		var low: Vector3 = sorted[ring_index]
		var high: Vector3 = sorted[ring_index + 1]
		var low_previous: Vector3 = sorted[maxi(0, ring_index - 1)]
		var high_next: Vector3 = sorted[mini(sorted.size() - 1, ring_index + 2)]
		var low_slope := ((high.y-low_previous.y)+(high.z-low_previous.z))*0.5 / maxf(high.x-low_previous.x,0.001)
		var high_slope := ((high_next.y-low.y)+(high_next.z-low.z))*0.5 / maxf(high_next.x-low.x,0.001)
		for side in sides:
			var angle := TAU * float(side) / sides
			var next_angle := TAU * float(side + 1) / sides
			var a := at + Vector3(cos(angle)*low.y,low.x,sin(angle)*low.z)
			var b := at + Vector3(cos(angle)*high.y,high.x,sin(angle)*high.z)
			var c := at + Vector3(cos(next_angle)*high.y,high.x,sin(next_angle)*high.z)
			var d := at + Vector3(cos(next_angle)*low.y,low.x,sin(next_angle)*low.z)
			var na := Vector3(cos(angle),-low_slope,sin(angle)).normalized()
			var nb := Vector3(cos(angle),-high_slope,sin(angle)).normalized()
			var nc := Vector3(cos(next_angle),-high_slope,sin(next_angle)).normalized()
			var nd := Vector3(cos(next_angle),-low_slope,sin(next_angle)).normalized()
			_triangle(surface,a,b,c,na,nb,nc,color)
			_triangle(surface,a,c,d,na,nc,nd,color)
	for end in [0,sorted.size()-1]:
		var ring: Vector3 = sorted[end]
		var normal := Vector3.DOWN if end == 0 else Vector3.UP
		var center := at + Vector3(0,ring.x,0)
		for side in sides:
			var angle := TAU * float(side) / sides
			var next_angle := TAU * float(side + 1) / sides
			var a := at + Vector3(cos(angle)*ring.y,ring.x,sin(angle)*ring.z)
			var b := at + Vector3(cos(next_angle)*ring.y,ring.x,sin(next_angle)*ring.z)
			if end == 0: _triangle(surface,center,a,b,normal,normal,normal,color)
			else: _triangle(surface,center,b,a,normal,normal,normal,color)

func _oval(parent: Node3D, at: Vector3, size: Vector3, color: Color, sides: int = 12) -> void:
	var rings: Array = []
	for ring in 7:
		var angle := PI * float(ring) / 6
		rings.append(Vector3(cos(angle)*size.y*0.5,maxf(0.001,sin(angle)*size.x*0.5),maxf(0.001,sin(angle)*size.z*0.5)))
	_loft(parent,at,rings,color,sides)

func _flush_meshes() -> void:
	if _cloth_material == null:
		_cloth_material = StandardMaterial3D.new()
		_cloth_material.vertex_color_use_as_albedo = true
		_cloth_material.roughness = 0.86
	for parent in _surfaces:
		var key := role + "/" + str(parent.name)
		if not _mesh_cache.has(key):
			var surface: SurfaceTool = _surfaces[parent]
			surface.index()
			_mesh_cache[key] = surface.commit()
		var instance := MeshInstance3D.new()
		instance.name = "Surface"
		instance.mesh = _mesh_cache[key]
		instance.material_override = _cloth_material
		parent.add_child(instance)
	_surfaces.clear()
