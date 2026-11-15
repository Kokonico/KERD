extends RigidBody3D
const KERD = preload("uid://cdkfp1xh3dbn0")

const RAY_LENGTH := 3.0
# Height of the KERD base
const SURFACE_OFFSET := 0.9
# A bit bigger than the TouchingArea so the nearest-surface query always reaches what it touched
const PROBE_RADIUS := 1.1

var spent := false

func _on_touching_area_body_entered(body: Node3D) -> void:
	if spent or not body.is_in_group("KERDable"):
		return
	spent = true
	var new_kerd: Node3D = KERD.instantiate()
	new_kerd.deployed = true
	get_tree().root.get_child(0).add_child(new_kerd)
	var hit := _find_surface(body)
	if hit.is_empty():
		# Couldn't find face :(
		new_kerd.global_position = global_position
	else:
		var normal: Vector3 = hit.normal
		new_kerd.global_transform = Transform3D(_surface_basis(normal), hit.position + normal * SURFACE_OFFSET)
	queue_free()


func _find_surface(body: Node3D) -> Dictionary:
	var space := get_world_3d().direct_space_state
	if linear_velocity.length_squared() > 0.01:
		var ray := PhysicsRayQueryParameters3D.create(global_position, global_position + linear_velocity.normalized() * RAY_LENGTH)
		ray.exclude = [get_rid()]
		var result := space.intersect_ray(ray)
		if not result.is_empty() and result.collider == body:
			return result

	var probe_shape := SphereShape3D.new()
	probe_shape.radius = PROBE_RADIUS
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = probe_shape
	probe.transform = Transform3D(Basis.IDENTITY, global_position)
	probe.exclude = [get_rid()]
	for i in 4:
		var info := space.get_rest_info(probe)
		if info.is_empty():
			break
		if info.collider_id == body.get_instance_id():
			return {"position": info.point, "normal": info.normal}
		probe.exclude += [info.rid]
	return {}

func _surface_basis(normal: Vector3) -> Basis:
	var forward := linear_velocity - normal * linear_velocity.dot(normal)
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD if absf(normal.dot(Vector3.UP)) > 0.99 else Vector3.UP
		forward -= normal * forward.dot(normal)
	return Basis.looking_at(forward.normalized(), normal)
