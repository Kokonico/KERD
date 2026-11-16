extends CharacterBody3D
@onready var camera_3d: Camera3D = $Pivot/Camera3D
@onready var pivot: Node3D = $Pivot
@onready var view_model: Node3D = $ViewModel
@onready var gun: Node3D = $ViewModel/Gun
# Sway tweens move the gun mesh instead of Gun so they stack with the shoot anim
@onready var gun_mesh: Node3D = $"ViewModel/Gun/KERD KERDL"

@export var speed := 10.0
@export var jump_velocity := 4.5

@export var air_accel := 8.0

@export var mouse_sensitivity := 0.003

const FLYING_KERD = preload("uid://dws2ata5x1mbo")
const AIR_MUSIC = preload("res://Audio/Music/MovingFast.wav")

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


const gun_weight := 15.0

# Ignore the floor briefly after a KERD launch, otherwise angled KERDs count as floor and ground friction eats the launch
const LAUNCH_GRACE_TIME := 0.15
var launch_grace := 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var gun_backwards_movement_tween: Tween
var gun_forwards_movement_tween: Tween

var gun_rotate_up_movement_tween: Tween
var gun_rotate_down_movement_tween: Tween

enum SwayState { NONE, IDLE, WALKING }
const WALK_BOB_SPEED_THRESHOLD := 1.0
var gun_sway_state := SwayState.NONE
var gun_sway_tween: Tween
var gun_mesh_base_position: Vector3
var gun_mesh_base_rotation: Vector3

const DEATH_FADE_OUT_TIME := 0.25
const DEATH_HOLD_TIME := 0.3
const DEATH_FADE_IN_TIME := 0.5
var death_fade: ColorRect
var dying := false

