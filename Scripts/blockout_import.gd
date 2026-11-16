@tool
extends EditorScenePostImport
# Makes blockout .blend meshes solid. Meshes with the "kerdable" custom property ticked in Blender
# join the KERDable group so KERDs can be deployed on them

func _post_import(scene: Node) -> Object:
	for mesh_instance: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		mesh_instance.create_trimesh_collision()
		var body := mesh_instance.get_child(-1) as StaticBody3D
		body.collision_mask = 5
		# Blender custom properties come through glTF as "extras" metadata
		var extras: Dictionary = mesh_instance.get_meta("extras", {})
		if extras.get("kerdable", false):
			body.add_to_group("KERDable", true)
	return scene
