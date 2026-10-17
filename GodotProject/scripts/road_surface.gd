extends RefCounted
## A joined ribbon gives each bend one surface instead of overlapping quads.

static func build(points: Array, half_width: float, elevation: float, uv_scale: float, end_edge := Vector3.ZERO) -> ArrayMesh:
	var edges: Array[Vector3] = []
	for i in points.size():
		var incoming: Vector3 = (points[i]-points[maxi(0,i-1)]).normalized()
		var outgoing: Vector3 = (points[mini(i+1,points.size()-1)]-points[i]).normalized()
		if i==0: incoming = outgoing
		if i==points.size()-1: outgoing = incoming
		var a := Vector3(incoming.z,0,-incoming.x)
		var b := Vector3(outgoing.z,0,-outgoing.x)
		var miter := (a+b).normalized()
		edges.append(miter*half_width/maxf(.5,miter.dot(b)))
	if end_edge!=Vector3.ZERO: edges[-1] = end_edge
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()):
		var a: Vector3 = points[i-1]
		var b: Vector3 = points[i]
		for p in [a-edges[i-1],a+edges[i-1],b+edges[i],a-edges[i-1],b+edges[i],b-edges[i]]:
			surface.set_uv(Vector2(p.x,p.z)*uv_scale)
			surface.add_vertex(Vector3(p.x,elevation,p.z))
	surface.generate_normals()
	surface.generate_tangents()
	return surface.commit()
