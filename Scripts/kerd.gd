extends StaticBody3D
# Minimum speed you leave the KERD with
@export var bounce_strength := 10.0
# How much of your incoming speed is kept
@export var restitution := 0.9


func bounce(incoming: Vector3) -> Vector3:
	var up := global_basis.y.normalized()
	var into := incoming.dot(up)
	var out_speed := maxf(bounce_strength, -into * restitution)
	return incoming - up * into + up * out_speed
