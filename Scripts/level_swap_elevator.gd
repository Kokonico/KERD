extends Area3D

signal activated(elevator: Area3D)

enum ELEVATOR_MODE {
	ENTRY,
	EXIT
}

@export var elevator_mode := ELEVATOR_MODE.ENTRY
@export var elevator_destination: PackedScene

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if elevator_mode != ELEVATOR_MODE.EXIT or elevator_destination == null:
		return
	if body is CharacterBody3D:
		activated.emit(self)
