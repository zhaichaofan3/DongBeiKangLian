extends RefCounted
## Local bounds let the renderer cull woodland cells instead of an entire forest.

const CELL_SIZE := 64.0

static func build(parent: Node3D, label: String, pieces: Array[Dictionary], placements: Array[Transform3D], tint: Color, shadows: bool = true, vertex_tint: bool = false) -> Array[MultiMeshInstance3D]:
	var cells := {}
	for placement in placements:
		var cell := Vector2i(floori(placement.origin.x/CELL_SIZE),floori(placement.origin.z/CELL_SIZE))
		if not cells.has(cell): cells[cell] = []
		cells[cell].append(placement)
	var batches: Array[MultiMeshInstance3D] = []
	for piece in pieces:
		var mesh: Mesh = piece.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var original := mesh.surface_get_material(surface)
			if not original is StandardMaterial3D: continue
			var material := original.duplicate() as StandardMaterial3D
			material.albedo_color = tint
			material.roughness = 1.0
			material.metallic_specular = .12
			material.vertex_color_use_as_albedo = vertex_tint
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold = .45
				material.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.surface_set_material(surface,material)
		for cell: Vector2i in cells:
			var center := Vector3((cell.x+.5)*CELL_SIZE,0,(cell.y+.5)*CELL_SIZE)
			var group: Array = cells[cell]
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.mesh = mesh
			instances.instance_count = group.size()
			var bounds := AABB()
			for i in group.size():
				var transform: Transform3D = group[i]*piece.transform
				transform.origin -= center
				instances.set_instance_transform(i,transform)
				var box := transform*mesh.get_aabb()
				bounds = box if i==0 else bounds.merge(box)
			instances.custom_aabb = bounds
			var trees := MultiMeshInstance3D.new()
			trees.name = "%s_%d_%d_%d" % [label,cell.x,cell.y,batches.size()]
			trees.position = center
			trees.multimesh = instances
			trees.visibility_range_end = 380.0
			trees.visibility_range_end_margin = 20.0
			trees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			trees.set_meta("vegetation_cell",cell)
			trees.set_meta("vegetation_shadow",shadows)
			parent.add_child(trees)
			batches.append(trees)
	return batches
