extends RefCounted
const Dressing = preload("res://scripts/asset_dressing.gd")
## S12 distant woodland: shared mesh batches, with all trunks on existing land.
var container: Node3D
var placements: Array[Dictionary] = []
var batches: Array[MultiMeshInstance3D] = []

func build(parent: Node3D) -> void:
	container = Node3D.new()
	container.name = "S12_岸上远林"
	parent.add_child(container)
	_build_banks()
	var source := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
	var parts: Array[Dictionary] = []
	_collect(source, Transform3D.IDENTITY, parts)
	var bounds := AABB()
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	var normalize := Transform3D(Basis.IDENTITY, -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z))
	var rng := RandomNumberGenerator.new()
	rng.seed = 193812
	# The river spans x=88..132.5. Give crowns extra clearance on both banks.
	var regions := [Rect2(-102,-26,80,220), Rect2(-17,-40,95,24), Rect2(-18,110,98,90), Rect2(150,-20,136,212)]
	var counts := [125,20,65,180]
	var chunks: Dictionary = {}
	for region_id in regions.size():
		var region: Rect2 = regions[region_id]
		for i in counts[region_id]:
			var at := Vector3(rng.randf_range(region.position.x,region.end.x), -0.38, rng.randf_range(region.position.y,region.end.y))
			var excluded := false
			for cabin in 4:
				if Vector2(at.x-142-cabin*18, at.z-20-cabin*19).length() < 10: excluded = true
			if Rect2(-29,56,22,22).has_point(Vector2(at.x,at.z)): excluded = true
			if excluded: continue
			var height := rng.randf_range(8.5,15.0)
			var factor := height / bounds.size.y
			var transform := Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*factor),at)
			var key := Vector2i(floori(at.x/48), floori(at.z/48))
			if not chunks.has(key): chunks[key] = []
			chunks[key].append({"transform":transform, "color":Color("8d9986").lerp(Color("c6c5a5"), rng.randf()*0.6)})
			placements.append({"base":[at.x,at.y,at.z], "height":height, "region":region_id, "ground":-0.35})
	for part in parts:
		var mesh: Mesh = part.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var mat := mesh.surface_get_material(surface).duplicate() as StandardMaterial3D
			if mat != null:
				mat.vertex_color_use_as_albedo = true
				mat.albedo_color = Color("819573")
				mat.roughness = 1.0
				mat.metallic_specular = 0.12
				if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold = 0.45
					mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh.surface_set_material(surface,mat)
		for key: Vector2i in chunks:
			var group: Array = chunks[key]
			var center := Vector3(key.x*48+24,0,key.y*48+24)
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.use_colors = true
			multimesh.mesh = mesh
			multimesh.instance_count = group.size()
			for i in group.size():
				var placement: Transform3D = group[i].transform * normalize * part.transform
				placement.origin -= center
				multimesh.set_instance_transform(i,placement)
				multimesh.set_instance_color(i,group[i].color)
			var batch := MultiMeshInstance3D.new()
			batch.name = "S12_远林分块"
			batch.position = center
			batch.multimesh = multimesh
			batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			container.add_child(batch)
			batches.append(batch)
	source.free()

func _build_banks() -> void:
	var material := Dressing.pbr("forest_ground_04",0.22,Color("7e8474"))
	for east in [false,true]:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for z in range(-124,216,4):
			var x := 132.5 if east else 88.0
			var width := (-1.2 if east else 1.0)*(1.0+sin(z*0.38)*0.12)
			var top := -0.35 if east or z < 0 or z >= 96 else 0.0
			var a := Vector3(x,top,z)
			var b := Vector3(x,top,z+4)
			var c := Vector3(x+width,-1.4,z+4)
			var d := Vector3(x+width,-1.4,z)
			for point in ([a,c,b,a,d,c] if east else [a,b,c,a,c,d]): surface.add_vertex(point)
		surface.generate_normals()
		var bank := MeshInstance3D.new()
		bank.name = "S12对岸土坡" if east else "S12近岸土坡"
		bank.mesh = surface.commit()
		bank.material_override = material
		bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(bank)

func _collect(node: Node3D, transform: Transform3D, parts: Array[Dictionary]) -> void:
	var current := transform * node.transform
	if node is MeshInstance3D:
		parts.append({"mesh":node.mesh, "transform":current})
	for child in node.get_children():
		if child is Node3D: _collect(child,current,parts)

func apply_quality(level: int) -> void:
	for batch in batches:
		batch.visibility_range_end = [210.0,280.0,340.0][level]
		batch.visibility_range_end_margin = 12.0
