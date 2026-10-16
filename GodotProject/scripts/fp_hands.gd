extends Node3D
## Continuous CC0 skinned hands by para. Finger poses are authored for our guns;
## the source asset's generic 2.25 second test motion is deliberately not used.

const LEFT_MODEL = preload("res://assets/first_person/hand_left.glb")
const RIGHT_MODEL = preload("res://assets/first_person/hand_right.glb")
const HAND_SCALE := 0.78
var is_right := false
var weapon_index := 0
var limb_scale := 1.0
var skeleton: Skeleton3D
var rest_rotations: Dictionary = {}
var finger_amounts := [0.9, 1.0, 1.0, 1.0, 0.45]
var sleeve: MeshInstance3D
var cuff: MeshInstance3D
var sleeve_material: StandardMaterial3D
var last_sleeve_transform := Transform3D.IDENTITY
var sleeve_ready := false
var sleeve_endpoint := Vector3.INF # Optional parent-space endpoint for close combat.
const SLEEVE_RINGS := 23
const SLEEVE_SEGMENTS := 24

static func create(right_hand: bool, gun_index: int, cloth: StandardMaterial3D, cuff_material: StandardMaterial3D) -> Node3D:
    var hand = load("res://scripts/fp_hands.gd").new()
    hand.is_right = right_hand
    hand.weapon_index = gun_index
    hand.name = "RightHand" if right_hand else "LeftHand"
    hand._build(cloth, cuff_material)
    return hand

func _build(cloth: StandardMaterial3D, cuff_material: StandardMaterial3D) -> void:
    # Scale skin, cuff and sleeve together to fit the supplied rifle's fore-end.
    limb_scale = 1.14 if not is_right and weapon_index == 0 else 1.0
    var instance: Node3D = (RIGHT_MODEL if is_right else LEFT_MODEL).instantiate()
    instance.scale = Vector3.ONE * HAND_SCALE * limb_scale
    add_child(instance)
    skeleton = _find_skeleton(instance)
    for i in skeleton.get_bone_count():
        rest_rotations[i] = skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
    _prepare_skin(instance)
    sleeve_material = cloth
    sleeve = MeshInstance3D.new()
    sleeve.name = "WoolSleeve"
    sleeve.material_override = cloth
    sleeve.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(sleeve)
    cuff = MeshInstance3D.new()
    cuff.name = "WoolCuff"
    cuff.mesh = _cuff_mesh()
    cuff.material_override = cuff_material
    cuff.scale = Vector3.ONE * limb_scale
    cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(cuff)
    _cuff_details(cuff_material)
    if is_right:
        basis = Basis(Vector3.UP, Vector3.FORWARD, Vector3.LEFT)
        position = Vector3(0.048,-0.062,0.136) if weapon_index == 0 else Vector3(0.048,-0.062,0.110)
    elif weapon_index == 0:
        # The support wrist rises diagonally into the fore-end. A transverse
        # wrist forced the sleeve through a visible right-angle turn.
        basis = Basis(Vector3.BACK, deg_to_rad(70.0)) * Basis(Vector3.BACK, Vector3.RIGHT, Vector3.UP) * Basis(Vector3.UP, deg_to_rad(-160.0))
        position = Vector3(-0.063,-0.068,-0.300)
    else:
        basis = Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT)
        position = Vector3(-0.050,-0.111,0.125)
    pose("grip", 1.0, 1.0)
    update_sleeve()

func _find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D: return node
    for child in node.get_children():
        var found := _find_skeleton(child)
        if found: return found
    return null

func _prepare_skin(node: Node) -> void:
    if node is MeshInstance3D:
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var skin: StandardMaterial3D = node.get_active_material(0).duplicate()
        skin.albedo_color = Color(0.84,0.78,0.70)
        skin.roughness = 0.79
        node.material_override = skin
    for child in node.get_children(): _prepare_skin(child)

