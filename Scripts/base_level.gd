class_name BaseLevel
extends Node3D

# When above 0, every KERD in this level launches the player at exactly this speed along its facing,
# ignoring incoming speed. A KERD's own launch_speed_override beats this
@export var kerd_launch_speed_override := 0.0

func _ready() -> void:
	add_to_group("levels")
