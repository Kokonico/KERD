extends Area3D

signal activated(elevator: Area3D)

enum ELEVATOR_MODE {
	ENTRY,
	EXIT
}

@export var elevator_mode := ELEVATOR_MODE.ENTRY
@export var elevator_destination: PackedScene

@onready var fog_volume: FogVolume = $FogVolume
@onready var area_shape: CollisionShape3D = $AreaShape

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Reshapes the trigger area and fog to match a level's exit shape, given relative to this elevator
func fit_to(shape_node: CollisionShape3D) -> void:
	area_shape.shape = shape_node.shape
	area_shape.transform = shape_node.transform
	fog_volume.transform = shape_node.transform
	var shape := shape_node.shape
	if shape is BoxShape3D:
		fog_volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		fog_volume.size = shape.size
	elif shape is SphereShape3D:
		fog_volume.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		fog_volume.size = Vector3.ONE * shape.radius * 2.0
	elif shape is CylinderShape3D:
		fog_volume.shape = RenderingServer.FOG_VOLUME_SHAPE_CYLINDER
		fog_volume.size = Vector3(shape.radius * 2.0, shape.height, shape.radius * 2.0)
	else:
		push_warning("Exit shape %s has no matching fog shape, fog left as is" % shape.get_class())

# Thins the elevator's fog out to nothing once the level around it has loaded
func clear_fog(duration: float) -> void:
	var fog_material := fog_volume.material as FogMaterial
	var fade := create_tween()
	fade.tween_property(fog_material, "density", 0.0, duration)
	fade.tween_callback(fog_volume.hide)

func _on_body_entered(body: Node3D) -> void:
	if elevator_mode != ELEVATOR_MODE.EXIT or elevator_destination == null:
		return
	if body is CharacterBody3D:
		activated.emit(self)
