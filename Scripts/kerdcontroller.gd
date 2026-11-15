extends CharacterBody3D
@onready var camera_3d: Camera3D = $Pivot/Camera3D
@onready var pivot: Node3D = $Pivot

@export var speed := 10.0
@export var jump_velocity := 4.5

@export var air_accel := 8.0

@export var mouse_sensitivity := 0.003

const FORWARD_LOCKED := false

const MAX_VELOCITY := 1.0

const FLYING_KERD = preload("uid://dws2ata5x1mbo")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DispenseKERD"):
		var my_flying_kerd: RigidBody3D = FLYING_KERD.instantiate()
		get_tree().root.get_child(0).add_child(my_flying_kerd)
		my_flying_kerd.global_position = pivot.global_position
		my_flying_kerd.position += 0.1 * -pivot.global_basis.z
		my_flying_kerd.global_rotation = pivot.global_rotation
		my_flying_kerd.apply_impulse((-pivot.global_basis.z * 50), Vector3.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	# Free the cursor for testing
	if event.is_action_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	camera_3d.fov = min((90 + velocity.length() *.2), 179)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Direction relative to where we're facing
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward = input_dir.y if not FORWARD_LOCKED else -1
	var direction := (transform.basis * Vector3(input_dir.x, 0, forward)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = move_toward(velocity.x, direction.x * speed, air_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, air_accel * delta)

	var pre_move_velocity := velocity
	move_and_slide()
	_bounce_off_kerds(pre_move_velocity)

	pre_move_velocity = velocity
	move_and_slide()
	_bounce_off_kerds(pre_move_velocity)

func _bounce_off_kerds(incoming: Vector3) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var kerd := collision.get_collider()
		if kerd.has_method("bounce"):
			velocity = kerd.bounce(incoming)
			return
