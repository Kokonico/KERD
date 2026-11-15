extends Area3D

enum ELEVATOR_MODE {
	ENTRY,
	EXIT
}

@export var elevator_mode := ELEVATOR_MODE.ENTRY
@export var elevator_destination: PackedScene
