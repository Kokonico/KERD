extends Node3D

const LEVEL_SWAP_ELEVATOR = preload("res://Scenes/level_swap_elevator.tscn")

# Screen-filling depth fog that hides the level swap. Elevator fog volumes show where it'll happen
const TRANSITION_FOG_DENSITY := 2.0
const FOG_IN_TIME := 0.1
const FOG_OUT_TIME := .3

@onready var kerdcontroller: CharacterBody3D = $KERDCONTROLLER

# The elevator the player starts in; the first level is placed around it
@onready var current_elevator: Area3D = $LevelSwapElevator
# Shared by every UniversalEnvironment instance, so this is the one being rendered
@onready var environment: Environment = $UniversalEnvironment/EnvironmentNode.environment

var current_level: Node3D
var current_level_index := 0
var fog_tween: Tween

func _ready() -> void:
	current_elevator.elevator_mode = current_elevator.ELEVATOR_MODE.ENTRY
	# Start fogged in so the first level appears the same way the rest do
	environment.fog_enabled = true
	environment.fog_density = TRANSITION_FOG_DENSITY
	_load_level(current_level_index)
	_clear_transition_fog()

func _exit_tree() -> void:
	# The Environment resource outlives this scene, so don't leave it fogged for the menu
	environment.fog_enabled = false
	environment.fog_density = 0.0

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
	exit_elevator.fit_to(exit_point.get_node("ExitShape"))
	exit_elevator.activated.connect(_on_exit_elevator_activated, CONNECT_ONE_SHOT)

func _on_exit_elevator_activated(elevator: Area3D) -> void:
	environment.fog_enabled = true
	kerdcontroller.velocity = Vector3.ZERO
	await _tween_transition_fog(TRANSITION_FOG_DENSITY, FOG_IN_TIME).finished
	_swap_level(elevator)
	_clear_transition_fog()

func _swap_level(elevator: Area3D) -> void:
	current_level.queue_free()
	current_elevator.queue_free()
	# Thrown and deployed KERDs live under Game, so they'd otherwise carry over
	for kerd in get_tree().get_nodes_in_group("player_kerds"):
		kerd.queue_free()

	current_elevator = elevator
	current_elevator.elevator_mode = current_elevator.ELEVATOR_MODE.ENTRY
	current_level_index = Levels.LEVEL_ORDER.find(elevator.elevator_destination)
	_load_level(current_level_index)

func _clear_transition_fog() -> void:
	# Let the new level render a frame under the fog so any load hitch stays hidden
	await get_tree().process_frame
	current_elevator.clear_fog(FOG_OUT_TIME)
	var fade := _tween_transition_fog(0.0, FOG_OUT_TIME)
	fade.tween_callback(func(): environment.fog_enabled = false)

func _tween_transition_fog(density: float, duration: float) -> Tween:
	if fog_tween and fog_tween.is_valid():
		fog_tween.kill()
	fog_tween = create_tween()
	fog_tween.tween_property(environment, "fog_density", density, duration)
	return fog_tween