func pose(action: String, weight: float, delta: float, trigger := 0.0) -> void:
    # The rifle fore-end and pistol grip need different finger arcs. In
    # particular, the support palm must carry the wood instead of pinching
    # an empty circle below it, and the pistol firing hand sits higher.
    var target: Array
    if weapon_index == 0:
        target = [0.40,0.88,0.94,1.00,0.56] if is_right else [0.72,0.82,0.88,0.94,0.50]
    else:
        target = [0.40,0.92,1.00,1.05,0.58] if is_right else [0.62,0.80,0.88,0.94,0.40]
    var requested: Array = target.duplicate()
    match action:
        "bolt": requested = [0.83, 0.95, 1.0, 1.10, 0.78]
        "clip": requested = [0.47, 1.12, 1.17, 1.23, 0.72]
        "push": requested = [0.55, 0.85, 0.96, 1.08, 0.18]
        "release": requested = [0.10,0.22,0.25,0.27,0.16]
    var smooth := 1.0 - exp(-delta * 30.0)
    var side := "R" if is_right else "L"
    var finger_names := ["index","middle","ring","pinky"]
    for f in 5:
        var value: float = lerpf(target[f],requested[f],clampf(weight,0,1))
        if f == 0 and is_right and action == "grip": value += trigger * 0.23
        finger_amounts[f] = lerpf(finger_amounts[f],value,smooth)
    for f in 4:
        for joint in range(1,4):
            var bone := skeleton.find_bone("f_%s_%02d_%s" % [finger_names[f],joint,side])
            if bone >= 0:
                var amount: float = finger_amounts[f] * [0.84,1.18,0.72][joint-1]
                skeleton.set_bone_pose_rotation(bone, rest_rotations[bone] * Quaternion(Vector3.RIGHT, amount))
    for joint in range(1,4):
        var bone := skeleton.find_bone("thumb_%02d_%s" % [joint,side])
        if bone >= 0:
            var q: Quaternion = Quaternion(Vector3.RIGHT, finger_amounts[4]*[0.32,0.63,0.52][joint-1])
            if joint == 1: q = Quaternion(Vector3.UP,(-0.26 if is_right else 0.26)) * q
            skeleton.set_bone_pose_rotation(bone,rest_rotations[bone]*q)

func bolt_contact() -> Vector3:
    # Use the current curled skeleton, including the finger transition,
    # rather than a fixed rest-space guess for the bolt-knob cradle.
    skeleton.force_update_all_bone_transforms()
    var middle := skeleton.find_bone("f_middle_03_R")
    var thumb := skeleton.find_bone("thumb_03_R")
    var center := (skeleton.get_bone_global_pose(middle).origin + skeleton.get_bone_global_pose(thumb).origin) * 0.5
    # Convert through the same global path used by the motion verifier. The
    # previous parent-transform shortcut dropped the imported instance's
    # effective basis, leaving a fixed ~2.7 cm offset from the bolt knob.
    return to_local(skeleton.to_global(center))

func loading_contact() -> Vector3:
    skeleton.force_update_all_bone_transforms()
    var thumb := skeleton.find_bone("thumb_03_L")
    return to_local(skeleton.to_global(skeleton.get_bone_global_pose(thumb).origin))

func _cuff_mesh() -> ArrayMesh:
    # An oval cloth opening with a turned hem; the skin continues inside it.
    # The last ring overlaps the sleeve, including while the wrist turns.
    var profile := [Vector3(-0.014,0.0285,0.023),Vector3(-0.005,0.0285,0.023),
        Vector3(-0.004,0.0305,0.025),Vector3(-0.008,0.032,0.0265),
        Vector3(-0.019,0.033,0.028),Vector3(-0.038,0.035,0.030),
        Vector3(-0.048,0.036,0.031)]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for r in profile.size()-1:
        for s in SLEEVE_SEGMENTS:
            for corner in [Vector2i(r,s),Vector2i(r+1,s),Vector2i(r+1,s+1),Vector2i(r,s),Vector2i(r+1,s+1),Vector2i(r,s+1)]:
                var section: Vector3 = profile[corner.x]
                var angle := float(corner.y)*TAU/SLEEVE_SEGMENTS
                surface.set_uv(Vector2(float(corner.y)/SLEEVE_SEGMENTS, float(corner.x)/(profile.size()-1)))
                surface.add_vertex(Vector3(cos(angle)*section.y,section.x,sin(angle)*section.z))
    surface.generate_normals()
    return surface.commit()

