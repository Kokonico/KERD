extends Node3D

const LEVEL_SWAP_ELEVATOR = preload("res://Scenes/level_swap_elevator.tscn")

# The elevator the player starts in; the first level is placed around it
@onready var current_elevator: Area3D = $LevelSwapElevator

var current_level: Node3D
var current_level_index := 0

func _ready() -> void:
	current_elevator.elevator_mode = current_elevator.ELEVATOR_MODE.ENTRY
	_load_level(current_level_index)

func _load_level(index: int) -> void:
	current_level = Levels.LEVEL_ORDER[index].instantiate()
	add_child(current_level)

	# Offset the level so its entry point lines up with the elevator the player is in
	var entry_point: Node3D = current_level.get_node("ElevatorEntryPoint")
	current_level.global_transform = current_elevator.global_transform * entry_point.transform.affine_inverse()

	if index + 1 < Levels.LEVEL_ORDER.size():
		_spawn_exit_elevator(Levels.LEVEL_ORDER[index + 1])

func _spawn_exit_elevator(destination: PackedScene) -> void:
	var exit_point: Node3D = current_level.get_node("ElevatorExitPoint")
	var exit_elevator: Area3D = LEVEL_SWAP_ELEVATOR.instantiate()
	exit_elevator.elevator_mode = exit_elevator.ELEVATOR_MODE.EXIT
	exit_elevator.elevator_destination = destination
	# Elevators live under Game, not the level, so they survive the level being freed
	add_child(exit_elevator)
	exit_elevator.global_transform = exit_point.global_transform
	exit_elevator.activated.connect(_on_exit_elevator_activated, CONNECT_ONE_SHOT)

func _on_exit_elevator_activated(elevator: Area3D) -> void:
	_swap_level.call_deferred(elevator)

func _swap_level(elevator: Area3D) -> void:
	current_level.queue_free()
	current_elevator.queue_free()

	current_elevator = elevator
	current_elevator.elevator_mode = current_elevator.ELEVATOR_MODE.ENTRY
	current_level_index = Levels.LEVEL_ORDER.find(elevator.elevator_destination)
	_load_level(current_level_index)
