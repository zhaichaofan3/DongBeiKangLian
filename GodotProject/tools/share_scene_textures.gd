@tool
extends EditorScenePostImport
## Imported scenes share byte-identical textures without changing their meshes.

func _post_import(scene: Node) -> Object:
	var aliases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/texture_aliases.json"))
	var materials := {}
	var replaced := 0
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var material: Material = node.mesh.surface_get_material(surface)
			if material == null or materials.has(material.get_instance_id()): continue
			materials[material.get_instance_id()] = true
			for property in material.get_property_list():
				if property.type != TYPE_OBJECT: continue
				var value = material.get(property.name)
				if value is Texture2D and aliases.has(value.resource_path):
					var shared := load(aliases[value.resource_path]) as Texture2D
					assert(shared != null, "Missing shared texture: " + value.resource_path)
					material.set(property.name, shared)
					replaced += 1
	print("SHARED SCENE TEXTURES: ", get_source_file(), " | references=", replaced)
	return scene
