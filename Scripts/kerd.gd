extends StaticBody3D
# Minimum speed you leave the KERD with
@export var bounce_strength := 10.0
# How much of your incoming speed is kept
@export var restitution := 0.9

@export var deployed := false


@onready var kerdmodel: Node3D = $KERDmodel

func _ready() -> void:
	if deployed:
		kerdmodel.scale = Vector3.ONE * 0.11
		var deploy_tween = create_tween()
		deploy_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		deploy_tween.tween_property(kerdmodel, "scale", Vector3.ONE, 0.5)
		
		deploy_tween.play()

func bounce(incoming: Vector3) -> Vector3:
	var up := global_basis.y.normalized()
	var into := incoming.dot(up)
	var out_speed := maxf(bounce_strength, -into * restitution)
	return incoming - up * into + up * out_speed