func _cuff_details(material: StandardMaterial3D) -> void:
    var stitches := MeshInstance3D.new()
    stitches.name = "CuffStitching"
    var thread := material.duplicate() as StandardMaterial3D
    thread.albedo_color = material.albedo_color.lightened(0.18)
    thread.albedo_texture = null
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in [Vector3(-0.012,0.0326,0.0273),Vector3(-0.040,0.0356,0.0307)]:
        for s in 40:
            var a := TAU*float(s)/40.0
            var b := a+TAU/40.0*0.52
            for uv in [Vector2(a,-0.00045),Vector2(a,0.00045),Vector2(b,0.00045),Vector2(a,-0.00045),Vector2(b,0.00045),Vector2(b,-0.00045)]:
                surface.set_normal(Vector3(cos(uv.x),0,sin(uv.x)))
                surface.add_vertex(Vector3(cos(uv.x)*row.y,row.x+uv.y,sin(uv.x)*row.z))
    stitches.mesh = surface.commit()
    stitches.material_override = thread
    stitches.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    cuff.add_child(stitches)
    var button := MeshInstance3D.new()
    button.name = "ClothCuffButton"
    var button_mesh := SphereMesh.new()
    button_mesh.radius = 0.0045
    button_mesh.height = 0.009
    button_mesh.radial_segments = 12
    button_mesh.rings = 6
    button.mesh = button_mesh
    button.scale = Vector3(0.38,1,1)
    button.position = Vector3(0.034,-0.027,0)
    button.material_override = material
    button.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    cuff.add_child(button)

func update_sleeve() -> void:
    if sleeve_ready and transform.is_equal_approx(last_sleeve_transform): return
    last_sleeve_transform = transform
    sleeve_ready = true
    # End the forearms below the frame without extending long tubes through
    # the near plane when the held weapon is brought closer to the camera.
    var end_weapon := Vector3(0.18,-0.23,0.20) if is_right else Vector3(-0.25,-0.27,0.18)
    if not is_right and weapon_index == 0:
        end_weapon = Vector3(-0.42,-0.30,0.0)
    if sleeve_endpoint.is_finite(): end_weapon = sleeve_endpoint
    var end := transform.affine_inverse() * end_weapon
    var start := Vector3(0,-0.044 * limb_scale,0)
    var length := start.distance_to(end)
    # A cubic curve leaves the cuff along the wrist, then bends into the
    # forearm. The old straight tube intersected the cuff at an oblique angle.
    var control_a := start + Vector3.DOWN * minf(length*0.30,0.10)
    var control_b := end.lerp(start,0.28)
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var points: Array[PackedVector3Array] = []
    var axis_x := Vector3.RIGHT
    for ring in SLEEVE_RINGS:
        var t := float(ring)/(SLEEVE_RINGS-1)
        var center := start.bezier_interpolate(control_a,control_b,end,t)
        var direction := start.bezier_derivative(control_a,control_b,end,t).normalized()
        # Transport the previous cross-section instead of switching reference
        # axes at a threshold, which caused sleeve twists during hand motions.
        axis_x = (axis_x-direction*axis_x.dot(direction)).normalized()
        var axis_z := direction.cross(axis_x).normalized()
        var radius_x := lerpf(0.0355,0.060,pow(t,0.72)) * limb_scale
        var radius_z := lerpf(0.0305,0.052,pow(t,0.72)) * limb_scale
        var row := PackedVector3Array()
        for segment in SLEEVE_SEGMENTS:
            var angle := float(segment)*TAU/SLEEVE_SEGMENTS
            var gathering := sin(t*PI) * exp(-t*2.0)
            var fold := gathering * (sin(t*PI*12.0+sin(angle*3.0)*0.7)*0.0038 + sin(angle*6.0+t*5.0)*0.0022)
            row.append(center+axis_x*cos(angle)*(radius_x+fold)+axis_z*sin(angle)*(radius_z+fold))
        points.append(row)
    for r in SLEEVE_RINGS-1:
        for s in SLEEVE_SEGMENTS:
            for v in [Vector2i(r,s),Vector2i(r+1,s),Vector2i(r+1,s+1),Vector2i(r,s),Vector2i(r+1,s+1),Vector2i(r,s+1)]:
                # Keep the closing UV at 1, avoiding a stretched stripe at 0.
                surface.set_uv(Vector2(float(v.y)/SLEEVE_SEGMENTS*2.0,float(v.x)/(SLEEVE_RINGS-1)*4.0))
                surface.add_vertex(points[v.x][v.y%SLEEVE_SEGMENTS])
    surface.generate_normals()
    sleeve.mesh = surface.commit()
