extends SceneTree
func _initialize():
 var scene = load("res://assets/characters/field_character.glb").instantiate()
 root.add_child(scene)
 inspect(scene)
 scene.free()
 quit()
func inspect(node):
 print(node.name, " / ", node.get_class())
 if node is Skeleton3D:
  for i in node.get_bone_count(): print("BONE ", i, " ", node.get_bone_name(i))
 for child in node.get_children(): inspect(child)
