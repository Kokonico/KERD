extends StaticBody3D
# Minimum speed you leave the KERD with
@export var bounce_strength := 10.0
# How much of your incoming speed is kept
@export var restitution := 0.9
# When above 0, always launches at exactly this speed along the KERD's facing, ignoring incoming speed.
# Takes priority over the level's kerd_launch_speed_override
@export var launch_speed_override := 0.0

@export_group("Funnel")
# Invisible tunnel along the KERD's facing that steers airborne players onto it, like Portal 2 funneling
@export var funnel_enabled := true
# How far out from the KERD's face the tunnel reaches
@export var funnel_length := 25.0
# How far off-center a player can be headed and still get pulled in
@export var funnel_radius := 3.5
# How hard the tunnel corrects sideways velocity
@export var funnel_strength := 6.0
# Must be moving toward the KERD at least this fast for the tunnel to engage
@export var funnel_min_approach_speed := 2.0
@export_group("")

@export var deployed := false

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Faces this close to the KERD's facing count as the launch surface. Hitting the rim or underside doesn't launch
const LAUNCH_FACE_DOT := 0.5
# Caps the sideways correction so the tunnel can't fling you when you're about to land
const FUNNEL_MAX_SIDE_SPEED := 15.0

@onready var kerdmodel: Node3D = $KERDmodel

func _ready() -> void:
	add_to_group("kerds")
	if deployed:
		kerdmodel.scale = Vector3.ONE * 0.11
		var deploy_tween = create_tween()
		deploy_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		deploy_tween.tween_property(kerdmodel, "scale", Vector3.ONE, 0.5)

		deploy_tween.play()

func is_launch_surface(collision_normal: Vector3) -> bool:
	return collision_normal.dot(global_basis.y.normalized()) > LAUNCH_FACE_DOT

func bounce(incoming: Vector3) -> Vector3:
	audio_stream_player_3d.play()
	var up := global_basis.y.normalized()
	var override_speed := _launch_speed_override()
	if override_speed > 0.0:
		return up * override_speed
	var into := incoming.dot(up)
	var out_speed := maxf(bounce_strength, -into * restitution)
	return incoming - up * into + up * out_speed

# Nudges sideways velocity so a player heading at the KERD lands on its center
func funnel(body_position: Vector3, velocity: Vector3, delta: float) -> Vector3:
	if not funnel_enabled:
		return velocity
	var up := global_basis.y.normalized()
	var offset := body_position - global_position
	var distance := offset.dot(up)
	var approach_speed := -velocity.dot(up)
	if distance < 0.0 or distance > funnel_length or approach_speed < funnel_min_approach_speed:
		return velocity

	var side_offset := offset - up * distance
	var side_velocity := velocity - up * velocity.dot(up)
	var time_to_land := distance / approach_speed
	# Only catch near misses, so players can still deliberately fly past
	if (side_offset + side_velocity * time_to_land).length() > funnel_radius:
		return velocity

	var target_side_velocity := (-side_offset / maxf(time_to_land, 0.05)).limit_length(FUNNEL_MAX_SIDE_SPEED)
	var new_side_velocity := side_velocity.lerp(target_side_velocity, 1.0 - exp(-funnel_strength * delta))
	return velocity - side_velocity + new_side_velocity

func _launch_speed_override() -> float:
	if launch_speed_override > 0.0:
		return launch_speed_override
	var level := get_tree().get_first_node_in_group("levels") as BaseLevel
	return level.kerd_launch_speed_override if level else 0.0