# Music plays at full volume while airborne after a KERD launch, fading out on landing
const AIR_MUSIC_GAIN := 4.0 # About +12 dB; the track is mastered quietly (peaks around -16 dB)
const AIR_MUSIC_FADE_IN_SPEED := 6.0 # Linear volume per second
const AIR_MUSIC_FADE_OUT_SPEED := 1.5
var air_music: AudioStreamPlayer
var air_music_volume := 0.0
var kerd_launched := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gun_mesh_base_position = gun_mesh.position
	gun_mesh_base_rotation = gun_mesh.rotation
	_set_gun_sway(SwayState.IDLE)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	death_fade = ColorRect.new()
	death_fade.color = Color.BLACK
	death_fade.modulate.a = 0.0
	death_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(death_fade)
	add_child(fade_layer)

	air_music = AudioStreamPlayer.new()
	air_music.stream = AIR_MUSIC
	air_music.bus = &"Music"
	air_music.volume_linear = 0.0
	# Keep it running silently so the song carries on between flights
	air_music.finished.connect(air_music.play)
	add_child(air_music)
	air_music.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DispenseKERD"):
		audio_stream_player_3d.play()
		_shoot_anim()
		var my_flying_kerd: RigidBody3D = FLYING_KERD.instantiate()
		# Cleared by Game when the level swaps
		my_flying_kerd.add_to_group("player_kerds")
		get_tree().current_scene.add_child(my_flying_kerd)
		my_flying_kerd.global_position = pivot.global_position
		my_flying_kerd.position += 0.5 * -pivot.global_basis.z
		my_flying_kerd.global_rotation = pivot.global_rotation
		my_flying_kerd.apply_impulse((velocity + -pivot.global_basis.z * 50), Vector3.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		view_model.rotate_y(event.relative.x * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	# Free the cursor for testing
	if event.is_action_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	camera_3d.fov = min((90 + velocity.length() *.4), 179)
	
	view_model.global_rotation.x = lerp_angle(view_model.global_rotation.x, camera_3d.global_rotation.x, delta * gun_weight)
	view_model.global_rotation.y = lerp_angle(view_model.global_rotation.y, camera_3d.global_rotation.y, delta * gun_weight)
	

func _physics_process(delta: float) -> void:
	launch_grace = maxf(launch_grace - delta, 0.0)
	var grounded := is_on_floor() and launch_grace <= 0.0

	# Gravity
	if not grounded:
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and grounded:
		velocity.y = jump_velocity

	# Direction relative to where we're facing
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if grounded:
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = move_toward(velocity.x, direction.x * speed, air_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, air_accel * delta)
		_funnel_toward_kerds(delta)

	var pre_move_velocity := velocity
	move_and_slide()
	_bounce_off_kerds(pre_move_velocity)

	pre_move_velocity = velocity
	move_and_slide()
	_bounce_off_kerds(pre_move_velocity)

	_update_air_music(delta)

	var walking := grounded and Vector2(velocity.x, velocity.z).length() > WALK_BOB_SPEED_THRESHOLD
	_set_gun_sway(SwayState.WALKING if walking else SwayState.IDLE)

func _update_air_music(delta: float) -> void:
	# Checked after the bounce so a fresh launch isn't cancelled by this frame's floor contact
	if is_on_floor() and launch_grace <= 0.0:
		kerd_launched = false

	var target := 1.0 if kerd_launched else 0.0
	var fade_speed := AIR_MUSIC_FADE_IN_SPEED if target > air_music_volume else AIR_MUSIC_FADE_OUT_SPEED
	air_music_volume = move_toward(air_music_volume, target, fade_speed * delta)
	air_music.volume_linear = air_music_volume * AIR_MUSIC_GAIN

# Fades to black, moves the player to respawn_position while hidden, then fades back in
func die(respawn_position: Vector3) -> void:
	if dying:
		return
	dying = true
	var fade := create_tween()
	fade.tween_property(death_fade, "modulate:a", 1.0, DEATH_FADE_OUT_TIME)
	fade.tween_interval(DEATH_HOLD_TIME)
	fade.tween_callback(func():
		global_position = respawn_position
		velocity = Vector3.ZERO
		dying = false)
	fade.tween_property(death_fade, "modulate:a", 0.0, DEATH_FADE_IN_TIME)

func _bounce_off_kerds(incoming: Vector3) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var kerd := collision.get_collider()
		if kerd.has_method("bounce") and kerd.is_launch_surface(collision.get_normal()):
			velocity = kerd.bounce(incoming)
			launch_grace = LAUNCH_GRACE_TIME
			kerd_launched = true
			return

func _funnel_toward_kerds(delta: float) -> void:
	for kerd in get_tree().get_nodes_in_group("kerds"):
		var funneled: Vector3 = kerd.funnel(global_position, velocity, delta)
		if funneled != velocity:
			velocity = funneled
			return

func _shoot_anim():
	var needs_reset := false
	if gun_backwards_movement_tween:
		if gun_backwards_movement_tween.is_valid():
			gun_backwards_movement_tween.kill()
			needs_reset = true
	if gun_forwards_movement_tween:
		if gun_forwards_movement_tween.is_valid():
			gun_forwards_movement_tween.kill()
			needs_reset = true
	if gun_rotate_up_movement_tween:
		if gun_rotate_up_movement_tween.is_valid():
			gun_rotate_up_movement_tween.kill()
			needs_reset = true
	if gun_rotate_down_movement_tween:
		if gun_rotate_down_movement_tween.is_valid():
			gun_rotate_down_movement_tween.kill()
			needs_reset = true

	if needs_reset:
		gun.position = Vector3.ZERO
		gun.rotation = Vector3.ZERO
	
	gun_backwards_movement_tween = create_tween()
	gun_forwards_movement_tween = create_tween()
	gun_rotate_down_movement_tween = create_tween()
	gun_rotate_up_movement_tween = create_tween()
	
	gun_backwards_movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	gun_forwards_movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	gun_rotate_down_movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	gun_rotate_up_movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	gun_forwards_movement_tween.tween_property(gun, "position", Vector3.ZERO, 0.4)
	
	gun_backwards_movement_tween.tween_property(gun, "position", Vector3(0, 0.05, 0.45), 0.1)
	gun_backwards_movement_tween.tween_subtween(gun_forwards_movement_tween)
	
	gun_rotate_up_movement_tween.tween_property(gun, "rotation", Vector3(0.1, 0, 0), 0.2)
	gun_rotate_down_movement_tween.tween_property(gun, "rotation", Vector3.ZERO, 0.3)
	
	gun_rotate_up_movement_tween.tween_subtween(gun_rotate_down_movement_tween)
	
	gun_rotate_up_movement_tween.play()
	gun_backwards_movement_tween.play()

func _set_gun_sway(state: SwayState) -> void:
	if state == gun_sway_state:
		return
	gun_sway_state = state
	if gun_sway_tween and gun_sway_tween.is_valid():
		gun_sway_tween.kill()

	gun_sway_tween = create_tween().set_loops()
	gun_sway_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var base := gun_mesh_base_position
	var base_rot := gun_mesh_base_rotation

	match state:
		SwayState.IDLE:
			# Slow breathing
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(0, 0.012, 0), 1.2)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot + Vector3(0.02, 0, 0.01), 1.2)
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(0, -0.008, 0), 1.2)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot + Vector3(-0.01, 0, -0.01), 1.2)
		SwayState.WALKING:
			# Side to side once per two steps, dipping on each step
			const STEP := 0.16
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(0.02, -0.025, 0), STEP)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot + Vector3(0, 0, -0.04), STEP)
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(0, 0.005, 0), STEP)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot, STEP)
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(-0.02, -0.025, 0), STEP)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot + Vector3(0, 0, 0.04), STEP)
			gun_sway_tween.tween_property(gun_mesh, "position", base + Vector3(0, 0.005, 0), STEP)
			gun_sway_tween.parallel().tween_property(gun_mesh, "rotation", base_rot, STEP)
