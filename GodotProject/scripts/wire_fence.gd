extends RefCounted
## Low side-path obstacles. Opaque mission walls remain separate.

const SOURCE = preload("res://assets/user_expansion_20261015/barbed_wire.glb")
const HEIGHT := .8
const WIDTH := 2.4390833
const DEPTH := .7443

static func add_visual(parent: Node3D, from: Vector3, to: Vector3) -> Node3D:
	var fence := Node3D.new()
	fence.name = "用户木桩铁丝网"
	fence.set_meta("user_wire_fence", true)
	parent.add_child(fence)
	var direction := to - from
	var length := direction.length()
	var count := maxi(1, roundi(length / WIDTH))
	var basis := Basis(Vector3.UP, atan2(-direction.z, direction.x))
	basis = basis.scaled(Vector3(length / count / WIDTH, 1, 1))
	var source := SOURCE.instantiate() as Node3D
	for part: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = part.mesh
		instances.instance_count = count
		for i in count:
			instances.set_instance_transform(i, Transform3D(basis, from.lerp(to, (i + .5) / count)) * part.transform)
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = instances
		fence.add_child(batch)
	source.free()
	return fence

static func add_blocker(parent: Node3D, title: String, from: Vector3, to: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	body.set_meta("low_side_wire", true)
	body.position = (from + to) * .5 + Vector3.UP * HEIGHT * .5
	body.rotation.y = atan2(-(to.z-from.z), to.x-from.x)
	parent.add_child(body)
	var length := from.distance_to(to)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, HEIGHT, DEPTH)
	collider.shape = shape
	body.add_child(collider)
	add_visual(body, Vector3(-length*.5, -HEIGHT*.5, 0), Vector3(length*.5, -HEIGHT*.5, 0))
	return body
